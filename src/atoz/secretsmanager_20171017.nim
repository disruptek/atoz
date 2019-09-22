
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602434 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602434](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602434): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CancelRotateSecret_602771 = ref object of OpenApiRestCall_602434
proc url_CancelRotateSecret_602773(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelRotateSecret_602772(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602885 = header.getOrDefault("X-Amz-Date")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Date", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Security-Token")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Security-Token", valid_602886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602900 = header.getOrDefault("X-Amz-Target")
  valid_602900 = validateParameter(valid_602900, JString, required = true, default = newJString(
      "secretsmanager.CancelRotateSecret"))
  if valid_602900 != nil:
    section.add "X-Amz-Target", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Content-Sha256", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Algorithm")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Algorithm", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Signature")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Signature", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-SignedHeaders", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Credential")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Credential", valid_602905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602929: Call_CancelRotateSecret_602771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables automatic scheduled rotation and cancels the rotation of a secret if one is currently in progress.</p> <p>To re-enable scheduled rotation, call <a>RotateSecret</a> with <code>AutomaticallyRotateAfterDays</code> set to a value greater than 0. This will immediately rotate your secret and then enable the automatic schedule.</p> <note> <p>If you cancel a rotation that is in progress, it can leave the <code>VersionStage</code> labels in an unexpected state. Depending on what step of the rotation was in progress, you might need to remove the staging label <code>AWSPENDING</code> from the partially created version, specified by the <code>VersionId</code> response value. You should also evaluate the partially rotated new version to see if it should be deleted, which you can do by removing all staging labels from the new version's <code>VersionStage</code> field.</p> </note> <p>To successfully start a rotation, the staging label <code>AWSPENDING</code> must be in one of the following states:</p> <ul> <li> <p>Not be attached to any version at all</p> </li> <li> <p>Attached to the same version as the staging label <code>AWSCURRENT</code> </p> </li> </ul> <p>If the staging label <code>AWSPENDING</code> is attached to a different version than the version with <code>AWSCURRENT</code> then the attempt to rotate fails.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CancelRotateSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To configure rotation for a secret or to manually trigger a rotation, use <a>RotateSecret</a>.</p> </li> <li> <p>To get the rotation configuration details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> <li> <p>To list all of the versions currently associated with a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_602929.validator(path, query, header, formData, body)
  let scheme = call_602929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602929.url(scheme.get, call_602929.host, call_602929.base,
                         call_602929.route, valid.getOrDefault("path"))
  result = hook(call_602929, url, valid)

proc call*(call_603000: Call_CancelRotateSecret_602771; body: JsonNode): Recallable =
  ## cancelRotateSecret
  ## <p>Disables automatic scheduled rotation and cancels the rotation of a secret if one is currently in progress.</p> <p>To re-enable scheduled rotation, call <a>RotateSecret</a> with <code>AutomaticallyRotateAfterDays</code> set to a value greater than 0. This will immediately rotate your secret and then enable the automatic schedule.</p> <note> <p>If you cancel a rotation that is in progress, it can leave the <code>VersionStage</code> labels in an unexpected state. Depending on what step of the rotation was in progress, you might need to remove the staging label <code>AWSPENDING</code> from the partially created version, specified by the <code>VersionId</code> response value. You should also evaluate the partially rotated new version to see if it should be deleted, which you can do by removing all staging labels from the new version's <code>VersionStage</code> field.</p> </note> <p>To successfully start a rotation, the staging label <code>AWSPENDING</code> must be in one of the following states:</p> <ul> <li> <p>Not be attached to any version at all</p> </li> <li> <p>Attached to the same version as the staging label <code>AWSCURRENT</code> </p> </li> </ul> <p>If the staging label <code>AWSPENDING</code> is attached to a different version than the version with <code>AWSCURRENT</code> then the attempt to rotate fails.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CancelRotateSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To configure rotation for a secret or to manually trigger a rotation, use <a>RotateSecret</a>.</p> </li> <li> <p>To get the rotation configuration details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> <li> <p>To list all of the versions currently associated with a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603001 = newJObject()
  if body != nil:
    body_603001 = body
  result = call_603000.call(nil, nil, nil, nil, body_603001)

var cancelRotateSecret* = Call_CancelRotateSecret_602771(
    name: "cancelRotateSecret", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.CancelRotateSecret",
    validator: validate_CancelRotateSecret_602772, base: "/",
    url: url_CancelRotateSecret_602773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecret_603040 = ref object of OpenApiRestCall_602434
proc url_CreateSecret_603042(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSecret_603041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603043 = header.getOrDefault("X-Amz-Date")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Date", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Security-Token")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Security-Token", valid_603044
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603045 = header.getOrDefault("X-Amz-Target")
  valid_603045 = validateParameter(valid_603045, JString, required = true, default = newJString(
      "secretsmanager.CreateSecret"))
  if valid_603045 != nil:
    section.add "X-Amz-Target", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Content-Sha256", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Algorithm")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Algorithm", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Signature")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Signature", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-SignedHeaders", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Credential")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Credential", valid_603050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603052: Call_CreateSecret_603040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new secret. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret.</p> <p>Secrets Manager stores the encrypted secret data in one of a collection of "versions" associated with the secret. Each version contains a copy of the encrypted secret data. Each version is associated with one or more "staging labels" that identify where the version is in the rotation cycle. The <code>SecretVersionsToStages</code> field of the secret contains the mapping of staging labels to the active versions of the secret. Versions without a staging label are considered deprecated and are not included in the list.</p> <p>You provide the secret data to be encrypted by putting text in either the <code>SecretString</code> parameter or binary data in the <code>SecretBinary</code> parameter, but not both. If you include <code>SecretString</code> or <code>SecretBinary</code> then Secrets Manager also creates an initial secret version and automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CreateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>secretsmanager:TagResource - needed only if you include the <code>Tags</code> parameter. </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> <li> <p>To modify an existing secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the encrypted secure string and secure binary values, use <a>GetSecretValue</a>.</p> </li> <li> <p>To retrieve all other details for a secret, use <a>DescribeSecret</a>. This does not include the encrypted secure string and secure binary values.</p> </li> <li> <p>To retrieve the list of secret versions associated with the current secret, use <a>DescribeSecret</a> and examine the <code>SecretVersionsToStages</code> response value.</p> </li> </ul>
  ## 
  let valid = call_603052.validator(path, query, header, formData, body)
  let scheme = call_603052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603052.url(scheme.get, call_603052.host, call_603052.base,
                         call_603052.route, valid.getOrDefault("path"))
  result = hook(call_603052, url, valid)

