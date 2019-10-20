
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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_592977 = ref object of OpenApiRestCall_592348
proc url_PostAddPermission_592979(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddPermission_592978(path: JsonNode; query: JsonNode;
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
  var valid_592980 = path.getOrDefault("AccountNumber")
  valid_592980 = validateParameter(valid_592980, JInt, required = true, default = nil)
  if valid_592980 != nil:
    section.add "AccountNumber", valid_592980
  var valid_592981 = path.getOrDefault("QueueName")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "QueueName", valid_592981
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_592982 = query.getOrDefault("Action")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_592982 != nil:
    section.add "Action", valid_592982
  var valid_592983 = query.getOrDefault("Version")
  valid_592983 = validateParameter(valid_592983, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_592983 != nil:
    section.add "Version", valid_592983
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
  var valid_592984 = header.getOrDefault("X-Amz-Signature")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Signature", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Content-Sha256", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Date")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Date", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Credential")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Credential", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Security-Token")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Security-Token", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Algorithm")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Algorithm", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-SignedHeaders", valid_592990
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
  var valid_592991 = formData.getOrDefault("Actions")
  valid_592991 = validateParameter(valid_592991, JArray, required = true, default = nil)
  if valid_592991 != nil:
    section.add "Actions", valid_592991
  var valid_592992 = formData.getOrDefault("Label")
  valid_592992 = validateParameter(valid_592992, JString, required = true,
                                 default = nil)
  if valid_592992 != nil:
    section.add "Label", valid_592992
  var valid_592993 = formData.getOrDefault("AWSAccountIds")
  valid_592993 = validateParameter(valid_592993, JArray, required = true, default = nil)
  if valid_592993 != nil:
    section.add "AWSAccountIds", valid_592993
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592994: Call_PostAddPermission_592977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_592994.validator(path, query, header, formData, body)
  let scheme = call_592994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592994.url(scheme.get, call_592994.host, call_592994.base,
                         call_592994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592994, url, valid)

proc call*(call_592995: Call_PostAddPermission_592977; Actions: JsonNode;
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
  var path_592996 = newJObject()
  var query_592997 = newJObject()
  var formData_592998 = newJObject()
  if Actions != nil:
    formData_592998.add "Actions", Actions
  add(path_592996, "AccountNumber", newJInt(AccountNumber))
  add(path_592996, "QueueName", newJString(QueueName))
  add(query_592997, "Action", newJString(Action))
  add(formData_592998, "Label", newJString(Label))
  add(query_592997, "Version", newJString(Version))
  if AWSAccountIds != nil:
    formData_592998.add "AWSAccountIds", AWSAccountIds
  result = call_592995.call(path_592996, query_592997, nil, formData_592998, nil)

var postAddPermission* = Call_PostAddPermission_592977(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_PostAddPermission_592978, base: "/",
    url: url_PostAddPermission_592979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_592687 = ref object of OpenApiRestCall_592348
proc url_GetAddPermission_592689(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddPermission_592688(path: JsonNode; query: JsonNode;
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
  var valid_592815 = path.getOrDefault("AccountNumber")
  valid_592815 = validateParameter(valid_592815, JInt, required = true, default = nil)
  if valid_592815 != nil:
    section.add "AccountNumber", valid_592815
  var valid_592816 = path.getOrDefault("QueueName")
  valid_592816 = validateParameter(valid_592816, JString, required = true,
                                 default = nil)
  if valid_592816 != nil:
    section.add "QueueName", valid_592816
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
  var valid_592817 = query.getOrDefault("Actions")
  valid_592817 = validateParameter(valid_592817, JArray, required = true, default = nil)
  if valid_592817 != nil:
    section.add "Actions", valid_592817
  var valid_592818 = query.getOrDefault("AWSAccountIds")
  valid_592818 = validateParameter(valid_592818, JArray, required = true, default = nil)
  if valid_592818 != nil:
    section.add "AWSAccountIds", valid_592818
  var valid_592832 = query.getOrDefault("Action")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_592832 != nil:
    section.add "Action", valid_592832
  var valid_592833 = query.getOrDefault("Version")
  valid_592833 = validateParameter(valid_592833, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_592833 != nil:
    section.add "Version", valid_592833
  var valid_592834 = query.getOrDefault("Label")
  valid_592834 = validateParameter(valid_592834, JString, required = true,
                                 default = nil)
  if valid_592834 != nil:
    section.add "Label", valid_592834
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
  var valid_592835 = header.getOrDefault("X-Amz-Signature")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Signature", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Content-Sha256", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Date")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Date", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Credential")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Credential", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Security-Token")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Security-Token", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-Algorithm")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-Algorithm", valid_592840
  var valid_592841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592841 = validateParameter(valid_592841, JString, required = false,
                                 default = nil)
  if valid_592841 != nil:
    section.add "X-Amz-SignedHeaders", valid_592841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592864: Call_GetAddPermission_592687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a permission to a queue for a specific <a href="https://docs.aws.amazon.com/general/latest/gr/glos-chap.html#P">principal</a>. This allows sharing access to the queue.</p> <p>When you create a queue, you have full control access rights for the queue. Only you, the owner of the queue, can grant or deny permissions to the queue. For more information about these permissions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <ul> <li> <p> <code>AddPermission</code> generates a policy for you. You can use <code> <a>SetQueueAttributes</a> </code> to upload your policy. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies.html">Using Custom Policies with the Amazon SQS Access Policy Language</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>An Amazon SQS policy can have a maximum of 7 actions.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_592864.validator(path, query, header, formData, body)
  let scheme = call_592864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592864.url(scheme.get, call_592864.host, call_592864.base,
                         call_592864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592864, url, valid)

proc call*(call_592935: Call_GetAddPermission_592687; Actions: JsonNode;
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
  var path_592936 = newJObject()
  var query_592938 = newJObject()
  if Actions != nil:
    query_592938.add "Actions", Actions
  add(path_592936, "AccountNumber", newJInt(AccountNumber))
  add(path_592936, "QueueName", newJString(QueueName))
  if AWSAccountIds != nil:
    query_592938.add "AWSAccountIds", AWSAccountIds
  add(query_592938, "Action", newJString(Action))
  add(query_592938, "Version", newJString(Version))
  add(query_592938, "Label", newJString(Label))
  result = call_592935.call(path_592936, query_592938, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_592687(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=AddPermission",
    validator: validate_GetAddPermission_592688, base: "/",
    url: url_GetAddPermission_592689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibility_593019 = ref object of OpenApiRestCall_592348
proc url_PostChangeMessageVisibility_593021(protocol: Scheme; host: string;
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

proc validate_PostChangeMessageVisibility_593020(path: JsonNode; query: JsonNode;
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
  var valid_593022 = path.getOrDefault("AccountNumber")
  valid_593022 = validateParameter(valid_593022, JInt, required = true, default = nil)
  if valid_593022 != nil:
    section.add "AccountNumber", valid_593022
  var valid_593023 = path.getOrDefault("QueueName")
  valid_593023 = validateParameter(valid_593023, JString, required = true,
                                 default = nil)
  if valid_593023 != nil:
    section.add "QueueName", valid_593023
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593024 = query.getOrDefault("Action")
  valid_593024 = validateParameter(valid_593024, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_593024 != nil:
    section.add "Action", valid_593024
  var valid_593025 = query.getOrDefault("Version")
  valid_593025 = validateParameter(valid_593025, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593025 != nil:
    section.add "Version", valid_593025
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
  var valid_593026 = header.getOrDefault("X-Amz-Signature")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Signature", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Content-Sha256", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Date")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Date", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Credential")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Credential", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Security-Token")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Security-Token", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Algorithm")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Algorithm", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-SignedHeaders", valid_593032
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ReceiptHandle` field"
  var valid_593033 = formData.getOrDefault("ReceiptHandle")
  valid_593033 = validateParameter(valid_593033, JString, required = true,
                                 default = nil)
  if valid_593033 != nil:
    section.add "ReceiptHandle", valid_593033
  var valid_593034 = formData.getOrDefault("VisibilityTimeout")
  valid_593034 = validateParameter(valid_593034, JInt, required = true, default = nil)
  if valid_593034 != nil:
    section.add "VisibilityTimeout", valid_593034
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593035: Call_PostChangeMessageVisibility_593019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_593035.validator(path, query, header, formData, body)
  let scheme = call_593035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593035.url(scheme.get, call_593035.host, call_593035.base,
                         call_593035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593035, url, valid)

proc call*(call_593036: Call_PostChangeMessageVisibility_593019;
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
  var path_593037 = newJObject()
  var query_593038 = newJObject()
  var formData_593039 = newJObject()
  add(formData_593039, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_593037, "AccountNumber", newJInt(AccountNumber))
  add(path_593037, "QueueName", newJString(QueueName))
  add(formData_593039, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(query_593038, "Action", newJString(Action))
  add(query_593038, "Version", newJString(Version))
  result = call_593036.call(path_593037, query_593038, nil, formData_593039, nil)

var postChangeMessageVisibility* = Call_PostChangeMessageVisibility_593019(
    name: "postChangeMessageVisibility", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_PostChangeMessageVisibility_593020, base: "/",
    url: url_PostChangeMessageVisibility_593021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibility_592999 = ref object of OpenApiRestCall_592348
proc url_GetChangeMessageVisibility_593001(protocol: Scheme; host: string;
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

proc validate_GetChangeMessageVisibility_593000(path: JsonNode; query: JsonNode;
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
  var valid_593002 = path.getOrDefault("AccountNumber")
  valid_593002 = validateParameter(valid_593002, JInt, required = true, default = nil)
  if valid_593002 != nil:
    section.add "AccountNumber", valid_593002
  var valid_593003 = path.getOrDefault("QueueName")
  valid_593003 = validateParameter(valid_593003, JString, required = true,
                                 default = nil)
  if valid_593003 != nil:
    section.add "QueueName", valid_593003
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message whose visibility timeout is changed. This parameter is returned by the <code> <a>ReceiveMessage</a> </code> action.
  ##   Version: JString (required)
  ##   VisibilityTimeout: JInt (required)
  ##                    : The new value for the message's visibility timeout (in seconds). Values values: <code>0</code> to <code>43200</code>. Maximum: 12 hours.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593004 = query.getOrDefault("Action")
  valid_593004 = validateParameter(valid_593004, JString, required = true, default = newJString(
      "ChangeMessageVisibility"))
  if valid_593004 != nil:
    section.add "Action", valid_593004
  var valid_593005 = query.getOrDefault("ReceiptHandle")
  valid_593005 = validateParameter(valid_593005, JString, required = true,
                                 default = nil)
  if valid_593005 != nil:
    section.add "ReceiptHandle", valid_593005
  var valid_593006 = query.getOrDefault("Version")
  valid_593006 = validateParameter(valid_593006, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593006 != nil:
    section.add "Version", valid_593006
  var valid_593007 = query.getOrDefault("VisibilityTimeout")
  valid_593007 = validateParameter(valid_593007, JInt, required = true, default = nil)
  if valid_593007 != nil:
    section.add "VisibilityTimeout", valid_593007
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
  var valid_593008 = header.getOrDefault("X-Amz-Signature")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Signature", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Content-Sha256", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Date")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Date", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Credential")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Credential", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Security-Token")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Security-Token", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Algorithm")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Algorithm", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-SignedHeaders", valid_593014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593015: Call_GetChangeMessageVisibility_592999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of a specified message in a queue to a new value. The default visibility timeout for a message is 30 seconds. The minimum is 0 seconds. The maximum is 12 hours. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>For example, you have a message with a visibility timeout of 5 minutes. After 3 minutes, you call <code>ChangeMessageVisibility</code> with a timeout of 10 minutes. You can continue to call <code>ChangeMessageVisibility</code> to extend the visibility timeout to the maximum allowed time. If you try to extend the visibility timeout beyond the maximum, your request is rejected.</p> <p>An Amazon SQS message has three basic states:</p> <ol> <li> <p>Sent to a queue by a producer.</p> </li> <li> <p>Received from the queue by a consumer.</p> </li> <li> <p>Deleted from the queue.</p> </li> </ol> <p>A message is considered to be <i>stored</i> after it is sent to a queue by a producer, but not yet received from the queue by a consumer (that is, between states 1 and 2). There is no limit to the number of stored messages. A message is considered to be <i>in flight</i> after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3). There is a limit to the number of inflight messages.</p> <p>Limits that apply to inflight messages are unrelated to the <i>unlimited</i> number of stored messages.</p> <p>For most standard queues (depending on queue traffic and message backlog), there can be a maximum of approximately 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the <code>OverLimit</code> error message. To avoid reaching the limit, you should delete messages from the queue after they're processed. You can also increase the number of queues you use to process your messages. To request a limit increase, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sqs">file a support request</a>.</p> <p>For FIFO queues, there can be a maximum of 20,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns no error messages.</p> <important> <p>If you attempt to set the <code>VisibilityTimeout</code> to a value greater than the maximum time left, Amazon SQS returns an error. Amazon SQS doesn't automatically recalculate and increase the timeout to the maximum remaining time.</p> <p>Unlike with a queue, when you change the visibility timeout for a specific message the timeout value is applied immediately but isn't saved in memory for that message. If you don't delete a message after it is received, the visibility timeout for the message reverts to the original timeout value (not to the value you set using the <code>ChangeMessageVisibility</code> action) the next time the message is received.</p> </important>
  ## 
  let valid = call_593015.validator(path, query, header, formData, body)
  let scheme = call_593015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593015.url(scheme.get, call_593015.host, call_593015.base,
                         call_593015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593015, url, valid)

proc call*(call_593016: Call_GetChangeMessageVisibility_592999; AccountNumber: int;
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
  var path_593017 = newJObject()
  var query_593018 = newJObject()
  add(path_593017, "AccountNumber", newJInt(AccountNumber))
  add(path_593017, "QueueName", newJString(QueueName))
  add(query_593018, "Action", newJString(Action))
  add(query_593018, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_593018, "Version", newJString(Version))
  add(query_593018, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_593016.call(path_593017, query_593018, nil, nil, nil)

var getChangeMessageVisibility* = Call_GetChangeMessageVisibility_592999(
    name: "getChangeMessageVisibility", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibility",
    validator: validate_GetChangeMessageVisibility_593000, base: "/",
    url: url_GetChangeMessageVisibility_593001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostChangeMessageVisibilityBatch_593059 = ref object of OpenApiRestCall_592348
proc url_PostChangeMessageVisibilityBatch_593061(protocol: Scheme; host: string;
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

proc validate_PostChangeMessageVisibilityBatch_593060(path: JsonNode;
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
  var valid_593062 = path.getOrDefault("AccountNumber")
  valid_593062 = validateParameter(valid_593062, JInt, required = true, default = nil)
  if valid_593062 != nil:
    section.add "AccountNumber", valid_593062
  var valid_593063 = path.getOrDefault("QueueName")
  valid_593063 = validateParameter(valid_593063, JString, required = true,
                                 default = nil)
  if valid_593063 != nil:
    section.add "QueueName", valid_593063
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593064 = query.getOrDefault("Action")
  valid_593064 = validateParameter(valid_593064, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_593064 != nil:
    section.add "Action", valid_593064
  var valid_593065 = query.getOrDefault("Version")
  valid_593065 = validateParameter(valid_593065, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593065 != nil:
    section.add "Version", valid_593065
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
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_593073 = formData.getOrDefault("Entries")
  valid_593073 = validateParameter(valid_593073, JArray, required = true, default = nil)
  if valid_593073 != nil:
    section.add "Entries", valid_593073
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_PostChangeMessageVisibilityBatch_593059;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_PostChangeMessageVisibilityBatch_593059;
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
  var path_593076 = newJObject()
  var query_593077 = newJObject()
  var formData_593078 = newJObject()
  add(path_593076, "AccountNumber", newJInt(AccountNumber))
  add(path_593076, "QueueName", newJString(QueueName))
  if Entries != nil:
    formData_593078.add "Entries", Entries
  add(query_593077, "Action", newJString(Action))
  add(query_593077, "Version", newJString(Version))
  result = call_593075.call(path_593076, query_593077, nil, formData_593078, nil)

var postChangeMessageVisibilityBatch* = Call_PostChangeMessageVisibilityBatch_593059(
    name: "postChangeMessageVisibilityBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_PostChangeMessageVisibilityBatch_593060, base: "/",
    url: url_PostChangeMessageVisibilityBatch_593061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeMessageVisibilityBatch_593040 = ref object of OpenApiRestCall_592348
proc url_GetChangeMessageVisibilityBatch_593042(protocol: Scheme; host: string;
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

proc validate_GetChangeMessageVisibilityBatch_593041(path: JsonNode;
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
  var valid_593043 = path.getOrDefault("AccountNumber")
  valid_593043 = validateParameter(valid_593043, JInt, required = true, default = nil)
  if valid_593043 != nil:
    section.add "AccountNumber", valid_593043
  var valid_593044 = path.getOrDefault("QueueName")
  valid_593044 = validateParameter(valid_593044, JString, required = true,
                                 default = nil)
  if valid_593044 != nil:
    section.add "QueueName", valid_593044
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles of the messages for which the visibility timeout must be changed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_593045 = query.getOrDefault("Entries")
  valid_593045 = validateParameter(valid_593045, JArray, required = true, default = nil)
  if valid_593045 != nil:
    section.add "Entries", valid_593045
  var valid_593046 = query.getOrDefault("Action")
  valid_593046 = validateParameter(valid_593046, JString, required = true, default = newJString(
      "ChangeMessageVisibilityBatch"))
  if valid_593046 != nil:
    section.add "Action", valid_593046
  var valid_593047 = query.getOrDefault("Version")
  valid_593047 = validateParameter(valid_593047, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593047 != nil:
    section.add "Version", valid_593047
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
  var valid_593048 = header.getOrDefault("X-Amz-Signature")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Signature", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Content-Sha256", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Date")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Date", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Credential")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Credential", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Security-Token")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Security-Token", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Algorithm")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Algorithm", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-SignedHeaders", valid_593054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593055: Call_GetChangeMessageVisibilityBatch_593040;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Changes the visibility timeout of multiple messages. This is a batch version of <code> <a>ChangeMessageVisibility</a>.</code> The result of the action on each message is reported individually in the response. You can send up to 10 <code> <a>ChangeMessageVisibility</a> </code> requests with each <code>ChangeMessageVisibilityBatch</code> action.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593055.validator(path, query, header, formData, body)
  let scheme = call_593055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593055.url(scheme.get, call_593055.host, call_593055.base,
                         call_593055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593055, url, valid)

proc call*(call_593056: Call_GetChangeMessageVisibilityBatch_593040;
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
  var path_593057 = newJObject()
  var query_593058 = newJObject()
  if Entries != nil:
    query_593058.add "Entries", Entries
  add(path_593057, "AccountNumber", newJInt(AccountNumber))
  add(path_593057, "QueueName", newJString(QueueName))
  add(query_593058, "Action", newJString(Action))
  add(query_593058, "Version", newJString(Version))
  result = call_593056.call(path_593057, query_593058, nil, nil, nil)

var getChangeMessageVisibilityBatch* = Call_GetChangeMessageVisibilityBatch_593040(
    name: "getChangeMessageVisibilityBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ChangeMessageVisibilityBatch",
    validator: validate_GetChangeMessageVisibilityBatch_593041, base: "/",
    url: url_GetChangeMessageVisibilityBatch_593042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateQueue_593107 = ref object of OpenApiRestCall_592348
proc url_PostCreateQueue_593109(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateQueue_593108(path: JsonNode; query: JsonNode;
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
  var valid_593110 = query.getOrDefault("Action")
  valid_593110 = validateParameter(valid_593110, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_593110 != nil:
    section.add "Action", valid_593110
  var valid_593111 = query.getOrDefault("Version")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593111 != nil:
    section.add "Version", valid_593111
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
  var valid_593112 = header.getOrDefault("X-Amz-Signature")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Signature", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Content-Sha256", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Date")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Date", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Credential")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Credential", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Security-Token")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Security-Token", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Algorithm")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Algorithm", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-SignedHeaders", valid_593118
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
  var valid_593119 = formData.getOrDefault("Tag.1.value")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "Tag.1.value", valid_593119
  var valid_593120 = formData.getOrDefault("Tag.2.key")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "Tag.2.key", valid_593120
  var valid_593121 = formData.getOrDefault("Attribute.2.key")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "Attribute.2.key", valid_593121
  var valid_593122 = formData.getOrDefault("Attribute.2.value")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "Attribute.2.value", valid_593122
  var valid_593123 = formData.getOrDefault("Tag.1.key")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "Tag.1.key", valid_593123
  var valid_593124 = formData.getOrDefault("Tag.2.value")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "Tag.2.value", valid_593124
  var valid_593125 = formData.getOrDefault("Attribute.0.value")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "Attribute.0.value", valid_593125
  var valid_593126 = formData.getOrDefault("Tag.0.value")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "Tag.0.value", valid_593126
  var valid_593127 = formData.getOrDefault("Attribute.1.key")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "Attribute.1.key", valid_593127
  var valid_593128 = formData.getOrDefault("Tag.0.key")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "Tag.0.key", valid_593128
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_593129 = formData.getOrDefault("QueueName")
  valid_593129 = validateParameter(valid_593129, JString, required = true,
                                 default = nil)
  if valid_593129 != nil:
    section.add "QueueName", valid_593129
  var valid_593130 = formData.getOrDefault("Attribute.1.value")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "Attribute.1.value", valid_593130
  var valid_593131 = formData.getOrDefault("Attribute.0.key")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "Attribute.0.key", valid_593131
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593132: Call_PostCreateQueue_593107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593132.validator(path, query, header, formData, body)
  let scheme = call_593132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593132.url(scheme.get, call_593132.host, call_593132.base,
                         call_593132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593132, url, valid)

proc call*(call_593133: Call_PostCreateQueue_593107; QueueName: string;
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
  var query_593134 = newJObject()
  var formData_593135 = newJObject()
  add(formData_593135, "Tag.1.value", newJString(Tag1Value))
  add(formData_593135, "Tag.2.key", newJString(Tag2Key))
  add(formData_593135, "Attribute.2.key", newJString(Attribute2Key))
  add(formData_593135, "Attribute.2.value", newJString(Attribute2Value))
  add(formData_593135, "Tag.1.key", newJString(Tag1Key))
  add(formData_593135, "Tag.2.value", newJString(Tag2Value))
  add(formData_593135, "Attribute.0.value", newJString(Attribute0Value))
  add(formData_593135, "Tag.0.value", newJString(Tag0Value))
  add(formData_593135, "Attribute.1.key", newJString(Attribute1Key))
  add(formData_593135, "Tag.0.key", newJString(Tag0Key))
  add(formData_593135, "QueueName", newJString(QueueName))
  add(formData_593135, "Attribute.1.value", newJString(Attribute1Value))
  add(query_593134, "Action", newJString(Action))
  add(query_593134, "Version", newJString(Version))
  add(formData_593135, "Attribute.0.key", newJString(Attribute0Key))
  result = call_593133.call(nil, query_593134, nil, formData_593135, nil)

var postCreateQueue* = Call_PostCreateQueue_593107(name: "postCreateQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_PostCreateQueue_593108,
    base: "/", url: url_PostCreateQueue_593109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateQueue_593079 = ref object of OpenApiRestCall_592348
proc url_GetCreateQueue_593081(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateQueue_593080(path: JsonNode; query: JsonNode;
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
  var valid_593082 = query.getOrDefault("Attribute.2.key")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "Attribute.2.key", valid_593082
  assert query != nil,
        "query argument is necessary due to required `QueueName` field"
  var valid_593083 = query.getOrDefault("QueueName")
  valid_593083 = validateParameter(valid_593083, JString, required = true,
                                 default = nil)
  if valid_593083 != nil:
    section.add "QueueName", valid_593083
  var valid_593084 = query.getOrDefault("Attribute.1.key")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "Attribute.1.key", valid_593084
  var valid_593085 = query.getOrDefault("Attribute.2.value")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "Attribute.2.value", valid_593085
  var valid_593086 = query.getOrDefault("Attribute.1.value")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "Attribute.1.value", valid_593086
  var valid_593087 = query.getOrDefault("Tag.0.value")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "Tag.0.value", valid_593087
  var valid_593088 = query.getOrDefault("Tag.1.key")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "Tag.1.key", valid_593088
  var valid_593089 = query.getOrDefault("Tag.1.value")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "Tag.1.value", valid_593089
  var valid_593090 = query.getOrDefault("Tag.0.key")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "Tag.0.key", valid_593090
  var valid_593091 = query.getOrDefault("Action")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = newJString("CreateQueue"))
  if valid_593091 != nil:
    section.add "Action", valid_593091
  var valid_593092 = query.getOrDefault("Tag.2.key")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "Tag.2.key", valid_593092
  var valid_593093 = query.getOrDefault("Attribute.0.key")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "Attribute.0.key", valid_593093
  var valid_593094 = query.getOrDefault("Version")
  valid_593094 = validateParameter(valid_593094, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593094 != nil:
    section.add "Version", valid_593094
  var valid_593095 = query.getOrDefault("Tag.2.value")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "Tag.2.value", valid_593095
  var valid_593096 = query.getOrDefault("Attribute.0.value")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "Attribute.0.value", valid_593096
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
  var valid_593097 = header.getOrDefault("X-Amz-Signature")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Signature", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Content-Sha256", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Date")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Date", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Credential")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Credential", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Security-Token")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Security-Token", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Algorithm")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Algorithm", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-SignedHeaders", valid_593103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593104: Call_GetCreateQueue_593079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new standard or FIFO queue. You can pass one or more attributes in the request. Keep the following caveats in mind:</p> <ul> <li> <p>If you don't specify the <code>FifoQueue</code> attribute, Amazon SQS creates a standard queue.</p> <note> <p>You can't change the queue type after you create it and you can't convert an existing standard queue into a FIFO queue. You must either create a new FIFO queue for your application or delete your existing standard queue and recreate it as a FIFO queue. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html#FIFO-queues-moving">Moving From a Standard Queue to a FIFO Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> </note> </li> <li> <p>If you don't provide a value for an attribute, the queue is created with the default value for the attribute.</p> </li> <li> <p>If you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> </li> </ul> <p>To successfully create a new queue, you must provide a queue name that adheres to the <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/limits-queues.html">limits related to queues</a> and is unique within the scope of your queues.</p> <p>To get the queue URL, use the <code> <a>GetQueueUrl</a> </code> action. <code> <a>GetQueueUrl</a> </code> requires only the <code>QueueName</code> parameter. be aware of existing queue names:</p> <ul> <li> <p>If you provide the name of an existing queue along with the exact names and values of all the queue's attributes, <code>CreateQueue</code> returns the queue URL for the existing queue.</p> </li> <li> <p>If the queue name, attribute names, or attribute values don't match an existing queue, <code>CreateQueue</code> returns an error.</p> </li> </ul> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593104.validator(path, query, header, formData, body)
  let scheme = call_593104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593104.url(scheme.get, call_593104.host, call_593104.base,
                         call_593104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593104, url, valid)

proc call*(call_593105: Call_GetCreateQueue_593079; QueueName: string;
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
  var query_593106 = newJObject()
  add(query_593106, "Attribute.2.key", newJString(Attribute2Key))
  add(query_593106, "QueueName", newJString(QueueName))
  add(query_593106, "Attribute.1.key", newJString(Attribute1Key))
  add(query_593106, "Attribute.2.value", newJString(Attribute2Value))
  add(query_593106, "Attribute.1.value", newJString(Attribute1Value))
  add(query_593106, "Tag.0.value", newJString(Tag0Value))
  add(query_593106, "Tag.1.key", newJString(Tag1Key))
  add(query_593106, "Tag.1.value", newJString(Tag1Value))
  add(query_593106, "Tag.0.key", newJString(Tag0Key))
  add(query_593106, "Action", newJString(Action))
  add(query_593106, "Tag.2.key", newJString(Tag2Key))
  add(query_593106, "Attribute.0.key", newJString(Attribute0Key))
  add(query_593106, "Version", newJString(Version))
  add(query_593106, "Tag.2.value", newJString(Tag2Value))
  add(query_593106, "Attribute.0.value", newJString(Attribute0Value))
  result = call_593105.call(nil, query_593106, nil, nil, nil)

var getCreateQueue* = Call_GetCreateQueue_593079(name: "getCreateQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=CreateQueue", validator: validate_GetCreateQueue_593080,
    base: "/", url: url_GetCreateQueue_593081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessage_593155 = ref object of OpenApiRestCall_592348
proc url_PostDeleteMessage_593157(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteMessage_593156(path: JsonNode; query: JsonNode;
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
  var valid_593158 = path.getOrDefault("AccountNumber")
  valid_593158 = validateParameter(valid_593158, JInt, required = true, default = nil)
  if valid_593158 != nil:
    section.add "AccountNumber", valid_593158
  var valid_593159 = path.getOrDefault("QueueName")
  valid_593159 = validateParameter(valid_593159, JString, required = true,
                                 default = nil)
  if valid_593159 != nil:
    section.add "QueueName", valid_593159
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593160 = query.getOrDefault("Action")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_593160 != nil:
    section.add "Action", valid_593160
  var valid_593161 = query.getOrDefault("Version")
  valid_593161 = validateParameter(valid_593161, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593161 != nil:
    section.add "Version", valid_593161
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
  var valid_593162 = header.getOrDefault("X-Amz-Signature")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Signature", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Content-Sha256", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Date")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Date", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Credential")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Credential", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Security-Token")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Security-Token", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Algorithm")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Algorithm", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-SignedHeaders", valid_593168
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ReceiptHandle` field"
  var valid_593169 = formData.getOrDefault("ReceiptHandle")
  valid_593169 = validateParameter(valid_593169, JString, required = true,
                                 default = nil)
  if valid_593169 != nil:
    section.add "ReceiptHandle", valid_593169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593170: Call_PostDeleteMessage_593155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_593170.validator(path, query, header, formData, body)
  let scheme = call_593170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593170.url(scheme.get, call_593170.host, call_593170.base,
                         call_593170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593170, url, valid)

proc call*(call_593171: Call_PostDeleteMessage_593155; ReceiptHandle: string;
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
  var path_593172 = newJObject()
  var query_593173 = newJObject()
  var formData_593174 = newJObject()
  add(formData_593174, "ReceiptHandle", newJString(ReceiptHandle))
  add(path_593172, "AccountNumber", newJInt(AccountNumber))
  add(path_593172, "QueueName", newJString(QueueName))
  add(query_593173, "Action", newJString(Action))
  add(query_593173, "Version", newJString(Version))
  result = call_593171.call(path_593172, query_593173, nil, formData_593174, nil)

var postDeleteMessage* = Call_PostDeleteMessage_593155(name: "postDeleteMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_PostDeleteMessage_593156, base: "/",
    url: url_PostDeleteMessage_593157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessage_593136 = ref object of OpenApiRestCall_592348
proc url_GetDeleteMessage_593138(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteMessage_593137(path: JsonNode; query: JsonNode;
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
  var valid_593139 = path.getOrDefault("AccountNumber")
  valid_593139 = validateParameter(valid_593139, JInt, required = true, default = nil)
  if valid_593139 != nil:
    section.add "AccountNumber", valid_593139
  var valid_593140 = path.getOrDefault("QueueName")
  valid_593140 = validateParameter(valid_593140, JString, required = true,
                                 default = nil)
  if valid_593140 != nil:
    section.add "QueueName", valid_593140
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ReceiptHandle: JString (required)
  ##                : The receipt handle associated with the message to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593141 = query.getOrDefault("Action")
  valid_593141 = validateParameter(valid_593141, JString, required = true,
                                 default = newJString("DeleteMessage"))
  if valid_593141 != nil:
    section.add "Action", valid_593141
  var valid_593142 = query.getOrDefault("ReceiptHandle")
  valid_593142 = validateParameter(valid_593142, JString, required = true,
                                 default = nil)
  if valid_593142 != nil:
    section.add "ReceiptHandle", valid_593142
  var valid_593143 = query.getOrDefault("Version")
  valid_593143 = validateParameter(valid_593143, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593143 != nil:
    section.add "Version", valid_593143
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
  var valid_593144 = header.getOrDefault("X-Amz-Signature")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Signature", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Content-Sha256", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Date")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Date", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Credential")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Credential", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Security-Token")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Security-Token", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-Algorithm")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Algorithm", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-SignedHeaders", valid_593150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593151: Call_GetDeleteMessage_593136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified message from the specified queue. To select the message to delete, use the <code>ReceiptHandle</code> of the message (<i>not</i> the <code>MessageId</code> which you receive when you send the message). Amazon SQS can delete a message from a queue even if a visibility timeout setting causes the message to be locked by another consumer. Amazon SQS automatically deletes messages left in a queue longer than the retention period configured for the queue. </p> <note> <p>The <code>ReceiptHandle</code> is associated with a <i>specific instance</i> of receiving a message. If you receive a message more than once, the <code>ReceiptHandle</code> is different each time you receive a message. When you use the <code>DeleteMessage</code> action, you must provide the most recently received <code>ReceiptHandle</code> for the message (otherwise, the request succeeds, but the message might not be deleted).</p> <p>For standard queues, it is possible to receive a message even after you delete it. This might happen on rare occasions if one of the servers which stores a copy of the message is unavailable when you send the request to delete the message. The copy remains on the server and might be returned to you during a subsequent receive request. You should ensure that your application is idempotent, so that receiving a message more than once does not cause issues.</p> </note>
  ## 
  let valid = call_593151.validator(path, query, header, formData, body)
  let scheme = call_593151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593151.url(scheme.get, call_593151.host, call_593151.base,
                         call_593151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593151, url, valid)

proc call*(call_593152: Call_GetDeleteMessage_593136; AccountNumber: int;
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
  var path_593153 = newJObject()
  var query_593154 = newJObject()
  add(path_593153, "AccountNumber", newJInt(AccountNumber))
  add(path_593153, "QueueName", newJString(QueueName))
  add(query_593154, "Action", newJString(Action))
  add(query_593154, "ReceiptHandle", newJString(ReceiptHandle))
  add(query_593154, "Version", newJString(Version))
  result = call_593152.call(path_593153, query_593154, nil, nil, nil)

var getDeleteMessage* = Call_GetDeleteMessage_593136(name: "getDeleteMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessage",
    validator: validate_GetDeleteMessage_593137, base: "/",
    url: url_GetDeleteMessage_593138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteMessageBatch_593194 = ref object of OpenApiRestCall_592348
proc url_PostDeleteMessageBatch_593196(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteMessageBatch_593195(path: JsonNode; query: JsonNode;
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
  var valid_593197 = path.getOrDefault("AccountNumber")
  valid_593197 = validateParameter(valid_593197, JInt, required = true, default = nil)
  if valid_593197 != nil:
    section.add "AccountNumber", valid_593197
  var valid_593198 = path.getOrDefault("QueueName")
  valid_593198 = validateParameter(valid_593198, JString, required = true,
                                 default = nil)
  if valid_593198 != nil:
    section.add "QueueName", valid_593198
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593199 = query.getOrDefault("Action")
  valid_593199 = validateParameter(valid_593199, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_593199 != nil:
    section.add "Action", valid_593199
  var valid_593200 = query.getOrDefault("Version")
  valid_593200 = validateParameter(valid_593200, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593200 != nil:
    section.add "Version", valid_593200
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
  var valid_593201 = header.getOrDefault("X-Amz-Signature")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Signature", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Content-Sha256", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Date")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Date", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Credential")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Credential", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Security-Token")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Security-Token", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Algorithm")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Algorithm", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-SignedHeaders", valid_593207
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_593208 = formData.getOrDefault("Entries")
  valid_593208 = validateParameter(valid_593208, JArray, required = true, default = nil)
  if valid_593208 != nil:
    section.add "Entries", valid_593208
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593209: Call_PostDeleteMessageBatch_593194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593209.validator(path, query, header, formData, body)
  let scheme = call_593209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593209.url(scheme.get, call_593209.host, call_593209.base,
                         call_593209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593209, url, valid)

proc call*(call_593210: Call_PostDeleteMessageBatch_593194; AccountNumber: int;
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
  var path_593211 = newJObject()
  var query_593212 = newJObject()
  var formData_593213 = newJObject()
  add(path_593211, "AccountNumber", newJInt(AccountNumber))
  add(path_593211, "QueueName", newJString(QueueName))
  if Entries != nil:
    formData_593213.add "Entries", Entries
  add(query_593212, "Action", newJString(Action))
  add(query_593212, "Version", newJString(Version))
  result = call_593210.call(path_593211, query_593212, nil, formData_593213, nil)

var postDeleteMessageBatch* = Call_PostDeleteMessageBatch_593194(
    name: "postDeleteMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_PostDeleteMessageBatch_593195, base: "/",
    url: url_PostDeleteMessageBatch_593196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteMessageBatch_593175 = ref object of OpenApiRestCall_592348
proc url_GetDeleteMessageBatch_593177(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteMessageBatch_593176(path: JsonNode; query: JsonNode;
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
  var valid_593178 = path.getOrDefault("AccountNumber")
  valid_593178 = validateParameter(valid_593178, JInt, required = true, default = nil)
  if valid_593178 != nil:
    section.add "AccountNumber", valid_593178
  var valid_593179 = path.getOrDefault("QueueName")
  valid_593179 = validateParameter(valid_593179, JString, required = true,
                                 default = nil)
  if valid_593179 != nil:
    section.add "QueueName", valid_593179
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of receipt handles for the messages to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_593180 = query.getOrDefault("Entries")
  valid_593180 = validateParameter(valid_593180, JArray, required = true, default = nil)
  if valid_593180 != nil:
    section.add "Entries", valid_593180
  var valid_593181 = query.getOrDefault("Action")
  valid_593181 = validateParameter(valid_593181, JString, required = true,
                                 default = newJString("DeleteMessageBatch"))
  if valid_593181 != nil:
    section.add "Action", valid_593181
  var valid_593182 = query.getOrDefault("Version")
  valid_593182 = validateParameter(valid_593182, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593182 != nil:
    section.add "Version", valid_593182
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
  var valid_593183 = header.getOrDefault("X-Amz-Signature")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Signature", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Content-Sha256", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Date")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Date", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Credential")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Credential", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Security-Token")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Security-Token", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Algorithm")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Algorithm", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-SignedHeaders", valid_593189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593190: Call_GetDeleteMessageBatch_593175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes up to ten messages from the specified queue. This is a batch version of <code> <a>DeleteMessage</a>.</code> The result of the action on each message is reported individually in the response.</p> <important> <p>Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> </important> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593190.validator(path, query, header, formData, body)
  let scheme = call_593190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593190.url(scheme.get, call_593190.host, call_593190.base,
                         call_593190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593190, url, valid)

proc call*(call_593191: Call_GetDeleteMessageBatch_593175; Entries: JsonNode;
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
  var path_593192 = newJObject()
  var query_593193 = newJObject()
  if Entries != nil:
    query_593193.add "Entries", Entries
  add(path_593192, "AccountNumber", newJInt(AccountNumber))
  add(path_593192, "QueueName", newJString(QueueName))
  add(query_593193, "Action", newJString(Action))
  add(query_593193, "Version", newJString(Version))
  result = call_593191.call(path_593192, query_593193, nil, nil, nil)

var getDeleteMessageBatch* = Call_GetDeleteMessageBatch_593175(
    name: "getDeleteMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteMessageBatch",
    validator: validate_GetDeleteMessageBatch_593176, base: "/",
    url: url_GetDeleteMessageBatch_593177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteQueue_593232 = ref object of OpenApiRestCall_592348
proc url_PostDeleteQueue_593234(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteQueue_593233(path: JsonNode; query: JsonNode;
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
  var valid_593235 = path.getOrDefault("AccountNumber")
  valid_593235 = validateParameter(valid_593235, JInt, required = true, default = nil)
  if valid_593235 != nil:
    section.add "AccountNumber", valid_593235
  var valid_593236 = path.getOrDefault("QueueName")
  valid_593236 = validateParameter(valid_593236, JString, required = true,
                                 default = nil)
  if valid_593236 != nil:
    section.add "QueueName", valid_593236
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593237 = query.getOrDefault("Action")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_593237 != nil:
    section.add "Action", valid_593237
  var valid_593238 = query.getOrDefault("Version")
  valid_593238 = validateParameter(valid_593238, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593238 != nil:
    section.add "Version", valid_593238
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
  var valid_593239 = header.getOrDefault("X-Amz-Signature")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Signature", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Content-Sha256", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Date")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Date", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Credential")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Credential", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Security-Token")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Security-Token", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Algorithm")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Algorithm", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-SignedHeaders", valid_593245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593246: Call_PostDeleteQueue_593232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593246.validator(path, query, header, formData, body)
  let scheme = call_593246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593246.url(scheme.get, call_593246.host, call_593246.base,
                         call_593246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593246, url, valid)

proc call*(call_593247: Call_PostDeleteQueue_593232; AccountNumber: int;
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
  var path_593248 = newJObject()
  var query_593249 = newJObject()
  add(path_593248, "AccountNumber", newJInt(AccountNumber))
  add(path_593248, "QueueName", newJString(QueueName))
  add(query_593249, "Action", newJString(Action))
  add(query_593249, "Version", newJString(Version))
  result = call_593247.call(path_593248, query_593249, nil, nil, nil)

var postDeleteQueue* = Call_PostDeleteQueue_593232(name: "postDeleteQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_PostDeleteQueue_593233, base: "/", url: url_PostDeleteQueue_593234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteQueue_593214 = ref object of OpenApiRestCall_592348
proc url_GetDeleteQueue_593216(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteQueue_593215(path: JsonNode; query: JsonNode;
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
  var valid_593217 = path.getOrDefault("AccountNumber")
  valid_593217 = validateParameter(valid_593217, JInt, required = true, default = nil)
  if valid_593217 != nil:
    section.add "AccountNumber", valid_593217
  var valid_593218 = path.getOrDefault("QueueName")
  valid_593218 = validateParameter(valid_593218, JString, required = true,
                                 default = nil)
  if valid_593218 != nil:
    section.add "QueueName", valid_593218
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593219 = query.getOrDefault("Action")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = newJString("DeleteQueue"))
  if valid_593219 != nil:
    section.add "Action", valid_593219
  var valid_593220 = query.getOrDefault("Version")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593220 != nil:
    section.add "Version", valid_593220
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
  var valid_593221 = header.getOrDefault("X-Amz-Signature")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Signature", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Content-Sha256", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Date")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Date", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Credential")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Credential", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Security-Token")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Security-Token", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Algorithm")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Algorithm", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-SignedHeaders", valid_593227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593228: Call_GetDeleteQueue_593214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the queue specified by the <code>QueueUrl</code>, regardless of the queue's contents. If the specified queue doesn't exist, Amazon SQS returns a successful response.</p> <important> <p>Be careful with the <code>DeleteQueue</code> action: When you delete a queue, any messages in the queue are no longer available. </p> </important> <p>When you delete a queue, the deletion process takes up to 60 seconds. Requests you send involving that queue during the 60 seconds might succeed. For example, a <code> <a>SendMessage</a> </code> request might succeed, but after 60 seconds the queue and the message you sent no longer exist.</p> <p>When you delete a queue, you must wait at least 60 seconds before creating a queue with the same name.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593228.validator(path, query, header, formData, body)
  let scheme = call_593228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593228.url(scheme.get, call_593228.host, call_593228.base,
                         call_593228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593228, url, valid)

proc call*(call_593229: Call_GetDeleteQueue_593214; AccountNumber: int;
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
  var path_593230 = newJObject()
  var query_593231 = newJObject()
  add(path_593230, "AccountNumber", newJInt(AccountNumber))
  add(path_593230, "QueueName", newJString(QueueName))
  add(query_593231, "Action", newJString(Action))
  add(query_593231, "Version", newJString(Version))
  result = call_593229.call(path_593230, query_593231, nil, nil, nil)

var getDeleteQueue* = Call_GetDeleteQueue_593214(name: "getDeleteQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=DeleteQueue",
    validator: validate_GetDeleteQueue_593215, base: "/", url: url_GetDeleteQueue_593216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueAttributes_593269 = ref object of OpenApiRestCall_592348
proc url_PostGetQueueAttributes_593271(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetQueueAttributes_593270(path: JsonNode; query: JsonNode;
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
  var valid_593272 = path.getOrDefault("AccountNumber")
  valid_593272 = validateParameter(valid_593272, JInt, required = true, default = nil)
  if valid_593272 != nil:
    section.add "AccountNumber", valid_593272
  var valid_593273 = path.getOrDefault("QueueName")
  valid_593273 = validateParameter(valid_593273, JString, required = true,
                                 default = nil)
  if valid_593273 != nil:
    section.add "QueueName", valid_593273
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593274 = query.getOrDefault("Action")
  valid_593274 = validateParameter(valid_593274, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_593274 != nil:
    section.add "Action", valid_593274
  var valid_593275 = query.getOrDefault("Version")
  valid_593275 = validateParameter(valid_593275, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593275 != nil:
    section.add "Version", valid_593275
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
  var valid_593276 = header.getOrDefault("X-Amz-Signature")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Signature", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Content-Sha256", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Date")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Date", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Credential")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Credential", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Security-Token")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Security-Token", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Algorithm")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Algorithm", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-SignedHeaders", valid_593282
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
  var valid_593283 = formData.getOrDefault("AttributeNames")
  valid_593283 = validateParameter(valid_593283, JArray, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "AttributeNames", valid_593283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593284: Call_PostGetQueueAttributes_593269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593284.validator(path, query, header, formData, body)
  let scheme = call_593284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593284.url(scheme.get, call_593284.host, call_593284.base,
                         call_593284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593284, url, valid)

proc call*(call_593285: Call_PostGetQueueAttributes_593269; AccountNumber: int;
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
  var path_593286 = newJObject()
  var query_593287 = newJObject()
  var formData_593288 = newJObject()
  add(path_593286, "AccountNumber", newJInt(AccountNumber))
  add(path_593286, "QueueName", newJString(QueueName))
  if AttributeNames != nil:
    formData_593288.add "AttributeNames", AttributeNames
  add(query_593287, "Action", newJString(Action))
  add(query_593287, "Version", newJString(Version))
  result = call_593285.call(path_593286, query_593287, nil, formData_593288, nil)

var postGetQueueAttributes* = Call_PostGetQueueAttributes_593269(
    name: "postGetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_PostGetQueueAttributes_593270, base: "/",
    url: url_PostGetQueueAttributes_593271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueAttributes_593250 = ref object of OpenApiRestCall_592348
proc url_GetGetQueueAttributes_593252(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetQueueAttributes_593251(path: JsonNode; query: JsonNode;
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
  var valid_593253 = path.getOrDefault("AccountNumber")
  valid_593253 = validateParameter(valid_593253, JInt, required = true, default = nil)
  if valid_593253 != nil:
    section.add "AccountNumber", valid_593253
  var valid_593254 = path.getOrDefault("QueueName")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = nil)
  if valid_593254 != nil:
    section.add "QueueName", valid_593254
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
  var valid_593255 = query.getOrDefault("AttributeNames")
  valid_593255 = validateParameter(valid_593255, JArray, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "AttributeNames", valid_593255
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593256 = query.getOrDefault("Action")
  valid_593256 = validateParameter(valid_593256, JString, required = true,
                                 default = newJString("GetQueueAttributes"))
  if valid_593256 != nil:
    section.add "Action", valid_593256
  var valid_593257 = query.getOrDefault("Version")
  valid_593257 = validateParameter(valid_593257, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593257 != nil:
    section.add "Version", valid_593257
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
  var valid_593258 = header.getOrDefault("X-Amz-Signature")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Signature", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Content-Sha256", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Date")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Date", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Credential")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Credential", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Security-Token")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Security-Token", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Algorithm")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Algorithm", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-SignedHeaders", valid_593264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593265: Call_GetGetQueueAttributes_593250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets attributes for the specified queue.</p> <note> <p>To determine whether a queue is <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html">FIFO</a>, you can check whether <code>QueueName</code> ends with the <code>.fifo</code> suffix.</p> </note> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593265.validator(path, query, header, formData, body)
  let scheme = call_593265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593265.url(scheme.get, call_593265.host, call_593265.base,
                         call_593265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593265, url, valid)

proc call*(call_593266: Call_GetGetQueueAttributes_593250; AccountNumber: int;
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
  var path_593267 = newJObject()
  var query_593268 = newJObject()
  add(path_593267, "AccountNumber", newJInt(AccountNumber))
  add(path_593267, "QueueName", newJString(QueueName))
  if AttributeNames != nil:
    query_593268.add "AttributeNames", AttributeNames
  add(query_593268, "Action", newJString(Action))
  add(query_593268, "Version", newJString(Version))
  result = call_593266.call(path_593267, query_593268, nil, nil, nil)

var getGetQueueAttributes* = Call_GetGetQueueAttributes_593250(
    name: "getGetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=GetQueueAttributes",
    validator: validate_GetGetQueueAttributes_593251, base: "/",
    url: url_GetGetQueueAttributes_593252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetQueueUrl_593306 = ref object of OpenApiRestCall_592348
proc url_PostGetQueueUrl_593308(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetQueueUrl_593307(path: JsonNode; query: JsonNode;
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
  var valid_593309 = query.getOrDefault("Action")
  valid_593309 = validateParameter(valid_593309, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_593309 != nil:
    section.add "Action", valid_593309
  var valid_593310 = query.getOrDefault("Version")
  valid_593310 = validateParameter(valid_593310, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593310 != nil:
    section.add "Version", valid_593310
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
  var valid_593311 = header.getOrDefault("X-Amz-Signature")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Signature", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Content-Sha256", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Date")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Date", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Credential")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Credential", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Security-Token")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Security-Token", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Algorithm")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Algorithm", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-SignedHeaders", valid_593317
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueName: JString (required)
  ##            : <p>The name of the queue whose URL must be fetched. Maximum 80 characters. Valid values: alphanumeric characters, hyphens (<code>-</code>), and underscores (<code>_</code>).</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   QueueOwnerAWSAccountId: JString
  ##                         : The AWS account ID of the account that created the queue.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `QueueName` field"
  var valid_593318 = formData.getOrDefault("QueueName")
  valid_593318 = validateParameter(valid_593318, JString, required = true,
                                 default = nil)
  if valid_593318 != nil:
    section.add "QueueName", valid_593318
  var valid_593319 = formData.getOrDefault("QueueOwnerAWSAccountId")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "QueueOwnerAWSAccountId", valid_593319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593320: Call_PostGetQueueUrl_593306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_593320.validator(path, query, header, formData, body)
  let scheme = call_593320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593320.url(scheme.get, call_593320.host, call_593320.base,
                         call_593320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593320, url, valid)

proc call*(call_593321: Call_PostGetQueueUrl_593306; QueueName: string;
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
  var query_593322 = newJObject()
  var formData_593323 = newJObject()
  add(formData_593323, "QueueName", newJString(QueueName))
  add(formData_593323, "QueueOwnerAWSAccountId",
      newJString(QueueOwnerAWSAccountId))
  add(query_593322, "Action", newJString(Action))
  add(query_593322, "Version", newJString(Version))
  result = call_593321.call(nil, query_593322, nil, formData_593323, nil)

var postGetQueueUrl* = Call_PostGetQueueUrl_593306(name: "postGetQueueUrl",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_PostGetQueueUrl_593307,
    base: "/", url: url_PostGetQueueUrl_593308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetQueueUrl_593289 = ref object of OpenApiRestCall_592348
proc url_GetGetQueueUrl_593291(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetQueueUrl_593290(path: JsonNode; query: JsonNode;
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
  var valid_593292 = query.getOrDefault("QueueName")
  valid_593292 = validateParameter(valid_593292, JString, required = true,
                                 default = nil)
  if valid_593292 != nil:
    section.add "QueueName", valid_593292
  var valid_593293 = query.getOrDefault("QueueOwnerAWSAccountId")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "QueueOwnerAWSAccountId", valid_593293
  var valid_593294 = query.getOrDefault("Action")
  valid_593294 = validateParameter(valid_593294, JString, required = true,
                                 default = newJString("GetQueueUrl"))
  if valid_593294 != nil:
    section.add "Action", valid_593294
  var valid_593295 = query.getOrDefault("Version")
  valid_593295 = validateParameter(valid_593295, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593295 != nil:
    section.add "Version", valid_593295
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
  var valid_593296 = header.getOrDefault("X-Amz-Signature")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Signature", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Content-Sha256", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Date")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Date", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Credential")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Credential", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Security-Token")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Security-Token", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Algorithm")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Algorithm", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-SignedHeaders", valid_593302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593303: Call_GetGetQueueUrl_593289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the URL of an existing Amazon SQS queue.</p> <p>To access a queue that belongs to another AWS account, use the <code>QueueOwnerAWSAccountId</code> parameter to specify the account ID of the queue's owner. The queue's owner must grant you permission to access the queue. For more information about shared queue access, see <code> <a>AddPermission</a> </code> or see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-writing-an-sqs-policy.html#write-messages-to-shared-queue">Allow Developers to Write Messages to a Shared Queue</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p>
  ## 
  let valid = call_593303.validator(path, query, header, formData, body)
  let scheme = call_593303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593303.url(scheme.get, call_593303.host, call_593303.base,
                         call_593303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593303, url, valid)

proc call*(call_593304: Call_GetGetQueueUrl_593289; QueueName: string;
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
  var query_593305 = newJObject()
  add(query_593305, "QueueName", newJString(QueueName))
  add(query_593305, "QueueOwnerAWSAccountId", newJString(QueueOwnerAWSAccountId))
  add(query_593305, "Action", newJString(Action))
  add(query_593305, "Version", newJString(Version))
  result = call_593304.call(nil, query_593305, nil, nil, nil)

var getGetQueueUrl* = Call_GetGetQueueUrl_593289(name: "getGetQueueUrl",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=GetQueueUrl", validator: validate_GetGetQueueUrl_593290,
    base: "/", url: url_GetGetQueueUrl_593291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDeadLetterSourceQueues_593342 = ref object of OpenApiRestCall_592348
proc url_PostListDeadLetterSourceQueues_593344(protocol: Scheme; host: string;
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

proc validate_PostListDeadLetterSourceQueues_593343(path: JsonNode;
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
  var valid_593345 = path.getOrDefault("AccountNumber")
  valid_593345 = validateParameter(valid_593345, JInt, required = true, default = nil)
  if valid_593345 != nil:
    section.add "AccountNumber", valid_593345
  var valid_593346 = path.getOrDefault("QueueName")
  valid_593346 = validateParameter(valid_593346, JString, required = true,
                                 default = nil)
  if valid_593346 != nil:
    section.add "QueueName", valid_593346
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593347 = query.getOrDefault("Action")
  valid_593347 = validateParameter(valid_593347, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_593347 != nil:
    section.add "Action", valid_593347
  var valid_593348 = query.getOrDefault("Version")
  valid_593348 = validateParameter(valid_593348, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593348 != nil:
    section.add "Version", valid_593348
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
  var valid_593349 = header.getOrDefault("X-Amz-Signature")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Signature", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Content-Sha256", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Date")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Date", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Credential")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Credential", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Security-Token")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Security-Token", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Algorithm")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Algorithm", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-SignedHeaders", valid_593355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593356: Call_PostListDeadLetterSourceQueues_593342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_593356.validator(path, query, header, formData, body)
  let scheme = call_593356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593356.url(scheme.get, call_593356.host, call_593356.base,
                         call_593356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593356, url, valid)

proc call*(call_593357: Call_PostListDeadLetterSourceQueues_593342;
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
  var path_593358 = newJObject()
  var query_593359 = newJObject()
  add(path_593358, "AccountNumber", newJInt(AccountNumber))
  add(path_593358, "QueueName", newJString(QueueName))
  add(query_593359, "Action", newJString(Action))
  add(query_593359, "Version", newJString(Version))
  result = call_593357.call(path_593358, query_593359, nil, nil, nil)

var postListDeadLetterSourceQueues* = Call_PostListDeadLetterSourceQueues_593342(
    name: "postListDeadLetterSourceQueues", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_PostListDeadLetterSourceQueues_593343, base: "/",
    url: url_PostListDeadLetterSourceQueues_593344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDeadLetterSourceQueues_593324 = ref object of OpenApiRestCall_592348
proc url_GetListDeadLetterSourceQueues_593326(protocol: Scheme; host: string;
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

proc validate_GetListDeadLetterSourceQueues_593325(path: JsonNode; query: JsonNode;
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
  var valid_593327 = path.getOrDefault("AccountNumber")
  valid_593327 = validateParameter(valid_593327, JInt, required = true, default = nil)
  if valid_593327 != nil:
    section.add "AccountNumber", valid_593327
  var valid_593328 = path.getOrDefault("QueueName")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = nil)
  if valid_593328 != nil:
    section.add "QueueName", valid_593328
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593329 = query.getOrDefault("Action")
  valid_593329 = validateParameter(valid_593329, JString, required = true, default = newJString(
      "ListDeadLetterSourceQueues"))
  if valid_593329 != nil:
    section.add "Action", valid_593329
  var valid_593330 = query.getOrDefault("Version")
  valid_593330 = validateParameter(valid_593330, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593330 != nil:
    section.add "Version", valid_593330
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
  var valid_593331 = header.getOrDefault("X-Amz-Signature")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Signature", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Content-Sha256", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Date")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Date", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Credential")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Credential", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Security-Token")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Security-Token", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Algorithm")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Algorithm", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-SignedHeaders", valid_593337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_GetListDeadLetterSourceQueues_593324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues that have the <code>RedrivePolicy</code> queue attribute configured with a dead-letter queue.</p> <p>For more information about using dead-letter queues, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html">Using Amazon SQS Dead-Letter Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p>
  ## 
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_GetListDeadLetterSourceQueues_593324;
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
  var path_593340 = newJObject()
  var query_593341 = newJObject()
  add(path_593340, "AccountNumber", newJInt(AccountNumber))
  add(path_593340, "QueueName", newJString(QueueName))
  add(query_593341, "Action", newJString(Action))
  add(query_593341, "Version", newJString(Version))
  result = call_593339.call(path_593340, query_593341, nil, nil, nil)

var getListDeadLetterSourceQueues* = Call_GetListDeadLetterSourceQueues_593324(
    name: "getListDeadLetterSourceQueues", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListDeadLetterSourceQueues",
    validator: validate_GetListDeadLetterSourceQueues_593325, base: "/",
    url: url_GetListDeadLetterSourceQueues_593326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueueTags_593378 = ref object of OpenApiRestCall_592348
proc url_PostListQueueTags_593380(protocol: Scheme; host: string; base: string;
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

proc validate_PostListQueueTags_593379(path: JsonNode; query: JsonNode;
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
  var valid_593381 = path.getOrDefault("AccountNumber")
  valid_593381 = validateParameter(valid_593381, JInt, required = true, default = nil)
  if valid_593381 != nil:
    section.add "AccountNumber", valid_593381
  var valid_593382 = path.getOrDefault("QueueName")
  valid_593382 = validateParameter(valid_593382, JString, required = true,
                                 default = nil)
  if valid_593382 != nil:
    section.add "QueueName", valid_593382
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593383 = query.getOrDefault("Action")
  valid_593383 = validateParameter(valid_593383, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_593383 != nil:
    section.add "Action", valid_593383
  var valid_593384 = query.getOrDefault("Version")
  valid_593384 = validateParameter(valid_593384, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593384 != nil:
    section.add "Version", valid_593384
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
  var valid_593385 = header.getOrDefault("X-Amz-Signature")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Signature", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Content-Sha256", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Date")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Date", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Credential")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Credential", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Security-Token")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Security-Token", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Algorithm")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Algorithm", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-SignedHeaders", valid_593391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593392: Call_PostListQueueTags_593378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593392.validator(path, query, header, formData, body)
  let scheme = call_593392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593392.url(scheme.get, call_593392.host, call_593392.base,
                         call_593392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593392, url, valid)

proc call*(call_593393: Call_PostListQueueTags_593378; AccountNumber: int;
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
  var path_593394 = newJObject()
  var query_593395 = newJObject()
  add(path_593394, "AccountNumber", newJInt(AccountNumber))
  add(path_593394, "QueueName", newJString(QueueName))
  add(query_593395, "Action", newJString(Action))
  add(query_593395, "Version", newJString(Version))
  result = call_593393.call(path_593394, query_593395, nil, nil, nil)

var postListQueueTags* = Call_PostListQueueTags_593378(name: "postListQueueTags",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_PostListQueueTags_593379, base: "/",
    url: url_PostListQueueTags_593380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueueTags_593360 = ref object of OpenApiRestCall_592348
proc url_GetListQueueTags_593362(protocol: Scheme; host: string; base: string;
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

proc validate_GetListQueueTags_593361(path: JsonNode; query: JsonNode;
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
  var valid_593363 = path.getOrDefault("AccountNumber")
  valid_593363 = validateParameter(valid_593363, JInt, required = true, default = nil)
  if valid_593363 != nil:
    section.add "AccountNumber", valid_593363
  var valid_593364 = path.getOrDefault("QueueName")
  valid_593364 = validateParameter(valid_593364, JString, required = true,
                                 default = nil)
  if valid_593364 != nil:
    section.add "QueueName", valid_593364
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593365 = query.getOrDefault("Action")
  valid_593365 = validateParameter(valid_593365, JString, required = true,
                                 default = newJString("ListQueueTags"))
  if valid_593365 != nil:
    section.add "Action", valid_593365
  var valid_593366 = query.getOrDefault("Version")
  valid_593366 = validateParameter(valid_593366, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593366 != nil:
    section.add "Version", valid_593366
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
  var valid_593367 = header.getOrDefault("X-Amz-Signature")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Signature", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Content-Sha256", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Date")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Date", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Credential")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Credential", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Security-Token")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Security-Token", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Algorithm")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Algorithm", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-SignedHeaders", valid_593373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593374: Call_GetListQueueTags_593360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all cost allocation tags added to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593374.validator(path, query, header, formData, body)
  let scheme = call_593374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593374.url(scheme.get, call_593374.host, call_593374.base,
                         call_593374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593374, url, valid)

proc call*(call_593375: Call_GetListQueueTags_593360; AccountNumber: int;
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
  var path_593376 = newJObject()
  var query_593377 = newJObject()
  add(path_593376, "AccountNumber", newJInt(AccountNumber))
  add(path_593376, "QueueName", newJString(QueueName))
  add(query_593377, "Action", newJString(Action))
  add(query_593377, "Version", newJString(Version))
  result = call_593375.call(path_593376, query_593377, nil, nil, nil)

var getListQueueTags* = Call_GetListQueueTags_593360(name: "getListQueueTags",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ListQueueTags",
    validator: validate_GetListQueueTags_593361, base: "/",
    url: url_GetListQueueTags_593362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListQueues_593412 = ref object of OpenApiRestCall_592348
proc url_PostListQueues_593414(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListQueues_593413(path: JsonNode; query: JsonNode;
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
  var valid_593415 = query.getOrDefault("Action")
  valid_593415 = validateParameter(valid_593415, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_593415 != nil:
    section.add "Action", valid_593415
  var valid_593416 = query.getOrDefault("Version")
  valid_593416 = validateParameter(valid_593416, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593416 != nil:
    section.add "Version", valid_593416
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
  var valid_593417 = header.getOrDefault("X-Amz-Signature")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Signature", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Content-Sha256", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Date")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Date", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Credential")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Credential", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-Security-Token")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Security-Token", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Algorithm")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Algorithm", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-SignedHeaders", valid_593423
  result.add "header", section
  ## parameters in `formData` object:
  ##   QueueNamePrefix: JString
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  section = newJObject()
  var valid_593424 = formData.getOrDefault("QueueNamePrefix")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "QueueNamePrefix", valid_593424
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593425: Call_PostListQueues_593412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593425.validator(path, query, header, formData, body)
  let scheme = call_593425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593425.url(scheme.get, call_593425.host, call_593425.base,
                         call_593425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593425, url, valid)

proc call*(call_593426: Call_PostListQueues_593412; Action: string = "ListQueues";
          QueueNamePrefix: string = ""; Version: string = "2012-11-05"): Recallable =
  ## postListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_593427 = newJObject()
  var formData_593428 = newJObject()
  add(query_593427, "Action", newJString(Action))
  add(formData_593428, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_593427, "Version", newJString(Version))
  result = call_593426.call(nil, query_593427, nil, formData_593428, nil)

var postListQueues* = Call_PostListQueues_593412(name: "postListQueues",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_PostListQueues_593413,
    base: "/", url: url_PostListQueues_593414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListQueues_593396 = ref object of OpenApiRestCall_592348
proc url_GetListQueues_593398(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListQueues_593397(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593399 = query.getOrDefault("Action")
  valid_593399 = validateParameter(valid_593399, JString, required = true,
                                 default = newJString("ListQueues"))
  if valid_593399 != nil:
    section.add "Action", valid_593399
  var valid_593400 = query.getOrDefault("QueueNamePrefix")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "QueueNamePrefix", valid_593400
  var valid_593401 = query.getOrDefault("Version")
  valid_593401 = validateParameter(valid_593401, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593401 != nil:
    section.add "Version", valid_593401
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
  var valid_593402 = header.getOrDefault("X-Amz-Signature")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Signature", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Content-Sha256", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Date")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Date", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Credential")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Credential", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Security-Token")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Security-Token", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Algorithm")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Algorithm", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-SignedHeaders", valid_593408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593409: Call_GetListQueues_593396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593409.validator(path, query, header, formData, body)
  let scheme = call_593409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593409.url(scheme.get, call_593409.host, call_593409.base,
                         call_593409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593409, url, valid)

proc call*(call_593410: Call_GetListQueues_593396; Action: string = "ListQueues";
          QueueNamePrefix: string = ""; Version: string = "2012-11-05"): Recallable =
  ## getListQueues
  ## <p>Returns a list of your queues. The maximum number of queues that can be returned is 1,000. If you specify a value for the optional <code>QueueNamePrefix</code> parameter, only queues with a name that begins with the specified value are returned.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ##   Action: string (required)
  ##   QueueNamePrefix: string
  ##                  : <p>A string to use for filtering the list results. Only those queues whose name begins with the specified string are returned.</p> <p>Queue URLs and names are case-sensitive.</p>
  ##   Version: string (required)
  var query_593411 = newJObject()
  add(query_593411, "Action", newJString(Action))
  add(query_593411, "QueueNamePrefix", newJString(QueueNamePrefix))
  add(query_593411, "Version", newJString(Version))
  result = call_593410.call(nil, query_593411, nil, nil, nil)

var getListQueues* = Call_GetListQueues_593396(name: "getListQueues",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/#Action=ListQueues", validator: validate_GetListQueues_593397,
    base: "/", url: url_GetListQueues_593398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurgeQueue_593447 = ref object of OpenApiRestCall_592348
proc url_PostPurgeQueue_593449(protocol: Scheme; host: string; base: string;
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

proc validate_PostPurgeQueue_593448(path: JsonNode; query: JsonNode;
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
  var valid_593450 = path.getOrDefault("AccountNumber")
  valid_593450 = validateParameter(valid_593450, JInt, required = true, default = nil)
  if valid_593450 != nil:
    section.add "AccountNumber", valid_593450
  var valid_593451 = path.getOrDefault("QueueName")
  valid_593451 = validateParameter(valid_593451, JString, required = true,
                                 default = nil)
  if valid_593451 != nil:
    section.add "QueueName", valid_593451
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593452 = query.getOrDefault("Action")
  valid_593452 = validateParameter(valid_593452, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_593452 != nil:
    section.add "Action", valid_593452
  var valid_593453 = query.getOrDefault("Version")
  valid_593453 = validateParameter(valid_593453, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593453 != nil:
    section.add "Version", valid_593453
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
  var valid_593454 = header.getOrDefault("X-Amz-Signature")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Signature", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Content-Sha256", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-Date")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Date", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Credential")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Credential", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Security-Token")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Security-Token", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Algorithm")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Algorithm", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-SignedHeaders", valid_593460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593461: Call_PostPurgeQueue_593447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_593461.validator(path, query, header, formData, body)
  let scheme = call_593461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593461.url(scheme.get, call_593461.host, call_593461.base,
                         call_593461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593461, url, valid)

proc call*(call_593462: Call_PostPurgeQueue_593447; AccountNumber: int;
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
  var path_593463 = newJObject()
  var query_593464 = newJObject()
  add(path_593463, "AccountNumber", newJInt(AccountNumber))
  add(path_593463, "QueueName", newJString(QueueName))
  add(query_593464, "Action", newJString(Action))
  add(query_593464, "Version", newJString(Version))
  result = call_593462.call(path_593463, query_593464, nil, nil, nil)

var postPurgeQueue* = Call_PostPurgeQueue_593447(name: "postPurgeQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_PostPurgeQueue_593448, base: "/", url: url_PostPurgeQueue_593449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurgeQueue_593429 = ref object of OpenApiRestCall_592348
proc url_GetPurgeQueue_593431(protocol: Scheme; host: string; base: string;
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

proc validate_GetPurgeQueue_593430(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593432 = path.getOrDefault("AccountNumber")
  valid_593432 = validateParameter(valid_593432, JInt, required = true, default = nil)
  if valid_593432 != nil:
    section.add "AccountNumber", valid_593432
  var valid_593433 = path.getOrDefault("QueueName")
  valid_593433 = validateParameter(valid_593433, JString, required = true,
                                 default = nil)
  if valid_593433 != nil:
    section.add "QueueName", valid_593433
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593434 = query.getOrDefault("Action")
  valid_593434 = validateParameter(valid_593434, JString, required = true,
                                 default = newJString("PurgeQueue"))
  if valid_593434 != nil:
    section.add "Action", valid_593434
  var valid_593435 = query.getOrDefault("Version")
  valid_593435 = validateParameter(valid_593435, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593435 != nil:
    section.add "Version", valid_593435
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
  var valid_593436 = header.getOrDefault("X-Amz-Signature")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Signature", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Content-Sha256", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Date")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Date", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Credential")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Credential", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Security-Token")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Security-Token", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Algorithm")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Algorithm", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-SignedHeaders", valid_593442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593443: Call_GetPurgeQueue_593429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the messages in a queue specified by the <code>QueueURL</code> parameter.</p> <important> <p>When you use the <code>PurgeQueue</code> action, you can't retrieve any messages deleted from a queue.</p> <p>The message deletion process takes up to 60 seconds. We recommend waiting for 60 seconds regardless of your queue's size. </p> </important> <p>Messages sent to the queue <i>before</i> you call <code>PurgeQueue</code> might be received but are deleted within the next minute.</p> <p>Messages sent to the queue <i>after</i> you call <code>PurgeQueue</code> might be deleted while the queue is being purged.</p>
  ## 
  let valid = call_593443.validator(path, query, header, formData, body)
  let scheme = call_593443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593443.url(scheme.get, call_593443.host, call_593443.base,
                         call_593443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593443, url, valid)

proc call*(call_593444: Call_GetPurgeQueue_593429; AccountNumber: int;
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
  var path_593445 = newJObject()
  var query_593446 = newJObject()
  add(path_593445, "AccountNumber", newJInt(AccountNumber))
  add(path_593445, "QueueName", newJString(QueueName))
  add(query_593446, "Action", newJString(Action))
  add(query_593446, "Version", newJString(Version))
  result = call_593444.call(path_593445, query_593446, nil, nil, nil)

var getPurgeQueue* = Call_GetPurgeQueue_593429(name: "getPurgeQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=PurgeQueue",
    validator: validate_GetPurgeQueue_593430, base: "/", url: url_GetPurgeQueue_593431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostReceiveMessage_593489 = ref object of OpenApiRestCall_592348
proc url_PostReceiveMessage_593491(protocol: Scheme; host: string; base: string;
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

proc validate_PostReceiveMessage_593490(path: JsonNode; query: JsonNode;
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
  var valid_593492 = path.getOrDefault("AccountNumber")
  valid_593492 = validateParameter(valid_593492, JInt, required = true, default = nil)
  if valid_593492 != nil:
    section.add "AccountNumber", valid_593492
  var valid_593493 = path.getOrDefault("QueueName")
  valid_593493 = validateParameter(valid_593493, JString, required = true,
                                 default = nil)
  if valid_593493 != nil:
    section.add "QueueName", valid_593493
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593494 = query.getOrDefault("Action")
  valid_593494 = validateParameter(valid_593494, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_593494 != nil:
    section.add "Action", valid_593494
  var valid_593495 = query.getOrDefault("Version")
  valid_593495 = validateParameter(valid_593495, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593495 != nil:
    section.add "Version", valid_593495
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
  var valid_593496 = header.getOrDefault("X-Amz-Signature")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Signature", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Content-Sha256", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Date")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Date", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Credential")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Credential", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Security-Token")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Security-Token", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Algorithm")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Algorithm", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-SignedHeaders", valid_593502
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
  var valid_593503 = formData.getOrDefault("WaitTimeSeconds")
  valid_593503 = validateParameter(valid_593503, JInt, required = false, default = nil)
  if valid_593503 != nil:
    section.add "WaitTimeSeconds", valid_593503
  var valid_593504 = formData.getOrDefault("MessageAttributeNames")
  valid_593504 = validateParameter(valid_593504, JArray, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "MessageAttributeNames", valid_593504
  var valid_593505 = formData.getOrDefault("VisibilityTimeout")
  valid_593505 = validateParameter(valid_593505, JInt, required = false, default = nil)
  if valid_593505 != nil:
    section.add "VisibilityTimeout", valid_593505
  var valid_593506 = formData.getOrDefault("ReceiveRequestAttemptId")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "ReceiveRequestAttemptId", valid_593506
  var valid_593507 = formData.getOrDefault("AttributeNames")
  valid_593507 = validateParameter(valid_593507, JArray, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "AttributeNames", valid_593507
  var valid_593508 = formData.getOrDefault("MaxNumberOfMessages")
  valid_593508 = validateParameter(valid_593508, JInt, required = false, default = nil)
  if valid_593508 != nil:
    section.add "MaxNumberOfMessages", valid_593508
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593509: Call_PostReceiveMessage_593489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_593509.validator(path, query, header, formData, body)
  let scheme = call_593509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593509.url(scheme.get, call_593509.host, call_593509.base,
                         call_593509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593509, url, valid)

proc call*(call_593510: Call_PostReceiveMessage_593489; AccountNumber: int;
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
  var path_593511 = newJObject()
  var query_593512 = newJObject()
  var formData_593513 = newJObject()
  add(formData_593513, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  add(path_593511, "AccountNumber", newJInt(AccountNumber))
  add(path_593511, "QueueName", newJString(QueueName))
  if MessageAttributeNames != nil:
    formData_593513.add "MessageAttributeNames", MessageAttributeNames
  add(formData_593513, "VisibilityTimeout", newJInt(VisibilityTimeout))
  add(formData_593513, "ReceiveRequestAttemptId",
      newJString(ReceiveRequestAttemptId))
  if AttributeNames != nil:
    formData_593513.add "AttributeNames", AttributeNames
  add(query_593512, "Action", newJString(Action))
  add(query_593512, "Version", newJString(Version))
  add(formData_593513, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  result = call_593510.call(path_593511, query_593512, nil, formData_593513, nil)

var postReceiveMessage* = Call_PostReceiveMessage_593489(
    name: "postReceiveMessage", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_PostReceiveMessage_593490, base: "/",
    url: url_PostReceiveMessage_593491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReceiveMessage_593465 = ref object of OpenApiRestCall_592348
proc url_GetReceiveMessage_593467(protocol: Scheme; host: string; base: string;
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

proc validate_GetReceiveMessage_593466(path: JsonNode; query: JsonNode;
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
  var valid_593468 = path.getOrDefault("AccountNumber")
  valid_593468 = validateParameter(valid_593468, JInt, required = true, default = nil)
  if valid_593468 != nil:
    section.add "AccountNumber", valid_593468
  var valid_593469 = path.getOrDefault("QueueName")
  valid_593469 = validateParameter(valid_593469, JString, required = true,
                                 default = nil)
  if valid_593469 != nil:
    section.add "QueueName", valid_593469
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
  var valid_593470 = query.getOrDefault("MaxNumberOfMessages")
  valid_593470 = validateParameter(valid_593470, JInt, required = false, default = nil)
  if valid_593470 != nil:
    section.add "MaxNumberOfMessages", valid_593470
  var valid_593471 = query.getOrDefault("AttributeNames")
  valid_593471 = validateParameter(valid_593471, JArray, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "AttributeNames", valid_593471
  var valid_593472 = query.getOrDefault("MessageAttributeNames")
  valid_593472 = validateParameter(valid_593472, JArray, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "MessageAttributeNames", valid_593472
  var valid_593473 = query.getOrDefault("ReceiveRequestAttemptId")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "ReceiveRequestAttemptId", valid_593473
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593474 = query.getOrDefault("Action")
  valid_593474 = validateParameter(valid_593474, JString, required = true,
                                 default = newJString("ReceiveMessage"))
  if valid_593474 != nil:
    section.add "Action", valid_593474
  var valid_593475 = query.getOrDefault("Version")
  valid_593475 = validateParameter(valid_593475, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593475 != nil:
    section.add "Version", valid_593475
  var valid_593476 = query.getOrDefault("WaitTimeSeconds")
  valid_593476 = validateParameter(valid_593476, JInt, required = false, default = nil)
  if valid_593476 != nil:
    section.add "WaitTimeSeconds", valid_593476
  var valid_593477 = query.getOrDefault("VisibilityTimeout")
  valid_593477 = validateParameter(valid_593477, JInt, required = false, default = nil)
  if valid_593477 != nil:
    section.add "VisibilityTimeout", valid_593477
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
  var valid_593478 = header.getOrDefault("X-Amz-Signature")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Signature", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Content-Sha256", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Date")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Date", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Credential")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Credential", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Security-Token")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Security-Token", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Algorithm")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Algorithm", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-SignedHeaders", valid_593484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593485: Call_GetReceiveMessage_593465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more messages (up to 10), from the specified queue. Using the <code>WaitTimeSeconds</code> parameter enables long-poll support. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-long-polling.html">Amazon SQS Long Polling</a> in the <i>Amazon Simple Queue Service Developer Guide</i>. </p> <p>Short poll is the default behavior where a weighted random set of machines is sampled on a <code>ReceiveMessage</code> call. Thus, only the messages on the sampled machines are returned. If the number of messages in the queue is small (fewer than 1,000), you most likely get fewer messages than you requested per <code>ReceiveMessage</code> call. If the number of messages in the queue is extremely small, you might not receive any messages in a particular <code>ReceiveMessage</code> response. If this happens, repeat the request. </p> <p>For each message returned, the response includes the following:</p> <ul> <li> <p>The message body.</p> </li> <li> <p>An MD5 digest of the message body. For information about MD5, see <a href="https://www.ietf.org/rfc/rfc1321.txt">RFC1321</a>.</p> </li> <li> <p>The <code>MessageId</code> you received when you sent the message to the queue.</p> </li> <li> <p>The receipt handle.</p> </li> <li> <p>The message attributes.</p> </li> <li> <p>An MD5 digest of the message attributes.</p> </li> </ul> <p>The receipt handle is the identifier you must provide when deleting the message. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html">Queue and Message Identifiers</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>You can provide the <code>VisibilityTimeout</code> parameter in your request. The parameter is applied to the messages that Amazon SQS returns in the response. If you don't include the parameter, the overall visibility timeout for the queue is used for the returned messages. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html">Visibility Timeout</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>A message that isn't deleted or a message whose visibility isn't extended before the visibility timeout expires counts as a failed receive. Depending on the configuration of the queue, the message might be sent to the dead-letter queue.</p> <note> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </note>
  ## 
  let valid = call_593485.validator(path, query, header, formData, body)
  let scheme = call_593485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593485.url(scheme.get, call_593485.host, call_593485.base,
                         call_593485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593485, url, valid)

proc call*(call_593486: Call_GetReceiveMessage_593465; AccountNumber: int;
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
  var path_593487 = newJObject()
  var query_593488 = newJObject()
  add(query_593488, "MaxNumberOfMessages", newJInt(MaxNumberOfMessages))
  add(path_593487, "AccountNumber", newJInt(AccountNumber))
  add(path_593487, "QueueName", newJString(QueueName))
  if AttributeNames != nil:
    query_593488.add "AttributeNames", AttributeNames
  if MessageAttributeNames != nil:
    query_593488.add "MessageAttributeNames", MessageAttributeNames
  add(query_593488, "ReceiveRequestAttemptId", newJString(ReceiveRequestAttemptId))
  add(query_593488, "Action", newJString(Action))
  add(query_593488, "Version", newJString(Version))
  add(query_593488, "WaitTimeSeconds", newJInt(WaitTimeSeconds))
  add(query_593488, "VisibilityTimeout", newJInt(VisibilityTimeout))
  result = call_593486.call(path_593487, query_593488, nil, nil, nil)

var getReceiveMessage* = Call_GetReceiveMessage_593465(name: "getReceiveMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=ReceiveMessage",
    validator: validate_GetReceiveMessage_593466, base: "/",
    url: url_GetReceiveMessage_593467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_593533 = ref object of OpenApiRestCall_592348
proc url_PostRemovePermission_593535(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemovePermission_593534(path: JsonNode; query: JsonNode;
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
  var valid_593536 = path.getOrDefault("AccountNumber")
  valid_593536 = validateParameter(valid_593536, JInt, required = true, default = nil)
  if valid_593536 != nil:
    section.add "AccountNumber", valid_593536
  var valid_593537 = path.getOrDefault("QueueName")
  valid_593537 = validateParameter(valid_593537, JString, required = true,
                                 default = nil)
  if valid_593537 != nil:
    section.add "QueueName", valid_593537
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593538 = query.getOrDefault("Action")
  valid_593538 = validateParameter(valid_593538, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_593538 != nil:
    section.add "Action", valid_593538
  var valid_593539 = query.getOrDefault("Version")
  valid_593539 = validateParameter(valid_593539, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593539 != nil:
    section.add "Version", valid_593539
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
  var valid_593540 = header.getOrDefault("X-Amz-Signature")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Signature", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Content-Sha256", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-Date")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-Date", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Credential")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Credential", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Security-Token")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Security-Token", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Algorithm")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Algorithm", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-SignedHeaders", valid_593546
  result.add "header", section
  ## parameters in `formData` object:
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Label` field"
  var valid_593547 = formData.getOrDefault("Label")
  valid_593547 = validateParameter(valid_593547, JString, required = true,
                                 default = nil)
  if valid_593547 != nil:
    section.add "Label", valid_593547
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593548: Call_PostRemovePermission_593533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_593548.validator(path, query, header, formData, body)
  let scheme = call_593548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593548.url(scheme.get, call_593548.host, call_593548.base,
                         call_593548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593548, url, valid)

proc call*(call_593549: Call_PostRemovePermission_593533; AccountNumber: int;
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
  var path_593550 = newJObject()
  var query_593551 = newJObject()
  var formData_593552 = newJObject()
  add(path_593550, "AccountNumber", newJInt(AccountNumber))
  add(path_593550, "QueueName", newJString(QueueName))
  add(query_593551, "Action", newJString(Action))
  add(formData_593552, "Label", newJString(Label))
  add(query_593551, "Version", newJString(Version))
  result = call_593549.call(path_593550, query_593551, nil, formData_593552, nil)

var postRemovePermission* = Call_PostRemovePermission_593533(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_PostRemovePermission_593534, base: "/",
    url: url_PostRemovePermission_593535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_593514 = ref object of OpenApiRestCall_592348
proc url_GetRemovePermission_593516(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemovePermission_593515(path: JsonNode; query: JsonNode;
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
  var valid_593517 = path.getOrDefault("AccountNumber")
  valid_593517 = validateParameter(valid_593517, JInt, required = true, default = nil)
  if valid_593517 != nil:
    section.add "AccountNumber", valid_593517
  var valid_593518 = path.getOrDefault("QueueName")
  valid_593518 = validateParameter(valid_593518, JString, required = true,
                                 default = nil)
  if valid_593518 != nil:
    section.add "QueueName", valid_593518
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The identification of the permission to remove. This is the label added using the <code> <a>AddPermission</a> </code> action.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593519 = query.getOrDefault("Action")
  valid_593519 = validateParameter(valid_593519, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_593519 != nil:
    section.add "Action", valid_593519
  var valid_593520 = query.getOrDefault("Version")
  valid_593520 = validateParameter(valid_593520, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593520 != nil:
    section.add "Version", valid_593520
  var valid_593521 = query.getOrDefault("Label")
  valid_593521 = validateParameter(valid_593521, JString, required = true,
                                 default = nil)
  if valid_593521 != nil:
    section.add "Label", valid_593521
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
  var valid_593522 = header.getOrDefault("X-Amz-Signature")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Signature", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Content-Sha256", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Date")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Date", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Credential")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Credential", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-Security-Token")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-Security-Token", valid_593526
  var valid_593527 = header.getOrDefault("X-Amz-Algorithm")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amz-Algorithm", valid_593527
  var valid_593528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "X-Amz-SignedHeaders", valid_593528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593529: Call_GetRemovePermission_593514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes any permissions in the queue policy that matches the specified <code>Label</code> parameter.</p> <note> <ul> <li> <p>Only the owner of a queue can remove permissions from it.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_593529.validator(path, query, header, formData, body)
  let scheme = call_593529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593529.url(scheme.get, call_593529.host, call_593529.base,
                         call_593529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593529, url, valid)

proc call*(call_593530: Call_GetRemovePermission_593514; AccountNumber: int;
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
  var path_593531 = newJObject()
  var query_593532 = newJObject()
  add(path_593531, "AccountNumber", newJInt(AccountNumber))
  add(path_593531, "QueueName", newJString(QueueName))
  add(query_593532, "Action", newJString(Action))
  add(query_593532, "Version", newJString(Version))
  add(query_593532, "Label", newJString(Label))
  result = call_593530.call(path_593531, query_593532, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_593514(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=RemovePermission",
    validator: validate_GetRemovePermission_593515, base: "/",
    url: url_GetRemovePermission_593516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessage_593587 = ref object of OpenApiRestCall_592348
proc url_PostSendMessage_593589(protocol: Scheme; host: string; base: string;
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

proc validate_PostSendMessage_593588(path: JsonNode; query: JsonNode;
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
  var valid_593590 = path.getOrDefault("AccountNumber")
  valid_593590 = validateParameter(valid_593590, JInt, required = true, default = nil)
  if valid_593590 != nil:
    section.add "AccountNumber", valid_593590
  var valid_593591 = path.getOrDefault("QueueName")
  valid_593591 = validateParameter(valid_593591, JString, required = true,
                                 default = nil)
  if valid_593591 != nil:
    section.add "QueueName", valid_593591
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593592 = query.getOrDefault("Action")
  valid_593592 = validateParameter(valid_593592, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_593592 != nil:
    section.add "Action", valid_593592
  var valid_593593 = query.getOrDefault("Version")
  valid_593593 = validateParameter(valid_593593, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593593 != nil:
    section.add "Version", valid_593593
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
  var valid_593594 = header.getOrDefault("X-Amz-Signature")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-Signature", valid_593594
  var valid_593595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593595 = validateParameter(valid_593595, JString, required = false,
                                 default = nil)
  if valid_593595 != nil:
    section.add "X-Amz-Content-Sha256", valid_593595
  var valid_593596 = header.getOrDefault("X-Amz-Date")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Date", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-Credential")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-Credential", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Security-Token")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Security-Token", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Algorithm")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Algorithm", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-SignedHeaders", valid_593600
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
  var valid_593601 = formData.getOrDefault("MessageDeduplicationId")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "MessageDeduplicationId", valid_593601
  var valid_593602 = formData.getOrDefault("DelaySeconds")
  valid_593602 = validateParameter(valid_593602, JInt, required = false, default = nil)
  if valid_593602 != nil:
    section.add "DelaySeconds", valid_593602
  var valid_593603 = formData.getOrDefault("MessageAttribute.1.key")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "MessageAttribute.1.key", valid_593603
  var valid_593604 = formData.getOrDefault("MessageAttribute.0.value")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "MessageAttribute.0.value", valid_593604
  var valid_593605 = formData.getOrDefault("MessageSystemAttribute.0.key")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "MessageSystemAttribute.0.key", valid_593605
  var valid_593606 = formData.getOrDefault("MessageAttribute.2.value")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "MessageAttribute.2.value", valid_593606
  var valid_593607 = formData.getOrDefault("MessageSystemAttribute.0.value")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "MessageSystemAttribute.0.value", valid_593607
  var valid_593608 = formData.getOrDefault("MessageAttribute.1.value")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "MessageAttribute.1.value", valid_593608
  var valid_593609 = formData.getOrDefault("MessageGroupId")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "MessageGroupId", valid_593609
  assert formData != nil,
        "formData argument is necessary due to required `MessageBody` field"
  var valid_593610 = formData.getOrDefault("MessageBody")
  valid_593610 = validateParameter(valid_593610, JString, required = true,
                                 default = nil)
  if valid_593610 != nil:
    section.add "MessageBody", valid_593610
  var valid_593611 = formData.getOrDefault("MessageSystemAttribute.1.value")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "MessageSystemAttribute.1.value", valid_593611
  var valid_593612 = formData.getOrDefault("MessageSystemAttribute.1.key")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "MessageSystemAttribute.1.key", valid_593612
  var valid_593613 = formData.getOrDefault("MessageSystemAttribute.2.key")
  valid_593613 = validateParameter(valid_593613, JString, required = false,
                                 default = nil)
  if valid_593613 != nil:
    section.add "MessageSystemAttribute.2.key", valid_593613
  var valid_593614 = formData.getOrDefault("MessageAttribute.0.key")
  valid_593614 = validateParameter(valid_593614, JString, required = false,
                                 default = nil)
  if valid_593614 != nil:
    section.add "MessageAttribute.0.key", valid_593614
  var valid_593615 = formData.getOrDefault("MessageAttribute.2.key")
  valid_593615 = validateParameter(valid_593615, JString, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "MessageAttribute.2.key", valid_593615
  var valid_593616 = formData.getOrDefault("MessageSystemAttribute.2.value")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "MessageSystemAttribute.2.value", valid_593616
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593617: Call_PostSendMessage_593587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_593617.validator(path, query, header, formData, body)
  let scheme = call_593617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593617.url(scheme.get, call_593617.host, call_593617.base,
                         call_593617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593617, url, valid)

proc call*(call_593618: Call_PostSendMessage_593587; AccountNumber: int;
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
  var path_593619 = newJObject()
  var query_593620 = newJObject()
  var formData_593621 = newJObject()
  add(formData_593621, "MessageDeduplicationId",
      newJString(MessageDeduplicationId))
  add(path_593619, "AccountNumber", newJInt(AccountNumber))
  add(path_593619, "QueueName", newJString(QueueName))
  add(formData_593621, "DelaySeconds", newJInt(DelaySeconds))
  add(formData_593621, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  add(formData_593621, "MessageAttribute.0.value",
      newJString(MessageAttribute0Value))
  add(formData_593621, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(formData_593621, "MessageAttribute.2.value",
      newJString(MessageAttribute2Value))
  add(formData_593621, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(formData_593621, "MessageAttribute.1.value",
      newJString(MessageAttribute1Value))
  add(formData_593621, "MessageGroupId", newJString(MessageGroupId))
  add(formData_593621, "MessageBody", newJString(MessageBody))
  add(formData_593621, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(formData_593621, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  add(query_593620, "Action", newJString(Action))
  add(formData_593621, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(formData_593621, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(formData_593621, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(query_593620, "Version", newJString(Version))
  add(formData_593621, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  result = call_593618.call(path_593619, query_593620, nil, formData_593621, nil)

var postSendMessage* = Call_PostSendMessage_593587(name: "postSendMessage",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_PostSendMessage_593588, base: "/", url: url_PostSendMessage_593589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessage_593553 = ref object of OpenApiRestCall_592348
proc url_GetSendMessage_593555(protocol: Scheme; host: string; base: string;
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

proc validate_GetSendMessage_593554(path: JsonNode; query: JsonNode;
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
  var valid_593556 = path.getOrDefault("AccountNumber")
  valid_593556 = validateParameter(valid_593556, JInt, required = true, default = nil)
  if valid_593556 != nil:
    section.add "AccountNumber", valid_593556
  var valid_593557 = path.getOrDefault("QueueName")
  valid_593557 = validateParameter(valid_593557, JString, required = true,
                                 default = nil)
  if valid_593557 != nil:
    section.add "QueueName", valid_593557
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
  var valid_593558 = query.getOrDefault("MessageAttribute.2.key")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "MessageAttribute.2.key", valid_593558
  var valid_593559 = query.getOrDefault("MessageDeduplicationId")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "MessageDeduplicationId", valid_593559
  var valid_593560 = query.getOrDefault("MessageSystemAttribute.0.value")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "MessageSystemAttribute.0.value", valid_593560
  var valid_593561 = query.getOrDefault("MessageAttribute.1.key")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "MessageAttribute.1.key", valid_593561
  var valid_593562 = query.getOrDefault("MessageSystemAttribute.1.value")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "MessageSystemAttribute.1.value", valid_593562
  var valid_593563 = query.getOrDefault("DelaySeconds")
  valid_593563 = validateParameter(valid_593563, JInt, required = false, default = nil)
  if valid_593563 != nil:
    section.add "DelaySeconds", valid_593563
  var valid_593564 = query.getOrDefault("MessageSystemAttribute.2.value")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "MessageSystemAttribute.2.value", valid_593564
  var valid_593565 = query.getOrDefault("MessageAttribute.0.value")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "MessageAttribute.0.value", valid_593565
  assert query != nil,
        "query argument is necessary due to required `MessageBody` field"
  var valid_593566 = query.getOrDefault("MessageBody")
  valid_593566 = validateParameter(valid_593566, JString, required = true,
                                 default = nil)
  if valid_593566 != nil:
    section.add "MessageBody", valid_593566
  var valid_593567 = query.getOrDefault("MessageAttribute.2.value")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "MessageAttribute.2.value", valid_593567
  var valid_593568 = query.getOrDefault("MessageGroupId")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "MessageGroupId", valid_593568
  var valid_593569 = query.getOrDefault("MessageSystemAttribute.2.key")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "MessageSystemAttribute.2.key", valid_593569
  var valid_593570 = query.getOrDefault("Action")
  valid_593570 = validateParameter(valid_593570, JString, required = true,
                                 default = newJString("SendMessage"))
  if valid_593570 != nil:
    section.add "Action", valid_593570
  var valid_593571 = query.getOrDefault("MessageSystemAttribute.0.key")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "MessageSystemAttribute.0.key", valid_593571
  var valid_593572 = query.getOrDefault("MessageAttribute.0.key")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "MessageAttribute.0.key", valid_593572
  var valid_593573 = query.getOrDefault("Version")
  valid_593573 = validateParameter(valid_593573, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593573 != nil:
    section.add "Version", valid_593573
  var valid_593574 = query.getOrDefault("MessageSystemAttribute.1.key")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "MessageSystemAttribute.1.key", valid_593574
  var valid_593575 = query.getOrDefault("MessageAttribute.1.value")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "MessageAttribute.1.value", valid_593575
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
  var valid_593576 = header.getOrDefault("X-Amz-Signature")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Signature", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Content-Sha256", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-Date")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-Date", valid_593578
  var valid_593579 = header.getOrDefault("X-Amz-Credential")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Credential", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-Security-Token")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-Security-Token", valid_593580
  var valid_593581 = header.getOrDefault("X-Amz-Algorithm")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Algorithm", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-SignedHeaders", valid_593582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593583: Call_GetSendMessage_593553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers a message to the specified queue.</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important>
  ## 
  let valid = call_593583.validator(path, query, header, formData, body)
  let scheme = call_593583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593583.url(scheme.get, call_593583.host, call_593583.base,
                         call_593583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593583, url, valid)

proc call*(call_593584: Call_GetSendMessage_593553; AccountNumber: int;
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
  var path_593585 = newJObject()
  var query_593586 = newJObject()
  add(query_593586, "MessageAttribute.2.key", newJString(MessageAttribute2Key))
  add(path_593585, "AccountNumber", newJInt(AccountNumber))
  add(path_593585, "QueueName", newJString(QueueName))
  add(query_593586, "MessageDeduplicationId", newJString(MessageDeduplicationId))
  add(query_593586, "MessageSystemAttribute.0.value",
      newJString(MessageSystemAttribute0Value))
  add(query_593586, "MessageAttribute.1.key", newJString(MessageAttribute1Key))
  add(query_593586, "MessageSystemAttribute.1.value",
      newJString(MessageSystemAttribute1Value))
  add(query_593586, "DelaySeconds", newJInt(DelaySeconds))
  add(query_593586, "MessageSystemAttribute.2.value",
      newJString(MessageSystemAttribute2Value))
  add(query_593586, "MessageAttribute.0.value", newJString(MessageAttribute0Value))
  add(query_593586, "MessageBody", newJString(MessageBody))
  add(query_593586, "MessageAttribute.2.value", newJString(MessageAttribute2Value))
  add(query_593586, "MessageGroupId", newJString(MessageGroupId))
  add(query_593586, "MessageSystemAttribute.2.key",
      newJString(MessageSystemAttribute2Key))
  add(query_593586, "Action", newJString(Action))
  add(query_593586, "MessageSystemAttribute.0.key",
      newJString(MessageSystemAttribute0Key))
  add(query_593586, "MessageAttribute.0.key", newJString(MessageAttribute0Key))
  add(query_593586, "Version", newJString(Version))
  add(query_593586, "MessageSystemAttribute.1.key",
      newJString(MessageSystemAttribute1Key))
  add(query_593586, "MessageAttribute.1.value", newJString(MessageAttribute1Value))
  result = call_593584.call(path_593585, query_593586, nil, nil, nil)

var getSendMessage* = Call_GetSendMessage_593553(name: "getSendMessage",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessage",
    validator: validate_GetSendMessage_593554, base: "/", url: url_GetSendMessage_593555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSendMessageBatch_593641 = ref object of OpenApiRestCall_592348
proc url_PostSendMessageBatch_593643(protocol: Scheme; host: string; base: string;
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

proc validate_PostSendMessageBatch_593642(path: JsonNode; query: JsonNode;
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
  var valid_593644 = path.getOrDefault("AccountNumber")
  valid_593644 = validateParameter(valid_593644, JInt, required = true, default = nil)
  if valid_593644 != nil:
    section.add "AccountNumber", valid_593644
  var valid_593645 = path.getOrDefault("QueueName")
  valid_593645 = validateParameter(valid_593645, JString, required = true,
                                 default = nil)
  if valid_593645 != nil:
    section.add "QueueName", valid_593645
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593646 = query.getOrDefault("Action")
  valid_593646 = validateParameter(valid_593646, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_593646 != nil:
    section.add "Action", valid_593646
  var valid_593647 = query.getOrDefault("Version")
  valid_593647 = validateParameter(valid_593647, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593647 != nil:
    section.add "Version", valid_593647
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
  var valid_593648 = header.getOrDefault("X-Amz-Signature")
  valid_593648 = validateParameter(valid_593648, JString, required = false,
                                 default = nil)
  if valid_593648 != nil:
    section.add "X-Amz-Signature", valid_593648
  var valid_593649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-Content-Sha256", valid_593649
  var valid_593650 = header.getOrDefault("X-Amz-Date")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Date", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Credential")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Credential", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Security-Token")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Security-Token", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Algorithm")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Algorithm", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-SignedHeaders", valid_593654
  result.add "header", section
  ## parameters in `formData` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Entries` field"
  var valid_593655 = formData.getOrDefault("Entries")
  valid_593655 = validateParameter(valid_593655, JArray, required = true, default = nil)
  if valid_593655 != nil:
    section.add "Entries", valid_593655
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593656: Call_PostSendMessageBatch_593641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593656.validator(path, query, header, formData, body)
  let scheme = call_593656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593656.url(scheme.get, call_593656.host, call_593656.base,
                         call_593656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593656, url, valid)

proc call*(call_593657: Call_PostSendMessageBatch_593641; AccountNumber: int;
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
  var path_593658 = newJObject()
  var query_593659 = newJObject()
  var formData_593660 = newJObject()
  add(path_593658, "AccountNumber", newJInt(AccountNumber))
  add(path_593658, "QueueName", newJString(QueueName))
  if Entries != nil:
    formData_593660.add "Entries", Entries
  add(query_593659, "Action", newJString(Action))
  add(query_593659, "Version", newJString(Version))
  result = call_593657.call(path_593658, query_593659, nil, formData_593660, nil)

var postSendMessageBatch* = Call_PostSendMessageBatch_593641(
    name: "postSendMessageBatch", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_PostSendMessageBatch_593642, base: "/",
    url: url_PostSendMessageBatch_593643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSendMessageBatch_593622 = ref object of OpenApiRestCall_592348
proc url_GetSendMessageBatch_593624(protocol: Scheme; host: string; base: string;
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

proc validate_GetSendMessageBatch_593623(path: JsonNode; query: JsonNode;
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
  var valid_593625 = path.getOrDefault("AccountNumber")
  valid_593625 = validateParameter(valid_593625, JInt, required = true, default = nil)
  if valid_593625 != nil:
    section.add "AccountNumber", valid_593625
  var valid_593626 = path.getOrDefault("QueueName")
  valid_593626 = validateParameter(valid_593626, JString, required = true,
                                 default = nil)
  if valid_593626 != nil:
    section.add "QueueName", valid_593626
  result.add "path", section
  ## parameters in `query` object:
  ##   Entries: JArray (required)
  ##          : A list of <code> <a>SendMessageBatchRequestEntry</a> </code> items.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Entries` field"
  var valid_593627 = query.getOrDefault("Entries")
  valid_593627 = validateParameter(valid_593627, JArray, required = true, default = nil)
  if valid_593627 != nil:
    section.add "Entries", valid_593627
  var valid_593628 = query.getOrDefault("Action")
  valid_593628 = validateParameter(valid_593628, JString, required = true,
                                 default = newJString("SendMessageBatch"))
  if valid_593628 != nil:
    section.add "Action", valid_593628
  var valid_593629 = query.getOrDefault("Version")
  valid_593629 = validateParameter(valid_593629, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593629 != nil:
    section.add "Version", valid_593629
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
  var valid_593630 = header.getOrDefault("X-Amz-Signature")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-Signature", valid_593630
  var valid_593631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "X-Amz-Content-Sha256", valid_593631
  var valid_593632 = header.getOrDefault("X-Amz-Date")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Date", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Credential")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Credential", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Security-Token")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Security-Token", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Algorithm")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Algorithm", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-SignedHeaders", valid_593636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593637: Call_GetSendMessageBatch_593622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delivers up to ten messages to the specified queue. This is a batch version of <code> <a>SendMessage</a>.</code> For a FIFO queue, multiple messages within a single batch are enqueued in the order they are sent.</p> <p>The result of sending each message is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of <code>200</code>.</p> <p>The maximum allowed individual message size and the maximum total payload size (the sum of the individual lengths of all of the batched messages) are both 256 KB (262,144 bytes).</p> <important> <p>A message can include only XML, JSON, and unformatted text. The following Unicode characters are allowed:</p> <p> <code>#x9</code> | <code>#xA</code> | <code>#xD</code> | <code>#x20</code> to <code>#xD7FF</code> | <code>#xE000</code> to <code>#xFFFD</code> | <code>#x10000</code> to <code>#x10FFFF</code> </p> <p>Any characters not included in this list will be rejected. For more information, see the <a href="http://www.w3.org/TR/REC-xml/#charsets">W3C specification for characters</a>.</p> </important> <p>If you don't specify the <code>DelaySeconds</code> parameter for an entry, Amazon SQS uses the default value for the queue.</p> <p>Some actions take lists of parameters. These lists are specified using the <code>param.n</code> notation. Values of <code>n</code> are integers starting from 1. For example, a parameter list with two elements looks like this:</p> <p> <code>&amp;Attribute.1=first</code> </p> <p> <code>&amp;Attribute.2=second</code> </p>
  ## 
  let valid = call_593637.validator(path, query, header, formData, body)
  let scheme = call_593637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593637.url(scheme.get, call_593637.host, call_593637.base,
                         call_593637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593637, url, valid)

proc call*(call_593638: Call_GetSendMessageBatch_593622; Entries: JsonNode;
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
  var path_593639 = newJObject()
  var query_593640 = newJObject()
  if Entries != nil:
    query_593640.add "Entries", Entries
  add(path_593639, "AccountNumber", newJInt(AccountNumber))
  add(path_593639, "QueueName", newJString(QueueName))
  add(query_593640, "Action", newJString(Action))
  add(query_593640, "Version", newJString(Version))
  result = call_593638.call(path_593639, query_593640, nil, nil, nil)

var getSendMessageBatch* = Call_GetSendMessageBatch_593622(
    name: "getSendMessageBatch", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SendMessageBatch",
    validator: validate_GetSendMessageBatch_593623, base: "/",
    url: url_GetSendMessageBatch_593624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetQueueAttributes_593685 = ref object of OpenApiRestCall_592348
proc url_PostSetQueueAttributes_593687(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetQueueAttributes_593686(path: JsonNode; query: JsonNode;
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
  var valid_593688 = path.getOrDefault("AccountNumber")
  valid_593688 = validateParameter(valid_593688, JInt, required = true, default = nil)
  if valid_593688 != nil:
    section.add "AccountNumber", valid_593688
  var valid_593689 = path.getOrDefault("QueueName")
  valid_593689 = validateParameter(valid_593689, JString, required = true,
                                 default = nil)
  if valid_593689 != nil:
    section.add "QueueName", valid_593689
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593690 = query.getOrDefault("Action")
  valid_593690 = validateParameter(valid_593690, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_593690 != nil:
    section.add "Action", valid_593690
  var valid_593691 = query.getOrDefault("Version")
  valid_593691 = validateParameter(valid_593691, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593691 != nil:
    section.add "Version", valid_593691
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
  var valid_593692 = header.getOrDefault("X-Amz-Signature")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Signature", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Content-Sha256", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Date")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Date", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Credential")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Credential", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-Security-Token")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Security-Token", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Algorithm")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Algorithm", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-SignedHeaders", valid_593698
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attribute.2.value: JString
  ##   Attribute.2.key: JString
  ##   Attribute.0.value: JString
  ##   Attribute.1.key: JString
  ##   Attribute.1.value: JString
  ##   Attribute.0.key: JString
  section = newJObject()
  var valid_593699 = formData.getOrDefault("Attribute.2.value")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "Attribute.2.value", valid_593699
  var valid_593700 = formData.getOrDefault("Attribute.2.key")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "Attribute.2.key", valid_593700
  var valid_593701 = formData.getOrDefault("Attribute.0.value")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "Attribute.0.value", valid_593701
  var valid_593702 = formData.getOrDefault("Attribute.1.key")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "Attribute.1.key", valid_593702
  var valid_593703 = formData.getOrDefault("Attribute.1.value")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "Attribute.1.value", valid_593703
  var valid_593704 = formData.getOrDefault("Attribute.0.key")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "Attribute.0.key", valid_593704
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593705: Call_PostSetQueueAttributes_593685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_593705.validator(path, query, header, formData, body)
  let scheme = call_593705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593705.url(scheme.get, call_593705.host, call_593705.base,
                         call_593705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593705, url, valid)

proc call*(call_593706: Call_PostSetQueueAttributes_593685; AccountNumber: int;
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
  var path_593707 = newJObject()
  var query_593708 = newJObject()
  var formData_593709 = newJObject()
  add(formData_593709, "Attribute.2.value", newJString(Attribute2Value))
  add(formData_593709, "Attribute.2.key", newJString(Attribute2Key))
  add(path_593707, "AccountNumber", newJInt(AccountNumber))
  add(path_593707, "QueueName", newJString(QueueName))
  add(formData_593709, "Attribute.0.value", newJString(Attribute0Value))
  add(formData_593709, "Attribute.1.key", newJString(Attribute1Key))
  add(formData_593709, "Attribute.1.value", newJString(Attribute1Value))
  add(query_593708, "Action", newJString(Action))
  add(query_593708, "Version", newJString(Version))
  add(formData_593709, "Attribute.0.key", newJString(Attribute0Key))
  result = call_593706.call(path_593707, query_593708, nil, formData_593709, nil)

var postSetQueueAttributes* = Call_PostSetQueueAttributes_593685(
    name: "postSetQueueAttributes", meth: HttpMethod.HttpPost,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_PostSetQueueAttributes_593686, base: "/",
    url: url_PostSetQueueAttributes_593687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetQueueAttributes_593661 = ref object of OpenApiRestCall_592348
proc url_GetSetQueueAttributes_593663(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetQueueAttributes_593662(path: JsonNode; query: JsonNode;
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
  var valid_593664 = path.getOrDefault("AccountNumber")
  valid_593664 = validateParameter(valid_593664, JInt, required = true, default = nil)
  if valid_593664 != nil:
    section.add "AccountNumber", valid_593664
  var valid_593665 = path.getOrDefault("QueueName")
  valid_593665 = validateParameter(valid_593665, JString, required = true,
                                 default = nil)
  if valid_593665 != nil:
    section.add "QueueName", valid_593665
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
  var valid_593666 = query.getOrDefault("Attribute.2.key")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "Attribute.2.key", valid_593666
  var valid_593667 = query.getOrDefault("Attribute.1.key")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "Attribute.1.key", valid_593667
  var valid_593668 = query.getOrDefault("Attribute.2.value")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "Attribute.2.value", valid_593668
  var valid_593669 = query.getOrDefault("Attribute.1.value")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "Attribute.1.value", valid_593669
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593670 = query.getOrDefault("Action")
  valid_593670 = validateParameter(valid_593670, JString, required = true,
                                 default = newJString("SetQueueAttributes"))
  if valid_593670 != nil:
    section.add "Action", valid_593670
  var valid_593671 = query.getOrDefault("Attribute.0.key")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "Attribute.0.key", valid_593671
  var valid_593672 = query.getOrDefault("Version")
  valid_593672 = validateParameter(valid_593672, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593672 != nil:
    section.add "Version", valid_593672
  var valid_593673 = query.getOrDefault("Attribute.0.value")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "Attribute.0.value", valid_593673
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
  var valid_593674 = header.getOrDefault("X-Amz-Signature")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Signature", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Content-Sha256", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Date")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Date", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Credential")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Credential", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Security-Token")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Security-Token", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-Algorithm")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-Algorithm", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-SignedHeaders", valid_593680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593681: Call_GetSetQueueAttributes_593661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the value of one or more queue attributes. When you change a queue's attributes, the change can take up to 60 seconds for most of the attributes to propagate throughout the Amazon SQS system. Changes made to the <code>MessageRetentionPeriod</code> attribute can take up to 15 minutes.</p> <note> <ul> <li> <p>In the future, new attributes might be added. If you write code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.</p> </li> <li> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </li> <li> <p>To remove the ability to change queue permissions, you must deny permission to the <code>AddPermission</code>, <code>RemovePermission</code>, and <code>SetQueueAttributes</code> actions in your IAM policy.</p> </li> </ul> </note>
  ## 
  let valid = call_593681.validator(path, query, header, formData, body)
  let scheme = call_593681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593681.url(scheme.get, call_593681.host, call_593681.base,
                         call_593681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593681, url, valid)

proc call*(call_593682: Call_GetSetQueueAttributes_593661; AccountNumber: int;
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
  var path_593683 = newJObject()
  var query_593684 = newJObject()
  add(query_593684, "Attribute.2.key", newJString(Attribute2Key))
  add(path_593683, "AccountNumber", newJInt(AccountNumber))
  add(path_593683, "QueueName", newJString(QueueName))
  add(query_593684, "Attribute.1.key", newJString(Attribute1Key))
  add(query_593684, "Attribute.2.value", newJString(Attribute2Value))
  add(query_593684, "Attribute.1.value", newJString(Attribute1Value))
  add(query_593684, "Action", newJString(Action))
  add(query_593684, "Attribute.0.key", newJString(Attribute0Key))
  add(query_593684, "Version", newJString(Version))
  add(query_593684, "Attribute.0.value", newJString(Attribute0Value))
  result = call_593682.call(path_593683, query_593684, nil, nil, nil)

var getSetQueueAttributes* = Call_GetSetQueueAttributes_593661(
    name: "getSetQueueAttributes", meth: HttpMethod.HttpGet,
    host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=SetQueueAttributes",
    validator: validate_GetSetQueueAttributes_593662, base: "/",
    url: url_GetSetQueueAttributes_593663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagQueue_593734 = ref object of OpenApiRestCall_592348
proc url_PostTagQueue_593736(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagQueue_593735(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593737 = path.getOrDefault("AccountNumber")
  valid_593737 = validateParameter(valid_593737, JInt, required = true, default = nil)
  if valid_593737 != nil:
    section.add "AccountNumber", valid_593737
  var valid_593738 = path.getOrDefault("QueueName")
  valid_593738 = validateParameter(valid_593738, JString, required = true,
                                 default = nil)
  if valid_593738 != nil:
    section.add "QueueName", valid_593738
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593739 = query.getOrDefault("Action")
  valid_593739 = validateParameter(valid_593739, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_593739 != nil:
    section.add "Action", valid_593739
  var valid_593740 = query.getOrDefault("Version")
  valid_593740 = validateParameter(valid_593740, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593740 != nil:
    section.add "Version", valid_593740
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
  var valid_593741 = header.getOrDefault("X-Amz-Signature")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-Signature", valid_593741
  var valid_593742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593742 = validateParameter(valid_593742, JString, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "X-Amz-Content-Sha256", valid_593742
  var valid_593743 = header.getOrDefault("X-Amz-Date")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "X-Amz-Date", valid_593743
  var valid_593744 = header.getOrDefault("X-Amz-Credential")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-Credential", valid_593744
  var valid_593745 = header.getOrDefault("X-Amz-Security-Token")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Security-Token", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-Algorithm")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Algorithm", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-SignedHeaders", valid_593747
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags.0.value: JString
  ##   Tags.2.key: JString
  ##   Tags.0.key: JString
  ##   Tags.1.key: JString
  ##   Tags.1.value: JString
  ##   Tags.2.value: JString
  section = newJObject()
  var valid_593748 = formData.getOrDefault("Tags.0.value")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "Tags.0.value", valid_593748
  var valid_593749 = formData.getOrDefault("Tags.2.key")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "Tags.2.key", valid_593749
  var valid_593750 = formData.getOrDefault("Tags.0.key")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "Tags.0.key", valid_593750
  var valid_593751 = formData.getOrDefault("Tags.1.key")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "Tags.1.key", valid_593751
  var valid_593752 = formData.getOrDefault("Tags.1.value")
  valid_593752 = validateParameter(valid_593752, JString, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "Tags.1.value", valid_593752
  var valid_593753 = formData.getOrDefault("Tags.2.value")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "Tags.2.value", valid_593753
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593754: Call_PostTagQueue_593734; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593754.validator(path, query, header, formData, body)
  let scheme = call_593754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593754.url(scheme.get, call_593754.host, call_593754.base,
                         call_593754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593754, url, valid)

proc call*(call_593755: Call_PostTagQueue_593734; AccountNumber: int;
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
  var path_593756 = newJObject()
  var query_593757 = newJObject()
  var formData_593758 = newJObject()
  add(path_593756, "AccountNumber", newJInt(AccountNumber))
  add(path_593756, "QueueName", newJString(QueueName))
  add(formData_593758, "Tags.0.value", newJString(Tags0Value))
  add(formData_593758, "Tags.2.key", newJString(Tags2Key))
  add(formData_593758, "Tags.0.key", newJString(Tags0Key))
  add(query_593757, "Action", newJString(Action))
  add(formData_593758, "Tags.1.key", newJString(Tags1Key))
  add(query_593757, "Version", newJString(Version))
  add(formData_593758, "Tags.1.value", newJString(Tags1Value))
  add(formData_593758, "Tags.2.value", newJString(Tags2Value))
  result = call_593755.call(path_593756, query_593757, nil, formData_593758, nil)

var postTagQueue* = Call_PostTagQueue_593734(name: "postTagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
    validator: validate_PostTagQueue_593735, base: "/", url: url_PostTagQueue_593736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagQueue_593710 = ref object of OpenApiRestCall_592348
proc url_GetTagQueue_593712(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagQueue_593711(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593713 = path.getOrDefault("AccountNumber")
  valid_593713 = validateParameter(valid_593713, JInt, required = true, default = nil)
  if valid_593713 != nil:
    section.add "AccountNumber", valid_593713
  var valid_593714 = path.getOrDefault("QueueName")
  valid_593714 = validateParameter(valid_593714, JString, required = true,
                                 default = nil)
  if valid_593714 != nil:
    section.add "QueueName", valid_593714
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
  var valid_593715 = query.getOrDefault("Tags.0.value")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "Tags.0.value", valid_593715
  var valid_593716 = query.getOrDefault("Tags.2.value")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "Tags.2.value", valid_593716
  var valid_593717 = query.getOrDefault("Tags.2.key")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "Tags.2.key", valid_593717
  var valid_593718 = query.getOrDefault("Tags.1.key")
  valid_593718 = validateParameter(valid_593718, JString, required = false,
                                 default = nil)
  if valid_593718 != nil:
    section.add "Tags.1.key", valid_593718
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593719 = query.getOrDefault("Action")
  valid_593719 = validateParameter(valid_593719, JString, required = true,
                                 default = newJString("TagQueue"))
  if valid_593719 != nil:
    section.add "Action", valid_593719
  var valid_593720 = query.getOrDefault("Tags.0.key")
  valid_593720 = validateParameter(valid_593720, JString, required = false,
                                 default = nil)
  if valid_593720 != nil:
    section.add "Tags.0.key", valid_593720
  var valid_593721 = query.getOrDefault("Tags.1.value")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "Tags.1.value", valid_593721
  var valid_593722 = query.getOrDefault("Version")
  valid_593722 = validateParameter(valid_593722, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593722 != nil:
    section.add "Version", valid_593722
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
  var valid_593723 = header.getOrDefault("X-Amz-Signature")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Signature", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Content-Sha256", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Date")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Date", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-Credential")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Credential", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Security-Token")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Security-Token", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Algorithm")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Algorithm", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-SignedHeaders", valid_593729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593730: Call_GetTagQueue_593710; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add cost allocation tags to the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <p>When you use queue tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a queue isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SQS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html#limits-queues">Limits Related to Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593730.validator(path, query, header, formData, body)
  let scheme = call_593730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593730.url(scheme.get, call_593730.host, call_593730.base,
                         call_593730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593730, url, valid)

proc call*(call_593731: Call_GetTagQueue_593710; AccountNumber: int;
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
  var path_593732 = newJObject()
  var query_593733 = newJObject()
  add(path_593732, "AccountNumber", newJInt(AccountNumber))
  add(query_593733, "Tags.0.value", newJString(Tags0Value))
  add(path_593732, "QueueName", newJString(QueueName))
  add(query_593733, "Tags.2.value", newJString(Tags2Value))
  add(query_593733, "Tags.2.key", newJString(Tags2Key))
  add(query_593733, "Tags.1.key", newJString(Tags1Key))
  add(query_593733, "Action", newJString(Action))
  add(query_593733, "Tags.0.key", newJString(Tags0Key))
  add(query_593733, "Tags.1.value", newJString(Tags1Value))
  add(query_593733, "Version", newJString(Version))
  result = call_593731.call(path_593732, query_593733, nil, nil, nil)

var getTagQueue* = Call_GetTagQueue_593710(name: "getTagQueue",
                                        meth: HttpMethod.HttpGet,
                                        host: "sqs.amazonaws.com", route: "/{AccountNumber}/{QueueName}/#Action=TagQueue",
                                        validator: validate_GetTagQueue_593711,
                                        base: "/", url: url_GetTagQueue_593712,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagQueue_593778 = ref object of OpenApiRestCall_592348
proc url_PostUntagQueue_593780(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagQueue_593779(path: JsonNode; query: JsonNode;
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
  var valid_593781 = path.getOrDefault("AccountNumber")
  valid_593781 = validateParameter(valid_593781, JInt, required = true, default = nil)
  if valid_593781 != nil:
    section.add "AccountNumber", valid_593781
  var valid_593782 = path.getOrDefault("QueueName")
  valid_593782 = validateParameter(valid_593782, JString, required = true,
                                 default = nil)
  if valid_593782 != nil:
    section.add "QueueName", valid_593782
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593783 = query.getOrDefault("Action")
  valid_593783 = validateParameter(valid_593783, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_593783 != nil:
    section.add "Action", valid_593783
  var valid_593784 = query.getOrDefault("Version")
  valid_593784 = validateParameter(valid_593784, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593784 != nil:
    section.add "Version", valid_593784
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
  var valid_593785 = header.getOrDefault("X-Amz-Signature")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "X-Amz-Signature", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-Content-Sha256", valid_593786
  var valid_593787 = header.getOrDefault("X-Amz-Date")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "X-Amz-Date", valid_593787
  var valid_593788 = header.getOrDefault("X-Amz-Credential")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "X-Amz-Credential", valid_593788
  var valid_593789 = header.getOrDefault("X-Amz-Security-Token")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "X-Amz-Security-Token", valid_593789
  var valid_593790 = header.getOrDefault("X-Amz-Algorithm")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "X-Amz-Algorithm", valid_593790
  var valid_593791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "X-Amz-SignedHeaders", valid_593791
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_593792 = formData.getOrDefault("TagKeys")
  valid_593792 = validateParameter(valid_593792, JArray, required = true, default = nil)
  if valid_593792 != nil:
    section.add "TagKeys", valid_593792
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593793: Call_PostUntagQueue_593778; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593793.validator(path, query, header, formData, body)
  let scheme = call_593793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593793.url(scheme.get, call_593793.host, call_593793.base,
                         call_593793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593793, url, valid)

proc call*(call_593794: Call_PostUntagQueue_593778; TagKeys: JsonNode;
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
  var path_593795 = newJObject()
  var query_593796 = newJObject()
  var formData_593797 = newJObject()
  if TagKeys != nil:
    formData_593797.add "TagKeys", TagKeys
  add(path_593795, "AccountNumber", newJInt(AccountNumber))
  add(path_593795, "QueueName", newJString(QueueName))
  add(query_593796, "Action", newJString(Action))
  add(query_593796, "Version", newJString(Version))
  result = call_593794.call(path_593795, query_593796, nil, formData_593797, nil)

var postUntagQueue* = Call_PostUntagQueue_593778(name: "postUntagQueue",
    meth: HttpMethod.HttpPost, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_PostUntagQueue_593779, base: "/", url: url_PostUntagQueue_593780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagQueue_593759 = ref object of OpenApiRestCall_592348
proc url_GetUntagQueue_593761(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagQueue_593760(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593762 = path.getOrDefault("AccountNumber")
  valid_593762 = validateParameter(valid_593762, JInt, required = true, default = nil)
  if valid_593762 != nil:
    section.add "AccountNumber", valid_593762
  var valid_593763 = path.getOrDefault("QueueName")
  valid_593763 = validateParameter(valid_593763, JString, required = true,
                                 default = nil)
  if valid_593763 != nil:
    section.add "QueueName", valid_593763
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tags to be removed from the specified queue.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_593764 = query.getOrDefault("TagKeys")
  valid_593764 = validateParameter(valid_593764, JArray, required = true, default = nil)
  if valid_593764 != nil:
    section.add "TagKeys", valid_593764
  var valid_593765 = query.getOrDefault("Action")
  valid_593765 = validateParameter(valid_593765, JString, required = true,
                                 default = newJString("UntagQueue"))
  if valid_593765 != nil:
    section.add "Action", valid_593765
  var valid_593766 = query.getOrDefault("Version")
  valid_593766 = validateParameter(valid_593766, JString, required = true,
                                 default = newJString("2012-11-05"))
  if valid_593766 != nil:
    section.add "Version", valid_593766
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
  var valid_593767 = header.getOrDefault("X-Amz-Signature")
  valid_593767 = validateParameter(valid_593767, JString, required = false,
                                 default = nil)
  if valid_593767 != nil:
    section.add "X-Amz-Signature", valid_593767
  var valid_593768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-Content-Sha256", valid_593768
  var valid_593769 = header.getOrDefault("X-Amz-Date")
  valid_593769 = validateParameter(valid_593769, JString, required = false,
                                 default = nil)
  if valid_593769 != nil:
    section.add "X-Amz-Date", valid_593769
  var valid_593770 = header.getOrDefault("X-Amz-Credential")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Credential", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Security-Token")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Security-Token", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Algorithm")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Algorithm", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-SignedHeaders", valid_593773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593774: Call_GetUntagQueue_593759; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Remove cost allocation tags from the specified Amazon SQS queue. For an overview, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-tags.html">Tagging Your Amazon SQS Queues</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> <note> <p>Cross-account permissions don't apply to this action. For more information, see <a href="https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-customer-managed-policy-examples.html#grant-cross-account-permissions-to-role-and-user-name">Grant Cross-Account Permissions to a Role and a User Name</a> in the <i>Amazon Simple Queue Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_593774.validator(path, query, header, formData, body)
  let scheme = call_593774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593774.url(scheme.get, call_593774.host, call_593774.base,
                         call_593774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593774, url, valid)

proc call*(call_593775: Call_GetUntagQueue_593759; AccountNumber: int;
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
  var path_593776 = newJObject()
  var query_593777 = newJObject()
  add(path_593776, "AccountNumber", newJInt(AccountNumber))
  add(path_593776, "QueueName", newJString(QueueName))
  if TagKeys != nil:
    query_593777.add "TagKeys", TagKeys
  add(query_593777, "Action", newJString(Action))
  add(query_593777, "Version", newJString(Version))
  result = call_593775.call(path_593776, query_593777, nil, nil, nil)

var getUntagQueue* = Call_GetUntagQueue_593759(name: "getUntagQueue",
    meth: HttpMethod.HttpGet, host: "sqs.amazonaws.com",
    route: "/{AccountNumber}/{QueueName}/#Action=UntagQueue",
    validator: validate_GetUntagQueue_593760, base: "/", url: url_GetUntagQueue_593761,
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
