
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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
  Call_PostAddPermission_594048 = ref object of OpenApiRestCall_593421
proc url_PostAddPermission_594050(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddPermission_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = path.getOrDefault("QueueName")
  valid_594051 = validateParameter(valid_594051, JString, required = true,
                                 default = nil)
  if valid_594051 != nil:
    section.add "QueueName", valid_594051
  var valid_594052 = path.getOrDefault("AccountNumber")
  valid_594052 = validateParameter(valid_594052, JInt, required = true, default = nil)
  if valid_594052 != nil:
    section.add "AccountNumber", valid_594052
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594053 = query.getOrDefault("Action")
  valid_594053 = validateParameter(valid_594053, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_594053 != nil:
    section.add "Action", valid_594053
  var valid_594054 = query.getOrDefault("Version")
  valid_594054 = validateParameter(valid_594054, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594054 != nil:
    section.add "Version", valid_594054
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
  var valid_594055 = header.getOrDefault("X-Amz-Date")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Date", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Security-Token")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Security-Token", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Content-Sha256", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Algorithm")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Algorithm", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Signature")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Signature", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-SignedHeaders", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Credential")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Credential", valid_594061
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
  var valid_594062 = formData.getOrDefault("Actions")
  valid_594062 = validateParameter(valid_594062, JArray, required = true, default = nil)
  if valid_594062 != nil:
    section.add "Actions", valid_594062
  var valid_594063 = formData.getOrDefault("Label")
  valid_594063 = validateParameter(valid_594063, JString, required = true,
                                 default = nil)
  if valid_594063 != nil:
    section.add "Label", valid_594063
  var valid_594064 = formData.getOrDefault("AWSAccountIds")
  valid_594064 = validateParameter(valid_594064, JArray, required = true, default = nil)
  if valid_594064 != nil:
    section.add "AWSAccountIds", valid_594064
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594065: Call_PostAddPermission_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594065.validator(path, query, header, formData, body)
  let scheme = call_594065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594065.url(scheme.get, call_594065.host, call_594065.base,
                         call_594065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594065, url, valid)

proc call*(call_594066: Call_PostAddPermission_594048; Actions: JsonNode;
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
  var path_594067 = newJObject()
  var query_594068 = newJObject()
  var formData_594069 = newJObject()
  if Actions != nil:
    formData_594069.add "Actions", Actions
  add(formData_594069, "Label", newJString(Label))
  if AWSAccountIds != nil:
    formData_594069.add "AWSAccountIds", AWSAccountIds
  add(path_594067, "QueueName", newJString(QueueName))
  add(query_594068, "Action", newJString(Action))
  add(path_594067, "AccountNumber", newJInt(AccountNumber))
  add(query_594068, "Version", newJString(Version))
  result = call_594066.call(path_594067, query_594068, nil, formData_594069, nil)

var postAddPermission* = Call_PostAddPermission_594048(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_PostAddPermission_594049, base: "/",
    url: url_PostAddPermission_594050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_593758 = ref object of OpenApiRestCall_593421
proc url_GetAddPermission_593760(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddPermission_593759(path: JsonNode; query: JsonNode;
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
  var valid_593886 = path.getOrDefault("QueueName")
  valid_593886 = validateParameter(valid_593886, JString, required = true,
                                 default = nil)
  if valid_593886 != nil:
    section.add "QueueName", valid_593886
  var valid_593887 = path.getOrDefault("AccountNumber")
  valid_593887 = validateParameter(valid_593887, JInt, required = true, default = nil)
  if valid_593887 != nil:
    section.add "AccountNumber", valid_593887
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
  var valid_593888 = query.getOrDefault("AWSAccountIds")
  valid_593888 = validateParameter(valid_593888, JArray, required = true, default = nil)
  if valid_593888 != nil:
    section.add "AWSAccountIds", valid_593888
  var valid_593902 = query.getOrDefault("Action")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_593902 != nil:
    section.add "Action", valid_593902
  var valid_593903 = query.getOrDefault("Actions")
  valid_593903 = validateParameter(valid_593903, JArray, required = true, default = nil)
  if valid_593903 != nil:
    section.add "Actions", valid_593903
  var valid_593904 = query.getOrDefault("Version")
  valid_593904 = validateParameter(valid_593904, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593904 != nil:
    section.add "Version", valid_593904
  var valid_593905 = query.getOrDefault("Label")
  valid_593905 = validateParameter(valid_593905, JString, required = true,
                                 default = nil)
  if valid_593905 != nil:
    section.add "Label", valid_593905
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
  var valid_593906 = header.getOrDefault("X-Amz-Date")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Date", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Security-Token")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Security-Token", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Content-Sha256", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Algorithm")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Algorithm", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Signature")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Signature", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-SignedHeaders", valid_593911
  var valid_593912 = header.getOrDefault("X-Amz-Credential")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "X-Amz-Credential", valid_593912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593935: Call_GetAddPermission_593758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593935.validator(path, query, header, formData, body)
  let scheme = call_593935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593935.url(scheme.get, call_593935.host, call_593935.base,
                         call_593935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593935, url, valid)

proc call*(call_594006: Call_GetAddPermission_593758; AWSAccountIds: JsonNode;
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
  var path_594007 = newJObject()
  var query_594009 = newJObject()
  if AWSAccountIds != nil:
    query_594009.add "AWSAccountIds", AWSAccountIds
  add(path_594007, "QueueName", newJString(QueueName))
  add(query_594009, "Action", newJString(Action))
  if Actions != nil:
    query_594009.add "Actions", Actions
  add(path_594007, "AccountNumber", newJInt(AccountNumber))
  add(query_594009, "Version", newJString(Version))
  add(query_594009, "Label", newJString(Label))
  result = call_594006.call(path_594007, query_594009, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_593758(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_GetAddPermission_593759, base: "/",
    url: url_GetAddPermission_593760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibility_594090 = ref object of OpenApiRestCall_593421
proc url_PostChangeMessageVisibility_594092(protocol: Scheme; host: string;
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

proc validate_PostChangeMessageVisibility_594091(path: JsonNode; query: JsonNode;
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
  var valid_594093 = path.getOrDefault("QueueName")
  valid_594093 = validateParameter(valid_594093, JString, required = true,
                                 default = nil)
  if valid_594093 != nil:
    section.add "QueueName", valid_594093
  var valid_594094 = path.getOrDefault("AccountNumber")
  valid_594094 = validateParameter(valid_594094, JInt, required = true, default = nil)
  if valid_594094 != nil:
    section.add "AccountNumber", valid_594094
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594095 = query.getOrDefault("Action")
  valid_594095 = validateParameter(valid_594095, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_594095 != nil:
    section.add "Action", valid_594095
  var valid_594096 = query.getOrDefault("Version")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594096 != nil:
    section.add "Version", valid_594096
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
  var valid_594097 = header.getOrDefault("X-Amz-Date")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Date", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Security-Token")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Security-Token", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Content-Sha256", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Algorithm")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Algorithm", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Signature")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Signature", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-SignedHeaders", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Credential")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Credential", valid_594103
  result.add "header", section
  ## parameters in `formData` object:
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `VisibilityTimeout` field"
  var valid_594104 = formData.getOrDefault("VisibilityTimeout")
  valid_594104 = validateParameter(valid_594104, JInt, required = true, default = nil)
  if valid_594104 != nil:
    section.add "VisibilityTimeout", valid_594104
  var valid_594105 = formData.getOrDefault("ReceiptHandle")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = nil)
  if valid_594105 != nil:
    section.add "ReceiptHandle", valid_594105
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594106: Call_PostChangeMessageVisibility_594090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_594106.validator(path, query, header, formData, body)
  let scheme = call_594106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594106.url(scheme.get, call_594106.host, call_594106.base,
                         call_594106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594106, url, valid)

proc call*(call_594107: Call_PostChangeMessageVisibility_594090;
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
  var path_594108 = newJObject()
  var query_594109 = newJObject()
  var formData_594110 = newJObject()
  add(formData_594110, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(path_594108, "QueueName", newJString(QueueName))
  add(query_594109, "Action", newJString(Action))
  add(path_594108, "AccountNumber", newJInt(AccountNumber))
  add(formData_594110, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_594109, "Version", newJString(Version))
  result = call_594107.call(path_594108, query_594109, nil, formData_594110, nil)

var postChangeMessageVisibility* = Call_PostChangeMessageVisibility_594090(
    name: "postChangeMessageVisibility", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_PostChangeMessageVisibility_594091, base: "/",
    url: url_PostChangeMessageVisibility_594092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibility_594070 = ref object of OpenApiRestCall_593421
proc url_GetChangeMessageVisibility_594072(protocol: Scheme; host: string;
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

proc validate_GetChangeMessageVisibility_594071(path: JsonNode; query: JsonNode;
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
  var valid_594073 = path.getOrDefault("QueueName")
  valid_594073 = validateParameter(valid_594073, JString, required = true,
                                 default = nil)
  if valid_594073 != nil:
    section.add "QueueName", valid_594073
  var valid_594074 = path.getOrDefault("AccountNumber")
  valid_594074 = validateParameter(valid_594074, JInt, required = true, default = nil)
  if valid_594074 != nil:
    section.add "AccountNumber", valid_594074
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
  var valid_594075 = query.getOrDefault("ReceiptHandle")
  valid_594075 = validateParameter(valid_594075, JString, required = true,
                                 default = nil)
  if valid_594075 != nil:
    section.add "ReceiptHandle", valid_594075
  var valid_594076 = query.getOrDefault("Action")
  valid_594076 = validateParameter(valid_594076, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_594076 != nil:
    section.add "Action", valid_594076
  var valid_594077 = query.getOrDefault("Version")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594077 != nil:
    section.add "Version", valid_594077
  var valid_594078 = query.getOrDefault("VisibilityTimeout")
  valid_594078 = validateParameter(valid_594078, JInt, required = true, default = nil)
  if valid_594078 != nil:
    section.add "VisibilityTimeout", valid_594078
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
  var valid_594079 = header.getOrDefault("X-Amz-Date")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Date", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Security-Token")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Security-Token", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Content-Sha256", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Algorithm")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Algorithm", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Signature")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Signature", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-SignedHeaders", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Credential")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Credential", valid_594085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_GetChangeMessageVisibility_594070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_GetChangeMessageVisibility_594070;
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
  var path_594088 = newJObject()
  var query_594089 = newJObject()
  add(query_594089, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_594088, "QueueName", newJString(QueueName))
  add(query_594089, "Action", newJString(Action))
  add(path_594088, "AccountNumber", newJInt(AccountNumber))
  add(query_594089, "Version", newJString(Version))
  add(query_594089, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_594087.call(path_594088, query_594089, nil, nil, nil)

var getChangeMessageVisibility* = Call_GetChangeMessageVisibility_594070(
    name: "getChangeMessageVisibility", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_GetChangeMessageVisibility_594071, base: "/",
    url: url_GetChangeMessageVisibility_594072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibilityBatch_594130 = ref object of OpenApiRestCall_593421
proc url_PostChangeMessageVisibilityBatch_594132(protocol: Scheme; host: string;
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

proc validate_PostChangeMessageVisibilityBatch_594131(path: JsonNode;
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
  var valid_594133 = path.getOrDefault("QueueName")
  valid_594133 = validateParameter(valid_594133, JString, required = true,
                                 default = nil)
  if valid_594133 != nil:
    section.add "QueueName", valid_594133
  var valid_594134 = path.getOrDefault("AccountNumber")
  valid_594134 = validateParameter(valid_594134, JInt, required = true, default = nil)
  if valid_594134 != nil:
    section.add "AccountNumber", valid_594134
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594135 = query.getOrDefault("Action")
  valid_594135 = validateParameter(valid_594135, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_594135 != nil:
    section.add "Action", valid_594135
  var valid_594136 = query.getOrDefault("Version")
  valid_594136 = validateParameter(valid_594136, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594136 != nil:
    section.add "Version", valid_594136
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
  var valid_594137 = header.getOrDefault("X-Amz-Date")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Date", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Security-Token")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Security-Token", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_594144 = formData.getOrDefault("Entries")
  valid_594144 = validateParameter(valid_594144, JArray, required = true, default = nil)
  if valid_594144 != nil:
    section.add "Entries", valid_594144
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_PostChangeMessageVisibilityBatch_594130;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_PostChangeMessageVisibilityBatch_594130;
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
  var path_594147 = newJObject()
  var query_594148 = newJObject()
  var formData_594149 = newJObject()
  if Entries != nil:
    formData_594149.add "Entries", Entries
  add(path_594147, "QueueName", newJString(QueueName))
  add(query_594148, "Action", newJString(Action))
  add(path_594147, "AccountNumber", newJInt(AccountNumber))
  add(query_594148, "Version", newJString(Version))
  result = call_594146.call(path_594147, query_594148, nil, formData_594149, nil)

var postChangeMessageVisibilityBatch* = Call_PostChangeMessageVisibilityBatch_594130(
    name: "postChangeMessageVisibilityBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_PostChangeMessageVisibilityBatch_594131, base: "/",
    url: url_PostChangeMessageVisibilityBatch_594132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibilityBatch_594111 = ref object of OpenApiRestCall_593421
proc url_GetChangeMessageVisibilityBatch_594113(protocol: Scheme; host: string;
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

proc validate_GetChangeMessageVisibilityBatch_594112(path: JsonNode;
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
  var valid_594114 = path.getOrDefault("QueueName")
  valid_594114 = validateParameter(valid_594114, JString, required = true,
                                 default = nil)
  if valid_594114 != nil:
    section.add "QueueName", valid_594114
  var valid_594115 = path.getOrDefault("AccountNumber")
  valid_594115 = validateParameter(valid_594115, JInt, required = true, default = nil)
  if valid_594115 != nil:
    section.add "AccountNumber", valid_594115
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_594116 = query.getOrDefault("Entries")
  valid_594116 = validateParameter(valid_594116, JArray, required = true, default = nil)
  if valid_594116 != nil:
    section.add "Entries", valid_594116
  var valid_594117 = query.getOrDefault("Action")
  valid_594117 = validateParameter(valid_594117, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_594117 != nil:
    section.add "Action", valid_594117
  var valid_594118 = query.getOrDefault("Version")
  valid_594118 = validateParameter(valid_594118, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594118 != nil:
    section.add "Version", valid_594118
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
  var valid_594119 = header.getOrDefault("X-Amz-Date")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Date", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Security-Token")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Security-Token", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Content-Sha256", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Algorithm")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Algorithm", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Signature")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Signature", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-SignedHeaders", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Credential")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Credential", valid_594125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594126: Call_GetChangeMessageVisibilityBatch_594111;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594126.validator(path, query, header, formData, body)
  let scheme = call_594126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594126.url(scheme.get, call_594126.host, call_594126.base,
                         call_594126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594126, url, valid)

proc call*(call_594127: Call_GetChangeMessageVisibilityBatch_594111;
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
  var path_594128 = newJObject()
  var query_594129 = newJObject()
  add(path_594128, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_594129.add "Entries", Entries
  add(query_594129, "Action", newJString(Action))
  add(path_594128, "AccountNumber", newJInt(AccountNumber))
  add(query_594129, "Version", newJString(Version))
  result = call_594127.call(path_594128, query_594129, nil, nil, nil)

var getChangeMessageVisibilityBatch* = Call_GetChangeMessageVisibilityBatch_594111(
    name: "getChangeMessageVisibilityBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_GetChangeMessageVisibilityBatch_594112, base: "/",
    url: url_GetChangeMessageVisibilityBatch_594113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateQueue_594178 = ref object of OpenApiRestCall_593421
proc url_PostCreateQueue_594180(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateQueue_594179(path: JsonNode; query: JsonNode;
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
  var valid_594181 = query.getOrDefault("Action")
  valid_594181 = validateParameter(valid_594181, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_594181 != nil:
    section.add "Action", valid_594181
  var valid_594182 = query.getOrDefault("Version")
  valid_594182 = validateParameter(valid_594182, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594182 != nil:
    section.add "Version", valid_594182
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
  var valid_594183 = header.getOrDefault("X-Amz-Date")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Date", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Content-Sha256", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Algorithm")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Algorithm", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Signature")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Signature", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-SignedHeaders", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Credential")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Credential", valid_594189
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
  var valid_594190 = formData.getOrDefault("Tag.1.value")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "Tag.1.value", valid_594190
  var valid_594191 = formData.getOrDefault("Attribute.0.key")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "Attribute.0.key", valid_594191
  var valid_594192 = formData.getOrDefault("Attribute.0.value")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "Attribute.0.value", valid_594192
  var valid_594193 = formData.getOrDefault("Attribute.1.value")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "Attribute.1.value", valid_594193
  var valid_594194 = formData.getOrDefault("Tag.0.key")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "Tag.0.key", valid_594194
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_594195 = formData.getOrDefault("QueueName")
  valid_594195 = validateParameter(valid_594195, JString, required = true,
                                 default = nil)
  if valid_594195 != nil:
    section.add "QueueName", valid_594195
  var valid_594196 = formData.getOrDefault("Attribute.1.key")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "Attribute.1.key", valid_594196
  var valid_594197 = formData.getOrDefault("Tag.1.key")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "Tag.1.key", valid_594197
  var valid_594198 = formData.getOrDefault("Tag.0.value")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "Tag.0.value", valid_594198
  var valid_594199 = formData.getOrDefault("Tag.2.key")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "Tag.2.key", valid_594199
  var valid_594200 = formData.getOrDefault("Tag.2.value")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "Tag.2.value", valid_594200
  var valid_594201 = formData.getOrDefault("Attribute.2.value")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "Attribute.2.value", valid_594201
  var valid_594202 = formData.getOrDefault("Attribute.2.key")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "Attribute.2.key", valid_594202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594203: Call_PostCreateQueue_594178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594203.validator(path, query, header, formData, body)
  let scheme = call_594203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594203.url(scheme.get, call_594203.host, call_594203.base,
                         call_594203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594203, url, valid)

proc call*(call_594204: Call_PostCreateQueue_594178; QueueName: string;
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
  var query_594205 = newJObject()
  var formData_594206 = newJObject()
  add(formData_594206, "Tag.1.value", newJString(Tag1Value))
  add(formData_594206, "Attribute.0.key", newJString(Attribute0Key))
  add(formData_594206, "Attribute.0.value", newJString(Attribute0Value))
  add(formData_594206, "Attribute.1.value", newJString(Attribute1Value))
  add(formData_594206, "Tag.0.key", newJString(Tag0Key))
  add(query_594205, "Action", newJString(Action))
  add(formData_594206, "QueueName", newJString(QueueName))
  add(formData_594206, "Attribute.1.key", newJString(Attribute1Key))
  add(formData_594206, "Tag.1.key", newJString(Tag1Key))
  add(formData_594206, "Tag.0.value", newJString(Tag0Value))
  add(formData_594206, "Tag.2.key", newJString(Tag2Key))
  add(formData_594206, "Tag.2.value", newJString(Tag2Value))
  add(formData_594206, "Attribute.2.value", newJString(Attribute2Value))
  add(query_594205, "Version", newJString(Version))
  add(formData_594206, "Attribute.2.key", newJString(Attribute2Key))
  result = call_594204.call(nil, query_594205, nil, formData_594206, nil)

var postCreateQueue* = Call_PostCreateQueue_594178(name: "postCreateQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_PostCreateQueue_594179,
    base: "/", url: url_PostCreateQueue_594180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateQueue_594150 = ref object of OpenApiRestCall_593421
proc url_GetCreateQueue_594152(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateQueue_594151(path: JsonNode; query: JsonNode;
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
  var valid_594153 = query.getOrDefault("Attribute.2.value")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "Attribute.2.value", valid_594153
  var valid_594154 = query.getOrDefault("Tag.0.value")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "Tag.0.value", valid_594154
  var valid_594155 = query.getOrDefault("Tag.2.value")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "Tag.2.value", valid_594155
  var valid_594156 = query.getOrDefault("Attribute.0.key")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "Attribute.0.key", valid_594156
  var valid_594157 = query.getOrDefault("Tag.1.value")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "Tag.1.value", valid_594157
  var valid_594158 = query.getOrDefault("Tag.2.key")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "Tag.2.key", valid_594158
  var valid_594159 = query.getOrDefault("Attribute.1.value")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "Attribute.1.value", valid_594159
  var valid_594160 = query.getOrDefault("Attribute.1.key")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "Attribute.1.key", valid_594160
  var valid_594161 = query.getOrDefault("Tag.0.key")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "Tag.0.key", valid_594161
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594162 = query.getOrDefault("Action")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_594162 != nil:
    section.add "Action", valid_594162
  var valid_594163 = query.getOrDefault("Attribute.2.key")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "Attribute.2.key", valid_594163
  var valid_594164 = query.getOrDefault("Tag.1.key")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "Tag.1.key", valid_594164
  var valid_594165 = query.getOrDefault("QueueName")
  valid_594165 = validateParameter(valid_594165, JString, required = true,
                                 default = nil)
  if valid_594165 != nil:
    section.add "QueueName", valid_594165
  var valid_594166 = query.getOrDefault("Attribute.0.value")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "Attribute.0.value", valid_594166
  var valid_594167 = query.getOrDefault("Version")
  valid_594167 = validateParameter(valid_594167, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594167 != nil:
    section.add "Version", valid_594167
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
  var valid_594168 = header.getOrDefault("X-Amz-Date")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Date", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Content-Sha256", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Algorithm")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Algorithm", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Signature")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Signature", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-SignedHeaders", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Credential")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Credential", valid_594174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_GetCreateQueue_594150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_GetCreateQueue_594150; QueueName: string;
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
  var query_594177 = newJObject()
  add(query_594177, "Attribute.2.value", newJString(Attribute2Value))
  add(query_594177, "Tag.0.value", newJString(Tag0Value))
  add(query_594177, "Tag.2.value", newJString(Tag2Value))
  add(query_594177, "Attribute.0.key", newJString(Attribute0Key))
  add(query_594177, "Tag.1.value", newJString(Tag1Value))
  add(query_594177, "Tag.2.key", newJString(Tag2Key))
  add(query_594177, "Attribute.1.value", newJString(Attribute1Value))
  add(query_594177, "Attribute.1.key", newJString(Attribute1Key))
  add(query_594177, "Tag.0.key", newJString(Tag0Key))
  add(query_594177, "Action", newJString(Action))
  add(query_594177, "Attribute.2.key", newJString(Attribute2Key))
  add(query_594177, "Tag.1.key", newJString(Tag1Key))
  add(query_594177, "QueueName", newJString(QueueName))
  add(query_594177, "Attribute.0.value", newJString(Attribute0Value))
  add(query_594177, "Version", newJString(Version))
  result = call_594176.call(nil, query_594177, nil, nil, nil)

var getCreateQueue* = Call_GetCreateQueue_594150(name: "getCreateQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_GetCreateQueue_594151,
    base: "/", url: url_GetCreateQueue_594152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessage_594226 = ref object of OpenApiRestCall_593421
proc url_PostDeleteMessage_594228(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteMessage_594227(path: JsonNode; query: JsonNode;
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
  var valid_594229 = path.getOrDefault("QueueName")
  valid_594229 = validateParameter(valid_594229, JString, required = true,
                                 default = nil)
  if valid_594229 != nil:
    section.add "QueueName", valid_594229
  var valid_594230 = path.getOrDefault("AccountNumber")
  valid_594230 = validateParameter(valid_594230, JInt, required = true, default = nil)
  if valid_594230 != nil:
    section.add "AccountNumber", valid_594230
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594231 = query.getOrDefault("Action")
  valid_594231 = validateParameter(valid_594231, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_594231 != nil:
    section.add "Action", valid_594231
  var valid_594232 = query.getOrDefault("Version")
  valid_594232 = validateParameter(valid_594232, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594232 != nil:
    section.add "Version", valid_594232
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
  var valid_594233 = header.getOrDefault("X-Amz-Date")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Date", valid_594233
  var valid_594234 = header.getOrDefault("X-Amz-Security-Token")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-Security-Token", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Content-Sha256", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Algorithm")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Algorithm", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Signature")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Signature", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-SignedHeaders", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Credential")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Credential", valid_594239
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ReceiptHandle` field"
  var valid_594240 = formData.getOrDefault("ReceiptHandle")
  valid_594240 = validateParameter(valid_594240, JString, required = true,
                                 default = nil)
  if valid_594240 != nil:
    section.add "ReceiptHandle", valid_594240
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594241: Call_PostDeleteMessage_594226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_594241.validator(path, query, header, formData, body)
  let scheme = call_594241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594241.url(scheme.get, call_594241.host, call_594241.base,
                         call_594241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594241, url, valid)

proc call*(call_594242: Call_PostDeleteMessage_594226; QueueName: string;
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
  var path_594243 = newJObject()
  var query_594244 = newJObject()
  var formData_594245 = newJObject()
  add(path_594243, "QueueName", newJString(QueueName))
  add(query_594244, "Action", newJString(Action))
  add(path_594243, "AccountNumber", newJInt(AccountNumber))
  add(formData_594245, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_594244, "Version", newJString(Version))
  result = call_594242.call(path_594243, query_594244, nil, formData_594245, nil)

var postDeleteMessage* = Call_PostDeleteMessage_594226(name: "postDeleteMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_PostDeleteMessage_594227, base: "/",
    url: url_PostDeleteMessage_594228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessage_594207 = ref object of OpenApiRestCall_593421
proc url_GetDeleteMessage_594209(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteMessage_594208(path: JsonNode; query: JsonNode;
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
  var valid_594210 = path.getOrDefault("QueueName")
  valid_594210 = validateParameter(valid_594210, JString, required = true,
                                 default = nil)
  if valid_594210 != nil:
    section.add "QueueName", valid_594210
  var valid_594211 = path.getOrDefault("AccountNumber")
  valid_594211 = validateParameter(valid_594211, JInt, required = true, default = nil)
  if valid_594211 != nil:
    section.add "AccountNumber", valid_594211
  result.add "path", section
  ## parameters in `query` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ReceiptHandle` field"
  var valid_594212 = query.getOrDefault("ReceiptHandle")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = nil)
  if valid_594212 != nil:
    section.add "ReceiptHandle", valid_594212
  var valid_594213 = query.getOrDefault("Action")
  valid_594213 = validateParameter(valid_594213, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_594213 != nil:
    section.add "Action", valid_594213
  var valid_594214 = query.getOrDefault("Version")
  valid_594214 = validateParameter(valid_594214, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594214 != nil:
    section.add "Version", valid_594214
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
  var valid_594215 = header.getOrDefault("X-Amz-Date")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Date", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Security-Token")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Security-Token", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Content-Sha256", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Algorithm")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Algorithm", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Signature")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Signature", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-SignedHeaders", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Credential")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Credential", valid_594221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594222: Call_GetDeleteMessage_594207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_594222.validator(path, query, header, formData, body)
  let scheme = call_594222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594222.url(scheme.get, call_594222.host, call_594222.base,
                         call_594222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594222, url, valid)

proc call*(call_594223: Call_GetDeleteMessage_594207; ReceiptHandle: string;
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
  var path_594224 = newJObject()
  var query_594225 = newJObject()
  add(query_594225, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_594224, "QueueName", newJString(QueueName))
  add(query_594225, "Action", newJString(Action))
  add(path_594224, "AccountNumber", newJInt(AccountNumber))
  add(query_594225, "Version", newJString(Version))
  result = call_594223.call(path_594224, query_594225, nil, nil, nil)

var getDeleteMessage* = Call_GetDeleteMessage_594207(name: "getDeleteMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_GetDeleteMessage_594208, base: "/",
    url: url_GetDeleteMessage_594209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessageBatch_594265 = ref object of OpenApiRestCall_593421
proc url_PostDeleteMessageBatch_594267(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteMessageBatch_594266(path: JsonNode; query: JsonNode;
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
  var valid_594268 = path.getOrDefault("QueueName")
  valid_594268 = validateParameter(valid_594268, JString, required = true,
                                 default = nil)
  if valid_594268 != nil:
    section.add "QueueName", valid_594268
  var valid_594269 = path.getOrDefault("AccountNumber")
  valid_594269 = validateParameter(valid_594269, JInt, required = true, default = nil)
  if valid_594269 != nil:
    section.add "AccountNumber", valid_594269
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594270 = query.getOrDefault("Action")
  valid_594270 = validateParameter(valid_594270, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_594270 != nil:
    section.add "Action", valid_594270
  var valid_594271 = query.getOrDefault("Version")
  valid_594271 = validateParameter(valid_594271, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594271 != nil:
    section.add "Version", valid_594271
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
  var valid_594272 = header.getOrDefault("X-Amz-Date")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Date", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Security-Token")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Security-Token", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_594279 = formData.getOrDefault("Entries")
  valid_594279 = validateParameter(valid_594279, JArray, required = true, default = nil)
  if valid_594279 != nil:
    section.add "Entries", valid_594279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_PostDeleteMessageBatch_594265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_PostDeleteMessageBatch_594265; Entries: JsonNode;
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
  var path_594282 = newJObject()
  var query_594283 = newJObject()
  var formData_594284 = newJObject()
  if Entries != nil:
    formData_594284.add "Entries", Entries
  add(path_594282, "QueueName", newJString(QueueName))
  add(query_594283, "Action", newJString(Action))
  add(path_594282, "AccountNumber", newJInt(AccountNumber))
  add(query_594283, "Version", newJString(Version))
  result = call_594281.call(path_594282, query_594283, nil, formData_594284, nil)

var postDeleteMessageBatch* = Call_PostDeleteMessageBatch_594265(
    name: "postDeleteMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_PostDeleteMessageBatch_594266, base: "/",
    url: url_PostDeleteMessageBatch_594267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessageBatch_594246 = ref object of OpenApiRestCall_593421
proc url_GetDeleteMessageBatch_594248(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteMessageBatch_594247(path: JsonNode; query: JsonNode;
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
  var valid_594249 = path.getOrDefault("QueueName")
  valid_594249 = validateParameter(valid_594249, JString, required = true,
                                 default = nil)
  if valid_594249 != nil:
    section.add "QueueName", valid_594249
  var valid_594250 = path.getOrDefault("AccountNumber")
  valid_594250 = validateParameter(valid_594250, JInt, required = true, default = nil)
  if valid_594250 != nil:
    section.add "AccountNumber", valid_594250
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_594251 = query.getOrDefault("Entries")
  valid_594251 = validateParameter(valid_594251, JArray, required = true, default = nil)
  if valid_594251 != nil:
    section.add "Entries", valid_594251
  var valid_594252 = query.getOrDefault("Action")
  valid_594252 = validateParameter(valid_594252, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_594252 != nil:
    section.add "Action", valid_594252
  var valid_594253 = query.getOrDefault("Version")
  valid_594253 = validateParameter(valid_594253, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594253 != nil:
    section.add "Version", valid_594253
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
  var valid_594254 = header.getOrDefault("X-Amz-Date")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Date", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Security-Token")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Security-Token", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Algorithm")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Algorithm", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Signature")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Signature", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-SignedHeaders", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Credential")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Credential", valid_594260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594261: Call_GetDeleteMessageBatch_594246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594261.validator(path, query, header, formData, body)
  let scheme = call_594261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594261.url(scheme.get, call_594261.host, call_594261.base,
                         call_594261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594261, url, valid)

proc call*(call_594262: Call_GetDeleteMessageBatch_594246; QueueName: string;
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
  var path_594263 = newJObject()
  var query_594264 = newJObject()
  add(path_594263, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_594264.add "Entries", Entries
  add(query_594264, "Action", newJString(Action))
  add(path_594263, "AccountNumber", newJInt(AccountNumber))
  add(query_594264, "Version", newJString(Version))
  result = call_594262.call(path_594263, query_594264, nil, nil, nil)

var getDeleteMessageBatch* = Call_GetDeleteMessageBatch_594246(
    name: "getDeleteMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_GetDeleteMessageBatch_594247, base: "/",
    url: url_GetDeleteMessageBatch_594248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteQueue_594303 = ref object of OpenApiRestCall_593421
proc url_PostDeleteQueue_594305(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteQueue_594304(path: JsonNode; query: JsonNode;
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
  var valid_594306 = path.getOrDefault("QueueName")
  valid_594306 = validateParameter(valid_594306, JString, required = true,
                                 default = nil)
  if valid_594306 != nil:
    section.add "QueueName", valid_594306
  var valid_594307 = path.getOrDefault("AccountNumber")
  valid_594307 = validateParameter(valid_594307, JInt, required = true, default = nil)
  if valid_594307 != nil:
    section.add "AccountNumber", valid_594307
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594308 = query.getOrDefault("Action")
  valid_594308 = validateParameter(valid_594308, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_594308 != nil:
    section.add "Action", valid_594308
  var valid_594309 = query.getOrDefault("Version")
  valid_594309 = validateParameter(valid_594309, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594309 != nil:
    section.add "Version", valid_594309
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
  var valid_594310 = header.getOrDefault("X-Amz-Date")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Date", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Security-Token")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Security-Token", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Content-Sha256", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-Algorithm")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-Algorithm", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Signature")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Signature", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-SignedHeaders", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Credential")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Credential", valid_594316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594317: Call_PostDeleteQueue_594303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594317.validator(path, query, header, formData, body)
  let scheme = call_594317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594317.url(scheme.get, call_594317.host, call_594317.base,
                         call_594317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594317, url, valid)

proc call*(call_594318: Call_PostDeleteQueue_594303; QueueName: string;
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
  var path_594319 = newJObject()
  var query_594320 = newJObject()
  add(path_594319, "QueueName", newJString(QueueName))
  add(query_594320, "Action", newJString(Action))
  add(path_594319, "AccountNumber", newJInt(AccountNumber))
  add(query_594320, "Version", newJString(Version))
  result = call_594318.call(path_594319, query_594320, nil, nil, nil)

var postDeleteQueue* = Call_PostDeleteQueue_594303(name: "postDeleteQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_PostDeleteQueue_594304, base: "/", url: url_PostDeleteQueue_594305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteQueue_594285 = ref object of OpenApiRestCall_593421
proc url_GetDeleteQueue_594287(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteQueue_594286(path: JsonNode; query: JsonNode;
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
  var valid_594288 = path.getOrDefault("QueueName")
  valid_594288 = validateParameter(valid_594288, JString, required = true,
                                 default = nil)
  if valid_594288 != nil:
    section.add "QueueName", valid_594288
  var valid_594289 = path.getOrDefault("AccountNumber")
  valid_594289 = validateParameter(valid_594289, JInt, required = true, default = nil)
  if valid_594289 != nil:
    section.add "AccountNumber", valid_594289
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594290 = query.getOrDefault("Action")
  valid_594290 = validateParameter(valid_594290, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_594290 != nil:
    section.add "Action", valid_594290
  var valid_594291 = query.getOrDefault("Version")
  valid_594291 = validateParameter(valid_594291, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594291 != nil:
    section.add "Version", valid_594291
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
  var valid_594292 = header.getOrDefault("X-Amz-Date")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Date", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Security-Token")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Security-Token", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Content-Sha256", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Algorithm")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Algorithm", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Signature")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Signature", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-SignedHeaders", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Credential")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Credential", valid_594298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594299: Call_GetDeleteQueue_594285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594299.validator(path, query, header, formData, body)
  let scheme = call_594299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594299.url(scheme.get, call_594299.host, call_594299.base,
                         call_594299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594299, url, valid)

proc call*(call_594300: Call_GetDeleteQueue_594285; QueueName: string;
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
  var path_594301 = newJObject()
  var query_594302 = newJObject()
  add(path_594301, "QueueName", newJString(QueueName))
  add(query_594302, "Action", newJString(Action))
  add(path_594301, "AccountNumber", newJInt(AccountNumber))
  add(query_594302, "Version", newJString(Version))
  result = call_594300.call(path_594301, query_594302, nil, nil, nil)

var getDeleteQueue* = Call_GetDeleteQueue_594285(name: "getDeleteQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_GetDeleteQueue_594286, base: "/", url: url_GetDeleteQueue_594287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueAttributes_594340 = ref object of OpenApiRestCall_593421
proc url_PostGetQueueAttributes_594342(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetQueueAttributes_594341(path: JsonNode; query: JsonNode;
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
  var valid_594343 = path.getOrDefault("QueueName")
  valid_594343 = validateParameter(valid_594343, JString, required = true,
                                 default = nil)
  if valid_594343 != nil:
    section.add "QueueName", valid_594343
  var valid_594344 = path.getOrDefault("AccountNumber")
  valid_594344 = validateParameter(valid_594344, JInt, required = true, default = nil)
  if valid_594344 != nil:
    section.add "AccountNumber", valid_594344
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594345 = query.getOrDefault("Action")
  valid_594345 = validateParameter(valid_594345, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_594345 != nil:
    section.add "Action", valid_594345
  var valid_594346 = query.getOrDefault("Version")
  valid_594346 = validateParameter(valid_594346, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594346 != nil:
    section.add "Version", valid_594346
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
  var valid_594347 = header.getOrDefault("X-Amz-Date")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Date", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Security-Token")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Security-Token", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
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
  var valid_594354 = formData.getOrDefault("AttributeNames")
  valid_594354 = validateParameter(valid_594354, JArray, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "AttributeNames", valid_594354
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_PostGetQueueAttributes_594340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_PostGetQueueAttributes_594340; QueueName: string;
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
  var path_594357 = newJObject()
  var query_594358 = newJObject()
  var formData_594359 = newJObject()
  add(path_594357, "QueueName", newJString(QueueName))
  add(query_594358, "Action", newJString(Action))
  add(path_594357, "AccountNumber", newJInt(AccountNumber))
  if AttributeNames != nil:
    formData_594359.add "AttributeNames", AttributeNames
  add(query_594358, "Version", newJString(Version))
  result = call_594356.call(path_594357, query_594358, nil, formData_594359, nil)

var postGetQueueAttributes* = Call_PostGetQueueAttributes_594340(
    name: "postGetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_PostGetQueueAttributes_594341, base: "/",
    url: url_PostGetQueueAttributes_594342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueAttributes_594321 = ref object of OpenApiRestCall_593421
proc url_GetGetQueueAttributes_594323(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetQueueAttributes_594322(path: JsonNode; query: JsonNode;
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
  var valid_594324 = path.getOrDefault("QueueName")
  valid_594324 = validateParameter(valid_594324, JString, required = true,
                                 default = nil)
  if valid_594324 != nil:
    section.add "QueueName", valid_594324
  var valid_594325 = path.getOrDefault("AccountNumber")
  valid_594325 = validateParameter(valid_594325, JInt, required = true, default = nil)
  if valid_594325 != nil:
    section.add "AccountNumber", valid_594325
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
  var valid_594326 = query.getOrDefault("AttributeNames")
  valid_594326 = validateParameter(valid_594326, JArray, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "AttributeNames", valid_594326
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594327 = query.getOrDefault("Action")
  valid_594327 = validateParameter(valid_594327, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_594327 != nil:
    section.add "Action", valid_594327
  var valid_594328 = query.getOrDefault("Version")
  valid_594328 = validateParameter(valid_594328, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594328 != nil:
    section.add "Version", valid_594328
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
  var valid_594329 = header.getOrDefault("X-Amz-Date")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Date", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Security-Token")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Security-Token", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Content-Sha256", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Algorithm")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Algorithm", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Signature")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Signature", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-SignedHeaders", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Credential")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Credential", valid_594335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594336: Call_GetGetQueueAttributes_594321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594336.validator(path, query, header, formData, body)
  let scheme = call_594336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594336.url(scheme.get, call_594336.host, call_594336.base,
                         call_594336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594336, url, valid)

proc call*(call_594337: Call_GetGetQueueAttributes_594321; QueueName: string;
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
  var path_594338 = newJObject()
  var query_594339 = newJObject()
  if AttributeNames != nil:
    query_594339.add "AttributeNames", AttributeNames
  add(path_594338, "QueueName", newJString(QueueName))
  add(query_594339, "Action", newJString(Action))
  add(path_594338, "AccountNumber", newJInt(AccountNumber))
  add(query_594339, "Version", newJString(Version))
  result = call_594337.call(path_594338, query_594339, nil, nil, nil)

var getGetQueueAttributes* = Call_GetGetQueueAttributes_594321(
    name: "getGetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_GetGetQueueAttributes_594322, base: "/",
    url: url_GetGetQueueAttributes_594323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueUrl_594377 = ref object of OpenApiRestCall_593421
proc url_PostGetQueueUrl_594379(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetQueueUrl_594378(path: JsonNode; query: JsonNode;
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
  var valid_594380 = query.getOrDefault("Action")
  valid_594380 = validateParameter(valid_594380, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_594380 != nil:
    section.add "Action", valid_594380
  var valid_594381 = query.getOrDefault("Version")
  valid_594381 = validateParameter(valid_594381, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594381 != nil:
    section.add "Version", valid_594381
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
  var valid_594382 = header.getOrDefault("X-Amz-Date")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Date", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Security-Token")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Security-Token", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Content-Sha256", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Algorithm")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Algorithm", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-Signature")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-Signature", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-SignedHeaders", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-Credential")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-Credential", valid_594388
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueOwnerAWSAccountId: JString
  ##                         : The AWS account ID of the account that created the queue.
  ##   QueueName: JString (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_594389 = formData.getOrDefault("QueueOwnerAWSAccountId")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "QueueOwnerAWSAccountId", valid_594389
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_594390 = formData.getOrDefault("QueueName")
  valid_594390 = validateParameter(valid_594390, JString, required = true,
                                 default = nil)
  if valid_594390 != nil:
    section.add "QueueName", valid_594390
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594391: Call_PostGetQueueUrl_594377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_594391.validator(path, query, header, formData, body)
  let scheme = call_594391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594391.url(scheme.get, call_594391.host, call_594391.base,
                         call_594391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594391, url, valid)

proc call*(call_594392: Call_PostGetQueueUrl_594377; QueueName: string;
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
  var query_594393 = newJObject()
  var formData_594394 = newJObject()
  add(formData_594394, "QueueOwnerAWSAccountId",
      newJString(QueueOwnerAWSAccountId))
  add(query_594393, "Action", newJString(Action))
  add(formData_594394, "QueueName", newJString(QueueName))
  add(query_594393, "Version", newJString(Version))
  result = call_594392.call(nil, query_594393, nil, formData_594394, nil)

var postGetQueueUrl* = Call_PostGetQueueUrl_594377(name: "postGetQueueUrl",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_PostGetQueueUrl_594378,
    base: "/", url: url_PostGetQueueUrl_594379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueUrl_594360 = ref object of OpenApiRestCall_593421
proc url_GetGetQueueUrl_594362(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetQueueUrl_594361(path: JsonNode; query: JsonNode;
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
  var valid_594363 = query.getOrDefault("Action")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_594363 != nil:
    section.add "Action", valid_594363
  var valid_594364 = query.getOrDefault("QueueOwnerAWSAccountId")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "QueueOwnerAWSAccountId", valid_594364
  var valid_594365 = query.getOrDefault("QueueName")
  valid_594365 = validateParameter(valid_594365, JString, required = true,
                                 default = nil)
  if valid_594365 != nil:
    section.add "QueueName", valid_594365
  var valid_594366 = query.getOrDefault("Version")
  valid_594366 = validateParameter(valid_594366, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594366 != nil:
    section.add "Version", valid_594366
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
  var valid_594367 = header.getOrDefault("X-Amz-Date")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Date", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Security-Token")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Security-Token", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Content-Sha256", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Algorithm")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Algorithm", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Signature")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Signature", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-SignedHeaders", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-Credential")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-Credential", valid_594373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594374: Call_GetGetQueueUrl_594360; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_594374.validator(path, query, header, formData, body)
  let scheme = call_594374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594374.url(scheme.get, call_594374.host, call_594374.base,
                         call_594374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594374, url, valid)

proc call*(call_594375: Call_GetGetQueueUrl_594360; QueueName: string;
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
  var query_594376 = newJObject()
  add(query_594376, "Action", newJString(Action))
  add(query_594376, "QueueOwnerAWSAccountId", newJString(QueueOwnerAWSAccountId))
  add(query_594376, "QueueName", newJString(QueueName))
  add(query_594376, "Version", newJString(Version))
  result = call_594375.call(nil, query_594376, nil, nil, nil)

var getGetQueueUrl* = Call_GetGetQueueUrl_594360(name: "getGetQueueUrl",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_GetGetQueueUrl_594361,
    base: "/", url: url_GetGetQueueUrl_594362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDeadLetterSourceQueues_594413 = ref object of OpenApiRestCall_593421
proc url_PostListDeadLetterSourceQueues_594415(protocol: Scheme; host: string;
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

proc validate_PostListDeadLetterSourceQueues_594414(path: JsonNode;
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
  var valid_594416 = path.getOrDefault("QueueName")
  valid_594416 = validateParameter(valid_594416, JString, required = true,
                                 default = nil)
  if valid_594416 != nil:
    section.add "QueueName", valid_594416
  var valid_594417 = path.getOrDefault("AccountNumber")
  valid_594417 = validateParameter(valid_594417, JInt, required = true, default = nil)
  if valid_594417 != nil:
    section.add "AccountNumber", valid_594417
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594418 = query.getOrDefault("Action")
  valid_594418 = validateParameter(valid_594418, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_594418 != nil:
    section.add "Action", valid_594418
  var valid_594419 = query.getOrDefault("Version")
  valid_594419 = validateParameter(valid_594419, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594419 != nil:
    section.add "Version", valid_594419
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
  var valid_594420 = header.getOrDefault("X-Amz-Date")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Date", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Security-Token")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Security-Token", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Content-Sha256", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Algorithm")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Algorithm", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Signature")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Signature", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-SignedHeaders", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Credential")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Credential", valid_594426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594427: Call_PostListDeadLetterSourceQueues_594413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_594427.validator(path, query, header, formData, body)
  let scheme = call_594427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594427.url(scheme.get, call_594427.host, call_594427.base,
                         call_594427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594427, url, valid)

proc call*(call_594428: Call_PostListDeadLetterSourceQueues_594413;
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
  var path_594429 = newJObject()
  var query_594430 = newJObject()
  add(path_594429, "QueueName", newJString(QueueName))
  add(query_594430, "Action", newJString(Action))
  add(path_594429, "AccountNumber", newJInt(AccountNumber))
  add(query_594430, "Version", newJString(Version))
  result = call_594428.call(path_594429, query_594430, nil, nil, nil)

var postListDeadLetterSourceQueues* = Call_PostListDeadLetterSourceQueues_594413(
    name: "postListDeadLetterSourceQueues", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_PostListDeadLetterSourceQueues_594414, base: "/",
    url: url_PostListDeadLetterSourceQueues_594415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDeadLetterSourceQueues_594395 = ref object of OpenApiRestCall_593421
proc url_GetListDeadLetterSourceQueues_594397(protocol: Scheme; host: string;
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

proc validate_GetListDeadLetterSourceQueues_594396(path: JsonNode; query: JsonNode;
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
  var valid_594398 = path.getOrDefault("QueueName")
  valid_594398 = validateParameter(valid_594398, JString, required = true,
                                 default = nil)
  if valid_594398 != nil:
    section.add "QueueName", valid_594398
  var valid_594399 = path.getOrDefault("AccountNumber")
  valid_594399 = validateParameter(valid_594399, JInt, required = true, default = nil)
  if valid_594399 != nil:
    section.add "AccountNumber", valid_594399
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594400 = query.getOrDefault("Action")
  valid_594400 = validateParameter(valid_594400, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_594400 != nil:
    section.add "Action", valid_594400
  var valid_594401 = query.getOrDefault("Version")
  valid_594401 = validateParameter(valid_594401, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594401 != nil:
    section.add "Version", valid_594401
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
  var valid_594402 = header.getOrDefault("X-Amz-Date")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Date", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Security-Token")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Security-Token", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Content-Sha256", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Algorithm")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Algorithm", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Signature")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Signature", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-SignedHeaders", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Credential")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Credential", valid_594408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594409: Call_GetListDeadLetterSourceQueues_594395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_594409.validator(path, query, header, formData, body)
  let scheme = call_594409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594409.url(scheme.get, call_594409.host, call_594409.base,
                         call_594409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594409, url, valid)

proc call*(call_594410: Call_GetListDeadLetterSourceQueues_594395;
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
  var path_594411 = newJObject()
  var query_594412 = newJObject()
  add(path_594411, "QueueName", newJString(QueueName))
  add(query_594412, "Action", newJString(Action))
  add(path_594411, "AccountNumber", newJInt(AccountNumber))
  add(query_594412, "Version", newJString(Version))
  result = call_594410.call(path_594411, query_594412, nil, nil, nil)

var getListDeadLetterSourceQueues* = Call_GetListDeadLetterSourceQueues_594395(
    name: "getListDeadLetterSourceQueues", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_GetListDeadLetterSourceQueues_594396, base: "/",
    url: url_GetListDeadLetterSourceQueues_594397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueueTags_594449 = ref object of OpenApiRestCall_593421
proc url_PostListQueueTags_594451(protocol: Scheme; host: string; base: string;
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

proc validate_PostListQueueTags_594450(path: JsonNode; query: JsonNode;
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
  var valid_594452 = path.getOrDefault("QueueName")
  valid_594452 = validateParameter(valid_594452, JString, required = true,
                                 default = nil)
  if valid_594452 != nil:
    section.add "QueueName", valid_594452
  var valid_594453 = path.getOrDefault("AccountNumber")
  valid_594453 = validateParameter(valid_594453, JInt, required = true, default = nil)
  if valid_594453 != nil:
    section.add "AccountNumber", valid_594453
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594454 = query.getOrDefault("Action")
  valid_594454 = validateParameter(valid_594454, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_594454 != nil:
    section.add "Action", valid_594454
  var valid_594455 = query.getOrDefault("Version")
  valid_594455 = validateParameter(valid_594455, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594455 != nil:
    section.add "Version", valid_594455
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
  var valid_594456 = header.getOrDefault("X-Amz-Date")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Date", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Security-Token")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Security-Token", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Content-Sha256", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Algorithm")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Algorithm", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Signature")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Signature", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-SignedHeaders", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Credential")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Credential", valid_594462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594463: Call_PostListQueueTags_594449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594463.validator(path, query, header, formData, body)
  let scheme = call_594463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594463.url(scheme.get, call_594463.host, call_594463.base,
                         call_594463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594463, url, valid)

proc call*(call_594464: Call_PostListQueueTags_594449; QueueName: string;
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
  var path_594465 = newJObject()
  var query_594466 = newJObject()
  add(path_594465, "QueueName", newJString(QueueName))
  add(query_594466, "Action", newJString(Action))
  add(path_594465, "AccountNumber", newJInt(AccountNumber))
  add(query_594466, "Version", newJString(Version))
  result = call_594464.call(path_594465, query_594466, nil, nil, nil)

var postListQueueTags* = Call_PostListQueueTags_594449(name: "postListQueueTags",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_PostListQueueTags_594450, base: "/",
    url: url_PostListQueueTags_594451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueueTags_594431 = ref object of OpenApiRestCall_593421
proc url_GetListQueueTags_594433(protocol: Scheme; host: string; base: string;
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

proc validate_GetListQueueTags_594432(path: JsonNode; query: JsonNode;
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
  var valid_594434 = path.getOrDefault("QueueName")
  valid_594434 = validateParameter(valid_594434, JString, required = true,
                                 default = nil)
  if valid_594434 != nil:
    section.add "QueueName", valid_594434
  var valid_594435 = path.getOrDefault("AccountNumber")
  valid_594435 = validateParameter(valid_594435, JInt, required = true, default = nil)
  if valid_594435 != nil:
    section.add "AccountNumber", valid_594435
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594436 = query.getOrDefault("Action")
  valid_594436 = validateParameter(valid_594436, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_594436 != nil:
    section.add "Action", valid_594436
  var valid_594437 = query.getOrDefault("Version")
  valid_594437 = validateParameter(valid_594437, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594437 != nil:
    section.add "Version", valid_594437
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
  var valid_594438 = header.getOrDefault("X-Amz-Date")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Date", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Security-Token")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Security-Token", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Content-Sha256", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Algorithm")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Algorithm", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Signature")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Signature", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-SignedHeaders", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Credential")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Credential", valid_594444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594445: Call_GetListQueueTags_594431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594445.validator(path, query, header, formData, body)
  let scheme = call_594445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594445.url(scheme.get, call_594445.host, call_594445.base,
                         call_594445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594445, url, valid)

proc call*(call_594446: Call_GetListQueueTags_594431; QueueName: string;
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
  var path_594447 = newJObject()
  var query_594448 = newJObject()
  add(path_594447, "QueueName", newJString(QueueName))
  add(query_594448, "Action", newJString(Action))
  add(path_594447, "AccountNumber", newJInt(AccountNumber))
  add(query_594448, "Version", newJString(Version))
  result = call_594446.call(path_594447, query_594448, nil, nil, nil)

var getListQueueTags* = Call_GetListQueueTags_594431(name: "getListQueueTags",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_GetListQueueTags_594432, base: "/",
    url: url_GetListQueueTags_594433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueues_594483 = ref object of OpenApiRestCall_593421
proc url_PostListQueues_594485(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListQueues_594484(path: JsonNode; query: JsonNode;
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
  var valid_594486 = query.getOrDefault("Action")
  valid_594486 = validateParameter(valid_594486, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_594486 != nil:
    section.add "Action", valid_594486
  var valid_594487 = query.getOrDefault("Version")
  valid_594487 = validateParameter(valid_594487, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594487 != nil:
    section.add "Version", valid_594487
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
  var valid_594488 = header.getOrDefault("X-Amz-Date")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Date", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Security-Token")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Security-Token", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Content-Sha256", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Algorithm")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Algorithm", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Signature")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Signature", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-SignedHeaders", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Credential")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Credential", valid_594494
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueNamePrefix: JString
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_594495 = formData.getOrDefault("QueueNamePrefix")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "QueueNamePrefix", valid_594495
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594496: Call_PostListQueues_594483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594496.validator(path, query, header, formData, body)
  let scheme = call_594496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594496.url(scheme.get, call_594496.host, call_594496.base,
                         call_594496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594496, url, valid)

proc call*(call_594497: Call_PostListQueues_594483; QueueNamePrefix: string = "";
          Action: string = "ListQueues"; Version: string = "2012-11-05"): Recallable =
  ## postListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594498 = newJObject()
  var formData_594499 = newJObject()
  add(formData_594499, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_594498, "Action", newJString(Action))
  add(query_594498, "Version", newJString(Version))
  result = call_594497.call(nil, query_594498, nil, formData_594499, nil)

var postListQueues* = Call_PostListQueues_594483(name: "postListQueues",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_PostListQueues_594484,
    base: "/", url: url_PostListQueues_594485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueues_594467 = ref object of OpenApiRestCall_593421
proc url_GetListQueues_594469(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListQueues_594468(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594470 = query.getOrDefault("Action")
  valid_594470 = validateParameter(valid_594470, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_594470 != nil:
    section.add "Action", valid_594470
  var valid_594471 = query.getOrDefault("QueueNamePrefix")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "QueueNamePrefix", valid_594471
  var valid_594472 = query.getOrDefault("Version")
  valid_594472 = validateParameter(valid_594472, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594472 != nil:
    section.add "Version", valid_594472
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
  var valid_594473 = header.getOrDefault("X-Amz-Date")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Date", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Security-Token")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Security-Token", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Content-Sha256", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Algorithm")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Algorithm", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Signature")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Signature", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-SignedHeaders", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-Credential")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Credential", valid_594479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594480: Call_GetListQueues_594467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594480.validator(path, query, header, formData, body)
  let scheme = call_594480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594480.url(scheme.get, call_594480.host, call_594480.base,
                         call_594480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594480, url, valid)

proc call*(call_594481: Call_GetListQueues_594467; Action: string = "ListQueues";
          QueueNamePrefix: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_594482 = newJObject()
  add(query_594482, "Action", newJString(Action))
  add(query_594482, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_594482, "Version", newJString(Version))
  result = call_594481.call(nil, query_594482, nil, nil, nil)

var getListQueues* = Call_GetListQueues_594467(name: "getListQueues",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_GetListQueues_594468,
    base: "/", url: url_GetListQueues_594469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurgeQueue_594518 = ref object of OpenApiRestCall_593421
proc url_PostPurgeQueue_594520(protocol: Scheme; host: string; base: string;
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

proc validate_PostPurgeQueue_594519(path: JsonNode; query: JsonNode;
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
  var valid_594521 = path.getOrDefault("QueueName")
  valid_594521 = validateParameter(valid_594521, JString, required = true,
                                 default = nil)
  if valid_594521 != nil:
    section.add "QueueName", valid_594521
  var valid_594522 = path.getOrDefault("AccountNumber")
  valid_594522 = validateParameter(valid_594522, JInt, required = true, default = nil)
  if valid_594522 != nil:
    section.add "AccountNumber", valid_594522
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594523 = query.getOrDefault("Action")
  valid_594523 = validateParameter(valid_594523, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_594523 != nil:
    section.add "Action", valid_594523
  var valid_594524 = query.getOrDefault("Version")
  valid_594524 = validateParameter(valid_594524, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594524 != nil:
    section.add "Version", valid_594524
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
  var valid_594525 = header.getOrDefault("X-Amz-Date")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Date", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Security-Token")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Security-Token", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Content-Sha256", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-Algorithm")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-Algorithm", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Signature")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Signature", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-SignedHeaders", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Credential")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Credential", valid_594531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594532: Call_PostPurgeQueue_594518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_594532.validator(path, query, header, formData, body)
  let scheme = call_594532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594532.url(scheme.get, call_594532.host, call_594532.base,
                         call_594532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594532, url, valid)

proc call*(call_594533: Call_PostPurgeQueue_594518; QueueName: string;
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
  var path_594534 = newJObject()
  var query_594535 = newJObject()
  add(path_594534, "QueueName", newJString(QueueName))
  add(query_594535, "Action", newJString(Action))
  add(path_594534, "AccountNumber", newJInt(AccountNumber))
  add(query_594535, "Version", newJString(Version))
  result = call_594533.call(path_594534, query_594535, nil, nil, nil)

var postPurgeQueue* = Call_PostPurgeQueue_594518(name: "postPurgeQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_PostPurgeQueue_594519, base: "/", url: url_PostPurgeQueue_594520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurgeQueue_594500 = ref object of OpenApiRestCall_593421
proc url_GetPurgeQueue_594502(protocol: Scheme; host: string; base: string;
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

proc validate_GetPurgeQueue_594501(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594503 = path.getOrDefault("QueueName")
  valid_594503 = validateParameter(valid_594503, JString, required = true,
                                 default = nil)
  if valid_594503 != nil:
    section.add "QueueName", valid_594503
  var valid_594504 = path.getOrDefault("AccountNumber")
  valid_594504 = validateParameter(valid_594504, JInt, required = true, default = nil)
  if valid_594504 != nil:
    section.add "AccountNumber", valid_594504
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594505 = query.getOrDefault("Action")
  valid_594505 = validateParameter(valid_594505, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_594505 != nil:
    section.add "Action", valid_594505
  var valid_594506 = query.getOrDefault("Version")
  valid_594506 = validateParameter(valid_594506, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594506 != nil:
    section.add "Version", valid_594506
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
  var valid_594507 = header.getOrDefault("X-Amz-Date")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Date", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Security-Token")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Security-Token", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Content-Sha256", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Algorithm")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Algorithm", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Signature")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Signature", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-SignedHeaders", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-Credential")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-Credential", valid_594513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594514: Call_GetPurgeQueue_594500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_594514.validator(path, query, header, formData, body)
  let scheme = call_594514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594514.url(scheme.get, call_594514.host, call_594514.base,
                         call_594514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594514, url, valid)

proc call*(call_594515: Call_GetPurgeQueue_594500; QueueName: string;
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
  var path_594516 = newJObject()
  var query_594517 = newJObject()
  add(path_594516, "QueueName", newJString(QueueName))
  add(query_594517, "Action", newJString(Action))
  add(path_594516, "AccountNumber", newJInt(AccountNumber))
  add(query_594517, "Version", newJString(Version))
  result = call_594515.call(path_594516, query_594517, nil, nil, nil)

var getPurgeQueue* = Call_GetPurgeQueue_594500(name: "getPurgeQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_GetPurgeQueue_594501, base: "/", url: url_GetPurgeQueue_594502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostReceiveMessage_594560 = ref object of OpenApiRestCall_593421
proc url_PostReceiveMessage_594562(protocol: Scheme; host: string; base: string;
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

proc validate_PostReceiveMessage_594561(path: JsonNode; query: JsonNode;
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
  var valid_594563 = path.getOrDefault("QueueName")
  valid_594563 = validateParameter(valid_594563, JString, required = true,
                                 default = nil)
  if valid_594563 != nil:
    section.add "QueueName", valid_594563
  var valid_594564 = path.getOrDefault("AccountNumber")
  valid_594564 = validateParameter(valid_594564, JInt, required = true, default = nil)
  if valid_594564 != nil:
    section.add "AccountNumber", valid_594564
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594565 = query.getOrDefault("Action")
  valid_594565 = validateParameter(valid_594565, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_594565 != nil:
    section.add "Action", valid_594565
  var valid_594566 = query.getOrDefault("Version")
  valid_594566 = validateParameter(valid_594566, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594566 != nil:
    section.add "Version", valid_594566
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
  var valid_594567 = header.getOrDefault("X-Amz-Date")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Date", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Security-Token")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Security-Token", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Content-Sha256", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Algorithm")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Algorithm", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Signature")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Signature", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-SignedHeaders", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Credential")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Credential", valid_594573
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
  var valid_594574 = formData.getOrDefault("VisibilityTimeout")
  valid_594574 = validateParameter(valid_594574, JInt, required = false, default = nil)
  if valid_594574 != nil:
    section.add "VisibilityTimeout", valid_594574
  var valid_594575 = formData.getOrDefault("MaxNumberOfMessages")
  valid_594575 = validateParameter(valid_594575, JInt, required = false, default = nil)
  if valid_594575 != nil:
    section.add "MaxNumberOfMessages", valid_594575
  var valid_594576 = formData.getOrDefault("ReceiveRequestAttemptId")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "ReceiveRequestAttemptId", valid_594576
  var valid_594577 = formData.getOrDefault("MessageAttributeNames")
  valid_594577 = validateParameter(valid_594577, JArray, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "MessageAttributeNames", valid_594577
  var valid_594578 = formData.getOrDefault("AttributeNames")
  valid_594578 = validateParameter(valid_594578, JArray, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "AttributeNames", valid_594578
  var valid_594579 = formData.getOrDefault("WaitTimeSeconds")
  valid_594579 = validateParameter(valid_594579, JInt, required = false, default = nil)
  if valid_594579 != nil:
    section.add "WaitTimeSeconds", valid_594579
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594580: Call_PostReceiveMessage_594560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_594580.validator(path, query, header, formData, body)
  let scheme = call_594580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594580.url(scheme.get, call_594580.host, call_594580.base,
                         call_594580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594580, url, valid)

proc call*(call_594581: Call_PostReceiveMessage_594560; QueueName: string;
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
  var path_594582 = newJObject()
  var query_594583 = newJObject()
  var formData_594584 = newJObject()
  add(formData_594584, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(formData_594584, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(formData_594584, "ReceiveRequestAttemptId",
      newJString(ReceiveRequestAttemptId))
  add(path_594582, "QueueName", newJString(QueueName))
  add(query_594583, "Action", newJString(Action))
  if MessageAttributeNames != nil:
    formData_594584.add "MessageAttributeNames", MessageAttributeNames
  add(path_594582, "AccountNumber", newJInt(AccountNumber))
  if AttributeNames != nil:
    formData_594584.add "AttributeNames", AttributeNames
  add(query_594583, "Version", newJString(Version))
  add(formData_594584, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  result = call_594581.call(path_594582, query_594583, nil, formData_594584, nil)

var postReceiveMessage* = Call_PostReceiveMessage_594560(
    name: "postReceiveMessage", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_PostReceiveMessage_594561, base: "/",
    url: url_PostReceiveMessage_594562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReceiveMessage_594536 = ref object of OpenApiRestCall_593421
proc url_GetReceiveMessage_594538(protocol: Scheme; host: string; base: string;
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

proc validate_GetReceiveMessage_594537(path: JsonNode; query: JsonNode;
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
  var valid_594539 = path.getOrDefault("QueueName")
  valid_594539 = validateParameter(valid_594539, JString, required = true,
                                 default = nil)
  if valid_594539 != nil:
    section.add "QueueName", valid_594539
  var valid_594540 = path.getOrDefault("AccountNumber")
  valid_594540 = validateParameter(valid_594540, JInt, required = true, default = nil)
  if valid_594540 != nil:
    section.add "AccountNumber", valid_594540
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
  var valid_594541 = query.getOrDefault("ReceiveRequestAttemptId")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "ReceiveRequestAttemptId", valid_594541
  var valid_594542 = query.getOrDefault("AttributeNames")
  valid_594542 = validateParameter(valid_594542, JArray, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "AttributeNames", valid_594542
  var valid_594543 = query.getOrDefault("WaitTimeSeconds")
  valid_594543 = validateParameter(valid_594543, JInt, required = false, default = nil)
  if valid_594543 != nil:
    section.add "WaitTimeSeconds", valid_594543
  var valid_594544 = query.getOrDefault("MessageAttributeNames")
  valid_594544 = validateParameter(valid_594544, JArray, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "MessageAttributeNames", valid_594544
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594545 = query.getOrDefault("Action")
  valid_594545 = validateParameter(valid_594545, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_594545 != nil:
    section.add "Action", valid_594545
  var valid_594546 = query.getOrDefault("MaxNumberOfMessages")
  valid_594546 = validateParameter(valid_594546, JInt, required = false, default = nil)
  if valid_594546 != nil:
    section.add "MaxNumberOfMessages", valid_594546
  var valid_594547 = query.getOrDefault("Version")
  valid_594547 = validateParameter(valid_594547, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594547 != nil:
    section.add "Version", valid_594547
  var valid_594548 = query.getOrDefault("VisibilityTimeout")
  valid_594548 = validateParameter(valid_594548, JInt, required = false, default = nil)
  if valid_594548 != nil:
    section.add "VisibilityTimeout", valid_594548
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
  var valid_594549 = header.getOrDefault("X-Amz-Date")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Date", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-Security-Token")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Security-Token", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Content-Sha256", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Algorithm")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Algorithm", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Signature")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Signature", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-SignedHeaders", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Credential")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Credential", valid_594555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594556: Call_GetReceiveMessage_594536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_594556.validator(path, query, header, formData, body)
  let scheme = call_594556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594556.url(scheme.get, call_594556.host, call_594556.base,
                         call_594556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594556, url, valid)

proc call*(call_594557: Call_GetReceiveMessage_594536; QueueName: string;
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
  var path_594558 = newJObject()
  var query_594559 = newJObject()
  add(query_594559, "ReceiveRequestAttemptId", newJString(ReceiveRequestAttemptId))
  if AttributeNames != nil:
    query_594559.add "AttributeNames", AttributeNames
  add(path_594558, "QueueName", newJString(QueueName))
  add(query_594559, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  if MessageAttributeNames != nil:
    query_594559.add "MessageAttributeNames", MessageAttributeNames
  add(query_594559, "Action", newJString(Action))
  add(path_594558, "AccountNumber", newJInt(AccountNumber))
  add(query_594559, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(query_594559, "Version", newJString(Version))
  add(query_594559, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_594557.call(path_594558, query_594559, nil, nil, nil)

var getReceiveMessage* = Call_GetReceiveMessage_594536(name: "getReceiveMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_GetReceiveMessage_594537, base: "/",
    url: url_GetReceiveMessage_594538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_594604 = ref object of OpenApiRestCall_593421
proc url_PostRemovePermission_594606(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemovePermission_594605(path: JsonNode; query: JsonNode;
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
  var valid_594607 = path.getOrDefault("QueueName")
  valid_594607 = validateParameter(valid_594607, JString, required = true,
                                 default = nil)
  if valid_594607 != nil:
    section.add "QueueName", valid_594607
  var valid_594608 = path.getOrDefault("AccountNumber")
  valid_594608 = validateParameter(valid_594608, JInt, required = true, default = nil)
  if valid_594608 != nil:
    section.add "AccountNumber", valid_594608
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594609 = query.getOrDefault("Action")
  valid_594609 = validateParameter(valid_594609, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_594609 != nil:
    section.add "Action", valid_594609
  var valid_594610 = query.getOrDefault("Version")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594610 != nil:
    section.add "Version", valid_594610
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
  var valid_594611 = header.getOrDefault("X-Amz-Date")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Date", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Security-Token")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Security-Token", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Content-Sha256", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-Algorithm")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-Algorithm", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Signature")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Signature", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-SignedHeaders", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Credential")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Credential", valid_594617
  result.add "header", section
  ## parameters in `formData` object:
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Label` field"
  var valid_594618 = formData.getOrDefault("Label")
  valid_594618 = validateParameter(valid_594618, JString, required = true,
                                 default = nil)
  if valid_594618 != nil:
    section.add "Label", valid_594618
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594619: Call_PostRemovePermission_594604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_594619.validator(path, query, header, formData, body)
  let scheme = call_594619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594619.url(scheme.get, call_594619.host, call_594619.base,
                         call_594619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594619, url, valid)

proc call*(call_594620: Call_PostRemovePermission_594604; Label: string;
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
  var path_594621 = newJObject()
  var query_594622 = newJObject()
  var formData_594623 = newJObject()
  add(formData_594623, "Label", newJString(Label))
  add(path_594621, "QueueName", newJString(QueueName))
  add(query_594622, "Action", newJString(Action))
  add(path_594621, "AccountNumber", newJInt(AccountNumber))
  add(query_594622, "Version", newJString(Version))
  result = call_594620.call(path_594621, query_594622, nil, formData_594623, nil)

var postRemovePermission* = Call_PostRemovePermission_594604(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_PostRemovePermission_594605, base: "/",
    url: url_PostRemovePermission_594606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_594585 = ref object of OpenApiRestCall_593421
proc url_GetRemovePermission_594587(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemovePermission_594586(path: JsonNode; query: JsonNode;
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
  var valid_594588 = path.getOrDefault("QueueName")
  valid_594588 = validateParameter(valid_594588, JString, required = true,
                                 default = nil)
  if valid_594588 != nil:
    section.add "QueueName", valid_594588
  var valid_594589 = path.getOrDefault("AccountNumber")
  valid_594589 = validateParameter(valid_594589, JInt, required = true, default = nil)
  if valid_594589 != nil:
    section.add "AccountNumber", valid_594589
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594590 = query.getOrDefault("Action")
  valid_594590 = validateParameter(valid_594590, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_594590 != nil:
    section.add "Action", valid_594590
  var valid_594591 = query.getOrDefault("Version")
  valid_594591 = validateParameter(valid_594591, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594591 != nil:
    section.add "Version", valid_594591
  var valid_594592 = query.getOrDefault("Label")
  valid_594592 = validateParameter(valid_594592, JString, required = true,
                                 default = nil)
  if valid_594592 != nil:
    section.add "Label", valid_594592
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
  var valid_594593 = header.getOrDefault("X-Amz-Date")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Date", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Security-Token")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Security-Token", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Content-Sha256", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Algorithm")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Algorithm", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Signature")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Signature", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-SignedHeaders", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-Credential")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Credential", valid_594599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594600: Call_GetRemovePermission_594585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_594600.validator(path, query, header, formData, body)
  let scheme = call_594600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594600.url(scheme.get, call_594600.host, call_594600.base,
                         call_594600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594600, url, valid)

proc call*(call_594601: Call_GetRemovePermission_594585; QueueName: string;
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
  var path_594602 = newJObject()
  var query_594603 = newJObject()
  add(path_594602, "QueueName", newJString(QueueName))
  add(query_594603, "Action", newJString(Action))
  add(path_594602, "AccountNumber", newJInt(AccountNumber))
  add(query_594603, "Version", newJString(Version))
  add(query_594603, "Label", newJString(Label))
  result = call_594601.call(path_594602, query_594603, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_594585(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_GetRemovePermission_594586, base: "/",
    url: url_GetRemovePermission_594587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessage_594658 = ref object of OpenApiRestCall_593421
proc url_PostSendMessage_594660(protocol: Scheme; host: string; base: string;
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

proc validate_PostSendMessage_594659(path: JsonNode; query: JsonNode;
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
  var valid_594661 = path.getOrDefault("QueueName")
  valid_594661 = validateParameter(valid_594661, JString, required = true,
                                 default = nil)
  if valid_594661 != nil:
    section.add "QueueName", valid_594661
  var valid_594662 = path.getOrDefault("AccountNumber")
  valid_594662 = validateParameter(valid_594662, JInt, required = true, default = nil)
  if valid_594662 != nil:
    section.add "AccountNumber", valid_594662
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594663 = query.getOrDefault("Action")
  valid_594663 = validateParameter(valid_594663, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_594663 != nil:
    section.add "Action", valid_594663
  var valid_594664 = query.getOrDefault("Version")
  valid_594664 = validateParameter(valid_594664, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594664 != nil:
    section.add "Version", valid_594664
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
  var valid_594665 = header.getOrDefault("X-Amz-Date")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Date", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Security-Token")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Security-Token", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Content-Sha256", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Algorithm")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Algorithm", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Signature")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Signature", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-SignedHeaders", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Credential")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Credential", valid_594671
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
  var valid_594672 = formData.getOrDefault("MessageSystemAttribute.1.value")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "MessageSystemAttribute.1.value", valid_594672
  var valid_594673 = formData.getOrDefault("MessageAttribute.1.key")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "MessageAttribute.1.key", valid_594673
  var valid_594674 = formData.getOrDefault("DelaySeconds")
  valid_594674 = validateParameter(valid_594674, JInt, required = false, default = nil)
  if valid_594674 != nil:
    section.add "DelaySeconds", valid_594674
  var valid_594675 = formData.getOrDefault("MessageGroupId")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "MessageGroupId", valid_594675
  var valid_594676 = formData.getOrDefault("MessageAttribute.0.value")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "MessageAttribute.0.value", valid_594676
  var valid_594677 = formData.getOrDefault("MessageSystemAttribute.2.key")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "MessageSystemAttribute.2.key", valid_594677
  var valid_594678 = formData.getOrDefault("MessageDeduplicationId")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "MessageDeduplicationId", valid_594678
  var valid_594679 = formData.getOrDefault("MessageAttribute.2.key")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "MessageAttribute.2.key", valid_594679
  var valid_594680 = formData.getOrDefault("MessageSystemAttribute.0.key")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "MessageSystemAttribute.0.key", valid_594680
  assert formData != nil,
        "formData argument is necessary due to required `MessageBody` field"
  var valid_594681 = formData.getOrDefault("MessageBody")
  valid_594681 = validateParameter(valid_594681, JString, required = true,
                                 default = nil)
  if valid_594681 != nil:
    section.add "MessageBody", valid_594681
  var valid_594682 = formData.getOrDefault("MessageAttribute.0.key")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "MessageAttribute.0.key", valid_594682
  var valid_594683 = formData.getOrDefault("MessageSystemAttribute.2.value")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "MessageSystemAttribute.2.value", valid_594683
  var valid_594684 = formData.getOrDefault("MessageAttribute.1.value")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "MessageAttribute.1.value", valid_594684
  var valid_594685 = formData.getOrDefault("MessageSystemAttribute.0.value")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "MessageSystemAttribute.0.value", valid_594685
  var valid_594686 = formData.getOrDefault("MessageAttribute.2.value")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "MessageAttribute.2.value", valid_594686
  var valid_594687 = formData.getOrDefault("MessageSystemAttribute.1.key")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "MessageSystemAttribute.1.key", valid_594687
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594688: Call_PostSendMessage_594658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_594688.validator(path, query, header, formData, body)
  let scheme = call_594688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594688.url(scheme.get, call_594688.host, call_594688.base,
                         call_594688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594688, url, valid)

proc call*(call_594689: Call_PostSendMessage_594658; QueueName: string;
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
  var path_594690 = newJObject()
  var query_594691 = newJObject()
  var formData_594692 = newJObject()
  add(formData_594692, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(formData_594692, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  add(formData_594692, "DelaySeconds", newJInt(DelaySeconds))
  add(formData_594692, "MessageGroupId", newJString(MessageGroupId))
  add(formData_594692, "MessageAttribute.0.value",
      newJString(MessageAttribute0Value))
  add(formData_594692, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(formData_594692, "MessageDeduplicationId",
      newJString(MessageDeduplicationId))
  add(path_594690, "QueueName", newJString(QueueName))
  add(formData_594692, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(formData_594692, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(formData_594692, "MessageBody", newJString(MessageBody))
  add(query_594691, "Action", newJString(Action))
  add(formData_594692, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(formData_594692, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(formData_594692, "MessageAttribute.1.value",
      newJString(MessageAttribute1Value))
  add(formData_594692, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(formData_594692, "MessageAttribute.2.value",
      newJString(MessageAttribute2Value))
  add(path_594690, "AccountNumber", newJInt(AccountNumber))
  add(query_594691, "Version", newJString(Version))
  add(formData_594692, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  result = call_594689.call(path_594690, query_594691, nil, formData_594692, nil)

var postSendMessage* = Call_PostSendMessage_594658(name: "postSendMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_PostSendMessage_594659, base: "/", url: url_PostSendMessage_594660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessage_594624 = ref object of OpenApiRestCall_593421
proc url_GetSendMessage_594626(protocol: Scheme; host: string; base: string;
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

proc validate_GetSendMessage_594625(path: JsonNode; query: JsonNode;
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
  var valid_594627 = path.getOrDefault("QueueName")
  valid_594627 = validateParameter(valid_594627, JString, required = true,
                                 default = nil)
  if valid_594627 != nil:
    section.add "QueueName", valid_594627
  var valid_594628 = path.getOrDefault("AccountNumber")
  valid_594628 = validateParameter(valid_594628, JInt, required = true, default = nil)
  if valid_594628 != nil:
    section.add "AccountNumber", valid_594628
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
  var valid_594629 = query.getOrDefault("MessageAttribute.0.key")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "MessageAttribute.0.key", valid_594629
  var valid_594630 = query.getOrDefault("MessageSystemAttribute.1.key")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "MessageSystemAttribute.1.key", valid_594630
  var valid_594631 = query.getOrDefault("MessageSystemAttribute.0.value")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "MessageSystemAttribute.0.value", valid_594631
  var valid_594632 = query.getOrDefault("MessageGroupId")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "MessageGroupId", valid_594632
  var valid_594633 = query.getOrDefault("MessageSystemAttribute.2.value")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "MessageSystemAttribute.2.value", valid_594633
  var valid_594634 = query.getOrDefault("MessageAttribute.2.key")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "MessageAttribute.2.key", valid_594634
  var valid_594635 = query.getOrDefault("MessageSystemAttribute.2.key")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "MessageSystemAttribute.2.key", valid_594635
  var valid_594636 = query.getOrDefault("MessageDeduplicationId")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "MessageDeduplicationId", valid_594636
  var valid_594637 = query.getOrDefault("MessageAttribute.2.value")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "MessageAttribute.2.value", valid_594637
  var valid_594638 = query.getOrDefault("MessageSystemAttribute.1.value")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "MessageSystemAttribute.1.value", valid_594638
  var valid_594639 = query.getOrDefault("MessageSystemAttribute.0.key")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "MessageSystemAttribute.0.key", valid_594639
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594640 = query.getOrDefault("Action")
  valid_594640 = validateParameter(valid_594640, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_594640 != nil:
    section.add "Action", valid_594640
  var valid_594641 = query.getOrDefault("MessageAttribute.1.value")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "MessageAttribute.1.value", valid_594641
  var valid_594642 = query.getOrDefault("DelaySeconds")
  valid_594642 = validateParameter(valid_594642, JInt, required = false, default = nil)
  if valid_594642 != nil:
    section.add "DelaySeconds", valid_594642
  var valid_594643 = query.getOrDefault("MessageAttribute.0.value")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "MessageAttribute.0.value", valid_594643
  var valid_594644 = query.getOrDefault("MessageBody")
  valid_594644 = validateParameter(valid_594644, JString, required = true,
                                 default = nil)
  if valid_594644 != nil:
    section.add "MessageBody", valid_594644
  var valid_594645 = query.getOrDefault("Version")
  valid_594645 = validateParameter(valid_594645, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594645 != nil:
    section.add "Version", valid_594645
  var valid_594646 = query.getOrDefault("MessageAttribute.1.key")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "MessageAttribute.1.key", valid_594646
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
  var valid_594647 = header.getOrDefault("X-Amz-Date")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Date", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-Security-Token")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-Security-Token", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Content-Sha256", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Algorithm")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Algorithm", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Signature")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Signature", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-SignedHeaders", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Credential")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Credential", valid_594653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594654: Call_GetSendMessage_594624; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_594654.validator(path, query, header, formData, body)
  let scheme = call_594654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594654.url(scheme.get, call_594654.host, call_594654.base,
                         call_594654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594654, url, valid)

proc call*(call_594655: Call_GetSendMessage_594624; QueueName: string;
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
  var path_594656 = newJObject()
  var query_594657 = newJObject()
  add(query_594657, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(query_594657, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  add(query_594657, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(query_594657, "MessageGroupId", newJString(MessageGroupId))
  add(query_594657, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(query_594657, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(query_594657, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(query_594657, "MessageDeduplicationId", newJString(MessageDeduplicationId))
  add(path_594656, "QueueName", newJString(QueueName))
  add(query_594657, "MessageAttribute.2.value", newJString(MessageAttribute2Value))
  add(query_594657, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(query_594657, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(query_594657, "Action", newJString(Action))
  add(query_594657, "MessageAttribute.1.value", newJString(MessageAttribute1Value))
  add(query_594657, "DelaySeconds", newJInt(DelaySeconds))
  add(path_594656, "AccountNumber", newJInt(AccountNumber))
  add(query_594657, "MessageAttribute.0.value", newJString(MessageAttribute0Value))
  add(query_594657, "MessageBody", newJString(MessageBody))
  add(query_594657, "Version", newJString(Version))
  add(query_594657, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  result = call_594655.call(path_594656, query_594657, nil, nil, nil)

var getSendMessage* = Call_GetSendMessage_594624(name: "getSendMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_GetSendMessage_594625, base: "/", url: url_GetSendMessage_594626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessageBatch_594712 = ref object of OpenApiRestCall_593421
proc url_PostSendMessageBatch_594714(protocol: Scheme; host: string; base: string;
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

proc validate_PostSendMessageBatch_594713(path: JsonNode; query: JsonNode;
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
  var valid_594715 = path.getOrDefault("QueueName")
  valid_594715 = validateParameter(valid_594715, JString, required = true,
                                 default = nil)
  if valid_594715 != nil:
    section.add "QueueName", valid_594715
  var valid_594716 = path.getOrDefault("AccountNumber")
  valid_594716 = validateParameter(valid_594716, JInt, required = true, default = nil)
  if valid_594716 != nil:
    section.add "AccountNumber", valid_594716
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594717 = query.getOrDefault("Action")
  valid_594717 = validateParameter(valid_594717, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_594717 != nil:
    section.add "Action", valid_594717
  var valid_594718 = query.getOrDefault("Version")
  valid_594718 = validateParameter(valid_594718, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594718 != nil:
    section.add "Version", valid_594718
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
  var valid_594719 = header.getOrDefault("X-Amz-Date")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-Date", valid_594719
  var valid_594720 = header.getOrDefault("X-Amz-Security-Token")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Security-Token", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Content-Sha256", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Algorithm")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Algorithm", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Signature")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Signature", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-SignedHeaders", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Credential")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Credential", valid_594725
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_594726 = formData.getOrDefault("Entries")
  valid_594726 = validateParameter(valid_594726, JArray, required = true, default = nil)
  if valid_594726 != nil:
    section.add "Entries", valid_594726
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594727: Call_PostSendMessageBatch_594712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594727.validator(path, query, header, formData, body)
  let scheme = call_594727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594727.url(scheme.get, call_594727.host, call_594727.base,
                         call_594727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594727, url, valid)

proc call*(call_594728: Call_PostSendMessageBatch_594712; Entries: JsonNode;
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
  var path_594729 = newJObject()
  var query_594730 = newJObject()
  var formData_594731 = newJObject()
  if Entries != nil:
    formData_594731.add "Entries", Entries
  add(path_594729, "QueueName", newJString(QueueName))
  add(query_594730, "Action", newJString(Action))
  add(path_594729, "AccountNumber", newJInt(AccountNumber))
  add(query_594730, "Version", newJString(Version))
  result = call_594728.call(path_594729, query_594730, nil, formData_594731, nil)

var postSendMessageBatch* = Call_PostSendMessageBatch_594712(
    name: "postSendMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_PostSendMessageBatch_594713, base: "/",
    url: url_PostSendMessageBatch_594714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessageBatch_594693 = ref object of OpenApiRestCall_593421
proc url_GetSendMessageBatch_594695(protocol: Scheme; host: string; base: string;
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

proc validate_GetSendMessageBatch_594694(path: JsonNode; query: JsonNode;
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
  var valid_594696 = path.getOrDefault("QueueName")
  valid_594696 = validateParameter(valid_594696, JString, required = true,
                                 default = nil)
  if valid_594696 != nil:
    section.add "QueueName", valid_594696
  var valid_594697 = path.getOrDefault("AccountNumber")
  valid_594697 = validateParameter(valid_594697, JInt, required = true, default = nil)
  if valid_594697 != nil:
    section.add "AccountNumber", valid_594697
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_594698 = query.getOrDefault("Entries")
  valid_594698 = validateParameter(valid_594698, JArray, required = true, default = nil)
  if valid_594698 != nil:
    section.add "Entries", valid_594698
  var valid_594699 = query.getOrDefault("Action")
  valid_594699 = validateParameter(valid_594699, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_594699 != nil:
    section.add "Action", valid_594699
  var valid_594700 = query.getOrDefault("Version")
  valid_594700 = validateParameter(valid_594700, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594700 != nil:
    section.add "Version", valid_594700
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
  var valid_594701 = header.getOrDefault("X-Amz-Date")
  valid_594701 = validateParameter(valid_594701, JString, required = false,
                                 default = nil)
  if valid_594701 != nil:
    section.add "X-Amz-Date", valid_594701
  var valid_594702 = header.getOrDefault("X-Amz-Security-Token")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Security-Token", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Content-Sha256", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-Algorithm")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Algorithm", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Signature")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Signature", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-SignedHeaders", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Credential")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Credential", valid_594707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594708: Call_GetSendMessageBatch_594693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_594708.validator(path, query, header, formData, body)
  let scheme = call_594708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594708.url(scheme.get, call_594708.host, call_594708.base,
                         call_594708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594708, url, valid)

proc call*(call_594709: Call_GetSendMessageBatch_594693; QueueName: string;
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
  var path_594710 = newJObject()
  var query_594711 = newJObject()
  add(path_594710, "QueueName", newJString(QueueName))
  if Entries != nil:
    query_594711.add "Entries", Entries
  add(query_594711, "Action", newJString(Action))
  add(path_594710, "AccountNumber", newJInt(AccountNumber))
  add(query_594711, "Version", newJString(Version))
  result = call_594709.call(path_594710, query_594711, nil, nil, nil)

var getSendMessageBatch* = Call_GetSendMessageBatch_594693(
    name: "getSendMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_GetSendMessageBatch_594694, base: "/",
    url: url_GetSendMessageBatch_594695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetQueueAttributes_594756 = ref object of OpenApiRestCall_593421
proc url_PostSetQueueAttributes_594758(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetQueueAttributes_594757(path: JsonNode; query: JsonNode;
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
  var valid_594759 = path.getOrDefault("QueueName")
  valid_594759 = validateParameter(valid_594759, JString, required = true,
                                 default = nil)
  if valid_594759 != nil:
    section.add "QueueName", valid_594759
  var valid_594760 = path.getOrDefault("AccountNumber")
  valid_594760 = validateParameter(valid_594760, JInt, required = true, default = nil)
  if valid_594760 != nil:
    section.add "AccountNumber", valid_594760
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594761 = query.getOrDefault("Action")
  valid_594761 = validateParameter(valid_594761, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_594761 != nil:
    section.add "Action", valid_594761
  var valid_594762 = query.getOrDefault("Version")
  valid_594762 = validateParameter(valid_594762, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594762 != nil:
    section.add "Version", valid_594762
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
  var valid_594763 = header.getOrDefault("X-Amz-Date")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Date", valid_594763
  var valid_594764 = header.getOrDefault("X-Amz-Security-Token")
  valid_594764 = validateParameter(valid_594764, JString, required = false,
                                 default = nil)
  if valid_594764 != nil:
    section.add "X-Amz-Security-Token", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Content-Sha256", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Algorithm")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Algorithm", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Signature")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Signature", valid_594767
  var valid_594768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-SignedHeaders", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Credential")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Credential", valid_594769
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attribute.0.key: JString
  ##   Attribute.0.value: JString
  ##   Attribute.1.value: JString
  ##   Attribute.1.key: JString
  ##   Attribute.2.value: JString
  ##   Attribute.2.key: JString
  section = newJObject()
  var valid_594770 = formData.getOrDefault("Attribute.0.key")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "Attribute.0.key", valid_594770
  var valid_594771 = formData.getOrDefault("Attribute.0.value")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "Attribute.0.value", valid_594771
  var valid_594772 = formData.getOrDefault("Attribute.1.value")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "Attribute.1.value", valid_594772
  var valid_594773 = formData.getOrDefault("Attribute.1.key")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "Attribute.1.key", valid_594773
  var valid_594774 = formData.getOrDefault("Attribute.2.value")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "Attribute.2.value", valid_594774
  var valid_594775 = formData.getOrDefault("Attribute.2.key")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "Attribute.2.key", valid_594775
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594776: Call_PostSetQueueAttributes_594756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_594776.validator(path, query, header, formData, body)
  let scheme = call_594776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594776.url(scheme.get, call_594776.host, call_594776.base,
                         call_594776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594776, url, valid)

proc call*(call_594777: Call_PostSetQueueAttributes_594756; QueueName: string;
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
  var path_594778 = newJObject()
  var query_594779 = newJObject()
  var formData_594780 = newJObject()
  add(formData_594780, "Attribute.0.key", newJString(Attribute0Key))
  add(formData_594780, "Attribute.0.value", newJString(Attribute0Value))
  add(path_594778, "QueueName", newJString(QueueName))
  add(formData_594780, "Attribute.1.value", newJString(Attribute1Value))
  add(query_594779, "Action", newJString(Action))
  add(formData_594780, "Attribute.1.key", newJString(Attribute1Key))
  add(path_594778, "AccountNumber", newJInt(AccountNumber))
  add(formData_594780, "Attribute.2.value", newJString(Attribute2Value))
  add(query_594779, "Version", newJString(Version))
  add(formData_594780, "Attribute.2.key", newJString(Attribute2Key))
  result = call_594777.call(path_594778, query_594779, nil, formData_594780, nil)

var postSetQueueAttributes* = Call_PostSetQueueAttributes_594756(
    name: "postSetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_PostSetQueueAttributes_594757, base: "/",
    url: url_PostSetQueueAttributes_594758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetQueueAttributes_594732 = ref object of OpenApiRestCall_593421
proc url_GetSetQueueAttributes_594734(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetQueueAttributes_594733(path: JsonNode; query: JsonNode;
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
  var valid_594735 = path.getOrDefault("QueueName")
  valid_594735 = validateParameter(valid_594735, JString, required = true,
                                 default = nil)
  if valid_594735 != nil:
    section.add "QueueName", valid_594735
  var valid_594736 = path.getOrDefault("AccountNumber")
  valid_594736 = validateParameter(valid_594736, JInt, required = true, default = nil)
  if valid_594736 != nil:
    section.add "AccountNumber", valid_594736
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
  var valid_594737 = query.getOrDefault("Attribute.2.value")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "Attribute.2.value", valid_594737
  var valid_594738 = query.getOrDefault("Attribute.0.key")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "Attribute.0.key", valid_594738
  var valid_594739 = query.getOrDefault("Attribute.1.value")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "Attribute.1.value", valid_594739
  var valid_594740 = query.getOrDefault("Attribute.1.key")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "Attribute.1.key", valid_594740
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594741 = query.getOrDefault("Action")
  valid_594741 = validateParameter(valid_594741, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_594741 != nil:
    section.add "Action", valid_594741
  var valid_594742 = query.getOrDefault("Attribute.2.key")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "Attribute.2.key", valid_594742
  var valid_594743 = query.getOrDefault("Attribute.0.value")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "Attribute.0.value", valid_594743
  var valid_594744 = query.getOrDefault("Version")
  valid_594744 = validateParameter(valid_594744, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594744 != nil:
    section.add "Version", valid_594744
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
  var valid_594745 = header.getOrDefault("X-Amz-Date")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "X-Amz-Date", valid_594745
  var valid_594746 = header.getOrDefault("X-Amz-Security-Token")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "X-Amz-Security-Token", valid_594746
  var valid_594747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Content-Sha256", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Algorithm")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Algorithm", valid_594748
  var valid_594749 = header.getOrDefault("X-Amz-Signature")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "X-Amz-Signature", valid_594749
  var valid_594750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "X-Amz-SignedHeaders", valid_594750
  var valid_594751 = header.getOrDefault("X-Amz-Credential")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Credential", valid_594751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594752: Call_GetSetQueueAttributes_594732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_594752.validator(path, query, header, formData, body)
  let scheme = call_594752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594752.url(scheme.get, call_594752.host, call_594752.base,
                         call_594752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594752, url, valid)

proc call*(call_594753: Call_GetSetQueueAttributes_594732; QueueName: string;
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
  var path_594754 = newJObject()
  var query_594755 = newJObject()
  add(query_594755, "Attribute.2.value", newJString(Attribute2Value))
  add(query_594755, "Attribute.0.key", newJString(Attribute0Key))
  add(query_594755, "Attribute.1.value", newJString(Attribute1Value))
  add(path_594754, "QueueName", newJString(QueueName))
  add(query_594755, "Attribute.1.key", newJString(Attribute1Key))
  add(query_594755, "Action", newJString(Action))
  add(query_594755, "Attribute.2.key", newJString(Attribute2Key))
  add(path_594754, "AccountNumber", newJInt(AccountNumber))
  add(query_594755, "Attribute.0.value", newJString(Attribute0Value))
  add(query_594755, "Version", newJString(Version))
  result = call_594753.call(path_594754, query_594755, nil, nil, nil)

var getSetQueueAttributes* = Call_GetSetQueueAttributes_594732(
    name: "getSetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_GetSetQueueAttributes_594733, base: "/",
    url: url_GetSetQueueAttributes_594734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagQueue_594805 = ref object of OpenApiRestCall_593421
proc url_PostTagQueue_594807(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagQueue_594806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594808 = path.getOrDefault("QueueName")
  valid_594808 = validateParameter(valid_594808, JString, required = true,
                                 default = nil)
  if valid_594808 != nil:
    section.add "QueueName", valid_594808
  var valid_594809 = path.getOrDefault("AccountNumber")
  valid_594809 = validateParameter(valid_594809, JInt, required = true, default = nil)
  if valid_594809 != nil:
    section.add "AccountNumber", valid_594809
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594810 = query.getOrDefault("Action")
  valid_594810 = validateParameter(valid_594810, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_594810 != nil:
    section.add "Action", valid_594810
  var valid_594811 = query.getOrDefault("Version")
  valid_594811 = validateParameter(valid_594811, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594811 != nil:
    section.add "Version", valid_594811
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
  var valid_594812 = header.getOrDefault("X-Amz-Date")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Date", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-Security-Token")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-Security-Token", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Content-Sha256", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Algorithm")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Algorithm", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Signature")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Signature", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-SignedHeaders", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Credential")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Credential", valid_594818
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags.0.key: JString
  ##   Tags.1.key: JString
  ##   Tags.2.value: JString
  ##   Tags.1.value: JString
  ##   Tags.2.key: JString
  ##   Tags.0.value: JString
  section = newJObject()
  var valid_594819 = formData.getOrDefault("Tags.0.key")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "Tags.0.key", valid_594819
  var valid_594820 = formData.getOrDefault("Tags.1.key")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "Tags.1.key", valid_594820
  var valid_594821 = formData.getOrDefault("Tags.2.value")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "Tags.2.value", valid_594821
  var valid_594822 = formData.getOrDefault("Tags.1.value")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "Tags.1.value", valid_594822
  var valid_594823 = formData.getOrDefault("Tags.2.key")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "Tags.2.key", valid_594823
  var valid_594824 = formData.getOrDefault("Tags.0.value")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "Tags.0.value", valid_594824
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594825: Call_PostTagQueue_594805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594825.validator(path, query, header, formData, body)
  let scheme = call_594825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594825.url(scheme.get, call_594825.host, call_594825.base,
                         call_594825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594825, url, valid)

proc call*(call_594826: Call_PostTagQueue_594805; QueueName: string;
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
  var path_594827 = newJObject()
  var query_594828 = newJObject()
  var formData_594829 = newJObject()
  add(formData_594829, "Tags.0.key", newJString(Tags0Key))
  add(formData_594829, "Tags.1.key", newJString(Tags1Key))
  add(path_594827, "QueueName", newJString(QueueName))
  add(formData_594829, "Tags.2.value", newJString(Tags2Value))
  add(query_594828, "Action", newJString(Action))
  add(formData_594829, "Tags.1.value", newJString(Tags1Value))
  add(path_594827, "AccountNumber", newJInt(AccountNumber))
  add(formData_594829, "Tags.2.key", newJString(Tags2Key))
  add(query_594828, "Version", newJString(Version))
  add(formData_594829, "Tags.0.value", newJString(Tags0Value))
  result = call_594826.call(path_594827, query_594828, nil, formData_594829, nil)

var postTagQueue* = Call_PostTagQueue_594805(name: "postTagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
    validator: validate_PostTagQueue_594806, base: "/", url: url_PostTagQueue_594807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagQueue_594781 = ref object of OpenApiRestCall_593421
proc url_GetTagQueue_594783(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagQueue_594782(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594784 = path.getOrDefault("QueueName")
  valid_594784 = validateParameter(valid_594784, JString, required = true,
                                 default = nil)
  if valid_594784 != nil:
    section.add "QueueName", valid_594784
  var valid_594785 = path.getOrDefault("AccountNumber")
  valid_594785 = validateParameter(valid_594785, JInt, required = true, default = nil)
  if valid_594785 != nil:
    section.add "AccountNumber", valid_594785
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
  var valid_594786 = query.getOrDefault("Tags.2.value")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "Tags.2.value", valid_594786
  var valid_594787 = query.getOrDefault("Tags.2.key")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "Tags.2.key", valid_594787
  var valid_594788 = query.getOrDefault("Tags.1.value")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "Tags.1.value", valid_594788
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594789 = query.getOrDefault("Action")
  valid_594789 = validateParameter(valid_594789, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_594789 != nil:
    section.add "Action", valid_594789
  var valid_594790 = query.getOrDefault("Tags.0.key")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "Tags.0.key", valid_594790
  var valid_594791 = query.getOrDefault("Tags.1.key")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "Tags.1.key", valid_594791
  var valid_594792 = query.getOrDefault("Tags.0.value")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "Tags.0.value", valid_594792
  var valid_594793 = query.getOrDefault("Version")
  valid_594793 = validateParameter(valid_594793, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594793 != nil:
    section.add "Version", valid_594793
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
  var valid_594794 = header.getOrDefault("X-Amz-Date")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Date", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Security-Token")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Security-Token", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Content-Sha256", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Algorithm")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Algorithm", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-Signature")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Signature", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-SignedHeaders", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Credential")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Credential", valid_594800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594801: Call_GetTagQueue_594781; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594801.validator(path, query, header, formData, body)
  let scheme = call_594801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594801.url(scheme.get, call_594801.host, call_594801.base,
                         call_594801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594801, url, valid)

proc call*(call_594802: Call_GetTagQueue_594781; QueueName: string;
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
  var path_594803 = newJObject()
  var query_594804 = newJObject()
  add(query_594804, "Tags.2.value", newJString(Tags2Value))
  add(query_594804, "Tags.2.key", newJString(Tags2Key))
  add(query_594804, "Tags.1.value", newJString(Tags1Value))
  add(path_594803, "QueueName", newJString(QueueName))
  add(query_594804, "Action", newJString(Action))
  add(query_594804, "Tags.0.key", newJString(Tags0Key))
  add(path_594803, "AccountNumber", newJInt(AccountNumber))
  add(query_594804, "Tags.1.key", newJString(Tags1Key))
  add(query_594804, "Tags.0.value", newJString(Tags0Value))
  add(query_594804, "Version", newJString(Version))
  result = call_594802.call(path_594803, query_594804, nil, nil, nil)

var getTagQueue* = Call_GetTagQueue_594781(name: "getTagQueue",
                                        meth: HttpMethod.HttpGet,
                                        host: "sqs.amazonaws.com", route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
                                        validator: validate_GetTagQueue_594782,
                                        base: "/", url: url_GetTagQueue_594783,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagQueue_594849 = ref object of OpenApiRestCall_593421
proc url_PostUntagQueue_594851(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagQueue_594850(path: JsonNode; query: JsonNode;
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
  var valid_594852 = path.getOrDefault("QueueName")
  valid_594852 = validateParameter(valid_594852, JString, required = true,
                                 default = nil)
  if valid_594852 != nil:
    section.add "QueueName", valid_594852
  var valid_594853 = path.getOrDefault("AccountNumber")
  valid_594853 = validateParameter(valid_594853, JInt, required = true, default = nil)
  if valid_594853 != nil:
    section.add "AccountNumber", valid_594853
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594854 = query.getOrDefault("Action")
  valid_594854 = validateParameter(valid_594854, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_594854 != nil:
    section.add "Action", valid_594854
  var valid_594855 = query.getOrDefault("Version")
  valid_594855 = validateParameter(valid_594855, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594855 != nil:
    section.add "Version", valid_594855
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
  var valid_594856 = header.getOrDefault("X-Amz-Date")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Date", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Security-Token")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Security-Token", valid_594857
  var valid_594858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-Content-Sha256", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Algorithm")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Algorithm", valid_594859
  var valid_594860 = header.getOrDefault("X-Amz-Signature")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "X-Amz-Signature", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-SignedHeaders", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-Credential")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-Credential", valid_594862
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594863 = formData.getOrDefault("TagKeys")
  valid_594863 = validateParameter(valid_594863, JArray, required = true, default = nil)
  if valid_594863 != nil:
    section.add "TagKeys", valid_594863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594864: Call_PostUntagQueue_594849; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594864.validator(path, query, header, formData, body)
  let scheme = call_594864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594864.url(scheme.get, call_594864.host, call_594864.base,
                         call_594864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594864, url, valid)

proc call*(call_594865: Call_PostUntagQueue_594849; QueueName: string;
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
  var path_594866 = newJObject()
  var query_594867 = newJObject()
  var formData_594868 = newJObject()
  add(path_594866, "QueueName", newJString(QueueName))
  add(query_594867, "Action", newJString(Action))
  if TagKeys != nil:
    formData_594868.add "TagKeys", TagKeys
  add(path_594866, "AccountNumber", newJInt(AccountNumber))
  add(query_594867, "Version", newJString(Version))
  result = call_594865.call(path_594866, query_594867, nil, formData_594868, nil)

var postUntagQueue* = Call_PostUntagQueue_594849(name: "postUntagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_PostUntagQueue_594850, base: "/", url: url_PostUntagQueue_594851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagQueue_594830 = ref object of OpenApiRestCall_593421
proc url_GetUntagQueue_594832(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagQueue_594831(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594833 = path.getOrDefault("QueueName")
  valid_594833 = validateParameter(valid_594833, JString, required = true,
                                 default = nil)
  if valid_594833 != nil:
    section.add "QueueName", valid_594833
  var valid_594834 = path.getOrDefault("AccountNumber")
  valid_594834 = validateParameter(valid_594834, JInt, required = true, default = nil)
  if valid_594834 != nil:
    section.add "AccountNumber", valid_594834
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594835 = query.getOrDefault("Action")
  valid_594835 = validateParameter(valid_594835, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_594835 != nil:
    section.add "Action", valid_594835
  var valid_594836 = query.getOrDefault("TagKeys")
  valid_594836 = validateParameter(valid_594836, JArray, required = true, default = nil)
  if valid_594836 != nil:
    section.add "TagKeys", valid_594836
  var valid_594837 = query.getOrDefault("Version")
  valid_594837 = validateParameter(valid_594837, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_594837 != nil:
    section.add "Version", valid_594837
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
  var valid_594838 = header.getOrDefault("X-Amz-Date")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Date", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-Security-Token")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Security-Token", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-Content-Sha256", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-Algorithm")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Algorithm", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Signature")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Signature", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-SignedHeaders", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Credential")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Credential", valid_594844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594845: Call_GetUntagQueue_594830; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_594845.validator(path, query, header, formData, body)
  let scheme = call_594845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594845.url(scheme.get, call_594845.host, call_594845.base,
                         call_594845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594845, url, valid)

proc call*(call_594846: Call_GetUntagQueue_594830; QueueName: string;
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
  var path_594847 = newJObject()
  var query_594848 = newJObject()
  add(path_594847, "QueueName", newJString(QueueName))
  add(query_594848, "Action", newJString(Action))
  add(path_594847, "AccountNumber", newJInt(AccountNumber))
  if TagKeys != nil:
    query_594848.add "TagKeys", TagKeys
  add(query_594848, "Version", newJString(Version))
  result = call_594846.call(path_594847, query_594848, nil, nil, nil)

var getUntagQueue* = Call_GetUntagQueue_594830(name: "getUntagQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_GetUntagQueue_594831, base: "/", url: url_GetUntagQueue_594832,
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
