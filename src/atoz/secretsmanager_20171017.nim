
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616867 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616867](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616867): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "secretsmanager.ap-northeast-1.amazonaws.com", "ap-southeast-1": "secretsmanager.ap-southeast-1.amazonaws.com", "us-west-2": "secretsmanager.us-west-2.amazonaws.com", "eu-west-2": "secretsmanager.eu-west-2.amazonaws.com", "ap-northeast-3": "secretsmanager.ap-northeast-3.amazonaws.com", "eu-central-1": "secretsmanager.eu-central-1.amazonaws.com", "us-east-2": "secretsmanager.us-east-2.amazonaws.com", "us-east-1": "secretsmanager.us-east-1.amazonaws.com", "cn-northwest-1": "secretsmanager.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "secretsmanager.ap-northeast-2.amazonaws.com", "ap-south-1": "secretsmanager.ap-south-1.amazonaws.com", "eu-north-1": "secretsmanager.eu-north-1.amazonaws.com", "us-west-1": "secretsmanager.us-west-1.amazonaws.com", "us-gov-east-1": "secretsmanager.us-gov-east-1.amazonaws.com", "eu-west-3": "secretsmanager.eu-west-3.amazonaws.com", "cn-north-1": "secretsmanager.cn-north-1.amazonaws.com.cn", "sa-east-1": "secretsmanager.sa-east-1.amazonaws.com", "eu-west-1": "secretsmanager.eu-west-1.amazonaws.com", "us-gov-west-1": "secretsmanager.us-gov-west-1.amazonaws.com", "ap-southeast-2": "secretsmanager.ap-southeast-2.amazonaws.com", "ca-central-1": "secretsmanager.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "secretsmanager.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "secretsmanager.ap-southeast-1.amazonaws.com",
      "us-west-2": "secretsmanager.us-west-2.amazonaws.com",
      "eu-west-2": "secretsmanager.eu-west-2.amazonaws.com",
      "ap-northeast-3": "secretsmanager.ap-northeast-3.amazonaws.com",
      "eu-central-1": "secretsmanager.eu-central-1.amazonaws.com",
      "us-east-2": "secretsmanager.us-east-2.amazonaws.com",
      "us-east-1": "secretsmanager.us-east-1.amazonaws.com",
      "cn-northwest-1": "secretsmanager.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "secretsmanager.ap-northeast-2.amazonaws.com",
      "ap-south-1": "secretsmanager.ap-south-1.amazonaws.com",
      "eu-north-1": "secretsmanager.eu-north-1.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CancelRotateSecret_617206 = ref object of OpenApiRestCall_616867