proc call*(call_603053: Call_CreateSecret_603040; body: JsonNode): Recallable =
  ## createSecret
  ## <p>Creates a new secret. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret.</p> <p>Secrets Manager stores the encrypted secret data in one of a collection of "versions" associated with the secret. Each version contains a copy of the encrypted secret data. Each version is associated with one or more "staging labels" that identify where the version is in the rotation cycle. The <code>SecretVersionsToStages</code> field of the secret contains the mapping of staging labels to the active versions of the secret. Versions without a staging label are considered deprecated and are not included in the list.</p> <p>You provide the secret data to be encrypted by putting text in either the <code>SecretString</code> parameter or binary data in the <code>SecretBinary</code> parameter, but not both. If you include <code>SecretString</code> or <code>SecretBinary</code> then Secrets Manager also creates an initial secret version and automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CreateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>secretsmanager:TagResource - needed only if you include the <code>Tags</code> parameter. </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> <li> <p>To modify an existing secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the encrypted secure string and secure binary values, use <a>GetSecretValue</a>.</p> </li> <li> <p>To retrieve all other details for a secret, use <a>DescribeSecret</a>. This does not include the encrypted secure string and secure binary values.</p> </li> <li> <p>To retrieve the list of secret versions associated with the current secret, use <a>DescribeSecret</a> and examine the <code>SecretVersionsToStages</code> response value.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603054 = newJObject()
  if body != nil:
    body_603054 = body
  result = call_603053.call(nil, nil, nil, nil, body_603054)

var createSecret* = Call_CreateSecret_603040(name: "createSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.CreateSecret",
    validator: validate_CreateSecret_603041, base: "/", url: url_CreateSecret_603042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_603055 = ref object of OpenApiRestCall_602434
proc url_DeleteResourcePolicy_603057(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteResourcePolicy_603056(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603058 = header.getOrDefault("X-Amz-Date")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Date", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Security-Token")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Security-Token", valid_603059
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603060 = header.getOrDefault("X-Amz-Target")
  valid_603060 = validateParameter(valid_603060, JString, required = true, default = newJString(
      "secretsmanager.DeleteResourcePolicy"))
  if valid_603060 != nil:
    section.add "X-Amz-Target", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Content-Sha256", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Algorithm")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Algorithm", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Signature")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Signature", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-SignedHeaders", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Credential")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Credential", valid_603065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603067: Call_DeleteResourcePolicy_603055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the resource-based permission policy that's attached to the secret.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To retrieve the current resource-based policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_603067.validator(path, query, header, formData, body)
  let scheme = call_603067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603067.url(scheme.get, call_603067.host, call_603067.base,
                         call_603067.route, valid.getOrDefault("path"))
  result = hook(call_603067, url, valid)

