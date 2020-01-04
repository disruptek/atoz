
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Secrets Manager
## version: 2017-10-17
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Secrets Manager API Reference</fullname> <p>AWS Secrets Manager is a web service that enables you to store, manage, and retrieve, secrets.</p> <p>This guide provides descriptions of the Secrets Manager API. For more information about using this service, see the <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/introduction.html">AWS Secrets Manager User Guide</a>.</p> <p> <b>API Version</b> </p> <p>This version of the Secrets Manager API Reference documents the Secrets Manager API version 2017-10-17.</p> <note> <p>As an alternative to using the API directly, you can use one of the AWS SDKs, which consist of libraries and sample code for various programming languages and platforms (such as Java, Ruby, .NET, iOS, and Android). The SDKs provide a convenient way to create programmatic access to AWS Secrets Manager. For example, the SDKs take care of cryptographically signing requests, managing errors, and retrying requests automatically. For more information about the AWS SDKs, including how to download and install them, see <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> </note> <p>We recommend that you use the AWS SDKs to make programmatic API calls to Secrets Manager. However, you also can use the Secrets Manager HTTP Query API to make direct calls to the Secrets Manager web service. To learn more about the Secrets Manager HTTP Query API, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/query-requests.html">Making Query Requests</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>Secrets Manager supports GET and POST requests for all actions. That is, the API doesn't require you to use GET for some actions and POST for others. However, GET requests are subject to the limitation size of a URL. Therefore, for operations that require larger sizes, use a POST request.</p> <p> <b>Support and Feedback for AWS Secrets Manager</b> </p> <p>We welcome your feedback. Send your comments to <a href="mailto:awssecretsmanager-feedback@amazon.com">awssecretsmanager-feedback@amazon.com</a>, or post your feedback and questions in the <a href="http://forums.aws.amazon.com/forum.jspa?forumID=296">AWS Secrets Manager Discussion Forum</a>. For more information about the AWS Discussion Forums, see <a href="http://forums.aws.amazon.com/help.jspa">Forums Help</a>.</p> <p> <b>How examples are presented</b> </p> <p>The JSON that AWS Secrets Manager expects as your request parameters and that the service returns as a response to HTTP query requests are single, long strings without line breaks or white space formatting. The JSON shown in the examples is formatted with both line breaks and white space to improve readability. When example input parameters would also result in long strings that extend beyond the screen, we insert line breaks to enhance readability. You should always submit the input as a single JSON text string.</p> <p> <b>Logging API Requests</b> </p> <p>AWS Secrets Manager supports AWS CloudTrail, a service that records AWS API calls for your AWS account and delivers log files to an Amazon S3 bucket. By using information that's collected by AWS CloudTrail, you can determine which requests were successfully made to Secrets Manager, who made the request, when it was made, and so on. For more about AWS Secrets Manager and its support for AWS CloudTrail, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/monitoring.html#monitoring_cloudtrail">Logging AWS Secrets Manager Events with AWS CloudTrail</a> in the <i>AWS Secrets Manager User Guide</i>. To learn more about CloudTrail, including how to turn it on and find your log files, see the <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/what_is_cloud_trail_top_level.html">AWS CloudTrail User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/secretsmanager/
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

  OpenApiRestCall_601390 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601390](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601390): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "secretsmanager.ap-northeast-1.amazonaws.com", "ap-southeast-1": "secretsmanager.ap-southeast-1.amazonaws.com", "us-west-2": "secretsmanager.us-west-2.amazonaws.com", "eu-west-2": "secretsmanager.eu-west-2.amazonaws.com", "ap-northeast-3": "secretsmanager.ap-northeast-3.amazonaws.com", "eu-central-1": "secretsmanager.eu-central-1.amazonaws.com", "us-east-2": "secretsmanager.us-east-2.amazonaws.com", "us-east-1": "secretsmanager.us-east-1.amazonaws.com", "cn-northwest-1": "secretsmanager.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "secretsmanager.ap-south-1.amazonaws.com", "eu-north-1": "secretsmanager.eu-north-1.amazonaws.com", "ap-northeast-2": "secretsmanager.ap-northeast-2.amazonaws.com", "us-west-1": "secretsmanager.us-west-1.amazonaws.com", "us-gov-east-1": "secretsmanager.us-gov-east-1.amazonaws.com", "eu-west-3": "secretsmanager.eu-west-3.amazonaws.com", "cn-north-1": "secretsmanager.cn-north-1.amazonaws.com.cn", "sa-east-1": "secretsmanager.sa-east-1.amazonaws.com", "eu-west-1": "secretsmanager.eu-west-1.amazonaws.com", "us-gov-west-1": "secretsmanager.us-gov-west-1.amazonaws.com", "ap-southeast-2": "secretsmanager.ap-southeast-2.amazonaws.com", "ca-central-1": "secretsmanager.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "secretsmanager.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "secretsmanager.ap-southeast-1.amazonaws.com",
      "us-west-2": "secretsmanager.us-west-2.amazonaws.com",
      "eu-west-2": "secretsmanager.eu-west-2.amazonaws.com",
      "ap-northeast-3": "secretsmanager.ap-northeast-3.amazonaws.com",
      "eu-central-1": "secretsmanager.eu-central-1.amazonaws.com",
      "us-east-2": "secretsmanager.us-east-2.amazonaws.com",
      "us-east-1": "secretsmanager.us-east-1.amazonaws.com",
      "cn-northwest-1": "secretsmanager.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "secretsmanager.ap-south-1.amazonaws.com",
      "eu-north-1": "secretsmanager.eu-north-1.amazonaws.com",
      "ap-northeast-2": "secretsmanager.ap-northeast-2.amazonaws.com",
      "us-west-1": "secretsmanager.us-west-1.amazonaws.com",
      "us-gov-east-1": "secretsmanager.us-gov-east-1.amazonaws.com",
      "eu-west-3": "secretsmanager.eu-west-3.amazonaws.com",
      "cn-north-1": "secretsmanager.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "secretsmanager.sa-east-1.amazonaws.com",
      "eu-west-1": "secretsmanager.eu-west-1.amazonaws.com",
      "us-gov-west-1": "secretsmanager.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "secretsmanager.ap-southeast-2.amazonaws.com",
      "ca-central-1": "secretsmanager.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "secretsmanager"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelRotateSecret_601728 = ref object of OpenApiRestCall_601390