proc url_CancelRotateSecret_617208(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelRotateSecret_617207(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617320 = header.getOrDefault("X-Amz-Date")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Date", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Security-Token")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Security-Token", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Content-Sha256", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Algorithm")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Algorithm", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-Signature")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-Signature", valid_617324
  var valid_617325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-SignedHeaders", valid_617325
  var valid_617339 = header.getOrDefault("X-Amz-Target")
  valid_617339 = validateParameter(valid_617339, JString, required = true, default = newJString(
      "secretsmanager.CancelRotateSecret"))
  if valid_617339 != nil:
    section.add "X-Amz-Target", valid_617339
  var valid_617340 = header.getOrDefault("X-Amz-Credential")
  valid_617340 = validateParameter(valid_617340, JString, required = false,
                                 default = nil)
  if valid_617340 != nil:
    section.add "X-Amz-Credential", valid_617340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617365: Call_CancelRotateSecret_617206; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables automatic scheduled rotation and cancels the rotation of a secret if one is currently in progress.</p> <p>To re-enable scheduled rotation, call <a>RotateSecret</a> with <code>AutomaticallyRotateAfterDays</code> set to a value greater than 0. This will immediately rotate your secret and then enable the automatic schedule.</p> <note> <p>If you cancel a rotation that is in progress, it can leave the <code>VersionStage</code> labels in an unexpected state. Depending on what step of the rotation was in progress, you might need to remove the staging label <code>AWSPENDING</code> from the partially created version, specified by the <code>VersionId</code> response value. You should also evaluate the partially rotated new version to see if it should be deleted, which you can do by removing all staging labels from the new version's <code>VersionStage</code> field.</p> </note> <p>To successfully start a rotation, the staging label <code>AWSPENDING</code> must be in one of the following states:</p> <ul> <li> <p>Not be attached to any version at all</p> </li> <li> <p>Attached to the same version as the staging label <code>AWSCURRENT</code> </p> </li> </ul> <p>If the staging label <code>AWSPENDING</code> is attached to a different version than the version with <code>AWSCURRENT</code> then the attempt to rotate fails.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CancelRotateSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To configure rotation for a secret or to manually trigger a rotation, use <a>RotateSecret</a>.</p> </li> <li> <p>To get the rotation configuration details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> <li> <p>To list all of the versions currently associated with a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_617365.validator(path, query, header, formData, body, _)
  let scheme = call_617365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617365.url(scheme.get, call_617365.host, call_617365.base,
                         call_617365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617365, url, valid, _)

proc call*(call_617436: Call_CancelRotateSecret_617206; body: JsonNode): Recallable =
  ## cancelRotateSecret
  ## <p>Disables automatic scheduled rotation and cancels the rotation of a secret if one is currently in progress.</p> <p>To re-enable scheduled rotation, call <a>RotateSecret</a> with <code>AutomaticallyRotateAfterDays</code> set to a value greater than 0. This will immediately rotate your secret and then enable the automatic schedule.</p> <note> <p>If you cancel a rotation that is in progress, it can leave the <code>VersionStage</code> labels in an unexpected state. Depending on what step of the rotation was in progress, you might need to remove the staging label <code>AWSPENDING</code> from the partially created version, specified by the <code>VersionId</code> response value. You should also evaluate the partially rotated new version to see if it should be deleted, which you can do by removing all staging labels from the new version's <code>VersionStage</code> field.</p> </note> <p>To successfully start a rotation, the staging label <code>AWSPENDING</code> must be in one of the following states:</p> <ul> <li> <p>Not be attached to any version at all</p> </li> <li> <p>Attached to the same version as the staging label <code>AWSCURRENT</code> </p> </li> </ul> <p>If the staging label <code>AWSPENDING</code> is attached to a different version than the version with <code>AWSCURRENT</code> then the attempt to rotate fails.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CancelRotateSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To configure rotation for a secret or to manually trigger a rotation, use <a>RotateSecret</a>.</p> </li> <li> <p>To get the rotation configuration details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> <li> <p>To list all of the versions currently associated with a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617437 = newJObject()
  if body != nil:
    body_617437 = body
  result = call_617436.call(nil, nil, nil, nil, body_617437)

var cancelRotateSecret* = Call_CancelRotateSecret_617206(
    name: "cancelRotateSecret", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.CancelRotateSecret",
    validator: validate_CancelRotateSecret_617207, base: "/",
    url: url_CancelRotateSecret_617208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecret_617478 = ref object of OpenApiRestCall_616867
proc url_CreateSecret_617480(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSecret_617479(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617481 = header.getOrDefault("X-Amz-Date")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Date", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Security-Token")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Security-Token", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Content-Sha256", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Algorithm")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Algorithm", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-Signature")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-Signature", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617486 = validateParameter(valid_617486, JString, required = false,
                                 default = nil)
  if valid_617486 != nil:
    section.add "X-Amz-SignedHeaders", valid_617486
  var valid_617487 = header.getOrDefault("X-Amz-Target")
  valid_617487 = validateParameter(valid_617487, JString, required = true, default = newJString(
      "secretsmanager.CreateSecret"))
  if valid_617487 != nil:
    section.add "X-Amz-Target", valid_617487
  var valid_617488 = header.getOrDefault("X-Amz-Credential")
  valid_617488 = validateParameter(valid_617488, JString, required = false,
                                 default = nil)
  if valid_617488 != nil:
    section.add "X-Amz-Credential", valid_617488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617490: Call_CreateSecret_617478; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new secret. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret.</p> <p>Secrets Manager stores the encrypted secret data in one of a collection of "versions" associated with the secret. Each version contains a copy of the encrypted secret data. Each version is associated with one or more "staging labels" that identify where the version is in the rotation cycle. The <code>SecretVersionsToStages</code> field of the secret contains the mapping of staging labels to the active versions of the secret. Versions without a staging label are considered deprecated and are not included in the list.</p> <p>You provide the secret data to be encrypted by putting text in either the <code>SecretString</code> parameter or binary data in the <code>SecretBinary</code> parameter, but not both. If you include <code>SecretString</code> or <code>SecretBinary</code> then Secrets Manager also creates an initial secret version and automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CreateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>secretsmanager:TagResource - needed only if you include the <code>Tags</code> parameter. </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> <li> <p>To modify an existing secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the encrypted secure string and secure binary values, use <a>GetSecretValue</a>.</p> </li> <li> <p>To retrieve all other details for a secret, use <a>DescribeSecret</a>. This does not include the encrypted secure string and secure binary values.</p> </li> <li> <p>To retrieve the list of secret versions associated with the current secret, use <a>DescribeSecret</a> and examine the <code>SecretVersionsToStages</code> response value.</p> </li> </ul>
  ## 
  let valid = call_617490.validator(path, query, header, formData, body, _)
  let scheme = call_617490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617490.url(scheme.get, call_617490.host, call_617490.base,
                         call_617490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617490, url, valid, _)

proc call*(call_617491: Call_CreateSecret_617478; body: JsonNode): Recallable =
  ## createSecret
  ## <p>Creates a new secret. A secret in Secrets Manager consists of both the protected secret data and the important information needed to manage the secret.</p> <p>Secrets Manager stores the encrypted secret data in one of a collection of "versions" associated with the secret. Each version contains a copy of the encrypted secret data. Each version is associated with one or more "staging labels" that identify where the version is in the rotation cycle. The <code>SecretVersionsToStages</code> field of the secret contains the mapping of staging labels to the active versions of the secret. Versions without a staging label are considered deprecated and are not included in the list.</p> <p>You provide the secret data to be encrypted by putting text in either the <code>SecretString</code> parameter or binary data in the <code>SecretBinary</code> parameter, but not both. If you include <code>SecretString</code> or <code>SecretBinary</code> then Secrets Manager also creates an initial secret version and automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:CreateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> <li> <p>secretsmanager:TagResource - needed only if you include the <code>Tags</code> parameter. </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> <li> <p>To modify an existing secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the encrypted secure string and secure binary values, use <a>GetSecretValue</a>.</p> </li> <li> <p>To retrieve all other details for a secret, use <a>DescribeSecret</a>. This does not include the encrypted secure string and secure binary values.</p> </li> <li> <p>To retrieve the list of secret versions associated with the current secret, use <a>DescribeSecret</a> and examine the <code>SecretVersionsToStages</code> response value.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617492 = newJObject()
  if body != nil:
    body_617492 = body
  result = call_617491.call(nil, nil, nil, nil, body_617492)

var createSecret* = Call_CreateSecret_617478(name: "createSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.CreateSecret",
    validator: validate_CreateSecret_617479, base: "/", url: url_CreateSecret_617480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_617493 = ref object of OpenApiRestCall_616867
proc url_DeleteResourcePolicy_617495(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourcePolicy_617494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617496 = header.getOrDefault("X-Amz-Date")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Date", valid_617496
  var valid_617497 = header.getOrDefault("X-Amz-Security-Token")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Security-Token", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Content-Sha256", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-Algorithm")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-Algorithm", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-Signature")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-Signature", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617501 = validateParameter(valid_617501, JString, required = false,
                                 default = nil)
  if valid_617501 != nil:
    section.add "X-Amz-SignedHeaders", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-Target")
  valid_617502 = validateParameter(valid_617502, JString, required = true, default = newJString(
      "secretsmanager.DeleteResourcePolicy"))
  if valid_617502 != nil:
    section.add "X-Amz-Target", valid_617502
  var valid_617503 = header.getOrDefault("X-Amz-Credential")
  valid_617503 = validateParameter(valid_617503, JString, required = false,
                                 default = nil)
  if valid_617503 != nil:
    section.add "X-Amz-Credential", valid_617503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617505: Call_DeleteResourcePolicy_617493; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the resource-based permission policy that's attached to the secret.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To retrieve the current resource-based policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_617505.validator(path, query, header, formData, body, _)
  let scheme = call_617505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617505.url(scheme.get, call_617505.host, call_617505.base,
                         call_617505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617505, url, valid, _)

proc call*(call_617506: Call_DeleteResourcePolicy_617493; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## <p>Deletes the resource-based permission policy that's attached to the secret.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To retrieve the current resource-based policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617507 = newJObject()
  if body != nil:
    body_617507 = body
  result = call_617506.call(nil, nil, nil, nil, body_617507)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_617493(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_617494, base: "/",
    url: url_DeleteResourcePolicy_617495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecret_617508 = ref object of OpenApiRestCall_616867
proc url_DeleteSecret_617510(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSecret_617509(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617511 = header.getOrDefault("X-Amz-Date")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Date", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Security-Token")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Security-Token", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-Content-Sha256", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Algorithm")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Algorithm", valid_617514
  var valid_617515 = header.getOrDefault("X-Amz-Signature")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-Signature", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617516 = validateParameter(valid_617516, JString, required = false,
                                 default = nil)
  if valid_617516 != nil:
    section.add "X-Amz-SignedHeaders", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Target")
  valid_617517 = validateParameter(valid_617517, JString, required = true, default = newJString(
      "secretsmanager.DeleteSecret"))
  if valid_617517 != nil:
    section.add "X-Amz-Target", valid_617517
  var valid_617518 = header.getOrDefault("X-Amz-Credential")
  valid_617518 = validateParameter(valid_617518, JString, required = false,
                                 default = nil)
  if valid_617518 != nil:
    section.add "X-Amz-Credential", valid_617518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617520: Call_DeleteSecret_617508; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an entire secret and all of its versions. You can optionally include a recovery window during which you can restore the secret. If you don't specify a recovery window value, the operation defaults to 30 days. Secrets Manager attaches a <code>DeletionDate</code> stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently.</p> <p>At any time before recovery window ends, you can use <a>RestoreSecret</a> to remove the <code>DeletionDate</code> and cancel the deletion of the secret.</p> <p>You cannot access the encrypted secret information in any secret that is scheduled for deletion. If you need to access that information, you must cancel the deletion with <a>RestoreSecret</a> and then retrieve the information.</p> <note> <ul> <li> <p>There is no explicit operation to delete a version of a secret. Instead, remove all staging labels from the <code>VersionStage</code> field of a version. That marks the version as deprecated and allows Secrets Manager to delete it as needed. Versions that do not have any staging labels do not show up in <a>ListSecretVersionIds</a> unless you specify <code>IncludeDeprecated</code>.</p> </li> <li> <p>The permanent secret deletion at the end of the waiting period is performed as a background task with low priority. There is no guarantee of a specific time after the recovery window for the actual delete operation to occur.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To cancel deletion of a version of a secret before the recovery window has expired, use <a>RestoreSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_617520.validator(path, query, header, formData, body, _)
  let scheme = call_617520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617520.url(scheme.get, call_617520.host, call_617520.base,
                         call_617520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617520, url, valid, _)

proc call*(call_617521: Call_DeleteSecret_617508; body: JsonNode): Recallable =
  ## deleteSecret
  ## <p>Deletes an entire secret and all of its versions. You can optionally include a recovery window during which you can restore the secret. If you don't specify a recovery window value, the operation defaults to 30 days. Secrets Manager attaches a <code>DeletionDate</code> stamp to the secret that specifies the end of the recovery window. At the end of the recovery window, Secrets Manager deletes the secret permanently.</p> <p>At any time before recovery window ends, you can use <a>RestoreSecret</a> to remove the <code>DeletionDate</code> and cancel the deletion of the secret.</p> <p>You cannot access the encrypted secret information in any secret that is scheduled for deletion. If you need to access that information, you must cancel the deletion with <a>RestoreSecret</a> and then retrieve the information.</p> <note> <ul> <li> <p>There is no explicit operation to delete a version of a secret. Instead, remove all staging labels from the <code>VersionStage</code> field of a version. That marks the version as deprecated and allows Secrets Manager to delete it as needed. Versions that do not have any staging labels do not show up in <a>ListSecretVersionIds</a> unless you specify <code>IncludeDeprecated</code>.</p> </li> <li> <p>The permanent secret deletion at the end of the waiting period is performed as a background task with low priority. There is no guarantee of a specific time after the recovery window for the actual delete operation to occur.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DeleteSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To cancel deletion of a version of a secret before the recovery window has expired, use <a>RestoreSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617522 = newJObject()
  if body != nil:
    body_617522 = body
  result = call_617521.call(nil, nil, nil, nil, body_617522)

var deleteSecret* = Call_DeleteSecret_617508(name: "deleteSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DeleteSecret",
    validator: validate_DeleteSecret_617509, base: "/", url: url_DeleteSecret_617510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSecret_617523 = ref object of OpenApiRestCall_616867
proc url_DescribeSecret_617525(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSecret_617524(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617526 = header.getOrDefault("X-Amz-Date")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "X-Amz-Date", valid_617526
  var valid_617527 = header.getOrDefault("X-Amz-Security-Token")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-Security-Token", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Content-Sha256", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Algorithm")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Algorithm", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-Signature")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-Signature", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617531 = validateParameter(valid_617531, JString, required = false,
                                 default = nil)
  if valid_617531 != nil:
    section.add "X-Amz-SignedHeaders", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Target")
  valid_617532 = validateParameter(valid_617532, JString, required = true, default = newJString(
      "secretsmanager.DescribeSecret"))
  if valid_617532 != nil:
    section.add "X-Amz-Target", valid_617532
  var valid_617533 = header.getOrDefault("X-Amz-Credential")
  valid_617533 = validateParameter(valid_617533, JString, required = false,
                                 default = nil)
  if valid_617533 != nil:
    section.add "X-Amz-Credential", valid_617533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617535: Call_DescribeSecret_617523; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the details of a secret. It does not include the encrypted fields. Only those fields that are populated with a value are returned in the response. </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DescribeSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To modify a secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To retrieve the encrypted secret information in a version of the secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To list all of the secrets in the AWS account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_617535.validator(path, query, header, formData, body, _)
  let scheme = call_617535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617535.url(scheme.get, call_617535.host, call_617535.base,
                         call_617535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617535, url, valid, _)

proc call*(call_617536: Call_DescribeSecret_617523; body: JsonNode): Recallable =
  ## describeSecret
  ## <p>Retrieves the details of a secret. It does not include the encrypted fields. Only those fields that are populated with a value are returned in the response. </p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:DescribeSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To modify a secret, use <a>UpdateSecret</a>.</p> </li> <li> <p>To retrieve the encrypted secret information in a version of the secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To list all of the secrets in the AWS account, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617537 = newJObject()
  if body != nil:
    body_617537 = body
  result = call_617536.call(nil, nil, nil, nil, body_617537)

var describeSecret* = Call_DescribeSecret_617523(name: "describeSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.DescribeSecret",
    validator: validate_DescribeSecret_617524, base: "/", url: url_DescribeSecret_617525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRandomPassword_617538 = ref object of OpenApiRestCall_616867
proc url_GetRandomPassword_617540(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRandomPassword_617539(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617541 = header.getOrDefault("X-Amz-Date")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-Date", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-Security-Token")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Security-Token", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Content-Sha256", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Algorithm")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Algorithm", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-Signature")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-Signature", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617546 = validateParameter(valid_617546, JString, required = false,
                                 default = nil)
  if valid_617546 != nil:
    section.add "X-Amz-SignedHeaders", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-Target")
  valid_617547 = validateParameter(valid_617547, JString, required = true, default = newJString(
      "secretsmanager.GetRandomPassword"))
  if valid_617547 != nil:
    section.add "X-Amz-Target", valid_617547
  var valid_617548 = header.getOrDefault("X-Amz-Credential")
  valid_617548 = validateParameter(valid_617548, JString, required = false,
                                 default = nil)
  if valid_617548 != nil:
    section.add "X-Amz-Credential", valid_617548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617550: Call_GetRandomPassword_617538; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a random password of the specified complexity. This operation is intended for use in the Lambda rotation function. Per best practice, we recommend that you specify the maximum length and include every character type that the system you are generating a password for can support.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetRandomPassword</p> </li> </ul>
  ## 
  let valid = call_617550.validator(path, query, header, formData, body, _)
  let scheme = call_617550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617550.url(scheme.get, call_617550.host, call_617550.base,
                         call_617550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617550, url, valid, _)

proc call*(call_617551: Call_GetRandomPassword_617538; body: JsonNode): Recallable =
  ## getRandomPassword
  ## <p>Generates a random password of the specified complexity. This operation is intended for use in the Lambda rotation function. Per best practice, we recommend that you specify the maximum length and include every character type that the system you are generating a password for can support.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetRandomPassword</p> </li> </ul>
  ##   body: JObject (required)
  var body_617552 = newJObject()
  if body != nil:
    body_617552 = body
  result = call_617551.call(nil, nil, nil, nil, body_617552)

var getRandomPassword* = Call_GetRandomPassword_617538(name: "getRandomPassword",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetRandomPassword",
    validator: validate_GetRandomPassword_617539, base: "/",
    url: url_GetRandomPassword_617540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_617553 = ref object of OpenApiRestCall_616867
proc url_GetResourcePolicy_617555(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourcePolicy_617554(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617556 = header.getOrDefault("X-Amz-Date")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "X-Amz-Date", valid_617556
  var valid_617557 = header.getOrDefault("X-Amz-Security-Token")
  valid_617557 = validateParameter(valid_617557, JString, required = false,
                                 default = nil)
  if valid_617557 != nil:
    section.add "X-Amz-Security-Token", valid_617557
  var valid_617558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617558 = validateParameter(valid_617558, JString, required = false,
                                 default = nil)
  if valid_617558 != nil:
    section.add "X-Amz-Content-Sha256", valid_617558
  var valid_617559 = header.getOrDefault("X-Amz-Algorithm")
  valid_617559 = validateParameter(valid_617559, JString, required = false,
                                 default = nil)
  if valid_617559 != nil:
    section.add "X-Amz-Algorithm", valid_617559
  var valid_617560 = header.getOrDefault("X-Amz-Signature")
  valid_617560 = validateParameter(valid_617560, JString, required = false,
                                 default = nil)
  if valid_617560 != nil:
    section.add "X-Amz-Signature", valid_617560
  var valid_617561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617561 = validateParameter(valid_617561, JString, required = false,
                                 default = nil)
  if valid_617561 != nil:
    section.add "X-Amz-SignedHeaders", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-Target")
  valid_617562 = validateParameter(valid_617562, JString, required = true, default = newJString(
      "secretsmanager.GetResourcePolicy"))
  if valid_617562 != nil:
    section.add "X-Amz-Target", valid_617562
  var valid_617563 = header.getOrDefault("X-Amz-Credential")
  valid_617563 = validateParameter(valid_617563, JString, required = false,
                                 default = nil)
  if valid_617563 != nil:
    section.add "X-Amz-Credential", valid_617563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617565: Call_GetResourcePolicy_617553; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the JSON text of the resource-based policy document that's attached to the specified secret. The JSON request string input and response output are shown formatted with white space and line breaks for better readability. Submit your input as a single line JSON string.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_617565.validator(path, query, header, formData, body, _)
  let scheme = call_617565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617565.url(scheme.get, call_617565.host, call_617565.base,
                         call_617565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617565, url, valid, _)

proc call*(call_617566: Call_GetResourcePolicy_617553; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## <p>Retrieves the JSON text of the resource-based policy document that's attached to the specified secret. The JSON request string input and response output are shown formatted with white space and line breaks for better readability. Submit your input as a single line JSON string.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To attach a resource policy to a secret, use <a>PutResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617567 = newJObject()
  if body != nil:
    body_617567 = body
  result = call_617566.call(nil, nil, nil, nil, body_617567)

var getResourcePolicy* = Call_GetResourcePolicy_617553(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetResourcePolicy",
    validator: validate_GetResourcePolicy_617554, base: "/",
    url: url_GetResourcePolicy_617555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecretValue_617568 = ref object of OpenApiRestCall_616867
proc url_GetSecretValue_617570(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecretValue_617569(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617571 = header.getOrDefault("X-Amz-Date")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "X-Amz-Date", valid_617571
  var valid_617572 = header.getOrDefault("X-Amz-Security-Token")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Security-Token", valid_617572
  var valid_617573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "X-Amz-Content-Sha256", valid_617573
  var valid_617574 = header.getOrDefault("X-Amz-Algorithm")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-Algorithm", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-Signature")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Signature", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617576 = validateParameter(valid_617576, JString, required = false,
                                 default = nil)
  if valid_617576 != nil:
    section.add "X-Amz-SignedHeaders", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-Target")
  valid_617577 = validateParameter(valid_617577, JString, required = true, default = newJString(
      "secretsmanager.GetSecretValue"))
  if valid_617577 != nil:
    section.add "X-Amz-Target", valid_617577
  var valid_617578 = header.getOrDefault("X-Amz-Credential")
  valid_617578 = validateParameter(valid_617578, JString, required = false,
                                 default = nil)
  if valid_617578 != nil:
    section.add "X-Amz-Credential", valid_617578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617580: Call_GetSecretValue_617568; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the contents of the encrypted fields <code>SecretString</code> or <code>SecretBinary</code> from the specified version of a secret, whichever contains content.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetSecretValue</p> </li> <li> <p>kms:Decrypt - required only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new version of the secret with different encrypted information, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the non-encrypted details for the secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_617580.validator(path, query, header, formData, body, _)
  let scheme = call_617580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617580.url(scheme.get, call_617580.host, call_617580.base,
                         call_617580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617580, url, valid, _)

proc call*(call_617581: Call_GetSecretValue_617568; body: JsonNode): Recallable =
  ## getSecretValue
  ## <p>Retrieves the contents of the encrypted fields <code>SecretString</code> or <code>SecretBinary</code> from the specified version of a secret, whichever contains content.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:GetSecretValue</p> </li> <li> <p>kms:Decrypt - required only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new version of the secret with different encrypted information, use <a>PutSecretValue</a>.</p> </li> <li> <p>To retrieve the non-encrypted details for the secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617582 = newJObject()
  if body != nil:
    body_617582 = body
  result = call_617581.call(nil, nil, nil, nil, body_617582)

var getSecretValue* = Call_GetSecretValue_617568(name: "getSecretValue",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.GetSecretValue",
    validator: validate_GetSecretValue_617569, base: "/", url: url_GetSecretValue_617570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecretVersionIds_617583 = ref object of OpenApiRestCall_616867
proc url_ListSecretVersionIds_617585(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSecretVersionIds_617584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617586 = query.getOrDefault("NextToken")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "NextToken", valid_617586
  var valid_617587 = query.getOrDefault("MaxResults")
  valid_617587 = validateParameter(valid_617587, JString, required = false,
                                 default = nil)
  if valid_617587 != nil:
    section.add "MaxResults", valid_617587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617588 = header.getOrDefault("X-Amz-Date")
  valid_617588 = validateParameter(valid_617588, JString, required = false,
                                 default = nil)
  if valid_617588 != nil:
    section.add "X-Amz-Date", valid_617588
  var valid_617589 = header.getOrDefault("X-Amz-Security-Token")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-Security-Token", valid_617589
  var valid_617590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-Content-Sha256", valid_617590
  var valid_617591 = header.getOrDefault("X-Amz-Algorithm")
  valid_617591 = validateParameter(valid_617591, JString, required = false,
                                 default = nil)
  if valid_617591 != nil:
    section.add "X-Amz-Algorithm", valid_617591
  var valid_617592 = header.getOrDefault("X-Amz-Signature")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Signature", valid_617592
  var valid_617593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617593 = validateParameter(valid_617593, JString, required = false,
                                 default = nil)
  if valid_617593 != nil:
    section.add "X-Amz-SignedHeaders", valid_617593
  var valid_617594 = header.getOrDefault("X-Amz-Target")
  valid_617594 = validateParameter(valid_617594, JString, required = true, default = newJString(
      "secretsmanager.ListSecretVersionIds"))
  if valid_617594 != nil:
    section.add "X-Amz-Target", valid_617594
  var valid_617595 = header.getOrDefault("X-Amz-Credential")
  valid_617595 = validateParameter(valid_617595, JString, required = false,
                                 default = nil)
  if valid_617595 != nil:
    section.add "X-Amz-Credential", valid_617595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617597: Call_ListSecretVersionIds_617583; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_617597.validator(path, query, header, formData, body, _)
  let scheme = call_617597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617597.url(scheme.get, call_617597.host, call_617597.base,
                         call_617597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617597, url, valid, _)

proc call*(call_617598: Call_ListSecretVersionIds_617583; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSecretVersionIds
  ## <p>Lists all of the versions attached to the specified secret. The output does not include the <code>SecretString</code> or <code>SecretBinary</code> fields. By default, the list includes only versions that have at least one staging label in <code>VersionStage</code> attached.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecretVersionIds</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in an account, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617599 = newJObject()
  var body_617600 = newJObject()
  add(query_617599, "NextToken", newJString(NextToken))
  if body != nil:
    body_617600 = body
  add(query_617599, "MaxResults", newJString(MaxResults))
  result = call_617598.call(nil, query_617599, nil, nil, body_617600)

var listSecretVersionIds* = Call_ListSecretVersionIds_617583(
    name: "listSecretVersionIds", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.ListSecretVersionIds",
    validator: validate_ListSecretVersionIds_617584, base: "/",
    url: url_ListSecretVersionIds_617585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecrets_617602 = ref object of OpenApiRestCall_616867
proc url_ListSecrets_617604(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSecrets_617603(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617605 = query.getOrDefault("NextToken")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "NextToken", valid_617605
  var valid_617606 = query.getOrDefault("MaxResults")
  valid_617606 = validateParameter(valid_617606, JString, required = false,
                                 default = nil)
  if valid_617606 != nil:
    section.add "MaxResults", valid_617606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617607 = header.getOrDefault("X-Amz-Date")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "X-Amz-Date", valid_617607
  var valid_617608 = header.getOrDefault("X-Amz-Security-Token")
  valid_617608 = validateParameter(valid_617608, JString, required = false,
                                 default = nil)
  if valid_617608 != nil:
    section.add "X-Amz-Security-Token", valid_617608
  var valid_617609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617609 = validateParameter(valid_617609, JString, required = false,
                                 default = nil)
  if valid_617609 != nil:
    section.add "X-Amz-Content-Sha256", valid_617609
  var valid_617610 = header.getOrDefault("X-Amz-Algorithm")
  valid_617610 = validateParameter(valid_617610, JString, required = false,
                                 default = nil)
  if valid_617610 != nil:
    section.add "X-Amz-Algorithm", valid_617610
  var valid_617611 = header.getOrDefault("X-Amz-Signature")
  valid_617611 = validateParameter(valid_617611, JString, required = false,
                                 default = nil)
  if valid_617611 != nil:
    section.add "X-Amz-Signature", valid_617611
  var valid_617612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617612 = validateParameter(valid_617612, JString, required = false,
                                 default = nil)
  if valid_617612 != nil:
    section.add "X-Amz-SignedHeaders", valid_617612
  var valid_617613 = header.getOrDefault("X-Amz-Target")
  valid_617613 = validateParameter(valid_617613, JString, required = true, default = newJString(
      "secretsmanager.ListSecrets"))
  if valid_617613 != nil:
    section.add "X-Amz-Target", valid_617613
  var valid_617614 = header.getOrDefault("X-Amz-Credential")
  valid_617614 = validateParameter(valid_617614, JString, required = false,
                                 default = nil)
  if valid_617614 != nil:
    section.add "X-Amz-Credential", valid_617614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617616: Call_ListSecrets_617602; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_617616.validator(path, query, header, formData, body, _)
  let scheme = call_617616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617616.url(scheme.get, call_617616.host, call_617616.base,
                         call_617616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617616, url, valid, _)

proc call*(call_617617: Call_ListSecrets_617602; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSecrets
  ## <p>Lists all of the secrets that are stored by Secrets Manager in the AWS account. To list the versions currently stored for a specific secret, use <a>ListSecretVersionIds</a>. The encrypted fields <code>SecretString</code> and <code>SecretBinary</code> are not included in the output. To get that information, call the <a>GetSecretValue</a> operation.</p> <note> <p>Always check the <code>NextToken</code> response parameter when calling any of the <code>List*</code> operations. These operations can occasionally return an empty or shorter than expected list of results even when there are more results available. When this happens, the <code>NextToken</code> response parameter contains a value to pass to the next call to the same API to request the next part of the list.</p> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:ListSecrets</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617618 = newJObject()
  var body_617619 = newJObject()
  add(query_617618, "NextToken", newJString(NextToken))
  if body != nil:
    body_617619 = body
  add(query_617618, "MaxResults", newJString(MaxResults))
  result = call_617617.call(nil, query_617618, nil, nil, body_617619)

var listSecrets* = Call_ListSecrets_617602(name: "listSecrets",
                                        meth: HttpMethod.HttpPost,
                                        host: "secretsmanager.amazonaws.com", route: "/#X-Amz-Target=secretsmanager.ListSecrets",
                                        validator: validate_ListSecrets_617603,
                                        base: "/", url: url_ListSecrets_617604,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_617620 = ref object of OpenApiRestCall_616867
proc url_PutResourcePolicy_617622(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourcePolicy_617621(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617623 = header.getOrDefault("X-Amz-Date")
  valid_617623 = validateParameter(valid_617623, JString, required = false,
                                 default = nil)
  if valid_617623 != nil:
    section.add "X-Amz-Date", valid_617623
  var valid_617624 = header.getOrDefault("X-Amz-Security-Token")
  valid_617624 = validateParameter(valid_617624, JString, required = false,
                                 default = nil)
  if valid_617624 != nil:
    section.add "X-Amz-Security-Token", valid_617624
  var valid_617625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617625 = validateParameter(valid_617625, JString, required = false,
                                 default = nil)
  if valid_617625 != nil:
    section.add "X-Amz-Content-Sha256", valid_617625
  var valid_617626 = header.getOrDefault("X-Amz-Algorithm")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-Algorithm", valid_617626
  var valid_617627 = header.getOrDefault("X-Amz-Signature")
  valid_617627 = validateParameter(valid_617627, JString, required = false,
                                 default = nil)
  if valid_617627 != nil:
    section.add "X-Amz-Signature", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-SignedHeaders", valid_617628
  var valid_617629 = header.getOrDefault("X-Amz-Target")
  valid_617629 = validateParameter(valid_617629, JString, required = true, default = newJString(
      "secretsmanager.PutResourcePolicy"))
  if valid_617629 != nil:
    section.add "X-Amz-Target", valid_617629
  var valid_617630 = header.getOrDefault("X-Amz-Credential")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-Credential", valid_617630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617632: Call_PutResourcePolicy_617620; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches the contents of the specified resource-based permission policy to a secret. A resource-based policy is optional. Alternatively, you can use IAM identity-based policies that specify the secret's Amazon Resource Name (ARN) in the policy statement's <code>Resources</code> element. You can also use a combination of both identity-based and resource-based policies. The affected users and roles receive the permissions that are permitted by all of the relevant policies. For more information, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html">Using Resource-Based Policies for AWS Secrets Manager</a>. For the complete description of the AWS policy syntax and grammar, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html">IAM JSON Policy Reference</a> in the <i>IAM User Guide</i>.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the resource policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ## 
  let valid = call_617632.validator(path, query, header, formData, body, _)
  let scheme = call_617632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617632.url(scheme.get, call_617632.host, call_617632.base,
                         call_617632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617632, url, valid, _)

proc call*(call_617633: Call_PutResourcePolicy_617620; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## <p>Attaches the contents of the specified resource-based permission policy to a secret. A resource-based policy is optional. Alternatively, you can use IAM identity-based policies that specify the secret's Amazon Resource Name (ARN) in the policy statement's <code>Resources</code> element. You can also use a combination of both identity-based and resource-based policies. The affected users and roles receive the permissions that are permitted by all of the relevant policies. For more information, see <a href="http://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-based-policies.html">Using Resource-Based Policies for AWS Secrets Manager</a>. For the complete description of the AWS policy syntax and grammar, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html">IAM JSON Policy Reference</a> in the <i>IAM User Guide</i>.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutResourcePolicy</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the resource policy that's attached to a secret, use <a>GetResourcePolicy</a>.</p> </li> <li> <p>To delete the resource-based policy that's attached to a secret, use <a>DeleteResourcePolicy</a>.</p> </li> <li> <p>To list all of the currently available secrets, use <a>ListSecrets</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617634 = newJObject()
  if body != nil:
    body_617634 = body
  result = call_617633.call(nil, nil, nil, nil, body_617634)

var putResourcePolicy* = Call_PutResourcePolicy_617620(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.PutResourcePolicy",
    validator: validate_PutResourcePolicy_617621, base: "/",
    url: url_PutResourcePolicy_617622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSecretValue_617635 = ref object of OpenApiRestCall_616867
proc url_PutSecretValue_617637(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSecretValue_617636(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617638 = header.getOrDefault("X-Amz-Date")
  valid_617638 = validateParameter(valid_617638, JString, required = false,
                                 default = nil)
  if valid_617638 != nil:
    section.add "X-Amz-Date", valid_617638
  var valid_617639 = header.getOrDefault("X-Amz-Security-Token")
  valid_617639 = validateParameter(valid_617639, JString, required = false,
                                 default = nil)
  if valid_617639 != nil:
    section.add "X-Amz-Security-Token", valid_617639
  var valid_617640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617640 = validateParameter(valid_617640, JString, required = false,
                                 default = nil)
  if valid_617640 != nil:
    section.add "X-Amz-Content-Sha256", valid_617640
  var valid_617641 = header.getOrDefault("X-Amz-Algorithm")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-Algorithm", valid_617641
  var valid_617642 = header.getOrDefault("X-Amz-Signature")
  valid_617642 = validateParameter(valid_617642, JString, required = false,
                                 default = nil)
  if valid_617642 != nil:
    section.add "X-Amz-Signature", valid_617642
  var valid_617643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617643 = validateParameter(valid_617643, JString, required = false,
                                 default = nil)
  if valid_617643 != nil:
    section.add "X-Amz-SignedHeaders", valid_617643
  var valid_617644 = header.getOrDefault("X-Amz-Target")
  valid_617644 = validateParameter(valid_617644, JString, required = true, default = newJString(
      "secretsmanager.PutSecretValue"))
  if valid_617644 != nil:
    section.add "X-Amz-Target", valid_617644
  var valid_617645 = header.getOrDefault("X-Amz-Credential")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Credential", valid_617645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617647: Call_PutSecretValue_617635; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stores a new encrypted secret value in the specified secret. To do this, the operation creates a new version and attaches it to the secret. The version can contain a new <code>SecretString</code> value or a new <code>SecretBinary</code> value. You can also specify the staging labels that are initially attached to the new version.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> field. To add binary data to a secret with the <code>SecretBinary</code> field you must use the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If this operation creates the first version for the secret then Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> </li> <li> <p>If another version of this secret already exists, then this operation does not automatically move any staging labels other than those that you explicitly specify in the <code>VersionStages</code> parameter.</p> </li> <li> <p>If this operation moves the staging label <code>AWSCURRENT</code> from another version to this version (because you included it in the <code>StagingLabels</code> parameter) then Secrets Manager also automatically moves the staging label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </li> <li> <p>This operation is idempotent. If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you cannot modify an existing version; you can only create new ones.</p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutSecretValue</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the encrypted value you store in the version of a secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_617647.validator(path, query, header, formData, body, _)
  let scheme = call_617647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617647.url(scheme.get, call_617647.host, call_617647.base,
                         call_617647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617647, url, valid, _)

proc call*(call_617648: Call_PutSecretValue_617635; body: JsonNode): Recallable =
  ## putSecretValue
  ## <p>Stores a new encrypted secret value in the specified secret. To do this, the operation creates a new version and attaches it to the secret. The version can contain a new <code>SecretString</code> value or a new <code>SecretBinary</code> value. You can also specify the staging labels that are initially attached to the new version.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> field. To add binary data to a secret with the <code>SecretBinary</code> field you must use the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If this operation creates the first version for the secret then Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version.</p> </li> <li> <p>If another version of this secret already exists, then this operation does not automatically move any staging labels other than those that you explicitly specify in the <code>VersionStages</code> parameter.</p> </li> <li> <p>If this operation moves the staging label <code>AWSCURRENT</code> from another version to this version (because you included it in the <code>StagingLabels</code> parameter) then Secrets Manager also automatically moves the staging label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </li> <li> <p>This operation is idempotent. If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists and you specify the same secret data, the operation succeeds but does nothing. However, if the secret data is different, then the operation fails because you cannot modify an existing version; you can only create new ones.</p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:PutSecretValue</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a customer-managed AWS KMS key to encrypt the secret. You do not need this permission to use the account's default AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To retrieve the encrypted value you store in the version of a secret, use <a>GetSecretValue</a>.</p> </li> <li> <p>To create a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions attached to a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617649 = newJObject()
  if body != nil:
    body_617649 = body
  result = call_617648.call(nil, nil, nil, nil, body_617649)

var putSecretValue* = Call_PutSecretValue_617635(name: "putSecretValue",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.PutSecretValue",
    validator: validate_PutSecretValue_617636, base: "/", url: url_PutSecretValue_617637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreSecret_617650 = ref object of OpenApiRestCall_616867
proc url_RestoreSecret_617652(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestoreSecret_617651(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617653 = header.getOrDefault("X-Amz-Date")
  valid_617653 = validateParameter(valid_617653, JString, required = false,
                                 default = nil)
  if valid_617653 != nil:
    section.add "X-Amz-Date", valid_617653
  var valid_617654 = header.getOrDefault("X-Amz-Security-Token")
  valid_617654 = validateParameter(valid_617654, JString, required = false,
                                 default = nil)
  if valid_617654 != nil:
    section.add "X-Amz-Security-Token", valid_617654
  var valid_617655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617655 = validateParameter(valid_617655, JString, required = false,
                                 default = nil)
  if valid_617655 != nil:
    section.add "X-Amz-Content-Sha256", valid_617655
  var valid_617656 = header.getOrDefault("X-Amz-Algorithm")
  valid_617656 = validateParameter(valid_617656, JString, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "X-Amz-Algorithm", valid_617656
  var valid_617657 = header.getOrDefault("X-Amz-Signature")
  valid_617657 = validateParameter(valid_617657, JString, required = false,
                                 default = nil)
  if valid_617657 != nil:
    section.add "X-Amz-Signature", valid_617657
  var valid_617658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617658 = validateParameter(valid_617658, JString, required = false,
                                 default = nil)
  if valid_617658 != nil:
    section.add "X-Amz-SignedHeaders", valid_617658
  var valid_617659 = header.getOrDefault("X-Amz-Target")
  valid_617659 = validateParameter(valid_617659, JString, required = true, default = newJString(
      "secretsmanager.RestoreSecret"))
  if valid_617659 != nil:
    section.add "X-Amz-Target", valid_617659
  var valid_617660 = header.getOrDefault("X-Amz-Credential")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Credential", valid_617660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617662: Call_RestoreSecret_617650; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Cancels the scheduled deletion of a secret by removing the <code>DeletedDate</code> time stamp. This makes the secret accessible to query once again.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RestoreSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_617662.validator(path, query, header, formData, body, _)
  let scheme = call_617662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617662.url(scheme.get, call_617662.host, call_617662.base,
                         call_617662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617662, url, valid, _)

proc call*(call_617663: Call_RestoreSecret_617650; body: JsonNode): Recallable =
  ## restoreSecret
  ## <p>Cancels the scheduled deletion of a secret by removing the <code>DeletedDate</code> time stamp. This makes the secret accessible to query once again.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RestoreSecret</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To delete a secret, use <a>DeleteSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617664 = newJObject()
  if body != nil:
    body_617664 = body
  result = call_617663.call(nil, nil, nil, nil, body_617664)

var restoreSecret* = Call_RestoreSecret_617650(name: "restoreSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.RestoreSecret",
    validator: validate_RestoreSecret_617651, base: "/", url: url_RestoreSecret_617652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateSecret_617665 = ref object of OpenApiRestCall_616867
proc url_RotateSecret_617667(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RotateSecret_617666(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617668 = header.getOrDefault("X-Amz-Date")
  valid_617668 = validateParameter(valid_617668, JString, required = false,
                                 default = nil)
  if valid_617668 != nil:
    section.add "X-Amz-Date", valid_617668
  var valid_617669 = header.getOrDefault("X-Amz-Security-Token")
  valid_617669 = validateParameter(valid_617669, JString, required = false,
                                 default = nil)
  if valid_617669 != nil:
    section.add "X-Amz-Security-Token", valid_617669
  var valid_617670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617670 = validateParameter(valid_617670, JString, required = false,
                                 default = nil)
  if valid_617670 != nil:
    section.add "X-Amz-Content-Sha256", valid_617670
  var valid_617671 = header.getOrDefault("X-Amz-Algorithm")
  valid_617671 = validateParameter(valid_617671, JString, required = false,
                                 default = nil)
  if valid_617671 != nil:
    section.add "X-Amz-Algorithm", valid_617671
  var valid_617672 = header.getOrDefault("X-Amz-Signature")
  valid_617672 = validateParameter(valid_617672, JString, required = false,
                                 default = nil)
  if valid_617672 != nil:
    section.add "X-Amz-Signature", valid_617672
  var valid_617673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617673 = validateParameter(valid_617673, JString, required = false,
                                 default = nil)
  if valid_617673 != nil:
    section.add "X-Amz-SignedHeaders", valid_617673
  var valid_617674 = header.getOrDefault("X-Amz-Target")
  valid_617674 = validateParameter(valid_617674, JString, required = true, default = newJString(
      "secretsmanager.RotateSecret"))
  if valid_617674 != nil:
    section.add "X-Amz-Target", valid_617674
  var valid_617675 = header.getOrDefault("X-Amz-Credential")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-Credential", valid_617675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617677: Call_RotateSecret_617665; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configures and starts the asynchronous process of rotating this secret. If you include the configuration parameters, the operation sets those values for the secret and then immediately starts a rotation. If you do not include the configuration parameters, the operation starts a rotation with the values already stored in the secret. After the rotation completes, the protected service and its clients all use the new version of the secret. </p> <p>This required configuration information includes the ARN of an AWS Lambda function and the time between scheduled rotations. The Lambda rotation function creates a new version of the secret and creates or updates the credentials on the protected service to match. After testing the new credentials, the function marks the new secret with the staging label <code>AWSCURRENT</code> so that your clients all immediately begin to use the new version. For more information about rotating secrets and how to configure a Lambda function to rotate the secrets for your protected service, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html">Rotating Secrets in AWS Secrets Manager</a> in the <i>AWS Secrets Manager User Guide</i>.</p> <p>Secrets Manager schedules the next rotation when the previous one is complete. Secrets Manager schedules the date by adding the rotation interval (number of days) to the actual date of the last rotation. The service chooses the hour within that 24-hour date window randomly. The minute is also chosen somewhat randomly, but weighted towards the top of the hour and influenced by a variety of factors that help distribute load.</p> <p>The rotation function must end with the versions of the secret in one of two states:</p> <ul> <li> <p>The <code>AWSPENDING</code> and <code>AWSCURRENT</code> staging labels are attached to the same version of the secret, or</p> </li> <li> <p>The <code>AWSPENDING</code> staging label is not attached to any version of the secret.</p> </li> </ul> <p>If instead the <code>AWSPENDING</code> staging label is present but is not attached to the same version as <code>AWSCURRENT</code> then any later invocation of <code>RotateSecret</code> assumes that a previous rotation request is still in progress and returns an error.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RotateSecret</p> </li> <li> <p>lambda:InvokeFunction (on the function specified in the secret's metadata)</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in your account, use <a>ListSecrets</a>.</p> </li> <li> <p>To get the details for a version of a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To attach staging labels to or remove staging labels from a version of a secret, use <a>UpdateSecretVersionStage</a>.</p> </li> </ul>
  ## 
  let valid = call_617677.validator(path, query, header, formData, body, _)
  let scheme = call_617677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617677.url(scheme.get, call_617677.host, call_617677.base,
                         call_617677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617677, url, valid, _)

proc call*(call_617678: Call_RotateSecret_617665; body: JsonNode): Recallable =
  ## rotateSecret
  ## <p>Configures and starts the asynchronous process of rotating this secret. If you include the configuration parameters, the operation sets those values for the secret and then immediately starts a rotation. If you do not include the configuration parameters, the operation starts a rotation with the values already stored in the secret. After the rotation completes, the protected service and its clients all use the new version of the secret. </p> <p>This required configuration information includes the ARN of an AWS Lambda function and the time between scheduled rotations. The Lambda rotation function creates a new version of the secret and creates or updates the credentials on the protected service to match. After testing the new credentials, the function marks the new secret with the staging label <code>AWSCURRENT</code> so that your clients all immediately begin to use the new version. For more information about rotating secrets and how to configure a Lambda function to rotate the secrets for your protected service, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html">Rotating Secrets in AWS Secrets Manager</a> in the <i>AWS Secrets Manager User Guide</i>.</p> <p>Secrets Manager schedules the next rotation when the previous one is complete. Secrets Manager schedules the date by adding the rotation interval (number of days) to the actual date of the last rotation. The service chooses the hour within that 24-hour date window randomly. The minute is also chosen somewhat randomly, but weighted towards the top of the hour and influenced by a variety of factors that help distribute load.</p> <p>The rotation function must end with the versions of the secret in one of two states:</p> <ul> <li> <p>The <code>AWSPENDING</code> and <code>AWSCURRENT</code> staging labels are attached to the same version of the secret, or</p> </li> <li> <p>The <code>AWSPENDING</code> staging label is not attached to any version of the secret.</p> </li> </ul> <p>If instead the <code>AWSPENDING</code> staging label is present but is not attached to the same version as <code>AWSCURRENT</code> then any later invocation of <code>RotateSecret</code> assumes that a previous rotation request is still in progress and returns an error.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:RotateSecret</p> </li> <li> <p>lambda:InvokeFunction (on the function specified in the secret's metadata)</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To list the secrets in your account, use <a>ListSecrets</a>.</p> </li> <li> <p>To get the details for a version of a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To create a new version of a secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To attach staging labels to or remove staging labels from a version of a secret, use <a>UpdateSecretVersionStage</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617679 = newJObject()
  if body != nil:
    body_617679 = body
  result = call_617678.call(nil, nil, nil, nil, body_617679)

var rotateSecret* = Call_RotateSecret_617665(name: "rotateSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.RotateSecret",
    validator: validate_RotateSecret_617666, base: "/", url: url_RotateSecret_617667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617680 = ref object of OpenApiRestCall_616867
proc url_TagResource_617682(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_617681(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617683 = header.getOrDefault("X-Amz-Date")
  valid_617683 = validateParameter(valid_617683, JString, required = false,
                                 default = nil)
  if valid_617683 != nil:
    section.add "X-Amz-Date", valid_617683
  var valid_617684 = header.getOrDefault("X-Amz-Security-Token")
  valid_617684 = validateParameter(valid_617684, JString, required = false,
                                 default = nil)
  if valid_617684 != nil:
    section.add "X-Amz-Security-Token", valid_617684
  var valid_617685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617685 = validateParameter(valid_617685, JString, required = false,
                                 default = nil)
  if valid_617685 != nil:
    section.add "X-Amz-Content-Sha256", valid_617685
  var valid_617686 = header.getOrDefault("X-Amz-Algorithm")
  valid_617686 = validateParameter(valid_617686, JString, required = false,
                                 default = nil)
  if valid_617686 != nil:
    section.add "X-Amz-Algorithm", valid_617686
  var valid_617687 = header.getOrDefault("X-Amz-Signature")
  valid_617687 = validateParameter(valid_617687, JString, required = false,
                                 default = nil)
  if valid_617687 != nil:
    section.add "X-Amz-Signature", valid_617687
  var valid_617688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617688 = validateParameter(valid_617688, JString, required = false,
                                 default = nil)
  if valid_617688 != nil:
    section.add "X-Amz-SignedHeaders", valid_617688
  var valid_617689 = header.getOrDefault("X-Amz-Target")
  valid_617689 = validateParameter(valid_617689, JString, required = true, default = newJString(
      "secretsmanager.TagResource"))
  if valid_617689 != nil:
    section.add "X-Amz-Target", valid_617689
  var valid_617690 = header.getOrDefault("X-Amz-Credential")
  valid_617690 = validateParameter(valid_617690, JString, required = false,
                                 default = nil)
  if valid_617690 != nil:
    section.add "X-Amz-Credential", valid_617690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617692: Call_TagResource_617680; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches one or more tags, each consisting of a key name and a value, to the specified secret. Tags are part of the secret's overall metadata, and are not associated with any specific version of the secret. This operation only appends tags to the existing list of tags. To remove tags, you must use <a>UntagResource</a>.</p> <p>The following basic restrictions apply to tags:</p> <ul> <li> <p>Maximum number of tags per secret—50</p> </li> <li> <p>Maximum key length—127 Unicode characters in UTF-8</p> </li> <li> <p>Maximum value length—255 Unicode characters in UTF-8</p> </li> <li> <p>Tag keys and values are case sensitive.</p> </li> <li> <p>Do not use the <code>aws:</code> prefix in your tag names or values because it is reserved for AWS use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit.</p> </li> <li> <p>If your tagging schema will be used across multiple services and resources, remember that other services might have restrictions on allowed characters. Generally allowed characters are: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @.</p> </li> </ul> <important> <p>If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:TagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To remove one or more tags from the collection attached to a secret, use <a>UntagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_617692.validator(path, query, header, formData, body, _)
  let scheme = call_617692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617692.url(scheme.get, call_617692.host, call_617692.base,
                         call_617692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617692, url, valid, _)

proc call*(call_617693: Call_TagResource_617680; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches one or more tags, each consisting of a key name and a value, to the specified secret. Tags are part of the secret's overall metadata, and are not associated with any specific version of the secret. This operation only appends tags to the existing list of tags. To remove tags, you must use <a>UntagResource</a>.</p> <p>The following basic restrictions apply to tags:</p> <ul> <li> <p>Maximum number of tags per secret—50</p> </li> <li> <p>Maximum key length—127 Unicode characters in UTF-8</p> </li> <li> <p>Maximum value length—255 Unicode characters in UTF-8</p> </li> <li> <p>Tag keys and values are case sensitive.</p> </li> <li> <p>Do not use the <code>aws:</code> prefix in your tag names or values because it is reserved for AWS use. You can't edit or delete tag names or values with this prefix. Tags with this prefix do not count against your tags per secret limit.</p> </li> <li> <p>If your tagging schema will be used across multiple services and resources, remember that other services might have restrictions on allowed characters. Generally allowed characters are: letters, spaces, and numbers representable in UTF-8, plus the following special characters: + - = . _ : / @.</p> </li> </ul> <important> <p>If you use tags as part of your security strategy, then adding or removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:TagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To remove one or more tags from the collection attached to a secret, use <a>UntagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617694 = newJObject()
  if body != nil:
    body_617694 = body
  result = call_617693.call(nil, nil, nil, nil, body_617694)

var tagResource* = Call_TagResource_617680(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "secretsmanager.amazonaws.com", route: "/#X-Amz-Target=secretsmanager.TagResource",
                                        validator: validate_TagResource_617681,
                                        base: "/", url: url_TagResource_617682,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617695 = ref object of OpenApiRestCall_616867
proc url_UntagResource_617697(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_617696(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617698 = header.getOrDefault("X-Amz-Date")
  valid_617698 = validateParameter(valid_617698, JString, required = false,
                                 default = nil)
  if valid_617698 != nil:
    section.add "X-Amz-Date", valid_617698
  var valid_617699 = header.getOrDefault("X-Amz-Security-Token")
  valid_617699 = validateParameter(valid_617699, JString, required = false,
                                 default = nil)
  if valid_617699 != nil:
    section.add "X-Amz-Security-Token", valid_617699
  var valid_617700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617700 = validateParameter(valid_617700, JString, required = false,
                                 default = nil)
  if valid_617700 != nil:
    section.add "X-Amz-Content-Sha256", valid_617700
  var valid_617701 = header.getOrDefault("X-Amz-Algorithm")
  valid_617701 = validateParameter(valid_617701, JString, required = false,
                                 default = nil)
  if valid_617701 != nil:
    section.add "X-Amz-Algorithm", valid_617701
  var valid_617702 = header.getOrDefault("X-Amz-Signature")
  valid_617702 = validateParameter(valid_617702, JString, required = false,
                                 default = nil)
  if valid_617702 != nil:
    section.add "X-Amz-Signature", valid_617702
  var valid_617703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617703 = validateParameter(valid_617703, JString, required = false,
                                 default = nil)
  if valid_617703 != nil:
    section.add "X-Amz-SignedHeaders", valid_617703
  var valid_617704 = header.getOrDefault("X-Amz-Target")
  valid_617704 = validateParameter(valid_617704, JString, required = true, default = newJString(
      "secretsmanager.UntagResource"))
  if valid_617704 != nil:
    section.add "X-Amz-Target", valid_617704
  var valid_617705 = header.getOrDefault("X-Amz-Credential")
  valid_617705 = validateParameter(valid_617705, JString, required = false,
                                 default = nil)
  if valid_617705 != nil:
    section.add "X-Amz-Credential", valid_617705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617707: Call_UntagResource_617695; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes one or more tags from the specified secret.</p> <p>This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged.</p> <important> <p>If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UntagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To add one or more tags to the collection attached to a secret, use <a>TagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ## 
  let valid = call_617707.validator(path, query, header, formData, body, _)
  let scheme = call_617707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617707.url(scheme.get, call_617707.host, call_617707.base,
                         call_617707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617707, url, valid, _)

proc call*(call_617708: Call_UntagResource_617695; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes one or more tags from the specified secret.</p> <p>This operation is idempotent. If a requested tag is not attached to the secret, no error is returned and the secret metadata is unchanged.</p> <important> <p>If you use tags as part of your security strategy, then removing a tag can change permissions. If successfully completing this operation would result in you losing your permissions for this secret, then the operation is blocked and returns an Access Denied error.</p> </important> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UntagResource</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To add one or more tags to the collection attached to a secret, use <a>TagResource</a>.</p> </li> <li> <p>To view the list of tags attached to a secret, use <a>DescribeSecret</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617709 = newJObject()
  if body != nil:
    body_617709 = body
  result = call_617708.call(nil, nil, nil, nil, body_617709)

var untagResource* = Call_UntagResource_617695(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UntagResource",
    validator: validate_UntagResource_617696, base: "/", url: url_UntagResource_617697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSecret_617710 = ref object of OpenApiRestCall_616867
proc url_UpdateSecret_617712(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSecret_617711(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617713 = header.getOrDefault("X-Amz-Date")
  valid_617713 = validateParameter(valid_617713, JString, required = false,
                                 default = nil)
  if valid_617713 != nil:
    section.add "X-Amz-Date", valid_617713
  var valid_617714 = header.getOrDefault("X-Amz-Security-Token")
  valid_617714 = validateParameter(valid_617714, JString, required = false,
                                 default = nil)
  if valid_617714 != nil:
    section.add "X-Amz-Security-Token", valid_617714
  var valid_617715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617715 = validateParameter(valid_617715, JString, required = false,
                                 default = nil)
  if valid_617715 != nil:
    section.add "X-Amz-Content-Sha256", valid_617715
  var valid_617716 = header.getOrDefault("X-Amz-Algorithm")
  valid_617716 = validateParameter(valid_617716, JString, required = false,
                                 default = nil)
  if valid_617716 != nil:
    section.add "X-Amz-Algorithm", valid_617716
  var valid_617717 = header.getOrDefault("X-Amz-Signature")
  valid_617717 = validateParameter(valid_617717, JString, required = false,
                                 default = nil)
  if valid_617717 != nil:
    section.add "X-Amz-Signature", valid_617717
  var valid_617718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617718 = validateParameter(valid_617718, JString, required = false,
                                 default = nil)
  if valid_617718 != nil:
    section.add "X-Amz-SignedHeaders", valid_617718
  var valid_617719 = header.getOrDefault("X-Amz-Target")
  valid_617719 = validateParameter(valid_617719, JString, required = true, default = newJString(
      "secretsmanager.UpdateSecret"))
  if valid_617719 != nil:
    section.add "X-Amz-Target", valid_617719
  var valid_617720 = header.getOrDefault("X-Amz-Credential")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-Credential", valid_617720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617722: Call_UpdateSecret_617710; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies many of the details of the specified secret. If you include a <code>ClientRequestToken</code> and <i>either</i> <code>SecretString</code> or <code>SecretBinary</code> then it also creates a new version attached to the secret.</p> <p>To modify the rotation configuration of a secret, use <a>RotateSecret</a> instead.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> parameter and therefore limits you to encrypting and storing only a text string. To encrypt and store binary data as part of the version of a secret, you must use either the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists, the operation results in an error. You cannot modify an existing version, you can only create a new version.</p> </li> <li> <p>If you include <code>SecretString</code> or <code>SecretBinary</code> to create a new secret version, Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version. </p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To add only a new version to an existing secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions contained in a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ## 
  let valid = call_617722.validator(path, query, header, formData, body, _)
  let scheme = call_617722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617722.url(scheme.get, call_617722.host, call_617722.base,
                         call_617722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617722, url, valid, _)

proc call*(call_617723: Call_UpdateSecret_617710; body: JsonNode): Recallable =
  ## updateSecret
  ## <p>Modifies many of the details of the specified secret. If you include a <code>ClientRequestToken</code> and <i>either</i> <code>SecretString</code> or <code>SecretBinary</code> then it also creates a new version attached to the secret.</p> <p>To modify the rotation configuration of a secret, use <a>RotateSecret</a> instead.</p> <note> <p>The Secrets Manager console uses only the <code>SecretString</code> parameter and therefore limits you to encrypting and storing only a text string. To encrypt and store binary data as part of the version of a secret, you must use either the AWS CLI or one of the AWS SDKs.</p> </note> <ul> <li> <p>If a version with a <code>VersionId</code> with the same value as the <code>ClientRequestToken</code> parameter already exists, the operation results in an error. You cannot modify an existing version, you can only create a new version.</p> </li> <li> <p>If you include <code>SecretString</code> or <code>SecretBinary</code> to create a new secret version, Secrets Manager automatically attaches the staging label <code>AWSCURRENT</code> to the new version. </p> </li> </ul> <note> <ul> <li> <p>If you call an operation that needs to encrypt or decrypt the <code>SecretString</code> or <code>SecretBinary</code> for a secret in the same account as the calling user and that secret doesn't specify a AWS KMS encryption key, Secrets Manager uses the account's default AWS managed customer master key (CMK) with the alias <code>aws/secretsmanager</code>. If this key doesn't already exist in your account then Secrets Manager creates it for you automatically. All users and roles in the same AWS account automatically have access to use the default CMK. Note that if an Secrets Manager API call results in AWS having to create the account's AWS-managed CMK, it can result in a one-time significant delay in returning the result.</p> </li> <li> <p>If the secret is in a different AWS account from the credentials calling an API that requires encryption or decryption of the secret value then you must create and use a custom AWS KMS CMK because you can't access the default CMK for the account using credentials from a different AWS account. Store the ARN of the CMK in the secret when you create the secret or when you update it by including it in the <code>KMSKeyId</code>. If you call an API that must encrypt or decrypt <code>SecretString</code> or <code>SecretBinary</code> using credentials from a different account then the AWS KMS key policy must grant cross-account access to that other account's user or role for both the kms:GenerateDataKey and kms:Decrypt operations.</p> </li> </ul> </note> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecret</p> </li> <li> <p>kms:GenerateDataKey - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> <li> <p>kms:Decrypt - needed only if you use a custom AWS KMS key to encrypt the secret. You do not need this permission to use the account's AWS managed CMK for Secrets Manager.</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To create a new secret, use <a>CreateSecret</a>.</p> </li> <li> <p>To add only a new version to an existing secret, use <a>PutSecretValue</a>.</p> </li> <li> <p>To get the details for a secret, use <a>DescribeSecret</a>.</p> </li> <li> <p>To list the versions contained in a secret, use <a>ListSecretVersionIds</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_617724 = newJObject()
  if body != nil:
    body_617724 = body
  result = call_617723.call(nil, nil, nil, nil, body_617724)

var updateSecret* = Call_UpdateSecret_617710(name: "updateSecret",
    meth: HttpMethod.HttpPost, host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UpdateSecret",
    validator: validate_UpdateSecret_617711, base: "/", url: url_UpdateSecret_617712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSecretVersionStage_617725 = ref object of OpenApiRestCall_616867
proc url_UpdateSecretVersionStage_617727(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSecretVersionStage_617726(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617728 = header.getOrDefault("X-Amz-Date")
  valid_617728 = validateParameter(valid_617728, JString, required = false,
                                 default = nil)
  if valid_617728 != nil:
    section.add "X-Amz-Date", valid_617728
  var valid_617729 = header.getOrDefault("X-Amz-Security-Token")
  valid_617729 = validateParameter(valid_617729, JString, required = false,
                                 default = nil)
  if valid_617729 != nil:
    section.add "X-Amz-Security-Token", valid_617729
  var valid_617730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617730 = validateParameter(valid_617730, JString, required = false,
                                 default = nil)
  if valid_617730 != nil:
    section.add "X-Amz-Content-Sha256", valid_617730
  var valid_617731 = header.getOrDefault("X-Amz-Algorithm")
  valid_617731 = validateParameter(valid_617731, JString, required = false,
                                 default = nil)
  if valid_617731 != nil:
    section.add "X-Amz-Algorithm", valid_617731
  var valid_617732 = header.getOrDefault("X-Amz-Signature")
  valid_617732 = validateParameter(valid_617732, JString, required = false,
                                 default = nil)
  if valid_617732 != nil:
    section.add "X-Amz-Signature", valid_617732
  var valid_617733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617733 = validateParameter(valid_617733, JString, required = false,
                                 default = nil)
  if valid_617733 != nil:
    section.add "X-Amz-SignedHeaders", valid_617733
  var valid_617734 = header.getOrDefault("X-Amz-Target")
  valid_617734 = validateParameter(valid_617734, JString, required = true, default = newJString(
      "secretsmanager.UpdateSecretVersionStage"))
  if valid_617734 != nil:
    section.add "X-Amz-Target", valid_617734
  var valid_617735 = header.getOrDefault("X-Amz-Credential")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-Credential", valid_617735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617737: Call_UpdateSecretVersionStage_617725; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the staging labels attached to a version of a secret. Staging labels are used to track a version as it progresses through the secret rotation process. You can attach a staging label to only one version of a secret at a time. If a staging label to be added is already attached to another version, then it is moved--removed from the other version first and then attached to this one. For more information about staging labels, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html#term_staging-label">Staging Labels</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>The staging labels that you specify in the <code>VersionStage</code> parameter are added to the existing list of staging labels--they don't replace it.</p> <p>You can move the <code>AWSCURRENT</code> staging label to this version by including it in this call.</p> <note> <p>Whenever you move <code>AWSCURRENT</code>, Secrets Manager automatically moves the label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </note> <p>If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecretVersionStage</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To get the list of staging labels that are currently associated with a version of a secret, use <code> <a>DescribeSecret</a> </code> and examine the <code>SecretVersionsToStages</code> response value. </p> </li> </ul>
  ## 
  let valid = call_617737.validator(path, query, header, formData, body, _)
  let scheme = call_617737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617737.url(scheme.get, call_617737.host, call_617737.base,
                         call_617737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617737, url, valid, _)

proc call*(call_617738: Call_UpdateSecretVersionStage_617725; body: JsonNode): Recallable =
  ## updateSecretVersionStage
  ## <p>Modifies the staging labels attached to a version of a secret. Staging labels are used to track a version as it progresses through the secret rotation process. You can attach a staging label to only one version of a secret at a time. If a staging label to be added is already attached to another version, then it is moved--removed from the other version first and then attached to this one. For more information about staging labels, see <a href="https://docs.aws.amazon.com/secretsmanager/latest/userguide/terms-concepts.html#term_staging-label">Staging Labels</a> in the <i>AWS Secrets Manager User Guide</i>. </p> <p>The staging labels that you specify in the <code>VersionStage</code> parameter are added to the existing list of staging labels--they don't replace it.</p> <p>You can move the <code>AWSCURRENT</code> staging label to this version by including it in this call.</p> <note> <p>Whenever you move <code>AWSCURRENT</code>, Secrets Manager automatically moves the label <code>AWSPREVIOUS</code> to the version that <code>AWSCURRENT</code> was removed from.</p> </note> <p>If this action results in the last label being removed from a version, then the version is considered to be 'deprecated' and can be deleted by Secrets Manager.</p> <p> <b>Minimum permissions</b> </p> <p>To run this command, you must have the following permissions:</p> <ul> <li> <p>secretsmanager:UpdateSecretVersionStage</p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p>To get the list of staging labels that are currently associated with a version of a secret, use <code> <a>DescribeSecret</a> </code> and examine the <code>SecretVersionsToStages</code> response value. </p> </li> </ul>
  ##   body: JObject (required)
  var body_617739 = newJObject()
  if body != nil:
    body_617739 = body
  result = call_617738.call(nil, nil, nil, nil, body_617739)

var updateSecretVersionStage* = Call_UpdateSecretVersionStage_617725(
    name: "updateSecretVersionStage", meth: HttpMethod.HttpPost,
    host: "secretsmanager.amazonaws.com",
    route: "/#X-Amz-Target=secretsmanager.UpdateSecretVersionStage",
    validator: validate_UpdateSecretVersionStage_617726, base: "/",
    url: url_UpdateSecretVersionStage_617727, schemes: {Scheme.Https, Scheme.Http})
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