proc call*(call_603068: Call_DeleteResourcePolicy_603055; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## <p>Deletes the resource-based permission policy that's attached to the secret.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To retrieve the current resource-based policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603069 = newJObject()
  if body != nil:
    body_603069 = body
  result = call_603068.call(nil, nil, nil, nil, body_603069)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_603055(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_603056, base: "/",
    url: url_DeleteResourcePolicy_603057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecret_603070 = ref object of OpenApiRestCall_602434
proc url_DeleteSecret_603072(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSecret_603071(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603073 = header.getOrDefault("X-Amz-Date")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Date", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Security-Token")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Security-Token", valid_603074
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603075 = header.getOrDefault("X-Amz-Target")
  valid_603075 = validateParameter(valid_603075, JString, required = true, default = newJString(
      "secretsmanager.DeleteSecret"))
  if valid_603075 != nil:
    section.add "X-Amz-Target", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Content-Sha256", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Algorithm")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Algorithm", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Signature")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Signature", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-SignedHeaders", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Credential")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Credential", valid_603080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603082: Call_DeleteSecret_603070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an entire secret and all of its versions. You can optionally include a recovery window during which you can restore the secret. If you don't specify a recovery window value, the operation defaults to 30 days. Secrets Manager attaches a <code>DeletionDate</code> stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently.</p> <p>At any time before recovery window ends, you can use <a>RestoreSecret</a> to remove the <code>DeletionDate</code> and cancel the deletion of the secret.</p> <p>You cannot access the encrypted secret information in any secret that is scheduled for deletion. If you need to access that information, you must cancel the deletion with <a>RestoreSecret</a> and then retrieve the information.</p> <note> <ul> <li> <p>There is no explicit operation to delete a version of a secret. Instead, remove all staging labels from the <code>VersionStage</code> field of a version. That marks the version as deprecated and allows Secrets Manager to delete it as needed. Versions that do not have any staging labels do not show up in <a>ListSecretVersionIds</a> unless you specify <code>IncludeDeprecated</code>.</p> </li> <li> <p>The permanent secret deletion at the end of the waiting period is performed as a background task with low priority. There is no guarantee of a specific time after the recovery window for the actual delete operation to occur.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To cancel deletion of a version of a secret before the recovery window has expired, use <a>RestoreSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_603082.validator(path, query, header, formData, body)
  let scheme = call_603082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603082.url(scheme.get, call_603082.host, call_603082.base,
                         call_603082.route, valid.getOrDefault("path"))
  result = hook(call_603082, url, valid)

proc call*(call_603083: Call_DeleteSecret_603070; body: JsonNode): Recallable =
  ## deleteSecret
  ## <p>Deletes an entire secret and all of its versions. You can optionally include a recovery window during which you can restore the secret. If you don't specify a recovery window value, the operation defaults to 30 days. Secrets Manager attaches a <code>DeletionDate</code> stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently.</p> <p>At any time before recovery window ends, you can use <a>RestoreSecret</a> to remove the <code>DeletionDate</code> and cancel the deletion of the secret.</p> <p>You cannot access the encrypted secret information in any secret that is scheduled for deletion. If you need to access that information, you must cancel the deletion with <a>RestoreSecret</a> and then retrieve the information.</p> <note> <ul> <li> <p>There is no explicit operation to delete a version of a secret. Instead, remove all staging labels from the <code>VersionStage</code> field of a version. That marks the version as deprecated and allows Secrets Manager to delete it as needed. Versions that do not have any staging labels do not show up in <a>ListSecretVersionIds</a> unless you specify <code>IncludeDeprecated</code>.</p> </li> <li> <p>The permanent secret deletion at the end of the waiting period is performed as a background task with low priority. There is no guarantee of a specific time after the recovery window for the actual delete operation to occur.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To cancel deletion of a version of a secret before the recovery window has expired, use <a>RestoreSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603084 = newJObject()
  if body != nil:
    body_603084 = body
  result = call_603083.call(nil, nil, nil, nil, body_603084)

var deleteSecret* = Call_DeleteSecret_603070(name: "deleteSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DeleteSecret",
    validator: validate_DeleteSecret_603071, base: "/", url: url_DeleteSecret_603072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSecret_603085 = ref object of OpenApiRestCall_602434
proc url_DescribeSecret_603087(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSecret_603086(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603088 = header.getOrDefault("X-Amz-Date")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Date", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Security-Token")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Security-Token", valid_603089
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603090 = header.getOrDefault("X-Amz-Target")
  valid_603090 = validateParameter(valid_603090, JString, required = true, default = newJString(
      "secretsmanager.DescribeSecret"))
  if valid_603090 != nil:
    section.add "X-Amz-Target", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Content-Sha256", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Algorithm")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Algorithm", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Signature")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Signature", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-SignedHeaders", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Credential")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Credential", valid_603095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603097: Call_DescribeSecret_603085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the details of a secret. It does not include the encrypted fields. Only those fields that are populated with a value are returned in the response. </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DescribeSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To modify a secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To retrieve the encrypted secret information in a version of the secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To list all of the secrets in the AWS account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_603097.validator(path, query, header, formData, body)
  let scheme = call_603097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603097.url(scheme.get, call_603097.host, call_603097.base,
                         call_603097.route, valid.getOrDefault("path"))
  result = hook(call_603097, url, valid)

proc call*(call_603098: Call_DescribeSecret_603085; body: JsonNode): Recallable =
  ## describeSecret
  ## <p>Retrieves the details of a secret. It does not include the encrypted fields. Only those fields that are populated with a value are returned in the response. </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DescribeSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To modify a secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To retrieve the encrypted secret information in a version of the secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To list all of the secrets in the AWS account, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603099 = newJObject()
  if body != nil:
    body_603099 = body
  result = call_603098.call(nil, nil, nil, nil, body_603099)

var describeSecret* = Call_DescribeSecret_603085(name: "describeSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DescribeSecret",
    validator: validate_DescribeSecret_603086, base: "/", url: url_DescribeSecret_603087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRandomPassword_603100 = ref object of OpenApiRestCall_602434
proc url_GetRandomPassword_603102(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRandomPassword_603101(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603103 = header.getOrDefault("X-Amz-Date")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Date", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Security-Token")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Security-Token", valid_603104
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603105 = header.getOrDefault("X-Amz-Target")
  valid_603105 = validateParameter(valid_603105, JString, required = true, default = newJString(
      "secretsmanager.GetRandomPassword"))
  if valid_603105 != nil:
    section.add "X-Amz-Target", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Content-Sha256", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Algorithm")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Algorithm", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Signature")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Signature", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-SignedHeaders", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Credential")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Credential", valid_603110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603112: Call_GetRandomPassword_603100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a random password of the specified complexity. This operation is intended for use in the Lambda rotation function. Per best practice, we recommend that you specify the maximum length and include every character type that the system you are generating a password for can support.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetRandomPassword</p> </li> </ul>
  ## 
  let valid = call_603112.validator(path, query, header, formData, body)
  let scheme = call_603112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603112.url(scheme.get, call_603112.host, call_603112.base,
                         call_603112.route, valid.getOrDefault("path"))
  result = hook(call_603112, url, valid)

proc call*(call_603113: Call_GetRandomPassword_603100; body: JsonNode): Recallable =
  ## getRandomPassword
  ## <p>Generates a random password of the specified complexity. This operation is intended for use in the Lambda rotation function. Per best practice, we recommend that you specify the maximum length and include every character type that the system you are generating a password for can support.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetRandomPassword</p> </li> </ul>
  ##   body: JObject (required)
  var body_603114 = newJObject()
  if body != nil:
    body_603114 = body
  result = call_603113.call(nil, nil, nil, nil, body_603114)

var getRandomPassword* = Call_GetRandomPassword_603100(name: "getRandomPassword",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetRandomPassword",
    validator: validate_GetRandomPassword_603101, base: "/",
    url: url_GetRandomPassword_603102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_603115 = ref object of OpenApiRestCall_602434
proc url_GetResourcePolicy_603117(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResourcePolicy_603116(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603118 = header.getOrDefault("X-Amz-Date")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Date", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Security-Token")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Security-Token", valid_603119
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603120 = header.getOrDefault("X-Amz-Target")
  valid_603120 = validateParameter(valid_603120, JString, required = true, default = newJString(
      "secretsmanager.GetResourcePolicy"))
  if valid_603120 != nil:
    section.add "X-Amz-Target", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Content-Sha256", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Algorithm")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Algorithm", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Signature")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Signature", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-SignedHeaders", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Credential")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Credential", valid_603125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603127: Call_GetResourcePolicy_603115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the JSON text of the resource-based policy document that's attached to the specified secret. The JSON request string input and response output are shown formatted with white space and line breaks for better readability. Submit your input as a single line JSON string.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_603127.validator(path, query, header, formData, body)
  let scheme = call_603127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603127.url(scheme.get, call_603127.host, call_603127.base,
                         call_603127.route, valid.getOrDefault("path"))
  result = hook(call_603127, url, valid)

proc call*(call_603128: Call_GetResourcePolicy_603115; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## <p>Retrieves the JSON text of the resource-based policy document that's attached to the specified secret. The JSON request string input and response output are shown formatted with white space and line breaks for better readability. Submit your input as a single line JSON string.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603129 = newJObject()
  if body != nil:
    body_603129 = body
  result = call_603128.call(nil, nil, nil, nil, body_603129)

var getResourcePolicy* = Call_GetResourcePolicy_603115(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetResourcePolicy",
    validator: validate_GetResourcePolicy_603116, base: "/",
    url: url_GetResourcePolicy_603117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecretValue_603130 = ref object of OpenApiRestCall_602434
proc url_GetSecretValue_603132(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSecretValue_603131(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603133 = header.getOrDefault("X-Amz-Date")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Date", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Security-Token")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Security-Token", valid_603134
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603135 = header.getOrDefault("X-Amz-Target")
  valid_603135 = validateParameter(valid_603135, JString, required = true, default = newJString(
      "secretsmanager.GetSecretValue"))
  if valid_603135 != nil:
    section.add "X-Amz-Target", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Content-Sha256", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Algorithm")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Algorithm", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Signature")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Signature", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-SignedHeaders", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Credential")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Credential", valid_603140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603142: Call_GetSecretValue_603130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the contents of the encrypted fields <code>SecretString</code> or <code>SecretBinary</code> from the specified version of a secret, whichever contains content.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetSecretValue</p> </li> <li> <p>kms:Decrypt - required only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new version of the secret with different encrypted information, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the non-encrypted details for the secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_603142.validator(path, query, header, formData, body)
  let scheme = call_603142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603142.url(scheme.get, call_603142.host, call_603142.base,
                         call_603142.route, valid.getOrDefault("path"))
  result = hook(call_603142, url, valid)

proc call*(call_603143: Call_GetSecretValue_603130; body: JsonNode): Recallable =
  ## getSecretValue
  ## <p>Retrieves the contents of the encrypted fields <code>SecretString</code> or <code>SecretBinary</code> from the specified version of a secret, whichever contains content.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetSecretValue</p> </li> <li> <p>kms:Decrypt - required only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new version of the secret with different encrypted information, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the non-encrypted details for the secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603144 = newJObject()
  if body != nil:
    body_603144 = body
  result = call_603143.call(nil, nil, nil, nil, body_603144)

var getSecretValue* = Call_GetSecretValue_603130(name: "getSecretValue",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetSecretValue",
    validator: validate_GetSecretValue_603131, base: "/", url: url_GetSecretValue_603132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecretVersionIds_603145 = ref object of OpenApiRestCall_602434
proc url_ListSecretVersionIds_603147(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSecretVersionIds_603146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603148 = query.getOrDefault("NextToken")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "NextToken", valid_603148
  var valid_603149 = query.getOrDefault("MaxResults")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "MaxResults", valid_603149
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "secretsmanager.ListSecretVersionIds"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_ListSecretVersionIds_603145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_ListSecretVersionIds_603145; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSecretVersionIds
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603161 = newJObject()
  var body_603162 = newJObject()
  add(query_603161, "NextToken", newJString(NextToken))
  if body != nil:
    body_603162 = body
  add(query_603161, "MaxResults", newJString(MaxResults))
  result = call_603160.call(nil, query_603161, nil, nil, body_603162)

var listSecretVersionIds* = Call_ListSecretVersionIds_603145(
    name: "listSecretVersionIds", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.ListSecretVersionIds",
    validator: validate_ListSecretVersionIds_603146, base: "/",
    url: url_ListSecretVersionIds_603147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecrets_603164 = ref object of OpenApiRestCall_602434
proc url_ListSecrets_603166(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSecrets_603165(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603167 = query.getOrDefault("NextToken")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "NextToken", valid_603167
  var valid_603168 = query.getOrDefault("MaxResults")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "MaxResults", valid_603168
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
  var valid_603169 = header.getOrDefault("X-Amz-Date")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Date", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Security-Token")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Security-Token", valid_603170
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603171 = header.getOrDefault("X-Amz-Target")
  valid_603171 = validateParameter(valid_603171, JString, required = true, default = newJString(
      "secretsmanager.ListSecrets"))
  if valid_603171 != nil:
    section.add "X-Amz-Target", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Content-Sha256", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Signature")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Signature", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-SignedHeaders", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Credential")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Credential", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_ListSecrets_603164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_ListSecrets_603164; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSecrets
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603180 = newJObject()
  var body_603181 = newJObject()
  add(query_603180, "NextToken", newJString(NextToken))
  if body != nil:
    body_603181 = body
  add(query_603180, "MaxResults", newJString(MaxResults))
  result = call_603179.call(nil, query_603180, nil, nil, body_603181)

var listSecrets* = Call_ListSecrets_603164(name: "listSecrets",
                                        meth: HttpMethod.HttpPost,
                                        host: "secretsmanager.amazonaws.com", route: "/#X-Amz-Target=secretsmanager.ListSecrets",
                                        validator: validate_ListSecrets_603165,
                                        base: "/", url: url_ListSecrets_603166,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_603182 = ref object of OpenApiRestCall_602434
proc url_PutResourcePolicy_603184(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutResourcePolicy_603183(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Security-Token")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Security-Token", valid_603186
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603187 = header.getOrDefault("X-Amz-Target")
  valid_603187 = validateParameter(valid_603187, JString, required = true, default = newJString(
      "secretsmanager.PutResourcePolicy"))
  if valid_603187 != nil:
    section.add "X-Amz-Target", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Content-Sha256", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Algorithm")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Algorithm", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Signature")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Signature", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-SignedHeaders", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Credential")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Credential", valid_603192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603194: Call_PutResourcePolicy_603182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches the contents of the specified resource-based permission policy to a secret. A resource-based policy is optional. Alternatively, you can use IAM identity-based policies that specify the secret's Amazon Resource Name (ARN) in the policy statement's <code>Resources</code> element. You can also use a combination of both identity-based and resource-based policies. The affected users and roles receive the permissions that are permitted by all of the relevant policies. For more information, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html">Using Resource-Based Policies for AWS Secrets Manager</a>. For the complete description of the AWS policy syntax and grammar, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html">IAM JSON Policy Reference</a> in the <i>IAM User Guide</i>.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the resource policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_603194.validator(path, query, header, formData, body)
  let scheme = call_603194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603194.url(scheme.get, call_603194.host, call_603194.base,
                         call_603194.route, valid.getOrDefault("path"))
  result = hook(call_603194, url, valid)

proc call*(call_603195: Call_PutResourcePolicy_603182; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## <p>Attaches the contents of the specified resource-based permission policy to a secret. A resource-based policy is optional. Alternatively, you can use IAM identity-based policies that specify the secret's Amazon Resource Name (ARN) in the policy statement's <code>Resources</code> element. You can also use a combination of both identity-based and resource-based policies. The affected users and roles receive the permissions that are permitted by all of the relevant policies. For more information, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html">Using Resource-Based Policies for AWS Secrets Manager</a>. For the complete description of the AWS policy syntax and grammar, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html">IAM JSON Policy Reference</a> in the <i>IAM User Guide</i>.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the resource policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603196 = newJObject()
  if body != nil:
    body_603196 = body
  result = call_603195.call(nil, nil, nil, nil, body_603196)

var putResourcePolicy* = Call_PutResourcePolicy_603182(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.PutResourcePolicy",
    validator: validate_PutResourcePolicy_603183, base: "/",
    url: url_PutResourcePolicy_603184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSecretValue_603197 = ref object of OpenApiRestCall_602434
proc url_PutSecretValue_603199(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutSecretValue_603198(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603200 = header.getOrDefault("X-Amz-Date")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Date", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Security-Token")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Security-Token", valid_603201
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603202 = header.getOrDefault("X-Amz-Target")
  valid_603202 = validateParameter(valid_603202, JString, required = true, default = newJString(
      "secretsmanager.PutSecretValue"))
  if valid_603202 != nil:
    section.add "X-Amz-Target", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Content-Sha256", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Algorithm")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Algorithm", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Signature")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Signature", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-SignedHeaders", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Credential")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Credential", valid_603207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603209: Call_PutSecretValue_603197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stores a new encrypted secret value in the specified secret. To do this, the operation creates a new version and attaches it to the secret. The version can contain a new <code>SecretString</code> value or a new <code>SecretBinary</code> value. You can also specify the staging labels that are initially attached to the new version.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> field. To add binary data to a secret with the <code>SecretBinary</code> field you must use the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If this operation creates the first version for the secret then Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> </li> <li> <p>If another version of this secret already exists, then this operation does not automatically move any staging labels other than those that you explicitly specify in the <code>VersionStages</code> parameter.</p> </li> <li> <p>If this operation moves the staging label <code>AWSCURRENT</code> from another version to this version (because you included it in the <code>StagingLabels</code> parameter) then Secrets Manager also automatically moves the staging label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </li> <li> <p>This operation is idempotent. If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you cannot modify an existing version; you can only create new ones.</p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutSecretValue</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the encrypted value you store in the version of a secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_603209.validator(path, query, header, formData, body)
  let scheme = call_603209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603209.url(scheme.get, call_603209.host, call_603209.base,
                         call_603209.route, valid.getOrDefault("path"))
  result = hook(call_603209, url, valid)

proc call*(call_603210: Call_PutSecretValue_603197; body: JsonNode): Recallable =
  ## putSecretValue
  ## <p>Stores a new encrypted secret value in the specified secret. To do this, the operation creates a new version and attaches it to the secret. The version can contain a new <code>SecretString</code> value or a new <code>SecretBinary</code> value. You can also specify the staging labels that are initially attached to the new version.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> field. To add binary data to a secret with the <code>SecretBinary</code> field you must use the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If this operation creates the first version for the secret then Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> </li> <li> <p>If another version of this secret already exists, then this operation does not automatically move any staging labels other than those that you explicitly specify in the <code>VersionStages</code> parameter.</p> </li> <li> <p>If this operation moves the staging label <code>AWSCURRENT</code> from another version to this version (because you included it in the <code>StagingLabels</code> parameter) then Secrets Manager also automatically moves the staging label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </li> <li> <p>This operation is idempotent. If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you cannot modify an existing version; you can only create new ones.</p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutSecretValue</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the encrypted value you store in the version of a secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603211 = newJObject()
  if body != nil:
    body_603211 = body
  result = call_603210.call(nil, nil, nil, nil, body_603211)

var putSecretValue* = Call_PutSecretValue_603197(name: "putSecretValue",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.PutSecretValue",
    validator: validate_PutSecretValue_603198, base: "/", url: url_PutSecretValue_603199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreSecret_603212 = ref object of OpenApiRestCall_602434
proc url_RestoreSecret_603214(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RestoreSecret_603213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603215 = header.getOrDefault("X-Amz-Date")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Date", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Security-Token")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Security-Token", valid_603216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603217 = header.getOrDefault("X-Amz-Target")
  valid_603217 = validateParameter(valid_603217, JString, required = true, default = newJString(
      "secretsmanager.RestoreSecret"))
  if valid_603217 != nil:
    section.add "X-Amz-Target", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Content-Sha256", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Algorithm")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Algorithm", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Signature")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Signature", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-SignedHeaders", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Credential")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Credential", valid_603222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603224: Call_RestoreSecret_603212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the scheduled deletion of a secret by removing the <code>DeletedDate</code> time stamp. This makes the secret accessible to query once again.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RestoreSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_603224.validator(path, query, header, formData, body)
  let scheme = call_603224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603224.url(scheme.get, call_603224.host, call_603224.base,
                         call_603224.route, valid.getOrDefault("path"))
  result = hook(call_603224, url, valid)

proc call*(call_603225: Call_RestoreSecret_603212; body: JsonNode): Recallable =
  ## restoreSecret
  ## <p>Cancels the scheduled deletion of a secret by removing the <code>DeletedDate</code> time stamp. This makes the secret accessible to query once again.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RestoreSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603226 = newJObject()
  if body != nil:
    body_603226 = body
  result = call_603225.call(nil, nil, nil, nil, body_603226)

var restoreSecret* = Call_RestoreSecret_603212(name: "restoreSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.RestoreSecret",
    validator: validate_RestoreSecret_603213, base: "/", url: url_RestoreSecret_603214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateSecret_603227 = ref object of OpenApiRestCall_602434
proc url_RotateSecret_603229(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RotateSecret_603228(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603230 = header.getOrDefault("X-Amz-Date")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Date", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Security-Token")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Security-Token", valid_603231
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603232 = header.getOrDefault("X-Amz-Target")
  valid_603232 = validateParameter(valid_603232, JString, required = true, default = newJString(
      "secretsmanager.RotateSecret"))
  if valid_603232 != nil:
    section.add "X-Amz-Target", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Content-Sha256", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Algorithm")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Algorithm", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Signature")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Signature", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-SignedHeaders", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Credential")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Credential", valid_603237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603239: Call_RotateSecret_603227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures and starts the asynchronous process of rotating this secret. If you include the configuration parameters, the operation sets those values for the secret and then immediately starts a rotation. If you do not include the configuration parameters, the operation starts a rotation with the values already stored in the secret. After the rotation completes, the protected service and its clients all use the new version of the secret. </p> <p>This required configuration information includes the ARN of an AWS Lambda function and the time between scheduled rotations. The Lambda rotation function creates a new version of the secret and creates or updates the credentials on the protected service to match. After testing the new credentials, the function marks the new secret with the staging label <code>AWSCURRENT</code> so that your clients all immediately begin to use the new version. For more information about rotating secrets and how to configure a Lambda function to rotate the secrets for your protected service, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html">Rotating Secrets in AWS Secrets Manager</a> in the <i>AWS Secrets Manager User Guide</i>.</p> <p>Secrets Manager schedules the next rotation when the previous one is complete. Secrets Manager schedules the date by adding the rotation interval (number of days) to the actual date of the last rotation. The service chooses the hour within that 24-hour date window randomly. The minute is also chosen somewhat randomly, but weighted towards the top of the hour and influenced by a variety of factors that help distribute load.</p> <p>The rotation function must end with the versions of the secret in one of two states:</p> <ul> <li> <p>The <code>AWSPENDING</code> and <code>AWSCURRENT</code> staging labels are attached to the same version of the secret, or</p> </li> <li> <p>The <code>AWSPENDING</code> staging label is not attached to any version of the secret.</p> </li> </ul> <p>If instead the <code>AWSPENDING</code> staging label is present but is not attached to the same version as <code>AWSCURRENT</code> then any later invocation of <code>RotateSecret</code> assumes that a previous rotation request is still in progress and returns an error.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RotateSecret</p> </li> <li> <p>lambda:InvokeFunction (on the function specified in the secret's metadata)</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in your account, use <a>ListSecrets</a>.</p> </li> <li> <p>To get the details for a version of a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To attach staging labels to or remove staging labels from a version of a secret, use <a>UpdateSecretVersionStage</a>.</p> </li> </ul>
  ## 
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_RotateSecret_603227; body: JsonNode): Recallable =
  ## rotateSecret
  ## <p>Configures and starts the asynchronous process of rotating this secret. If you include the configuration parameters, the operation sets those values for the secret and then immediately starts a rotation. If you do not include the configuration parameters, the operation starts a rotation with the values already stored in the secret. After the rotation completes, the protected service and its clients all use the new version of the secret. </p> <p>This required configuration information includes the ARN of an AWS Lambda function and the time between scheduled rotations. The Lambda rotation function creates a new version of the secret and creates or updates the credentials on the protected service to match. After testing the new credentials, the function marks the new secret with the staging label <code>AWSCURRENT</code> so that your clients all immediately begin to use the new version. For more information about rotating secrets and how to configure a Lambda function to rotate the secrets for your protected service, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html">Rotating Secrets in AWS Secrets Manager</a> in the <i>AWS Secrets Manager User Guide</i>.</p> <p>Secrets Manager schedules the next rotation when the previous one is complete. Secrets Manager schedules the date by adding the rotation interval (number of days) to the actual date of the last rotation. The service chooses the hour within that 24-hour date window randomly. The minute is also chosen somewhat randomly, but weighted towards the top of the hour and influenced by a variety of factors that help distribute load.</p> <p>The rotation function must end with the versions of the secret in one of two states:</p> <ul> <li> <p>The <code>AWSPENDING</code> and <code>AWSCURRENT</code> staging labels are attached to the same version of the secret, or</p> </li> <li> <p>The <code>AWSPENDING</code> staging label is not attached to any version of the secret.</p> </li> </ul> <p>If instead the <code>AWSPENDING</code> staging label is present but is not attached to the same version as <code>AWSCURRENT</code> then any later invocation of <code>RotateSecret</code> assumes that a previous rotation request is still in progress and returns an error.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RotateSecret</p> </li> <li> <p>lambda:InvokeFunction (on the function specified in the secret's metadata)</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in your account, use <a>ListSecrets</a>.</p> </li> <li> <p>To get the details for a version of a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To attach staging labels to or remove staging labels from a version of a secret, use <a>UpdateSecretVersionStage</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603241 = newJObject()
  if body != nil:
    body_603241 = body
  result = call_603240.call(nil, nil, nil, nil, body_603241)

var rotateSecret* = Call_RotateSecret_603227(name: "rotateSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.RotateSecret",
    validator: validate_RotateSecret_603228, base: "/", url: url_RotateSecret_603229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603242 = ref object of OpenApiRestCall_602434
proc url_TagResource_603244(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_603243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603245 = header.getOrDefault("X-Amz-Date")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Date", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Security-Token")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Security-Token", valid_603246
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603247 = header.getOrDefault("X-Amz-Target")
  valid_603247 = validateParameter(valid_603247, JString, required = true, default = newJString(
      "secretsmanager.TagResource"))
  if valid_603247 != nil:
    section.add "X-Amz-Target", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Content-Sha256", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Algorithm")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Algorithm", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Signature")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Signature", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-SignedHeaders", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Credential")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Credential", valid_603252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603254: Call_TagResource_603242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches one or more tags, each consisting of a key name and a value, to the specified secret. Tags are part of the secret's overall metadata, and are not associated with any specific version of the secret. This operation only appends tags to the existing list of tags. To remove tags, you must use <a>UntagResource</a>.</p> <p>The following basic restrictions apply to tags:</p> <ul> <li> <p>Maximum number of tags per secret—50</p> </li> <li> <p>Maximum key length—127 Unicode characters in UTF-8</p> </li> <li> <p>Maximum value length—255 Unicode characters in UTF-8</p> </li> <li> <p>Tag keys and values are case sensitive.</p> </li> <li> <p>Do not use the <code>aws:</code> prefix in your tag names or values because it is reserved for AWS use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit.</p> </li> <li> <p>If your tagging schema will be used across multiple services and resources, remember that other services might have restrictions on allowed characters. Generally allowed characters are: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @.</p> </li> </ul> <important> <p>If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:TagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To remove one or more tags from the collection attached to a secret, use <a>UntagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_603254.validator(path, query, header, formData, body)
  let scheme = call_603254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603254.url(scheme.get, call_603254.host, call_603254.base,
                         call_603254.route, valid.getOrDefault("path"))
  result = hook(call_603254, url, valid)

proc call*(call_603255: Call_TagResource_603242; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches one or more tags, each consisting of a key name and a value, to the specified secret. Tags are part of the secret's overall metadata, and are not associated with any specific version of the secret. This operation only appends tags to the existing list of tags. To remove tags, you must use <a>UntagResource</a>.</p> <p>The following basic restrictions apply to tags:</p> <ul> <li> <p>Maximum number of tags per secret—50</p> </li> <li> <p>Maximum key length—127 Unicode characters in UTF-8</p> </li> <li> <p>Maximum value length—255 Unicode characters in UTF-8</p> </li> <li> <p>Tag keys and values are case sensitive.</p> </li> <li> <p>Do not use the <code>aws:</code> prefix in your tag names or values because it is reserved for AWS use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit.</p> </li> <li> <p>If your tagging schema will be used across multiple services and resources, remember that other services might have restrictions on allowed characters. Generally allowed characters are: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @.</p> </li> </ul> <important> <p>If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:TagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To remove one or more tags from the collection attached to a secret, use <a>UntagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603256 = newJObject()
  if body != nil:
    body_603256 = body
  result = call_603255.call(nil, nil, nil, nil, body_603256)

var tagResource* = Call_TagResource_603242(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "secretsmanager.amazonaws.com", route: "/#X-Amz-Target=secretsmanager.TagResource",
                                        validator: validate_TagResource_603243,
                                        base: "/", url: url_TagResource_603244,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603257 = ref object of OpenApiRestCall_602434
proc url_UntagResource_603259(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_603258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603260 = header.getOrDefault("X-Amz-Date")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Date", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Security-Token")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Security-Token", valid_603261
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603262 = header.getOrDefault("X-Amz-Target")
  valid_603262 = validateParameter(valid_603262, JString, required = true, default = newJString(
      "secretsmanager.UntagResource"))
  if valid_603262 != nil:
    section.add "X-Amz-Target", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Content-Sha256", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Algorithm")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Algorithm", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Signature")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Signature", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-SignedHeaders", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Credential")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Credential", valid_603267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603269: Call_UntagResource_603257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more tags from the specified secret.</p> <p>This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged.</p> <important> <p>If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UntagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To add one or more tags to the collection attached to a secret, use <a>TagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_603269.validator(path, query, header, formData, body)
  let scheme = call_603269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603269.url(scheme.get, call_603269.host, call_603269.base,
                         call_603269.route, valid.getOrDefault("path"))
  result = hook(call_603269, url, valid)

proc call*(call_603270: Call_UntagResource_603257; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes one or more tags from the specified secret.</p> <p>This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged.</p> <important> <p>If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UntagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To add one or more tags to the collection attached to a secret, use <a>TagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603271 = newJObject()
  if body != nil:
    body_603271 = body
  result = call_603270.call(nil, nil, nil, nil, body_603271)

var untagResource* = Call_UntagResource_603257(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UntagResource",
    validator: validate_UntagResource_603258, base: "/", url: url_UntagResource_603259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSecret_603272 = ref object of OpenApiRestCall_602434
proc url_UpdateSecret_603274(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateSecret_603273(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603275 = header.getOrDefault("X-Amz-Date")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Date", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Security-Token")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Security-Token", valid_603276
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603277 = header.getOrDefault("X-Amz-Target")
  valid_603277 = validateParameter(valid_603277, JString, required = true, default = newJString(
      "secretsmanager.UpdateSecret"))
  if valid_603277 != nil:
    section.add "X-Amz-Target", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Content-Sha256", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Algorithm")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Algorithm", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Signature")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Signature", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-SignedHeaders", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Credential")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Credential", valid_603282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603284: Call_UpdateSecret_603272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies many of the details of the specified secret. If you include a <code>ClientRequestToken</code> and <i>either</i> <code>SecretString</code> or <code>SecretBinary</code> then it also creates a new version attached to the secret.</p> <p>To modify the rotation configuration of a secret, use <a>RotateSecret</a> instead.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> parameter and therefore limits you to encrypting and storing only a text string. To encrypt and store binary data as part of the version of a secret, you must use either the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists, the operation results in an error. You cannot modify an existing version, you can only create a new version.</p> </li> <li> <p>If you include <code>SecretString</code> or <code>SecretBinary</code> to create a new secret version, Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version. </p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To add only a new version to an existing secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions contained in a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_603284.validator(path, query, header, formData, body)
  let scheme = call_603284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603284.url(scheme.get, call_603284.host, call_603284.base,
                         call_603284.route, valid.getOrDefault("path"))
  result = hook(call_603284, url, valid)

proc call*(call_603285: Call_UpdateSecret_603272; body: JsonNode): Recallable =
  ## updateSecret
  ## <p>Modifies many of the details of the specified secret. If you include a <code>ClientRequestToken</code> and <i>either</i> <code>SecretString</code> or <code>SecretBinary</code> then it also creates a new version attached to the secret.</p> <p>To modify the rotation configuration of a secret, use <a>RotateSecret</a> instead.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> parameter and therefore limits you to encrypting and storing only a text string. To encrypt and store binary data as part of the version of a secret, you must use either the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists, the operation results in an error. You cannot modify an existing version, you can only create a new version.</p> </li> <li> <p>If you include <code>SecretString</code> or <code>SecretBinary</code> to create a new secret version, Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version. </p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To add only a new version to an existing secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions contained in a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603286 = newJObject()
  if body != nil:
    body_603286 = body
  result = call_603285.call(nil, nil, nil, nil, body_603286)

var updateSecret* = Call_UpdateSecret_603272(name: "updateSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UpdateSecret",
    validator: validate_UpdateSecret_603273, base: "/", url: url_UpdateSecret_603274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSecretVersionStage_603287 = ref object of OpenApiRestCall_602434
proc url_UpdateSecretVersionStage_603289(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateSecretVersionStage_603288(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603290 = header.getOrDefault("X-Amz-Date")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Date", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Security-Token")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Security-Token", valid_603291
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603292 = header.getOrDefault("X-Amz-Target")
  valid_603292 = validateParameter(valid_603292, JString, required = true, default = newJString(
      "secretsmanager.UpdateSecretVersionStage"))
  if valid_603292 != nil:
    section.add "X-Amz-Target", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Content-Sha256", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Algorithm")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Algorithm", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Signature")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Signature", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-SignedHeaders", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Credential")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Credential", valid_603297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603299: Call_UpdateSecretVersionStage_603287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the staging labels attached to a version of a secret. Staging labels are used to track a version as it progresses through the secret rotation process. You can attach a staging label to only one version of a secret at a time. If a staging label to be added is already attached to another version, then it is moved--removed from the other version first and then attached to this one. For more information about staging labels, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html#term_staging-label">Staging Labels</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>The staging labels that you specify in the <code>VersionStage</code> parameter are added to the existing list of staging labels--they don't replace it.</p> <p>You can move the <code>AWSCURRENT</code> staging label to this version by including it in this call.</p> <note> <p>Whenever you move <code>AWSCURRENT</code>, Secrets Manager automatically moves the label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </note> <p>If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecretVersionStage</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To get the list of staging labels that are currently associated with a version of a secret, use <code> <a>DescribeSecret</a> </code> and examine the <code>SecretVersionsToStages</code> response value. </p> </li> </ul>
  ## 
  let valid = call_603299.validator(path, query, header, formData, body)
  let scheme = call_603299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603299.url(scheme.get, call_603299.host, call_603299.base,
                         call_603299.route, valid.getOrDefault("path"))
  result = hook(call_603299, url, valid)

proc call*(call_603300: Call_UpdateSecretVersionStage_603287; body: JsonNode): Recallable =
  ## updateSecretVersionStage
  ## <p>Modifies the staging labels attached to a version of a secret. Staging labels are used to track a version as it progresses through the secret rotation process. You can attach a staging label to only one version of a secret at a time. If a staging label to be added is already attached to another version, then it is moved--removed from the other version first and then attached to this one. For more information about staging labels, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html#term_staging-label">Staging Labels</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>The staging labels that you specify in the <code>VersionStage</code> parameter are added to the existing list of staging labels--they don't replace it.</p> <p>You can move the <code>AWSCURRENT</code> staging label to this version by including it in this call.</p> <note> <p>Whenever you move <code>AWSCURRENT</code>, Secrets Manager automatically moves the label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </note> <p>If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecretVersionStage</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To get the list of staging labels that are currently associated with a version of a secret, use <code> <a>DescribeSecret</a> </code> and examine the <code>SecretVersionsToStages</code> response value. </p> </li> </ul>
  ##   body: JObject (required)
  var body_603301 = newJObject()
  if body != nil:
    body_603301 = body
  result = call_603300.call(nil, nil, nil, nil, body_603301)

var updateSecretVersionStage* = Call_UpdateSecretVersionStage_603287(
    name: "updateSecretVersionStage", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UpdateSecretVersionStage",
    validator: validate_UpdateSecretVersionStage_603288, base: "/",
    url: url_UpdateSecretVersionStage_603289, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