proc url_CancelRotateSecret_601730(protocol: Scheme; host: string; base: string;
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

proc validate_CancelRotateSecret_601729(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Disables automatic scheduled rotation and cancels the rotation of a secret if one is currently in progress.</p> <p>To re-enable scheduled rotation, call <a>RotateSecret</a> with <code>AutomaticallyRotateAfterDays</code> set to a value greater than 0. This will immediately rotate your secret and then enable the automatic schedule.</p> <note> <p>If you cancel a rotation that is in progress, it can leave the <code>VersionStage</code> labels in an unexpected state. Depending on what step of the rotation was in progress, you might need to remove the staging label <code>AWSPENDING</code> from the partially created version, specified by the <code>VersionId</code> response value. You should also evaluate the partially rotated new version to see if it should be deleted, which you can do by removing all staging labels from the new version's <code>VersionStage</code> field.</p> </note> <p>To successfully start a rotation, the staging label <code>AWSPENDING</code> must be in one of the following states:</p> <ul> <li> <p>Not be attached to any version at all</p> </li> <li> <p>Attached to the same version as the staging label <code>AWSCURRENT</code> </p> </li> </ul> <p>If the staging label <code>AWSPENDING</code> is attached to a different version than the version with <code>AWSCURRENT</code> then the attempt to rotate fails.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CancelRotateSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To configure rotation for a secret or to manually trigger a rotation, use <a>RotateSecret</a>.</p> </li> <li> <p>To get the rotation configuration details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> <li> <p>To list all of the versions currently associated with a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
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
  var valid_601855 = header.getOrDefault("X-Amz-Target")
  valid_601855 = validateParameter(valid_601855, JString, required = true, default = newJString(
      "secretsmanager.CancelRotateSecret"))
  if valid_601855 != nil:
    section.add "X-Amz-Target", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_CancelRotateSecret_601728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables automatic scheduled rotation and cancels the rotation of a secret if one is currently in progress.</p> <p>To re-enable scheduled rotation, call <a>RotateSecret</a> with <code>AutomaticallyRotateAfterDays</code> set to a value greater than 0. This will immediately rotate your secret and then enable the automatic schedule.</p> <note> <p>If you cancel a rotation that is in progress, it can leave the <code>VersionStage</code> labels in an unexpected state. Depending on what step of the rotation was in progress, you might need to remove the staging label <code>AWSPENDING</code> from the partially created version, specified by the <code>VersionId</code> response value. You should also evaluate the partially rotated new version to see if it should be deleted, which you can do by removing all staging labels from the new version's <code>VersionStage</code> field.</p> </note> <p>To successfully start a rotation, the staging label <code>AWSPENDING</code> must be in one of the following states:</p> <ul> <li> <p>Not be attached to any version at all</p> </li> <li> <p>Attached to the same version as the staging label <code>AWSCURRENT</code> </p> </li> </ul> <p>If the staging label <code>AWSPENDING</code> is attached to a different version than the version with <code>AWSCURRENT</code> then the attempt to rotate fails.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CancelRotateSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To configure rotation for a secret or to manually trigger a rotation, use <a>RotateSecret</a>.</p> </li> <li> <p>To get the rotation configuration details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> <li> <p>To list all of the versions currently associated with a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_CancelRotateSecret_601728; body: JsonNode): Recallable =
  ## cancelRotateSecret
  ## <p>Disables automatic scheduled rotation and cancels the rotation of a secret if one is currently in progress.</p> <p>To re-enable scheduled rotation, call <a>RotateSecret</a> with <code>AutomaticallyRotateAfterDays</code> set to a value greater than 0. This will immediately rotate your secret and then enable the automatic schedule.</p> <note> <p>If you cancel a rotation that is in progress, it can leave the <code>VersionStage</code> labels in an unexpected state. Depending on what step of the rotation was in progress, you might need to remove the staging label <code>AWSPENDING</code> from the partially created version, specified by the <code>VersionId</code> response value. You should also evaluate the partially rotated new version to see if it should be deleted, which you can do by removing all staging labels from the new version's <code>VersionStage</code> field.</p> </note> <p>To successfully start a rotation, the staging label <code>AWSPENDING</code> must be in one of the following states:</p> <ul> <li> <p>Not be attached to any version at all</p> </li> <li> <p>Attached to the same version as the staging label <code>AWSCURRENT</code> </p> </li> </ul> <p>If the staging label <code>AWSPENDING</code> is attached to a different version than the version with <code>AWSCURRENT</code> then the attempt to rotate fails.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CancelRotateSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To configure rotation for a secret or to manually trigger a rotation, use <a>RotateSecret</a>.</p> </li> <li> <p>To get the rotation configuration details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> <li> <p>To list all of the versions currently associated with a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601958 = newJObject()
  if body != nil:
    body_601958 = body
  result = call_601957.call(nil, nil, nil, nil, body_601958)

var cancelRotateSecret* = Call_CancelRotateSecret_601728(
    name: "cancelRotateSecret", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.CancelRotateSecret",
    validator: validate_CancelRotateSecret_601729, base: "/",
    url: url_CancelRotateSecret_601730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecret_601997 = ref object of OpenApiRestCall_601390
proc url_CreateSecret_601999(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSecret_601998(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new secret. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret.</p> <p>Secrets Manager stores the encrypted secret data in one of a collection of "versions" associated with the secret. Each version contains a copy of the encrypted secret data. Each version is associated with one or more "staging labels" that identify where the version is in the rotation cycle. The <code>SecretVersionsToStages</code> field of the secret contains the mapping of staging labels to the active versions of the secret. Versions without a staging label are considered deprecated and are not included in the list.</p> <p>You provide the secret data to be encrypted by putting text in either the <code>SecretString</code> parameter or binary data in the <code>SecretBinary</code> parameter, but not both. If you include <code>SecretString</code> or <code>SecretBinary</code> then Secrets Manager also creates an initial secret version and automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CreateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>secretsmanager:TagResource - needed only if you include the <code>Tags</code> parameter. </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> <li> <p>To modify an existing secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the encrypted secure string and secure binary values, use <a>GetSecretValue</a>.</p> </li> <li> <p>To retrieve all other details for a secret, use <a>DescribeSecret</a>. This does not include the encrypted secure string and secure binary values.</p> </li> <li> <p>To retrieve the list of secret versions associated with the current secret, use <a>DescribeSecret</a> and examine the <code>SecretVersionsToStages</code> response value.</p> </li> </ul>
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
  var valid_602000 = header.getOrDefault("X-Amz-Target")
  valid_602000 = validateParameter(valid_602000, JString, required = true, default = newJString(
      "secretsmanager.CreateSecret"))
  if valid_602000 != nil:
    section.add "X-Amz-Target", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_CreateSecret_601997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new secret. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret.</p> <p>Secrets Manager stores the encrypted secret data in one of a collection of "versions" associated with the secret. Each version contains a copy of the encrypted secret data. Each version is associated with one or more "staging labels" that identify where the version is in the rotation cycle. The <code>SecretVersionsToStages</code> field of the secret contains the mapping of staging labels to the active versions of the secret. Versions without a staging label are considered deprecated and are not included in the list.</p> <p>You provide the secret data to be encrypted by putting text in either the <code>SecretString</code> parameter or binary data in the <code>SecretBinary</code> parameter, but not both. If you include <code>SecretString</code> or <code>SecretBinary</code> then Secrets Manager also creates an initial secret version and automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CreateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>secretsmanager:TagResource - needed only if you include the <code>Tags</code> parameter. </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> <li> <p>To modify an existing secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the encrypted secure string and secure binary values, use <a>GetSecretValue</a>.</p> </li> <li> <p>To retrieve all other details for a secret, use <a>DescribeSecret</a>. This does not include the encrypted secure string and secure binary values.</p> </li> <li> <p>To retrieve the list of secret versions associated with the current secret, use <a>DescribeSecret</a> and examine the <code>SecretVersionsToStages</code> response value.</p> </li> </ul>
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_CreateSecret_601997; body: JsonNode): Recallable =
  ## createSecret
  ## <p>Creates a new secret. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret.</p> <p>Secrets Manager stores the encrypted secret data in one of a collection of "versions" associated with the secret. Each version contains a copy of the encrypted secret data. Each version is associated with one or more "staging labels" that identify where the version is in the rotation cycle. The <code>SecretVersionsToStages</code> field of the secret contains the mapping of staging labels to the active versions of the secret. Versions without a staging label are considered deprecated and are not included in the list.</p> <p>You provide the secret data to be encrypted by putting text in either the <code>SecretString</code> parameter or binary data in the <code>SecretBinary</code> parameter, but not both. If you include <code>SecretString</code> or <code>SecretBinary</code> then Secrets Manager also creates an initial secret version and automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CreateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>secretsmanager:TagResource - needed only if you include the <code>Tags</code> parameter. </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> <li> <p>To modify an existing secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the encrypted secure string and secure binary values, use <a>GetSecretValue</a>.</p> </li> <li> <p>To retrieve all other details for a secret, use <a>DescribeSecret</a>. This does not include the encrypted secure string and secure binary values.</p> </li> <li> <p>To retrieve the list of secret versions associated with the current secret, use <a>DescribeSecret</a> and examine the <code>SecretVersionsToStages</code> response value.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602011 = newJObject()
  if body != nil:
    body_602011 = body
  result = call_602010.call(nil, nil, nil, nil, body_602011)

var createSecret* = Call_CreateSecret_601997(name: "createSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.CreateSecret",
    validator: validate_CreateSecret_601998, base: "/", url: url_CreateSecret_601999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_602012 = ref object of OpenApiRestCall_601390
proc url_DeleteResourcePolicy_602014(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourcePolicy_602013(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the resource-based permission policy that's attached to the secret.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To retrieve the current resource-based policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
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
  var valid_602015 = header.getOrDefault("X-Amz-Target")
  valid_602015 = validateParameter(valid_602015, JString, required = true, default = newJString(
      "secretsmanager.DeleteResourcePolicy"))
  if valid_602015 != nil:
    section.add "X-Amz-Target", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_DeleteResourcePolicy_602012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the resource-based permission policy that's attached to the secret.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To retrieve the current resource-based policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_DeleteResourcePolicy_602012; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## <p>Deletes the resource-based permission policy that's attached to the secret.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To retrieve the current resource-based policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602026 = newJObject()
  if body != nil:
    body_602026 = body
  result = call_602025.call(nil, nil, nil, nil, body_602026)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_602012(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_602013, base: "/",
    url: url_DeleteResourcePolicy_602014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecret_602027 = ref object of OpenApiRestCall_601390
proc url_DeleteSecret_602029(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSecret_602028(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an entire secret and all of its versions. You can optionally include a recovery window during which you can restore the secret. If you don't specify a recovery window value, the operation defaults to 30 days. Secrets Manager attaches a <code>DeletionDate</code> stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently.</p> <p>At any time before recovery window ends, you can use <a>RestoreSecret</a> to remove the <code>DeletionDate</code> and cancel the deletion of the secret.</p> <p>You cannot access the encrypted secret information in any secret that is scheduled for deletion. If you need to access that information, you must cancel the deletion with <a>RestoreSecret</a> and then retrieve the information.</p> <note> <ul> <li> <p>There is no explicit operation to delete a version of a secret. Instead, remove all staging labels from the <code>VersionStage</code> field of a version. That marks the version as deprecated and allows Secrets Manager to delete it as needed. Versions that do not have any staging labels do not show up in <a>ListSecretVersionIds</a> unless you specify <code>IncludeDeprecated</code>.</p> </li> <li> <p>The permanent secret deletion at the end of the waiting period is performed as a background task with low priority. There is no guarantee of a specific time after the recovery window for the actual delete operation to occur.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To cancel deletion of a version of a secret before the recovery window has expired, use <a>RestoreSecret</a>.</p> </li> </ul>
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
  var valid_602030 = header.getOrDefault("X-Amz-Target")
  valid_602030 = validateParameter(valid_602030, JString, required = true, default = newJString(
      "secretsmanager.DeleteSecret"))
  if valid_602030 != nil:
    section.add "X-Amz-Target", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Signature", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Content-Sha256", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Algorithm")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Algorithm", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-SignedHeaders", valid_602037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_DeleteSecret_602027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an entire secret and all of its versions. You can optionally include a recovery window during which you can restore the secret. If you don't specify a recovery window value, the operation defaults to 30 days. Secrets Manager attaches a <code>DeletionDate</code> stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently.</p> <p>At any time before recovery window ends, you can use <a>RestoreSecret</a> to remove the <code>DeletionDate</code> and cancel the deletion of the secret.</p> <p>You cannot access the encrypted secret information in any secret that is scheduled for deletion. If you need to access that information, you must cancel the deletion with <a>RestoreSecret</a> and then retrieve the information.</p> <note> <ul> <li> <p>There is no explicit operation to delete a version of a secret. Instead, remove all staging labels from the <code>VersionStage</code> field of a version. That marks the version as deprecated and allows Secrets Manager to delete it as needed. Versions that do not have any staging labels do not show up in <a>ListSecretVersionIds</a> unless you specify <code>IncludeDeprecated</code>.</p> </li> <li> <p>The permanent secret deletion at the end of the waiting period is performed as a background task with low priority. There is no guarantee of a specific time after the recovery window for the actual delete operation to occur.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To cancel deletion of a version of a secret before the recovery window has expired, use <a>RestoreSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_DeleteSecret_602027; body: JsonNode): Recallable =
  ## deleteSecret
  ## <p>Deletes an entire secret and all of its versions. You can optionally include a recovery window during which you can restore the secret. If you don't specify a recovery window value, the operation defaults to 30 days. Secrets Manager attaches a <code>DeletionDate</code> stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently.</p> <p>At any time before recovery window ends, you can use <a>RestoreSecret</a> to remove the <code>DeletionDate</code> and cancel the deletion of the secret.</p> <p>You cannot access the encrypted secret information in any secret that is scheduled for deletion. If you need to access that information, you must cancel the deletion with <a>RestoreSecret</a> and then retrieve the information.</p> <note> <ul> <li> <p>There is no explicit operation to delete a version of a secret. Instead, remove all staging labels from the <code>VersionStage</code> field of a version. That marks the version as deprecated and allows Secrets Manager to delete it as needed. Versions that do not have any staging labels do not show up in <a>ListSecretVersionIds</a> unless you specify <code>IncludeDeprecated</code>.</p> </li> <li> <p>The permanent secret deletion at the end of the waiting period is performed as a background task with low priority. There is no guarantee of a specific time after the recovery window for the actual delete operation to occur.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To cancel deletion of a version of a secret before the recovery window has expired, use <a>RestoreSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602041 = newJObject()
  if body != nil:
    body_602041 = body
  result = call_602040.call(nil, nil, nil, nil, body_602041)

var deleteSecret* = Call_DeleteSecret_602027(name: "deleteSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DeleteSecret",
    validator: validate_DeleteSecret_602028, base: "/", url: url_DeleteSecret_602029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSecret_602042 = ref object of OpenApiRestCall_601390
proc url_DescribeSecret_602044(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSecret_602043(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves the details of a secret. It does not include the encrypted fields. Only those fields that are populated with a value are returned in the response. </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DescribeSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To modify a secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To retrieve the encrypted secret information in a version of the secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To list all of the secrets in the AWS account, use <a>ListSecrets</a>.</p> </li> </ul>
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
  var valid_602045 = header.getOrDefault("X-Amz-Target")
  valid_602045 = validateParameter(valid_602045, JString, required = true, default = newJString(
      "secretsmanager.DescribeSecret"))
  if valid_602045 != nil:
    section.add "X-Amz-Target", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Algorithm")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Algorithm", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_DescribeSecret_602042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the details of a secret. It does not include the encrypted fields. Only those fields that are populated with a value are returned in the response. </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DescribeSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To modify a secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To retrieve the encrypted secret information in a version of the secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To list all of the secrets in the AWS account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_DescribeSecret_602042; body: JsonNode): Recallable =
  ## describeSecret
  ## <p>Retrieves the details of a secret. It does not include the encrypted fields. Only those fields that are populated with a value are returned in the response. </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DescribeSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To modify a secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To retrieve the encrypted secret information in a version of the secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To list all of the secrets in the AWS account, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602056 = newJObject()
  if body != nil:
    body_602056 = body
  result = call_602055.call(nil, nil, nil, nil, body_602056)

var describeSecret* = Call_DescribeSecret_602042(name: "describeSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DescribeSecret",
    validator: validate_DescribeSecret_602043, base: "/", url: url_DescribeSecret_602044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRandomPassword_602057 = ref object of OpenApiRestCall_601390
proc url_GetRandomPassword_602059(protocol: Scheme; host: string; base: string;
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

proc validate_GetRandomPassword_602058(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Generates a random password of the specified complexity. This operation is intended for use in the Lambda rotation function. Per best practice, we recommend that you specify the maximum length and include every character type that the system you are generating a password for can support.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetRandomPassword</p> </li> </ul>
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
  var valid_602060 = header.getOrDefault("X-Amz-Target")
  valid_602060 = validateParameter(valid_602060, JString, required = true, default = newJString(
      "secretsmanager.GetRandomPassword"))
  if valid_602060 != nil:
    section.add "X-Amz-Target", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602069: Call_GetRandomPassword_602057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a random password of the specified complexity. This operation is intended for use in the Lambda rotation function. Per best practice, we recommend that you specify the maximum length and include every character type that the system you are generating a password for can support.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetRandomPassword</p> </li> </ul>
  ## 
  let valid = call_602069.validator(path, query, header, formData, body)
  let scheme = call_602069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602069.url(scheme.get, call_602069.host, call_602069.base,
                         call_602069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602069, url, valid)

proc call*(call_602070: Call_GetRandomPassword_602057; body: JsonNode): Recallable =
  ## getRandomPassword
  ## <p>Generates a random password of the specified complexity. This operation is intended for use in the Lambda rotation function. Per best practice, we recommend that you specify the maximum length and include every character type that the system you are generating a password for can support.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetRandomPassword</p> </li> </ul>
  ##   body: JObject (required)
  var body_602071 = newJObject()
  if body != nil:
    body_602071 = body
  result = call_602070.call(nil, nil, nil, nil, body_602071)

var getRandomPassword* = Call_GetRandomPassword_602057(name: "getRandomPassword",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetRandomPassword",
    validator: validate_GetRandomPassword_602058, base: "/",
    url: url_GetRandomPassword_602059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_602072 = ref object of OpenApiRestCall_601390
proc url_GetResourcePolicy_602074(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicy_602073(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves the JSON text of the resource-based policy document that's attached to the specified secret. The JSON request string input and response output are shown formatted with white space and line breaks for better readability. Submit your input as a single line JSON string.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
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
  var valid_602075 = header.getOrDefault("X-Amz-Target")
  valid_602075 = validateParameter(valid_602075, JString, required = true, default = newJString(
      "secretsmanager.GetResourcePolicy"))
  if valid_602075 != nil:
    section.add "X-Amz-Target", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Signature")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Signature", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Content-Sha256", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Date")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Date", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Credential")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Credential", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Security-Token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Security-Token", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Algorithm")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Algorithm", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-SignedHeaders", valid_602082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602084: Call_GetResourcePolicy_602072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the JSON text of the resource-based policy document that's attached to the specified secret. The JSON request string input and response output are shown formatted with white space and line breaks for better readability. Submit your input as a single line JSON string.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_602084.validator(path, query, header, formData, body)
  let scheme = call_602084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602084.url(scheme.get, call_602084.host, call_602084.base,
                         call_602084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602084, url, valid)

proc call*(call_602085: Call_GetResourcePolicy_602072; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## <p>Retrieves the JSON text of the resource-based policy document that's attached to the specified secret. The JSON request string input and response output are shown formatted with white space and line breaks for better readability. Submit your input as a single line JSON string.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602086 = newJObject()
  if body != nil:
    body_602086 = body
  result = call_602085.call(nil, nil, nil, nil, body_602086)

var getResourcePolicy* = Call_GetResourcePolicy_602072(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetResourcePolicy",
    validator: validate_GetResourcePolicy_602073, base: "/",
    url: url_GetResourcePolicy_602074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecretValue_602087 = ref object of OpenApiRestCall_601390
proc url_GetSecretValue_602089(protocol: Scheme; host: string; base: string;
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

proc validate_GetSecretValue_602088(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves the contents of the encrypted fields <code>SecretString</code> or <code>SecretBinary</code> from the specified version of a secret, whichever contains content.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetSecretValue</p> </li> <li> <p>kms:Decrypt - required only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new version of the secret with different encrypted information, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the non-encrypted details for the secret, use <a>DescribeSecret</a>.</p> </li> </ul>
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
  var valid_602090 = header.getOrDefault("X-Amz-Target")
  valid_602090 = validateParameter(valid_602090, JString, required = true, default = newJString(
      "secretsmanager.GetSecretValue"))
  if valid_602090 != nil:
    section.add "X-Amz-Target", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Signature")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Signature", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Content-Sha256", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Date")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Date", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Credential")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Credential", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Security-Token")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Security-Token", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Algorithm")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Algorithm", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-SignedHeaders", valid_602097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_GetSecretValue_602087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the contents of the encrypted fields <code>SecretString</code> or <code>SecretBinary</code> from the specified version of a secret, whichever contains content.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetSecretValue</p> </li> <li> <p>kms:Decrypt - required only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new version of the secret with different encrypted information, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the non-encrypted details for the secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602099, url, valid)

proc call*(call_602100: Call_GetSecretValue_602087; body: JsonNode): Recallable =
  ## getSecretValue
  ## <p>Retrieves the contents of the encrypted fields <code>SecretString</code> or <code>SecretBinary</code> from the specified version of a secret, whichever contains content.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetSecretValue</p> </li> <li> <p>kms:Decrypt - required only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new version of the secret with different encrypted information, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the non-encrypted details for the secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602101 = newJObject()
  if body != nil:
    body_602101 = body
  result = call_602100.call(nil, nil, nil, nil, body_602101)

var getSecretValue* = Call_GetSecretValue_602087(name: "getSecretValue",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetSecretValue",
    validator: validate_GetSecretValue_602088, base: "/", url: url_GetSecretValue_602089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecretVersionIds_602102 = ref object of OpenApiRestCall_601390
proc url_ListSecretVersionIds_602104(protocol: Scheme; host: string; base: string;
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

proc validate_ListSecretVersionIds_602103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602105 = query.getOrDefault("MaxResults")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "MaxResults", valid_602105
  var valid_602106 = query.getOrDefault("NextToken")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "NextToken", valid_602106
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
  var valid_602107 = header.getOrDefault("X-Amz-Target")
  valid_602107 = validateParameter(valid_602107, JString, required = true, default = newJString(
      "secretsmanager.ListSecretVersionIds"))
  if valid_602107 != nil:
    section.add "X-Amz-Target", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Signature")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Signature", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Date")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Date", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Credential")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Credential", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Security-Token")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Security-Token", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Algorithm")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Algorithm", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_ListSecretVersionIds_602102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602116, url, valid)

proc call*(call_602117: Call_ListSecretVersionIds_602102; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSecretVersionIds
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602118 = newJObject()
  var body_602119 = newJObject()
  add(query_602118, "MaxResults", newJString(MaxResults))
  add(query_602118, "NextToken", newJString(NextToken))
  if body != nil:
    body_602119 = body
  result = call_602117.call(nil, query_602118, nil, nil, body_602119)

var listSecretVersionIds* = Call_ListSecretVersionIds_602102(
    name: "listSecretVersionIds", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.ListSecretVersionIds",
    validator: validate_ListSecretVersionIds_602103, base: "/",
    url: url_ListSecretVersionIds_602104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecrets_602121 = ref object of OpenApiRestCall_601390
proc url_ListSecrets_602123(protocol: Scheme; host: string; base: string;
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

proc validate_ListSecrets_602122(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602124 = query.getOrDefault("MaxResults")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "MaxResults", valid_602124
  var valid_602125 = query.getOrDefault("NextToken")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "NextToken", valid_602125
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
      "secretsmanager.ListSecrets"))
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

proc call*(call_602135: Call_ListSecrets_602121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_602135.validator(path, query, header, formData, body)
  let scheme = call_602135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602135.url(scheme.get, call_602135.host, call_602135.base,
                         call_602135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602135, url, valid)

proc call*(call_602136: Call_ListSecrets_602121; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSecrets
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602137 = newJObject()
  var body_602138 = newJObject()
  add(query_602137, "MaxResults", newJString(MaxResults))
  add(query_602137, "NextToken", newJString(NextToken))
  if body != nil:
    body_602138 = body
  result = call_602136.call(nil, query_602137, nil, nil, body_602138)

var listSecrets* = Call_ListSecrets_602121(name: "listSecrets",
                                        meth: HttpMethod.HttpPost,
                                        host: "secretsmanager.amazonaws.com", route: "/#X-Amz-Target=secretsmanager.ListSecrets",
                                        validator: validate_ListSecrets_602122,
                                        base: "/", url: url_ListSecrets_602123,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_602139 = ref object of OpenApiRestCall_601390
proc url_PutResourcePolicy_602141(protocol: Scheme; host: string; base: string;
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

proc validate_PutResourcePolicy_602140(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Attaches the contents of the specified resource-based permission policy to a secret. A resource-based policy is optional. Alternatively, you can use IAM identity-based policies that specify the secret's Amazon Resource Name (ARN) in the policy statement's <code>Resources</code> element. You can also use a combination of both identity-based and resource-based policies. The affected users and roles receive the permissions that are permitted by all of the relevant policies. For more information, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html">Using Resource-Based Policies for AWS Secrets Manager</a>. For the complete description of the AWS policy syntax and grammar, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html">IAM JSON Policy Reference</a> in the <i>IAM User Guide</i>.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the resource policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
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
  var valid_602142 = header.getOrDefault("X-Amz-Target")
  valid_602142 = validateParameter(valid_602142, JString, required = true, default = newJString(
      "secretsmanager.PutResourcePolicy"))
  if valid_602142 != nil:
    section.add "X-Amz-Target", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Signature")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Signature", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Content-Sha256", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Date")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Date", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Credential")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Credential", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Security-Token")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Security-Token", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Algorithm")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Algorithm", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-SignedHeaders", valid_602149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602151: Call_PutResourcePolicy_602139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches the contents of the specified resource-based permission policy to a secret. A resource-based policy is optional. Alternatively, you can use IAM identity-based policies that specify the secret's Amazon Resource Name (ARN) in the policy statement's <code>Resources</code> element. You can also use a combination of both identity-based and resource-based policies. The affected users and roles receive the permissions that are permitted by all of the relevant policies. For more information, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html">Using Resource-Based Policies for AWS Secrets Manager</a>. For the complete description of the AWS policy syntax and grammar, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html">IAM JSON Policy Reference</a> in the <i>IAM User Guide</i>.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the resource policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_602151.validator(path, query, header, formData, body)
  let scheme = call_602151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602151.url(scheme.get, call_602151.host, call_602151.base,
                         call_602151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602151, url, valid)

proc call*(call_602152: Call_PutResourcePolicy_602139; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## <p>Attaches the contents of the specified resource-based permission policy to a secret. A resource-based policy is optional. Alternatively, you can use IAM identity-based policies that specify the secret's Amazon Resource Name (ARN) in the policy statement's <code>Resources</code> element. You can also use a combination of both identity-based and resource-based policies. The affected users and roles receive the permissions that are permitted by all of the relevant policies. For more information, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html">Using Resource-Based Policies for AWS Secrets Manager</a>. For the complete description of the AWS policy syntax and grammar, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html">IAM JSON Policy Reference</a> in the <i>IAM User Guide</i>.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the resource policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602153 = newJObject()
  if body != nil:
    body_602153 = body
  result = call_602152.call(nil, nil, nil, nil, body_602153)

var putResourcePolicy* = Call_PutResourcePolicy_602139(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.PutResourcePolicy",
    validator: validate_PutResourcePolicy_602140, base: "/",
    url: url_PutResourcePolicy_602141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSecretValue_602154 = ref object of OpenApiRestCall_601390
proc url_PutSecretValue_602156(protocol: Scheme; host: string; base: string;
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

proc validate_PutSecretValue_602155(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Stores a new encrypted secret value in the specified secret. To do this, the operation creates a new version and attaches it to the secret. The version can contain a new <code>SecretString</code> value or a new <code>SecretBinary</code> value. You can also specify the staging labels that are initially attached to the new version.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> field. To add binary data to a secret with the <code>SecretBinary</code> field you must use the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If this operation creates the first version for the secret then Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> </li> <li> <p>If another version of this secret already exists, then this operation does not automatically move any staging labels other than those that you explicitly specify in the <code>VersionStages</code> parameter.</p> </li> <li> <p>If this operation moves the staging label <code>AWSCURRENT</code> from another version to this version (because you included it in the <code>StagingLabels</code> parameter) then Secrets Manager also automatically moves the staging label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </li> <li> <p>This operation is idempotent. If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you cannot modify an existing version; you can only create new ones.</p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutSecretValue</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the encrypted value you store in the version of a secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
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
  var valid_602157 = header.getOrDefault("X-Amz-Target")
  valid_602157 = validateParameter(valid_602157, JString, required = true, default = newJString(
      "secretsmanager.PutSecretValue"))
  if valid_602157 != nil:
    section.add "X-Amz-Target", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Signature")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Signature", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Date")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Date", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Credential")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Credential", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Security-Token")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Security-Token", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Algorithm")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Algorithm", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-SignedHeaders", valid_602164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602166: Call_PutSecretValue_602154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stores a new encrypted secret value in the specified secret. To do this, the operation creates a new version and attaches it to the secret. The version can contain a new <code>SecretString</code> value or a new <code>SecretBinary</code> value. You can also specify the staging labels that are initially attached to the new version.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> field. To add binary data to a secret with the <code>SecretBinary</code> field you must use the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If this operation creates the first version for the secret then Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> </li> <li> <p>If another version of this secret already exists, then this operation does not automatically move any staging labels other than those that you explicitly specify in the <code>VersionStages</code> parameter.</p> </li> <li> <p>If this operation moves the staging label <code>AWSCURRENT</code> from another version to this version (because you included it in the <code>StagingLabels</code> parameter) then Secrets Manager also automatically moves the staging label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </li> <li> <p>This operation is idempotent. If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you cannot modify an existing version; you can only create new ones.</p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutSecretValue</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the encrypted value you store in the version of a secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_602166.validator(path, query, header, formData, body)
  let scheme = call_602166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602166.url(scheme.get, call_602166.host, call_602166.base,
                         call_602166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602166, url, valid)

proc call*(call_602167: Call_PutSecretValue_602154; body: JsonNode): Recallable =
  ## putSecretValue
  ## <p>Stores a new encrypted secret value in the specified secret. To do this, the operation creates a new version and attaches it to the secret. The version can contain a new <code>SecretString</code> value or a new <code>SecretBinary</code> value. You can also specify the staging labels that are initially attached to the new version.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> field. To add binary data to a secret with the <code>SecretBinary</code> field you must use the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If this operation creates the first version for the secret then Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> </li> <li> <p>If another version of this secret already exists, then this operation does not automatically move any staging labels other than those that you explicitly specify in the <code>VersionStages</code> parameter.</p> </li> <li> <p>If this operation moves the staging label <code>AWSCURRENT</code> from another version to this version (because you included it in the <code>StagingLabels</code> parameter) then Secrets Manager also automatically moves the staging label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </li> <li> <p>This operation is idempotent. If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you cannot modify an existing version; you can only create new ones.</p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutSecretValue</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the encrypted value you store in the version of a secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602168 = newJObject()
  if body != nil:
    body_602168 = body
  result = call_602167.call(nil, nil, nil, nil, body_602168)

var putSecretValue* = Call_PutSecretValue_602154(name: "putSecretValue",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.PutSecretValue",
    validator: validate_PutSecretValue_602155, base: "/", url: url_PutSecretValue_602156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreSecret_602169 = ref object of OpenApiRestCall_601390
proc url_RestoreSecret_602171(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreSecret_602170(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Cancels the scheduled deletion of a secret by removing the <code>DeletedDate</code> time stamp. This makes the secret accessible to query once again.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RestoreSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> </ul>
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
  var valid_602172 = header.getOrDefault("X-Amz-Target")
  valid_602172 = validateParameter(valid_602172, JString, required = true, default = newJString(
      "secretsmanager.RestoreSecret"))
  if valid_602172 != nil:
    section.add "X-Amz-Target", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Signature")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Signature", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Content-Sha256", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Date")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Date", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Credential")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Credential", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Security-Token")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Security-Token", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Algorithm")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Algorithm", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-SignedHeaders", valid_602179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602181: Call_RestoreSecret_602169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the scheduled deletion of a secret by removing the <code>DeletedDate</code> time stamp. This makes the secret accessible to query once again.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RestoreSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_602181.validator(path, query, header, formData, body)
  let scheme = call_602181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602181.url(scheme.get, call_602181.host, call_602181.base,
                         call_602181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602181, url, valid)

proc call*(call_602182: Call_RestoreSecret_602169; body: JsonNode): Recallable =
  ## restoreSecret
  ## <p>Cancels the scheduled deletion of a secret by removing the <code>DeletedDate</code> time stamp. This makes the secret accessible to query once again.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RestoreSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602183 = newJObject()
  if body != nil:
    body_602183 = body
  result = call_602182.call(nil, nil, nil, nil, body_602183)

var restoreSecret* = Call_RestoreSecret_602169(name: "restoreSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.RestoreSecret",
    validator: validate_RestoreSecret_602170, base: "/", url: url_RestoreSecret_602171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateSecret_602184 = ref object of OpenApiRestCall_601390
proc url_RotateSecret_602186(protocol: Scheme; host: string; base: string;
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

proc validate_RotateSecret_602185(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Configures and starts the asynchronous process of rotating this secret. If you include the configuration parameters, the operation sets those values for the secret and then immediately starts a rotation. If you do not include the configuration parameters, the operation starts a rotation with the values already stored in the secret. After the rotation completes, the protected service and its clients all use the new version of the secret. </p> <p>This required configuration information includes the ARN of an AWS Lambda function and the time between scheduled rotations. The Lambda rotation function creates a new version of the secret and creates or updates the credentials on the protected service to match. After testing the new credentials, the function marks the new secret with the staging label <code>AWSCURRENT</code> so that your clients all immediately begin to use the new version. For more information about rotating secrets and how to configure a Lambda function to rotate the secrets for your protected service, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html">Rotating Secrets in AWS Secrets Manager</a> in the <i>AWS Secrets Manager User Guide</i>.</p> <p>Secrets Manager schedules the next rotation when the previous one is complete. Secrets Manager schedules the date by adding the rotation interval (number of days) to the actual date of the last rotation. The service chooses the hour within that 24-hour date window randomly. The minute is also chosen somewhat randomly, but weighted towards the top of the hour and influenced by a variety of factors that help distribute load.</p> <p>The rotation function must end with the versions of the secret in one of two states:</p> <ul> <li> <p>The <code>AWSPENDING</code> and <code>AWSCURRENT</code> staging labels are attached to the same version of the secret, or</p> </li> <li> <p>The <code>AWSPENDING</code> staging label is not attached to any version of the secret.</p> </li> </ul> <p>If instead the <code>AWSPENDING</code> staging label is present but is not attached to the same version as <code>AWSCURRENT</code> then any later invocation of <code>RotateSecret</code> assumes that a previous rotation request is still in progress and returns an error.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RotateSecret</p> </li> <li> <p>lambda:InvokeFunction (on the function specified in the secret's metadata)</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in your account, use <a>ListSecrets</a>.</p> </li> <li> <p>To get the details for a version of a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To attach staging labels to or remove staging labels from a version of a secret, use <a>UpdateSecretVersionStage</a>.</p> </li> </ul>
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
  var valid_602187 = header.getOrDefault("X-Amz-Target")
  valid_602187 = validateParameter(valid_602187, JString, required = true, default = newJString(
      "secretsmanager.RotateSecret"))
  if valid_602187 != nil:
    section.add "X-Amz-Target", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Signature")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Signature", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Content-Sha256", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Date")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Date", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Credential")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Credential", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Security-Token")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Security-Token", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Algorithm")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Algorithm", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-SignedHeaders", valid_602194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602196: Call_RotateSecret_602184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures and starts the asynchronous process of rotating this secret. If you include the configuration parameters, the operation sets those values for the secret and then immediately starts a rotation. If you do not include the configuration parameters, the operation starts a rotation with the values already stored in the secret. After the rotation completes, the protected service and its clients all use the new version of the secret. </p> <p>This required configuration information includes the ARN of an AWS Lambda function and the time between scheduled rotations. The Lambda rotation function creates a new version of the secret and creates or updates the credentials on the protected service to match. After testing the new credentials, the function marks the new secret with the staging label <code>AWSCURRENT</code> so that your clients all immediately begin to use the new version. For more information about rotating secrets and how to configure a Lambda function to rotate the secrets for your protected service, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html">Rotating Secrets in AWS Secrets Manager</a> in the <i>AWS Secrets Manager User Guide</i>.</p> <p>Secrets Manager schedules the next rotation when the previous one is complete. Secrets Manager schedules the date by adding the rotation interval (number of days) to the actual date of the last rotation. The service chooses the hour within that 24-hour date window randomly. The minute is also chosen somewhat randomly, but weighted towards the top of the hour and influenced by a variety of factors that help distribute load.</p> <p>The rotation function must end with the versions of the secret in one of two states:</p> <ul> <li> <p>The <code>AWSPENDING</code> and <code>AWSCURRENT</code> staging labels are attached to the same version of the secret, or</p> </li> <li> <p>The <code>AWSPENDING</code> staging label is not attached to any version of the secret.</p> </li> </ul> <p>If instead the <code>AWSPENDING</code> staging label is present but is not attached to the same version as <code>AWSCURRENT</code> then any later invocation of <code>RotateSecret</code> assumes that a previous rotation request is still in progress and returns an error.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RotateSecret</p> </li> <li> <p>lambda:InvokeFunction (on the function specified in the secret's metadata)</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in your account, use <a>ListSecrets</a>.</p> </li> <li> <p>To get the details for a version of a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To attach staging labels to or remove staging labels from a version of a secret, use <a>UpdateSecretVersionStage</a>.</p> </li> </ul>
  ## 
  let valid = call_602196.validator(path, query, header, formData, body)
  let scheme = call_602196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602196.url(scheme.get, call_602196.host, call_602196.base,
                         call_602196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602196, url, valid)

proc call*(call_602197: Call_RotateSecret_602184; body: JsonNode): Recallable =
  ## rotateSecret
  ## <p>Configures and starts the asynchronous process of rotating this secret. If you include the configuration parameters, the operation sets those values for the secret and then immediately starts a rotation. If you do not include the configuration parameters, the operation starts a rotation with the values already stored in the secret. After the rotation completes, the protected service and its clients all use the new version of the secret. </p> <p>This required configuration information includes the ARN of an AWS Lambda function and the time between scheduled rotations. The Lambda rotation function creates a new version of the secret and creates or updates the credentials on the protected service to match. After testing the new credentials, the function marks the new secret with the staging label <code>AWSCURRENT</code> so that your clients all immediately begin to use the new version. For more information about rotating secrets and how to configure a Lambda function to rotate the secrets for your protected service, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html">Rotating Secrets in AWS Secrets Manager</a> in the <i>AWS Secrets Manager User Guide</i>.</p> <p>Secrets Manager schedules the next rotation when the previous one is complete. Secrets Manager schedules the date by adding the rotation interval (number of days) to the actual date of the last rotation. The service chooses the hour within that 24-hour date window randomly. The minute is also chosen somewhat randomly, but weighted towards the top of the hour and influenced by a variety of factors that help distribute load.</p> <p>The rotation function must end with the versions of the secret in one of two states:</p> <ul> <li> <p>The <code>AWSPENDING</code> and <code>AWSCURRENT</code> staging labels are attached to the same version of the secret, or</p> </li> <li> <p>The <code>AWSPENDING</code> staging label is not attached to any version of the secret.</p> </li> </ul> <p>If instead the <code>AWSPENDING</code> staging label is present but is not attached to the same version as <code>AWSCURRENT</code> then any later invocation of <code>RotateSecret</code> assumes that a previous rotation request is still in progress and returns an error.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RotateSecret</p> </li> <li> <p>lambda:InvokeFunction (on the function specified in the secret's metadata)</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in your account, use <a>ListSecrets</a>.</p> </li> <li> <p>To get the details for a version of a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To attach staging labels to or remove staging labels from a version of a secret, use <a>UpdateSecretVersionStage</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602198 = newJObject()
  if body != nil:
    body_602198 = body
  result = call_602197.call(nil, nil, nil, nil, body_602198)

var rotateSecret* = Call_RotateSecret_602184(name: "rotateSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.RotateSecret",
    validator: validate_RotateSecret_602185, base: "/", url: url_RotateSecret_602186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602199 = ref object of OpenApiRestCall_601390
proc url_TagResource_602201(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602200(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Attaches one or more tags, each consisting of a key name and a value, to the specified secret. Tags are part of the secret's overall metadata, and are not associated with any specific version of the secret. This operation only appends tags to the existing list of tags. To remove tags, you must use <a>UntagResource</a>.</p> <p>The following basic restrictions apply to tags:</p> <ul> <li> <p>Maximum number of tags per secret—50</p> </li> <li> <p>Maximum key length—127 Unicode characters in UTF-8</p> </li> <li> <p>Maximum value length—255 Unicode characters in UTF-8</p> </li> <li> <p>Tag keys and values are case sensitive.</p> </li> <li> <p>Do not use the <code>aws:</code> prefix in your tag names or values because it is reserved for AWS use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit.</p> </li> <li> <p>If your tagging schema will be used across multiple services and resources, remember that other services might have restrictions on allowed characters. Generally allowed characters are: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @.</p> </li> </ul> <important> <p>If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:TagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To remove one or more tags from the collection attached to a secret, use <a>UntagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
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
  var valid_602202 = header.getOrDefault("X-Amz-Target")
  valid_602202 = validateParameter(valid_602202, JString, required = true, default = newJString(
      "secretsmanager.TagResource"))
  if valid_602202 != nil:
    section.add "X-Amz-Target", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Signature")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Signature", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Content-Sha256", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Date")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Date", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Credential")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Credential", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Security-Token")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Security-Token", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Algorithm")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Algorithm", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-SignedHeaders", valid_602209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602211: Call_TagResource_602199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches one or more tags, each consisting of a key name and a value, to the specified secret. Tags are part of the secret's overall metadata, and are not associated with any specific version of the secret. This operation only appends tags to the existing list of tags. To remove tags, you must use <a>UntagResource</a>.</p> <p>The following basic restrictions apply to tags:</p> <ul> <li> <p>Maximum number of tags per secret—50</p> </li> <li> <p>Maximum key length—127 Unicode characters in UTF-8</p> </li> <li> <p>Maximum value length—255 Unicode characters in UTF-8</p> </li> <li> <p>Tag keys and values are case sensitive.</p> </li> <li> <p>Do not use the <code>aws:</code> prefix in your tag names or values because it is reserved for AWS use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit.</p> </li> <li> <p>If your tagging schema will be used across multiple services and resources, remember that other services might have restrictions on allowed characters. Generally allowed characters are: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @.</p> </li> </ul> <important> <p>If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:TagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To remove one or more tags from the collection attached to a secret, use <a>UntagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_602211.validator(path, query, header, formData, body)
  let scheme = call_602211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602211.url(scheme.get, call_602211.host, call_602211.base,
                         call_602211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602211, url, valid)

proc call*(call_602212: Call_TagResource_602199; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches one or more tags, each consisting of a key name and a value, to the specified secret. Tags are part of the secret's overall metadata, and are not associated with any specific version of the secret. This operation only appends tags to the existing list of tags. To remove tags, you must use <a>UntagResource</a>.</p> <p>The following basic restrictions apply to tags:</p> <ul> <li> <p>Maximum number of tags per secret—50</p> </li> <li> <p>Maximum key length—127 Unicode characters in UTF-8</p> </li> <li> <p>Maximum value length—255 Unicode characters in UTF-8</p> </li> <li> <p>Tag keys and values are case sensitive.</p> </li> <li> <p>Do not use the <code>aws:</code> prefix in your tag names or values because it is reserved for AWS use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit.</p> </li> <li> <p>If your tagging schema will be used across multiple services and resources, remember that other services might have restrictions on allowed characters. Generally allowed characters are: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @.</p> </li> </ul> <important> <p>If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:TagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To remove one or more tags from the collection attached to a secret, use <a>UntagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602213 = newJObject()
  if body != nil:
    body_602213 = body
  result = call_602212.call(nil, nil, nil, nil, body_602213)

var tagResource* = Call_TagResource_602199(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "secretsmanager.amazonaws.com", route: "/#X-Amz-Target=secretsmanager.TagResource",
                                        validator: validate_TagResource_602200,
                                        base: "/", url: url_TagResource_602201,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602214 = ref object of OpenApiRestCall_601390
proc url_UntagResource_602216(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602215(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes one or more tags from the specified secret.</p> <p>This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged.</p> <important> <p>If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UntagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To add one or more tags to the collection attached to a secret, use <a>TagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
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
  var valid_602217 = header.getOrDefault("X-Amz-Target")
  valid_602217 = validateParameter(valid_602217, JString, required = true, default = newJString(
      "secretsmanager.UntagResource"))
  if valid_602217 != nil:
    section.add "X-Amz-Target", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Signature")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Signature", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Content-Sha256", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Date")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Date", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Credential")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Credential", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Security-Token")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Security-Token", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Algorithm")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Algorithm", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-SignedHeaders", valid_602224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602226: Call_UntagResource_602214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more tags from the specified secret.</p> <p>This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged.</p> <important> <p>If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UntagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To add one or more tags to the collection attached to a secret, use <a>TagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_602226.validator(path, query, header, formData, body)
  let scheme = call_602226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602226.url(scheme.get, call_602226.host, call_602226.base,
                         call_602226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602226, url, valid)

proc call*(call_602227: Call_UntagResource_602214; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes one or more tags from the specified secret.</p> <p>This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged.</p> <important> <p>If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UntagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To add one or more tags to the collection attached to a secret, use <a>TagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602228 = newJObject()
  if body != nil:
    body_602228 = body
  result = call_602227.call(nil, nil, nil, nil, body_602228)

var untagResource* = Call_UntagResource_602214(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UntagResource",
    validator: validate_UntagResource_602215, base: "/", url: url_UntagResource_602216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSecret_602229 = ref object of OpenApiRestCall_601390
proc url_UpdateSecret_602231(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSecret_602230(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies many of the details of the specified secret. If you include a <code>ClientRequestToken</code> and <i>either</i> <code>SecretString</code> or <code>SecretBinary</code> then it also creates a new version attached to the secret.</p> <p>To modify the rotation configuration of a secret, use <a>RotateSecret</a> instead.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> parameter and therefore limits you to encrypting and storing only a text string. To encrypt and store binary data as part of the version of a secret, you must use either the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists, the operation results in an error. You cannot modify an existing version, you can only create a new version.</p> </li> <li> <p>If you include <code>SecretString</code> or <code>SecretBinary</code> to create a new secret version, Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version. </p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To add only a new version to an existing secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions contained in a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
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
  var valid_602232 = header.getOrDefault("X-Amz-Target")
  valid_602232 = validateParameter(valid_602232, JString, required = true, default = newJString(
      "secretsmanager.UpdateSecret"))
  if valid_602232 != nil:
    section.add "X-Amz-Target", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Signature")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Signature", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Content-Sha256", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Date")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Date", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Credential")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Credential", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Security-Token")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Security-Token", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Algorithm")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Algorithm", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-SignedHeaders", valid_602239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602241: Call_UpdateSecret_602229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies many of the details of the specified secret. If you include a <code>ClientRequestToken</code> and <i>either</i> <code>SecretString</code> or <code>SecretBinary</code> then it also creates a new version attached to the secret.</p> <p>To modify the rotation configuration of a secret, use <a>RotateSecret</a> instead.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> parameter and therefore limits you to encrypting and storing only a text string. To encrypt and store binary data as part of the version of a secret, you must use either the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists, the operation results in an error. You cannot modify an existing version, you can only create a new version.</p> </li> <li> <p>If you include <code>SecretString</code> or <code>SecretBinary</code> to create a new secret version, Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version. </p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To add only a new version to an existing secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions contained in a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_602241.validator(path, query, header, formData, body)
  let scheme = call_602241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602241.url(scheme.get, call_602241.host, call_602241.base,
                         call_602241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602241, url, valid)

proc call*(call_602242: Call_UpdateSecret_602229; body: JsonNode): Recallable =
  ## updateSecret
  ## <p>Modifies many of the details of the specified secret. If you include a <code>ClientRequestToken</code> and <i>either</i> <code>SecretString</code> or <code>SecretBinary</code> then it also creates a new version attached to the secret.</p> <p>To modify the rotation configuration of a secret, use <a>RotateSecret</a> instead.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> parameter and therefore limits you to encrypting and storing only a text string. To encrypt and store binary data as part of the version of a secret, you must use either the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists, the operation results in an error. You cannot modify an existing version, you can only create a new version.</p> </li> <li> <p>If you include <code>SecretString</code> or <code>SecretBinary</code> to create a new secret version, Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version. </p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To add only a new version to an existing secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions contained in a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602243 = newJObject()
  if body != nil:
    body_602243 = body
  result = call_602242.call(nil, nil, nil, nil, body_602243)

var updateSecret* = Call_UpdateSecret_602229(name: "updateSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UpdateSecret",
    validator: validate_UpdateSecret_602230, base: "/", url: url_UpdateSecret_602231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSecretVersionStage_602244 = ref object of OpenApiRestCall_601390
proc url_UpdateSecretVersionStage_602246(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSecretVersionStage_602245(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the staging labels attached to a version of a secret. Staging labels are used to track a version as it progresses through the secret rotation process. You can attach a staging label to only one version of a secret at a time. If a staging label to be added is already attached to another version, then it is moved--removed from the other version first and then attached to this one. For more information about staging labels, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html#term_staging-label">Staging Labels</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>The staging labels that you specify in the <code>VersionStage</code> parameter are added to the existing list of staging labels--they don't replace it.</p> <p>You can move the <code>AWSCURRENT</code> staging label to this version by including it in this call.</p> <note> <p>Whenever you move <code>AWSCURRENT</code>, Secrets Manager automatically moves the label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </note> <p>If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecretVersionStage</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To get the list of staging labels that are currently associated with a version of a secret, use <code> <a>DescribeSecret</a> </code> and examine the <code>SecretVersionsToStages</code> response value. </p> </li> </ul>
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
  var valid_602247 = header.getOrDefault("X-Amz-Target")
  valid_602247 = validateParameter(valid_602247, JString, required = true, default = newJString(
      "secretsmanager.UpdateSecretVersionStage"))
  if valid_602247 != nil:
    section.add "X-Amz-Target", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Signature")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Signature", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Content-Sha256", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Date")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Date", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Credential")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Credential", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Security-Token")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Security-Token", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Algorithm")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Algorithm", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-SignedHeaders", valid_602254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602256: Call_UpdateSecretVersionStage_602244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the staging labels attached to a version of a secret. Staging labels are used to track a version as it progresses through the secret rotation process. You can attach a staging label to only one version of a secret at a time. If a staging label to be added is already attached to another version, then it is moved--removed from the other version first and then attached to this one. For more information about staging labels, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html#term_staging-label">Staging Labels</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>The staging labels that you specify in the <code>VersionStage</code> parameter are added to the existing list of staging labels--they don't replace it.</p> <p>You can move the <code>AWSCURRENT</code> staging label to this version by including it in this call.</p> <note> <p>Whenever you move <code>AWSCURRENT</code>, Secrets Manager automatically moves the label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </note> <p>If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecretVersionStage</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To get the list of staging labels that are currently associated with a version of a secret, use <code> <a>DescribeSecret</a> </code> and examine the <code>SecretVersionsToStages</code> response value. </p> </li> </ul>
  ## 
  let valid = call_602256.validator(path, query, header, formData, body)
  let scheme = call_602256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602256.url(scheme.get, call_602256.host, call_602256.base,
                         call_602256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602256, url, valid)

proc call*(call_602257: Call_UpdateSecretVersionStage_602244; body: JsonNode): Recallable =
  ## updateSecretVersionStage
  ## <p>Modifies the staging labels attached to a version of a secret. Staging labels are used to track a version as it progresses through the secret rotation process. You can attach a staging label to only one version of a secret at a time. If a staging label to be added is already attached to another version, then it is moved--removed from the other version first and then attached to this one. For more information about staging labels, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html#term_staging-label">Staging Labels</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>The staging labels that you specify in the <code>VersionStage</code> parameter are added to the existing list of staging labels--they don't replace it.</p> <p>You can move the <code>AWSCURRENT</code> staging label to this version by including it in this call.</p> <note> <p>Whenever you move <code>AWSCURRENT</code>, Secrets Manager automatically moves the label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </note> <p>If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecretVersionStage</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To get the list of staging labels that are currently associated with a version of a secret, use <code> <a>DescribeSecret</a> </code> and examine the <code>SecretVersionsToStages</code> response value. </p> </li> </ul>
  ##   body: JObject (required)
  var body_602258 = newJObject()
  if body != nil:
    body_602258 = body
  result = call_602257.call(nil, nil, nil, nil, body_602258)

var updateSecretVersionStage* = Call_UpdateSecretVersionStage_602244(
    name: "updateSecretVersionStage", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UpdateSecretVersionStage",
    validator: validate_UpdateSecretVersionStage_602245, base: "/",
    url: url_UpdateSecretVersionStage_602246, schemes: {Scheme.Https, Scheme.Http})
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
