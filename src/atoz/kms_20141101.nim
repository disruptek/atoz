
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Key Management Service
## version: 2014-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Key Management Service</fullname> <p>AWS Key Management Service (AWS KMS) is an encryption and key management web service. This guide describes the AWS KMS operations that you can call programmatically. For general information about AWS KMS, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/"> <i>AWS Key Management Service Developer Guide</i> </a>.</p> <note> <p>AWS provides SDKs that consist of libraries and sample code for various programming languages and platforms (Java, Ruby, .Net, macOS, Android, etc.). The SDKs provide a convenient way to create programmatic access to AWS KMS and other AWS services. For example, the SDKs take care of tasks such as signing requests (see below), managing errors, and retrying requests automatically. For more information about the AWS SDKs, including how to download and install them, see <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> </note> <p>We recommend that you use the AWS SDKs to make programmatic API calls to AWS KMS.</p> <p>Clients must support TLS (Transport Layer Security) 1.0. We recommend TLS 1.2. Clients must also support cipher suites with Perfect Forward Secrecy (PFS) such as Ephemeral Diffie-Hellman (DHE) or Elliptic Curve Ephemeral Diffie-Hellman (ECDHE). Most modern systems such as Java 7 and later support these modes.</p> <p> <b>Signing Requests</b> </p> <p>Requests must be signed by using an access key ID and a secret access key. We strongly recommend that you <i>do not</i> use your AWS account (root) access key ID and secret key for everyday work with AWS KMS. Instead, use the access key ID and secret access key for an IAM user. You can also use the AWS Security Token Service to generate temporary security credentials that you can use to sign requests.</p> <p>All AWS KMS operations require <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4</a>.</p> <p> <b>Logging API Requests</b> </p> <p>AWS KMS supports AWS CloudTrail, a service that logs AWS API calls and related events for your AWS account and delivers them to an Amazon S3 bucket that you specify. By using the information collected by CloudTrail, you can determine what requests were made to AWS KMS, who made the request, when it was made, and so on. To learn more about CloudTrail, including how to turn it on and find your log files, see the <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/">AWS CloudTrail User Guide</a>.</p> <p> <b>Additional Resources</b> </p> <p>For more information about credentials and request signing, see the following:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html">AWS Security Credentials</a> - This topic provides general information about the types of credentials used for accessing AWS.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html">Temporary Security Credentials</a> - This section of the <i>IAM User Guide</i> describes how to create and use temporary security credentials.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a> - This set of topics walks you through the process of signing a request using an access key ID and a secret access key.</p> </li> </ul> <p> <b>Commonly Used API Operations</b> </p> <p>Of the API operations discussed in this guide, the following will prove the most useful for most applications. You will likely perform operations other than these, such as creating keys and assigning policies, by using the console.</p> <ul> <li> <p> <a>Encrypt</a> </p> </li> <li> <p> <a>Decrypt</a> </p> </li> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/kms/
type
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "kms.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kms.ap-southeast-1.amazonaws.com",
                               "us-west-2": "kms.us-west-2.amazonaws.com",
                               "eu-west-2": "kms.eu-west-2.amazonaws.com", "ap-northeast-3": "kms.ap-northeast-3.amazonaws.com", "eu-central-1": "kms.eu-central-1.amazonaws.com",
                               "us-east-2": "kms.us-east-2.amazonaws.com",
                               "us-east-1": "kms.us-east-1.amazonaws.com", "cn-northwest-1": "kms.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "kms.ap-south-1.amazonaws.com",
                               "eu-north-1": "kms.eu-north-1.amazonaws.com", "ap-northeast-2": "kms.ap-northeast-2.amazonaws.com",
                               "us-west-1": "kms.us-west-1.amazonaws.com", "us-gov-east-1": "kms.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "kms.eu-west-3.amazonaws.com",
                               "cn-north-1": "kms.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "kms.sa-east-1.amazonaws.com",
                               "eu-west-1": "kms.eu-west-1.amazonaws.com", "us-gov-west-1": "kms.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kms.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "kms.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "kms.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "kms.ap-southeast-1.amazonaws.com",
      "us-west-2": "kms.us-west-2.amazonaws.com",
      "eu-west-2": "kms.eu-west-2.amazonaws.com",
      "ap-northeast-3": "kms.ap-northeast-3.amazonaws.com",
      "eu-central-1": "kms.eu-central-1.amazonaws.com",
      "us-east-2": "kms.us-east-2.amazonaws.com",
      "us-east-1": "kms.us-east-1.amazonaws.com",
      "cn-northwest-1": "kms.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "kms.ap-south-1.amazonaws.com",
      "eu-north-1": "kms.eu-north-1.amazonaws.com",
      "ap-northeast-2": "kms.ap-northeast-2.amazonaws.com",
      "us-west-1": "kms.us-west-1.amazonaws.com",
      "us-gov-east-1": "kms.us-gov-east-1.amazonaws.com",
      "eu-west-3": "kms.eu-west-3.amazonaws.com",
      "cn-north-1": "kms.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "kms.sa-east-1.amazonaws.com",
      "eu-west-1": "kms.eu-west-1.amazonaws.com",
      "us-gov-west-1": "kms.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "kms.ap-southeast-2.amazonaws.com",
      "ca-central-1": "kms.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "kms"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CancelKeyDeletion_402656294 = ref object of OpenApiRestCall_402656044
proc url_CancelKeyDeletion_402656296(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelKeyDeletion_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation succeeds, the key state of the CMK is <code>Disabled</code>. To enable the CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "TrentService.CancelKeyDeletion"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
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

proc call*(call_402656412: Call_CancelKeyDeletion_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation succeeds, the key state of the CMK is <code>Disabled</code>. To enable the CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_CancelKeyDeletion_402656294; body: JsonNode): Recallable =
  ## cancelKeyDeletion
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation succeeds, the key state of the CMK is <code>Disabled</code>. To enable the CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var cancelKeyDeletion* = Call_CancelKeyDeletion_402656294(
    name: "cancelKeyDeletion", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CancelKeyDeletion",
    validator: validate_CancelKeyDeletion_402656295, base: "/",
    makeUrl: url_CancelKeyDeletion_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectCustomKeyStore_402656489 = ref object of OpenApiRestCall_402656044
proc url_ConnectCustomKeyStore_402656491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConnectCustomKeyStore_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation. Also, the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU) must not be logged into the cluster. This prevents AWS KMS from using this account to log in.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <code>kmsuser</code> CU, and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "TrentService.ConnectCustomKeyStore"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_ConnectCustomKeyStore_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation. Also, the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU) must not be logged into the cluster. This prevents AWS KMS from using this account to log in.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <code>kmsuser</code> CU, and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_ConnectCustomKeyStore_402656489; body: JsonNode): Recallable =
  ## connectCustomKeyStore
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation. Also, the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU) must not be logged into the cluster. This prevents AWS KMS from using this account to log in.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <code>kmsuser</code> CU, and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var connectCustomKeyStore* = Call_ConnectCustomKeyStore_402656489(
    name: "connectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ConnectCustomKeyStore",
    validator: validate_ConnectCustomKeyStore_402656490, base: "/",
    makeUrl: url_ConnectCustomKeyStore_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateAlias_402656506(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlias_402656505(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in cryptographic operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. You can change the CMK associated with the alias at any time.</p> <p>Aliases are easier to remember than key IDs. They can also help to simplify your applications. For example, if you use an alias in your code, you can change the CMK your code uses by associating a given alias with a different CMK. </p> <p>To run the same code in multiple AWS regions, use an alias in your code, such as <code>alias/ApplicationKey</code>. Then, in each AWS Region, create an <code>alias/ApplicationKey</code> alias that is associated with a CMK in that Region. When you run your code, it uses the <code>alias/ApplicationKey</code> CMK for that AWS Region without any Region-specific code.</p> <p>This operation does not return a response. To get the alias that you created, use the <a>ListAliases</a> operation.</p> <p>To use aliases successfully, be aware of the following information.</p> <ul> <li> <p>Each alias points to only one CMK at a time, although a single CMK can have multiple aliases. The alias and its associated CMK must be in the same AWS account and Region. </p> </li> <li> <p>You can associate an alias with any customer managed CMK in the same AWS account and Region. However, you do not have permission to associate an alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk">AWS owned CMK</a>. </p> </li> <li> <p>To change the CMK associated with an alias, use the <a>UpdateAlias</a> operation. The current CMK and the new CMK must be the same type (both symmetric or both asymmetric) and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents cryptographic errors in code that uses aliases.</p> </li> <li> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> </li> <li> <p>The alias name must be unique within an AWS Region. However, you can use the same alias name in multiple Regions of the same AWS account. Each instance of the alias is associated with a CMK in its Region.</p> </li> <li> <p>After you create an alias, you cannot change its alias name. However, you can use the <a>DeleteAlias</a> operation to delete the alias and then create a new alias with the desired name.</p> </li> <li> <p>You can use an alias name or alias ARN to identify a CMK in AWS KMS cryptographic operations and in the <a>DescribeKey</a> operation. However, you cannot use alias names or alias ARNs in API operations that manage CMKs, such as <a>DisableKey</a> or <a>GetKeyPolicy</a>. For information about the valid CMK identifiers for each AWS KMS API operation, see the descriptions of the <code>KeyId</code> parameter in the API operation documentation.</p> </li> </ul> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases and alias ARNs of CMKs in each AWS account and Region, use the <a>ListAliases</a> operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "TrentService.CreateAlias"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_CreateAlias_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in cryptographic operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. You can change the CMK associated with the alias at any time.</p> <p>Aliases are easier to remember than key IDs. They can also help to simplify your applications. For example, if you use an alias in your code, you can change the CMK your code uses by associating a given alias with a different CMK. </p> <p>To run the same code in multiple AWS regions, use an alias in your code, such as <code>alias/ApplicationKey</code>. Then, in each AWS Region, create an <code>alias/ApplicationKey</code> alias that is associated with a CMK in that Region. When you run your code, it uses the <code>alias/ApplicationKey</code> CMK for that AWS Region without any Region-specific code.</p> <p>This operation does not return a response. To get the alias that you created, use the <a>ListAliases</a> operation.</p> <p>To use aliases successfully, be aware of the following information.</p> <ul> <li> <p>Each alias points to only one CMK at a time, although a single CMK can have multiple aliases. The alias and its associated CMK must be in the same AWS account and Region. </p> </li> <li> <p>You can associate an alias with any customer managed CMK in the same AWS account and Region. However, you do not have permission to associate an alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk">AWS owned CMK</a>. </p> </li> <li> <p>To change the CMK associated with an alias, use the <a>UpdateAlias</a> operation. The current CMK and the new CMK must be the same type (both symmetric or both asymmetric) and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents cryptographic errors in code that uses aliases.</p> </li> <li> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> </li> <li> <p>The alias name must be unique within an AWS Region. However, you can use the same alias name in multiple Regions of the same AWS account. Each instance of the alias is associated with a CMK in its Region.</p> </li> <li> <p>After you create an alias, you cannot change its alias name. However, you can use the <a>DeleteAlias</a> operation to delete the alias and then create a new alias with the desired name.</p> </li> <li> <p>You can use an alias name or alias ARN to identify a CMK in AWS KMS cryptographic operations and in the <a>DescribeKey</a> operation. However, you cannot use alias names or alias ARNs in API operations that manage CMKs, such as <a>DisableKey</a> or <a>GetKeyPolicy</a>. For information about the valid CMK identifiers for each AWS KMS API operation, see the descriptions of the <code>KeyId</code> parameter in the API operation documentation.</p> </li> </ul> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases and alias ARNs of CMKs in each AWS account and Region, use the <a>ListAliases</a> operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateAlias_402656504; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in cryptographic operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. You can change the CMK associated with the alias at any time.</p> <p>Aliases are easier to remember than key IDs. They can also help to simplify your applications. For example, if you use an alias in your code, you can change the CMK your code uses by associating a given alias with a different CMK. </p> <p>To run the same code in multiple AWS regions, use an alias in your code, such as <code>alias/ApplicationKey</code>. Then, in each AWS Region, create an <code>alias/ApplicationKey</code> alias that is associated with a CMK in that Region. When you run your code, it uses the <code>alias/ApplicationKey</code> CMK for that AWS Region without any Region-specific code.</p> <p>This operation does not return a response. To get the alias that you created, use the <a>ListAliases</a> operation.</p> <p>To use aliases successfully, be aware of the following information.</p> <ul> <li> <p>Each alias points to only one CMK at a time, although a single CMK can have multiple aliases. The alias and its associated CMK must be in the same AWS account and Region. </p> </li> <li> <p>You can associate an alias with any customer managed CMK in the same AWS account and Region. However, you do not have permission to associate an alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk">AWS owned CMK</a>. </p> </li> <li> <p>To change the CMK associated with an alias, use the <a>UpdateAlias</a> operation. The current CMK and the new CMK must be the same type (both symmetric or both asymmetric) and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents cryptographic errors in code that uses aliases.</p> </li> <li> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> </li> <li> <p>The alias name must be unique within an AWS Region. However, you can use the same alias name in multiple Regions of the same AWS account. Each instance of the alias is associated with a CMK in its Region.</p> </li> <li> <p>After you create an alias, you cannot change its alias name. However, you can use the <a>DeleteAlias</a> operation to delete the alias and then create a new alias with the desired name.</p> </li> <li> <p>You can use an alias name or alias ARN to identify a CMK in AWS KMS cryptographic operations and in the <a>DescribeKey</a> operation. However, you cannot use alias names or alias ARNs in API operations that manage CMKs, such as <a>DisableKey</a> or <a>GetKeyPolicy</a>. For information about the valid CMK identifiers for each AWS KMS API operation, see the descriptions of the <code>KeyId</code> parameter in the API operation documentation.</p> </li> </ul> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases and alias ARNs of CMKs in each AWS account and Region, use the <a>ListAliases</a> operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createAlias* = Call_CreateAlias_402656504(name: "createAlias",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CreateAlias",
    validator: validate_CreateAlias_402656505, base: "/",
    makeUrl: url_CreateAlias_402656506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomKeyStore_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateCustomKeyStore_402656521(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCustomKeyStore_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "TrentService.CreateCustomKeyStore"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_CreateCustomKeyStore_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateCustomKeyStore_402656519; body: JsonNode): Recallable =
  ## createCustomKeyStore
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createCustomKeyStore* = Call_CreateCustomKeyStore_402656519(
    name: "createCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CreateCustomKeyStore",
    validator: validate_CreateCustomKeyStore_402656520, base: "/",
    makeUrl: url_CreateCustomKeyStore_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGrant_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateGrant_402656536(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGrant_402656535(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the request includes a particular <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">encryption context</a>, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>You can create grants on symmetric and asymmetric CMKs. However, if the grant allows an operation that the CMK does not support, <code>CreateGrant</code> fails with a <code>ValidationException</code>. </p> <ul> <li> <p>Grants for symmetric CMKs cannot allow operations that are not supported for symmetric CMKs, including <a>Sign</a>, <a>Verify</a>, and <a>GetPublicKey</a>. (There are limited exceptions to this rule for legacy operations, but you should not create a grant for an operation that AWS KMS does not support.)</p> </li> <li> <p>Grants for asymmetric CMKs cannot allow operations that are not supported for asymmetric CMKs, including operations that <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKey">generate data keys</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKeyPair">data key pairs</a>, or operations related to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic key rotation</a>, <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">imported key material</a>, or CMKs in <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a>.</p> </li> <li> <p>Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>ENCRYPT_DECRYPT</code> cannot allow the <a>Sign</a> or <a>Verify</a> operations. Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>SIGN_VERIFY</code> cannot allow the <a>Encrypt</a> or <a>Decrypt</a> operations.</p> </li> <li> <p>Grants for asymmetric CMKs cannot include an encryption context grant constraint. An encryption context is not supported on asymmetric CMKs.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "TrentService.CreateGrant"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
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

proc call*(call_402656546: Call_CreateGrant_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the request includes a particular <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">encryption context</a>, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>You can create grants on symmetric and asymmetric CMKs. However, if the grant allows an operation that the CMK does not support, <code>CreateGrant</code> fails with a <code>ValidationException</code>. </p> <ul> <li> <p>Grants for symmetric CMKs cannot allow operations that are not supported for symmetric CMKs, including <a>Sign</a>, <a>Verify</a>, and <a>GetPublicKey</a>. (There are limited exceptions to this rule for legacy operations, but you should not create a grant for an operation that AWS KMS does not support.)</p> </li> <li> <p>Grants for asymmetric CMKs cannot allow operations that are not supported for asymmetric CMKs, including operations that <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKey">generate data keys</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKeyPair">data key pairs</a>, or operations related to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic key rotation</a>, <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">imported key material</a>, or CMKs in <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a>.</p> </li> <li> <p>Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>ENCRYPT_DECRYPT</code> cannot allow the <a>Sign</a> or <a>Verify</a> operations. Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>SIGN_VERIFY</code> cannot allow the <a>Encrypt</a> or <a>Decrypt</a> operations.</p> </li> <li> <p>Grants for asymmetric CMKs cannot include an encryption context grant constraint. An encryption context is not supported on asymmetric CMKs.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateGrant_402656534; body: JsonNode): Recallable =
  ## createGrant
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the request includes a particular <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">encryption context</a>, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>You can create grants on symmetric and asymmetric CMKs. However, if the grant allows an operation that the CMK does not support, <code>CreateGrant</code> fails with a <code>ValidationException</code>. </p> <ul> <li> <p>Grants for symmetric CMKs cannot allow operations that are not supported for symmetric CMKs, including <a>Sign</a>, <a>Verify</a>, and <a>GetPublicKey</a>. (There are limited exceptions to this rule for legacy operations, but you should not create a grant for an operation that AWS KMS does not support.)</p> </li> <li> <p>Grants for asymmetric CMKs cannot allow operations that are not supported for asymmetric CMKs, including operations that <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKey">generate data keys</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKeyPair">data key pairs</a>, or operations related to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic key rotation</a>, <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">imported key material</a>, or CMKs in <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a>.</p> </li> <li> <p>Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>ENCRYPT_DECRYPT</code> cannot allow the <a>Sign</a> or <a>Verify</a> operations. Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>SIGN_VERIFY</code> cannot allow the <a>Encrypt</a> or <a>Decrypt</a> operations.</p> </li> <li> <p>Grants for asymmetric CMKs cannot include an encryption context grant constraint. An encryption context is not supported on asymmetric CMKs.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createGrant* = Call_CreateGrant_402656534(name: "createGrant",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CreateGrant",
    validator: validate_CreateGrant_402656535, base: "/",
    makeUrl: url_CreateGrant_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKey_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreateKey_402656551(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateKey_402656550(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a unique customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master-keys">customer master key</a> (CMK) in your AWS account and Region. You cannot use this operation to create a CMK in a different AWS account.</p> <p>You can use the <code>CreateKey</code> operation to create symmetric or asymmetric CMKs.</p> <ul> <li> <p> <b>Symmetric CMKs</b> contain a 256-bit symmetric key that never leaves AWS KMS unencrypted. To use the CMK, you must call AWS KMS. You can use a symmetric CMK to encrypt and decrypt small amounts of data, but they are typically used to generate <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> and <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-key-pairs">data keys pairs</a>. For details, see <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a>.</p> </li> <li> <p> <b>Asymmetric CMKs</b> can contain an RSA key pair or an Elliptic Curve (ECC) key pair. The private key in an asymmetric CMK never leaves AWS KMS unencrypted. However, you can use the <a>GetPublicKey</a> operation to download the public key so it can be used outside of AWS KMS. CMKs with RSA key pairs can be used to encrypt or decrypt data or sign and verify messages (but not both). CMKs with ECC key pairs can be used only to sign and verify messages.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To create different types of CMKs, use the following guidance:</p> <dl> <dt>Asymmetric CMKs</dt> <dd> <p>To create an asymmetric CMK, use the <code>CustomerMasterKeySpec</code> parameter to specify the type of key material in the CMK. Then, use the <code>KeyUsage</code> parameter to determine whether the CMK will be used to encrypt and decrypt or sign and verify. You can't change these properties after the CMK is created.</p> <p> </p> </dd> <dt>Symmetric CMKs</dt> <dd> <p>When creating a symmetric CMK, you don't need to specify the <code>CustomerMasterKeySpec</code> or <code>KeyUsage</code> parameters. The default value for <code>CustomerMasterKeySpec</code>, <code>SYMMETRIC_DEFAULT</code>, and the default value for <code>KeyUsage</code>, <code>ENCRYPT_DECRYPT</code>, are the only valid values for symmetric CMKs. </p> <p> </p> </dd> <dt>Imported Key Material</dt> <dd> <p>To import your own key material, begin by creating a symmetric CMK with no key material. To do this, use the <code>Origin</code> parameter of <code>CreateKey</code> with a value of <code>EXTERNAL</code>. Next, use <a>GetParametersForImport</a> operation to get a public key and import token, and use the public key to encrypt your key material. Then, use <a>ImportKeyMaterial</a> with your import token to import the key material. For step-by-step instructions, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>. You cannot import the key material into an asymmetric CMK.</p> <p> </p> </dd> <dt>Custom Key Stores</dt> <dd> <p>To create a symmetric CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region. </p> <p>You cannot create an asymmetric CMK in a custom key store. For information about custom key stores in AWS KMS see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Using Custom Key Stores</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> </dd> </dl>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "TrentService.CreateKey"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
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

proc call*(call_402656561: Call_CreateKey_402656549; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a unique customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master-keys">customer master key</a> (CMK) in your AWS account and Region. You cannot use this operation to create a CMK in a different AWS account.</p> <p>You can use the <code>CreateKey</code> operation to create symmetric or asymmetric CMKs.</p> <ul> <li> <p> <b>Symmetric CMKs</b> contain a 256-bit symmetric key that never leaves AWS KMS unencrypted. To use the CMK, you must call AWS KMS. You can use a symmetric CMK to encrypt and decrypt small amounts of data, but they are typically used to generate <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> and <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-key-pairs">data keys pairs</a>. For details, see <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a>.</p> </li> <li> <p> <b>Asymmetric CMKs</b> can contain an RSA key pair or an Elliptic Curve (ECC) key pair. The private key in an asymmetric CMK never leaves AWS KMS unencrypted. However, you can use the <a>GetPublicKey</a> operation to download the public key so it can be used outside of AWS KMS. CMKs with RSA key pairs can be used to encrypt or decrypt data or sign and verify messages (but not both). CMKs with ECC key pairs can be used only to sign and verify messages.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To create different types of CMKs, use the following guidance:</p> <dl> <dt>Asymmetric CMKs</dt> <dd> <p>To create an asymmetric CMK, use the <code>CustomerMasterKeySpec</code> parameter to specify the type of key material in the CMK. Then, use the <code>KeyUsage</code> parameter to determine whether the CMK will be used to encrypt and decrypt or sign and verify. You can't change these properties after the CMK is created.</p> <p> </p> </dd> <dt>Symmetric CMKs</dt> <dd> <p>When creating a symmetric CMK, you don't need to specify the <code>CustomerMasterKeySpec</code> or <code>KeyUsage</code> parameters. The default value for <code>CustomerMasterKeySpec</code>, <code>SYMMETRIC_DEFAULT</code>, and the default value for <code>KeyUsage</code>, <code>ENCRYPT_DECRYPT</code>, are the only valid values for symmetric CMKs. </p> <p> </p> </dd> <dt>Imported Key Material</dt> <dd> <p>To import your own key material, begin by creating a symmetric CMK with no key material. To do this, use the <code>Origin</code> parameter of <code>CreateKey</code> with a value of <code>EXTERNAL</code>. Next, use <a>GetParametersForImport</a> operation to get a public key and import token, and use the public key to encrypt your key material. Then, use <a>ImportKeyMaterial</a> with your import token to import the key material. For step-by-step instructions, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>. You cannot import the key material into an asymmetric CMK.</p> <p> </p> </dd> <dt>Custom Key Stores</dt> <dd> <p>To create a symmetric CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region. </p> <p>You cannot create an asymmetric CMK in a custom key store. For information about custom key stores in AWS KMS see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Using Custom Key Stores</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> </dd> </dl>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreateKey_402656549; body: JsonNode): Recallable =
  ## createKey
  ## <p>Creates a unique customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master-keys">customer master key</a> (CMK) in your AWS account and Region. You cannot use this operation to create a CMK in a different AWS account.</p> <p>You can use the <code>CreateKey</code> operation to create symmetric or asymmetric CMKs.</p> <ul> <li> <p> <b>Symmetric CMKs</b> contain a 256-bit symmetric key that never leaves AWS KMS unencrypted. To use the CMK, you must call AWS KMS. You can use a symmetric CMK to encrypt and decrypt small amounts of data, but they are typically used to generate <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> and <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-key-pairs">data keys pairs</a>. For details, see <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a>.</p> </li> <li> <p> <b>Asymmetric CMKs</b> can contain an RSA key pair or an Elliptic Curve (ECC) key pair. The private key in an asymmetric CMK never leaves AWS KMS unencrypted. However, you can use the <a>GetPublicKey</a> operation to download the public key so it can be used outside of AWS KMS. CMKs with RSA key pairs can be used to encrypt or decrypt data or sign and verify messages (but not both). CMKs with ECC key pairs can be used only to sign and verify messages.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To create different types of CMKs, use the following guidance:</p> <dl> <dt>Asymmetric CMKs</dt> <dd> <p>To create an asymmetric CMK, use the <code>CustomerMasterKeySpec</code> parameter to specify the type of key material in the CMK. Then, use the <code>KeyUsage</code> parameter to determine whether the CMK will be used to encrypt and decrypt or sign and verify. You can't change these properties after the CMK is created.</p> <p> </p> </dd> <dt>Symmetric CMKs</dt> <dd> <p>When creating a symmetric CMK, you don't need to specify the <code>CustomerMasterKeySpec</code> or <code>KeyUsage</code> parameters. The default value for <code>CustomerMasterKeySpec</code>, <code>SYMMETRIC_DEFAULT</code>, and the default value for <code>KeyUsage</code>, <code>ENCRYPT_DECRYPT</code>, are the only valid values for symmetric CMKs. </p> <p> </p> </dd> <dt>Imported Key Material</dt> <dd> <p>To import your own key material, begin by creating a symmetric CMK with no key material. To do this, use the <code>Origin</code> parameter of <code>CreateKey</code> with a value of <code>EXTERNAL</code>. Next, use <a>GetParametersForImport</a> operation to get a public key and import token, and use the public key to encrypt your key material. Then, use <a>ImportKeyMaterial</a> with your import token to import the key material. For step-by-step instructions, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>. You cannot import the key material into an asymmetric CMK.</p> <p> </p> </dd> <dt>Custom Key Stores</dt> <dd> <p>To create a symmetric CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region. </p> <p>You cannot create an asymmetric CMK in a custom key store. For information about custom key stores in AWS KMS see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Using Custom Key Stores</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> </dd> </dl>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createKey* = Call_CreateKey_402656549(name: "createKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CreateKey",
    validator: validate_CreateKey_402656550, base: "/", makeUrl: url_CreateKey_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Decrypt_402656564 = ref object of OpenApiRestCall_402656044
proc url_Decrypt_402656566(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Decrypt_402656565(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Decrypts ciphertext that was encrypted by a AWS KMS customer master key (CMK) using any of the following operations:</p> <ul> <li> <p> <a>Encrypt</a> </p> </li> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyPair</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>GenerateDataKeyPairWithoutPlaintext</a> </p> </li> </ul> <p>You can use this operation to decrypt ciphertext that was encrypted under a symmetric or asymmetric CMK. When the CMK is asymmetric, you must specify the CMK and the encryption algorithm that was used to encrypt the ciphertext. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The Decrypt operation also decrypts ciphertext that was encrypted outside of AWS KMS by the public key in an AWS KMS asymmetric CMK. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>If the ciphertext was encrypted under a symmetric CMK, you do not need to specify the CMK or the encryption algorithm. AWS KMS can get this information from metadata that it adds to the symmetric ciphertext blob. However, if you prefer, you can specify the <code>KeyId</code> to ensure that a particular CMK is used to decrypt the ciphertext. If you specify a different CMK than the one used to encrypt the ciphertext, the <code>Decrypt</code> operation fails.</p> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on a particular CMK, instead of using IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "TrentService.Decrypt"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
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

proc call*(call_402656576: Call_Decrypt_402656564; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Decrypts ciphertext that was encrypted by a AWS KMS customer master key (CMK) using any of the following operations:</p> <ul> <li> <p> <a>Encrypt</a> </p> </li> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyPair</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>GenerateDataKeyPairWithoutPlaintext</a> </p> </li> </ul> <p>You can use this operation to decrypt ciphertext that was encrypted under a symmetric or asymmetric CMK. When the CMK is asymmetric, you must specify the CMK and the encryption algorithm that was used to encrypt the ciphertext. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The Decrypt operation also decrypts ciphertext that was encrypted outside of AWS KMS by the public key in an AWS KMS asymmetric CMK. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>If the ciphertext was encrypted under a symmetric CMK, you do not need to specify the CMK or the encryption algorithm. AWS KMS can get this information from metadata that it adds to the symmetric ciphertext blob. However, if you prefer, you can specify the <code>KeyId</code> to ensure that a particular CMK is used to decrypt the ciphertext. If you specify a different CMK than the one used to encrypt the ciphertext, the <code>Decrypt</code> operation fails.</p> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on a particular CMK, instead of using IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_Decrypt_402656564; body: JsonNode): Recallable =
  ## decrypt
  ## <p>Decrypts ciphertext that was encrypted by a AWS KMS customer master key (CMK) using any of the following operations:</p> <ul> <li> <p> <a>Encrypt</a> </p> </li> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyPair</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>GenerateDataKeyPairWithoutPlaintext</a> </p> </li> </ul> <p>You can use this operation to decrypt ciphertext that was encrypted under a symmetric or asymmetric CMK. When the CMK is asymmetric, you must specify the CMK and the encryption algorithm that was used to encrypt the ciphertext. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The Decrypt operation also decrypts ciphertext that was encrypted outside of AWS KMS by the public key in an AWS KMS asymmetric CMK. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>If the ciphertext was encrypted under a symmetric CMK, you do not need to specify the CMK or the encryption algorithm. AWS KMS can get this information from metadata that it adds to the symmetric ciphertext blob. However, if you prefer, you can specify the <code>KeyId</code> to ensure that a particular CMK is used to decrypt the ciphertext. If you specify a different CMK than the one used to encrypt the ciphertext, the <code>Decrypt</code> operation fails.</p> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on a particular CMK, instead of using IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var decrypt* = Call_Decrypt_402656564(name: "decrypt",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.Decrypt",
                                      validator: validate_Decrypt_402656565,
                                      base: "/", makeUrl: url_Decrypt_402656566,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_402656579 = ref object of OpenApiRestCall_402656044
proc url_DeleteAlias_402656581(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlias_402656580(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "TrentService.DeleteAlias"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
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

proc call*(call_402656591: Call_DeleteAlias_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_DeleteAlias_402656579; body: JsonNode): Recallable =
  ## deleteAlias
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var deleteAlias* = Call_DeleteAlias_402656579(name: "deleteAlias",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteAlias",
    validator: validate_DeleteAlias_402656580, base: "/",
    makeUrl: url_DeleteAlias_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomKeyStore_402656594 = ref object of OpenApiRestCall_402656044
proc url_DeleteCustomKeyStore_402656596(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCustomKeyStore_402656595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "TrentService.DeleteCustomKeyStore"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_DeleteCustomKeyStore_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_DeleteCustomKeyStore_402656594; body: JsonNode): Recallable =
  ## deleteCustomKeyStore
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var deleteCustomKeyStore* = Call_DeleteCustomKeyStore_402656594(
    name: "deleteCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteCustomKeyStore",
    validator: validate_DeleteCustomKeyStore_402656595, base: "/",
    makeUrl: url_DeleteCustomKeyStore_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImportedKeyMaterial_402656609 = ref object of OpenApiRestCall_402656044
proc url_DeleteImportedKeyMaterial_402656611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImportedKeyMaterial_402656610(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "TrentService.DeleteImportedKeyMaterial"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
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

proc call*(call_402656621: Call_DeleteImportedKeyMaterial_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DeleteImportedKeyMaterial_402656609;
           body: JsonNode): Recallable =
  ## deleteImportedKeyMaterial
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var deleteImportedKeyMaterial* = Call_DeleteImportedKeyMaterial_402656609(
    name: "deleteImportedKeyMaterial", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteImportedKeyMaterial",
    validator: validate_DeleteImportedKeyMaterial_402656610, base: "/",
    makeUrl: url_DeleteImportedKeyMaterial_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCustomKeyStores_402656624 = ref object of OpenApiRestCall_402656044
proc url_DescribeCustomKeyStores_402656626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCustomKeyStores_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "TrentService.DescribeCustomKeyStores"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
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

proc call*(call_402656636: Call_DescribeCustomKeyStores_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DescribeCustomKeyStores_402656624;
           body: JsonNode): Recallable =
  ## describeCustomKeyStores
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var describeCustomKeyStores* = Call_DescribeCustomKeyStores_402656624(
    name: "describeCustomKeyStores", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DescribeCustomKeyStores",
    validator: validate_DescribeCustomKeyStores_402656625, base: "/",
    makeUrl: url_DescribeCustomKeyStores_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKey_402656639 = ref object of OpenApiRestCall_402656044
proc url_DescribeKey_402656641(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeKey_402656640(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Provides detailed information about a customer master key (CMK). You can run <code>DescribeKey</code> on a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk">customer managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a>.</p> <p>This detailed information includes the key ARN, creation date (and deletion date, if applicable), the key state, and the origin and expiration date (if any) of the key material. For CMKs in custom key stores, it includes information about the custom key store, such as the key store ID and the AWS CloudHSM cluster ID. It includes fields, like <code>KeySpec</code>, that help you distinguish symmetric from asymmetric CMKs. It also provides information that is particularly important to asymmetric CMKs, such as the key usage (encryption or signing) and the encryption algorithms or signing algorithms that the CMK supports.</p> <p> <code>DescribeKey</code> does not return the following information:</p> <ul> <li> <p>Aliases associated with the CMK. To get this information, use <a>ListAliases</a>.</p> </li> <li> <p>Whether automatic key rotation is enabled on the CMK. To get this information, use <a>GetKeyRotationStatus</a>. Also, some key states prevent a CMK from being automatically rotated. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works">How Automatic Key Rotation Works</a> in <i>AWS Key Management Service Developer Guide</i>.</p> </li> <li> <p>Tags on the CMK. To get this information, use <a>ListResourceTags</a>.</p> </li> <li> <p>Key policies and grants on the CMK. To get this information, use <a>GetKeyPolicy</a> and <a>ListGrants</a>.</p> </li> </ul> <p>If you call the <code>DescribeKey</code> operation on a <i>predefined AWS alias</i>, that is, an AWS alias with no key ID, AWS KMS creates an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a>. Then, it associates the alias with the new CMK, and returns the <code>KeyId</code> and <code>Arn</code> of the new CMK in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "TrentService.DescribeKey"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
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

proc call*(call_402656651: Call_DescribeKey_402656639; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provides detailed information about a customer master key (CMK). You can run <code>DescribeKey</code> on a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk">customer managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a>.</p> <p>This detailed information includes the key ARN, creation date (and deletion date, if applicable), the key state, and the origin and expiration date (if any) of the key material. For CMKs in custom key stores, it includes information about the custom key store, such as the key store ID and the AWS CloudHSM cluster ID. It includes fields, like <code>KeySpec</code>, that help you distinguish symmetric from asymmetric CMKs. It also provides information that is particularly important to asymmetric CMKs, such as the key usage (encryption or signing) and the encryption algorithms or signing algorithms that the CMK supports.</p> <p> <code>DescribeKey</code> does not return the following information:</p> <ul> <li> <p>Aliases associated with the CMK. To get this information, use <a>ListAliases</a>.</p> </li> <li> <p>Whether automatic key rotation is enabled on the CMK. To get this information, use <a>GetKeyRotationStatus</a>. Also, some key states prevent a CMK from being automatically rotated. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works">How Automatic Key Rotation Works</a> in <i>AWS Key Management Service Developer Guide</i>.</p> </li> <li> <p>Tags on the CMK. To get this information, use <a>ListResourceTags</a>.</p> </li> <li> <p>Key policies and grants on the CMK. To get this information, use <a>GetKeyPolicy</a> and <a>ListGrants</a>.</p> </li> </ul> <p>If you call the <code>DescribeKey</code> operation on a <i>predefined AWS alias</i>, that is, an AWS alias with no key ID, AWS KMS creates an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a>. Then, it associates the alias with the new CMK, and returns the <code>KeyId</code> and <code>Arn</code> of the new CMK in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DescribeKey_402656639; body: JsonNode): Recallable =
  ## describeKey
  ## <p>Provides detailed information about a customer master key (CMK). You can run <code>DescribeKey</code> on a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk">customer managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a>.</p> <p>This detailed information includes the key ARN, creation date (and deletion date, if applicable), the key state, and the origin and expiration date (if any) of the key material. For CMKs in custom key stores, it includes information about the custom key store, such as the key store ID and the AWS CloudHSM cluster ID. It includes fields, like <code>KeySpec</code>, that help you distinguish symmetric from asymmetric CMKs. It also provides information that is particularly important to asymmetric CMKs, such as the key usage (encryption or signing) and the encryption algorithms or signing algorithms that the CMK supports.</p> <p> <code>DescribeKey</code> does not return the following information:</p> <ul> <li> <p>Aliases associated with the CMK. To get this information, use <a>ListAliases</a>.</p> </li> <li> <p>Whether automatic key rotation is enabled on the CMK. To get this information, use <a>GetKeyRotationStatus</a>. Also, some key states prevent a CMK from being automatically rotated. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works">How Automatic Key Rotation Works</a> in <i>AWS Key Management Service Developer Guide</i>.</p> </li> <li> <p>Tags on the CMK. To get this information, use <a>ListResourceTags</a>.</p> </li> <li> <p>Key policies and grants on the CMK. To get this information, use <a>GetKeyPolicy</a> and <a>ListGrants</a>.</p> </li> </ul> <p>If you call the <code>DescribeKey</code> operation on a <i>predefined AWS alias</i>, that is, an AWS alias with no key ID, AWS KMS creates an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a>. Then, it associates the alias with the new CMK, and returns the <code>KeyId</code> and <code>Arn</code> of the new CMK in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var describeKey* = Call_DescribeKey_402656639(name: "describeKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DescribeKey",
    validator: validate_DescribeKey_402656640, base: "/",
    makeUrl: url_DescribeKey_402656641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKey_402656654 = ref object of OpenApiRestCall_402656044
proc url_DisableKey_402656656(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableKey_402656655(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "TrentService.DisableKey"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
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

proc call*(call_402656666: Call_DisableKey_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DisableKey_402656654; body: JsonNode): Recallable =
  ## disableKey
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var disableKey* = Call_DisableKey_402656654(name: "disableKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisableKey",
    validator: validate_DisableKey_402656655, base: "/",
    makeUrl: url_DisableKey_402656656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKeyRotation_402656669 = ref object of OpenApiRestCall_402656044
proc url_DisableKeyRotation_402656671(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableKeyRotation_402656670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK).</p> <p> You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "TrentService.DisableKeyRotation"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
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

proc call*(call_402656681: Call_DisableKeyRotation_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK).</p> <p> You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DisableKeyRotation_402656669; body: JsonNode): Recallable =
  ## disableKeyRotation
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK).</p> <p> You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var disableKeyRotation* = Call_DisableKeyRotation_402656669(
    name: "disableKeyRotation", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisableKeyRotation",
    validator: validate_DisableKeyRotation_402656670, base: "/",
    makeUrl: url_DisableKeyRotation_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectCustomKeyStore_402656684 = ref object of OpenApiRestCall_402656044
proc url_DisconnectCustomKeyStore_402656686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisconnectCustomKeyStore_402656685(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "TrentService.DisconnectCustomKeyStore"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
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

proc call*(call_402656696: Call_DisconnectCustomKeyStore_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_DisconnectCustomKeyStore_402656684;
           body: JsonNode): Recallable =
  ## disconnectCustomKeyStore
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var disconnectCustomKeyStore* = Call_DisconnectCustomKeyStore_402656684(
    name: "disconnectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisconnectCustomKeyStore",
    validator: validate_DisconnectCustomKeyStore_402656685, base: "/",
    makeUrl: url_DisconnectCustomKeyStore_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKey_402656699 = ref object of OpenApiRestCall_402656044
proc url_EnableKey_402656701(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableKey_402656700(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "TrentService.EnableKey"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
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

proc call*(call_402656711: Call_EnableKey_402656699; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_EnableKey_402656699; body: JsonNode): Recallable =
  ## enableKey
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var enableKey* = Call_EnableKey_402656699(name: "enableKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.EnableKey",
    validator: validate_EnableKey_402656700, base: "/", makeUrl: url_EnableKey_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKeyRotation_402656714 = ref object of OpenApiRestCall_402656044
proc url_EnableKeyRotation_402656716(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableKeyRotation_402656715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "TrentService.EnableKeyRotation"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
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

proc call*(call_402656726: Call_EnableKeyRotation_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_EnableKeyRotation_402656714; body: JsonNode): Recallable =
  ## enableKeyRotation
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var enableKeyRotation* = Call_EnableKeyRotation_402656714(
    name: "enableKeyRotation", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.EnableKeyRotation",
    validator: validate_EnableKeyRotation_402656715, base: "/",
    makeUrl: url_EnableKeyRotation_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Encrypt_402656729 = ref object of OpenApiRestCall_402656044
proc url_Encrypt_402656731(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Encrypt_402656730(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt small amounts of arbitrary data, such as a personal identifier or database password, or other sensitive information. </p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need to use the <code>Encrypt</code> operation to encrypt a data key. The <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a> operations return a plaintext data key and an encrypted copy of that data key.</p> <p>When you encrypt data, you must specify a symmetric or asymmetric CMK to use in the encryption operation. The CMK must have a <code>KeyUsage</code> value of <code>ENCRYPT_DECRYPT.</code> To find the <code>KeyUsage</code> of a CMK, use the <a>DescribeKey</a> operation. </p> <p>If you use a symmetric CMK, you can use an encryption context to add additional security to your encryption operation. If you specify an <code>EncryptionContext</code> when encrypting data, you must specify the same encryption context (a case-sensitive exact match) when decrypting the data. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>If you specify an asymmetric CMK, you must also specify the encryption algorithm. The algorithm must be compatible with the CMK type.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> <p>The maximum size of the data that you can encrypt varies with the type of CMK and the encryption algorithm that you choose.</p> <ul> <li> <p>Symmetric CMKs</p> <ul> <li> <p> <code>SYMMETRIC_DEFAULT</code>: 4096 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_2048</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 214 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 190 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_3072</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 342 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 318 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_4096</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 470 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 446 bytes</p> </li> </ul> </li> </ul> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "TrentService.Encrypt"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
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

proc call*(call_402656741: Call_Encrypt_402656729; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt small amounts of arbitrary data, such as a personal identifier or database password, or other sensitive information. </p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need to use the <code>Encrypt</code> operation to encrypt a data key. The <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a> operations return a plaintext data key and an encrypted copy of that data key.</p> <p>When you encrypt data, you must specify a symmetric or asymmetric CMK to use in the encryption operation. The CMK must have a <code>KeyUsage</code> value of <code>ENCRYPT_DECRYPT.</code> To find the <code>KeyUsage</code> of a CMK, use the <a>DescribeKey</a> operation. </p> <p>If you use a symmetric CMK, you can use an encryption context to add additional security to your encryption operation. If you specify an <code>EncryptionContext</code> when encrypting data, you must specify the same encryption context (a case-sensitive exact match) when decrypting the data. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>If you specify an asymmetric CMK, you must also specify the encryption algorithm. The algorithm must be compatible with the CMK type.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> <p>The maximum size of the data that you can encrypt varies with the type of CMK and the encryption algorithm that you choose.</p> <ul> <li> <p>Symmetric CMKs</p> <ul> <li> <p> <code>SYMMETRIC_DEFAULT</code>: 4096 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_2048</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 214 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 190 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_3072</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 342 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 318 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_4096</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 470 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 446 bytes</p> </li> </ul> </li> </ul> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_Encrypt_402656729; body: JsonNode): Recallable =
  ## encrypt
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt small amounts of arbitrary data, such as a personal identifier or database password, or other sensitive information. </p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need to use the <code>Encrypt</code> operation to encrypt a data key. The <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a> operations return a plaintext data key and an encrypted copy of that data key.</p> <p>When you encrypt data, you must specify a symmetric or asymmetric CMK to use in the encryption operation. The CMK must have a <code>KeyUsage</code> value of <code>ENCRYPT_DECRYPT.</code> To find the <code>KeyUsage</code> of a CMK, use the <a>DescribeKey</a> operation. </p> <p>If you use a symmetric CMK, you can use an encryption context to add additional security to your encryption operation. If you specify an <code>EncryptionContext</code> when encrypting data, you must specify the same encryption context (a case-sensitive exact match) when decrypting the data. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>If you specify an asymmetric CMK, you must also specify the encryption algorithm. The algorithm must be compatible with the CMK type.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> <p>The maximum size of the data that you can encrypt varies with the type of CMK and the encryption algorithm that you choose.</p> <ul> <li> <p>Symmetric CMKs</p> <ul> <li> <p> <code>SYMMETRIC_DEFAULT</code>: 4096 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_2048</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 214 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 190 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_3072</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 342 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 318 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_4096</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 470 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 446 bytes</p> </li> </ul> </li> </ul> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var encrypt* = Call_Encrypt_402656729(name: "encrypt",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.Encrypt",
                                      validator: validate_Encrypt_402656730,
                                      base: "/", makeUrl: url_Encrypt_402656731,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKey_402656744 = ref object of OpenApiRestCall_402656044
proc url_GenerateDataKey_402656746(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateDataKey_402656745(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Generates a unique symmetric data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of AWS KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, specify the symmetric CMK that will be used to encrypt the data key. You cannot use an asymmetric CMK to generate data keys. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>You must also specify the length of the data key. Use either the <code>KeySpec</code> or <code>NumberOfBytes</code> parameters (but not both). For 128-bit and 256-bit data keys, use the <code>KeySpec</code> parameter. </p> <p>If the operation succeeds, the plaintext copy of the data key is in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To generate an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operation. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "TrentService.GenerateDataKey"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
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

proc call*(call_402656756: Call_GenerateDataKey_402656744; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a unique symmetric data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of AWS KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, specify the symmetric CMK that will be used to encrypt the data key. You cannot use an asymmetric CMK to generate data keys. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>You must also specify the length of the data key. Use either the <code>KeySpec</code> or <code>NumberOfBytes</code> parameters (but not both). For 128-bit and 256-bit data keys, use the <code>KeySpec</code> parameter. </p> <p>If the operation succeeds, the plaintext copy of the data key is in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To generate an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operation. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_GenerateDataKey_402656744; body: JsonNode): Recallable =
  ## generateDataKey
  ## <p>Generates a unique symmetric data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of AWS KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, specify the symmetric CMK that will be used to encrypt the data key. You cannot use an asymmetric CMK to generate data keys. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>You must also specify the length of the data key. Use either the <code>KeySpec</code> or <code>NumberOfBytes</code> parameters (but not both). For 128-bit and 256-bit data keys, use the <code>KeySpec</code> parameter. </p> <p>If the operation succeeds, the plaintext copy of the data key is in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To generate an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operation. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var generateDataKey* = Call_GenerateDataKey_402656744(name: "generateDataKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKey",
    validator: validate_GenerateDataKey_402656745, base: "/",
    makeUrl: url_GenerateDataKey_402656746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyPair_402656759 = ref object of OpenApiRestCall_402656044
proc url_GenerateDataKeyPair_402656761(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateDataKeyPair_402656760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPair</code> operation returns a plaintext public key, a plaintext private key, and a copy of the private key that is encrypted under the symmetric CMK you specify. You can use the data key pair to perform asymmetric cryptography outside of AWS KMS.</p> <p> <code>GenerateDataKeyPair</code> returns a unique data key pair for each request. The bytes in the keys are not related to the caller or the CMK that is used to encrypt the private key.</p> <p>You can use the public key that <code>GenerateDataKeyPair</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in a data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If you are using the data key pair to encrypt data, or for any operation where you don't immediately need a private key, consider using the <a>GenerateDataKeyPairWithoutPlaintext</a> operation. <code>GenerateDataKeyPairWithoutPlaintext</code> returns a plaintext public key and an encrypted private key, but omits the plaintext private key that you need only to decrypt ciphertext or sign a message. Later, when you need to decrypt the data or sign a message, use the <a>Decrypt</a> operation to decrypt the encrypted private key in the data key pair.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyPair"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
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

proc call*(call_402656771: Call_GenerateDataKeyPair_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPair</code> operation returns a plaintext public key, a plaintext private key, and a copy of the private key that is encrypted under the symmetric CMK you specify. You can use the data key pair to perform asymmetric cryptography outside of AWS KMS.</p> <p> <code>GenerateDataKeyPair</code> returns a unique data key pair for each request. The bytes in the keys are not related to the caller or the CMK that is used to encrypt the private key.</p> <p>You can use the public key that <code>GenerateDataKeyPair</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in a data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If you are using the data key pair to encrypt data, or for any operation where you don't immediately need a private key, consider using the <a>GenerateDataKeyPairWithoutPlaintext</a> operation. <code>GenerateDataKeyPairWithoutPlaintext</code> returns a plaintext public key and an encrypted private key, but omits the plaintext private key that you need only to decrypt ciphertext or sign a message. Later, when you need to decrypt the data or sign a message, use the <a>Decrypt</a> operation to decrypt the encrypted private key in the data key pair.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_GenerateDataKeyPair_402656759; body: JsonNode): Recallable =
  ## generateDataKeyPair
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPair</code> operation returns a plaintext public key, a plaintext private key, and a copy of the private key that is encrypted under the symmetric CMK you specify. You can use the data key pair to perform asymmetric cryptography outside of AWS KMS.</p> <p> <code>GenerateDataKeyPair</code> returns a unique data key pair for each request. The bytes in the keys are not related to the caller or the CMK that is used to encrypt the private key.</p> <p>You can use the public key that <code>GenerateDataKeyPair</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in a data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If you are using the data key pair to encrypt data, or for any operation where you don't immediately need a private key, consider using the <a>GenerateDataKeyPairWithoutPlaintext</a> operation. <code>GenerateDataKeyPairWithoutPlaintext</code> returns a plaintext public key and an encrypted private key, but omits the plaintext private key that you need only to decrypt ciphertext or sign a message. Later, when you need to decrypt the data or sign a message, use the <a>Decrypt</a> operation to decrypt the encrypted private key in the data key pair.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var generateDataKeyPair* = Call_GenerateDataKeyPair_402656759(
    name: "generateDataKeyPair", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyPair",
    validator: validate_GenerateDataKeyPair_402656760, base: "/",
    makeUrl: url_GenerateDataKeyPair_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyPairWithoutPlaintext_402656774 = ref object of OpenApiRestCall_402656044
proc url_GenerateDataKeyPairWithoutPlaintext_402656776(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateDataKeyPairWithoutPlaintext_402656775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPairWithoutPlaintext</code> operation returns a plaintext public key and a copy of the private key that is encrypted under the symmetric CMK you specify. Unlike <a>GenerateDataKeyPair</a>, this operation does not return a plaintext private key. </p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in the data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <code>KeySpec</code> field in the <a>DescribeKey</a> response.</p> <p>You can use the public key that <code>GenerateDataKeyPairWithoutPlaintext</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p> <code>GenerateDataKeyPairWithoutPlaintext</code> returns a unique data key pair for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the private key.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyPairWithoutPlaintext"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
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

proc call*(call_402656786: Call_GenerateDataKeyPairWithoutPlaintext_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPairWithoutPlaintext</code> operation returns a plaintext public key and a copy of the private key that is encrypted under the symmetric CMK you specify. Unlike <a>GenerateDataKeyPair</a>, this operation does not return a plaintext private key. </p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in the data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <code>KeySpec</code> field in the <a>DescribeKey</a> response.</p> <p>You can use the public key that <code>GenerateDataKeyPairWithoutPlaintext</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p> <code>GenerateDataKeyPairWithoutPlaintext</code> returns a unique data key pair for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the private key.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_GenerateDataKeyPairWithoutPlaintext_402656774;
           body: JsonNode): Recallable =
  ## generateDataKeyPairWithoutPlaintext
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPairWithoutPlaintext</code> operation returns a plaintext public key and a copy of the private key that is encrypted under the symmetric CMK you specify. Unlike <a>GenerateDataKeyPair</a>, this operation does not return a plaintext private key. </p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in the data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <code>KeySpec</code> field in the <a>DescribeKey</a> response.</p> <p>You can use the public key that <code>GenerateDataKeyPairWithoutPlaintext</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p> <code>GenerateDataKeyPairWithoutPlaintext</code> returns a unique data key pair for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the private key.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var generateDataKeyPairWithoutPlaintext* = Call_GenerateDataKeyPairWithoutPlaintext_402656774(
    name: "generateDataKeyPairWithoutPlaintext", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyPairWithoutPlaintext",
    validator: validate_GenerateDataKeyPairWithoutPlaintext_402656775,
    base: "/", makeUrl: url_GenerateDataKeyPairWithoutPlaintext_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyWithoutPlaintext_402656789 = ref object of OpenApiRestCall_402656044
proc url_GenerateDataKeyWithoutPlaintext_402656791(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateDataKeyWithoutPlaintext_402656790(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Generates a unique symmetric data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. To request an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operations.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> is identical to the <a>GenerateDataKey</a> operation except that returns only the encrypted copy of the data key. This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key. </p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the keys are not related to the caller or CMK that is used to encrypt the private key.</p> <p>To generate a data key, you must specify the symmetric customer master key (CMK) that is used to encrypt the data key. You cannot use an asymmetric CMK to generate a data key. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If the operation succeeds, you will find the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyWithoutPlaintext"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
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

proc call*(call_402656801: Call_GenerateDataKeyWithoutPlaintext_402656789;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a unique symmetric data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. To request an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operations.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> is identical to the <a>GenerateDataKey</a> operation except that returns only the encrypted copy of the data key. This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key. </p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the keys are not related to the caller or CMK that is used to encrypt the private key.</p> <p>To generate a data key, you must specify the symmetric customer master key (CMK) that is used to encrypt the data key. You cannot use an asymmetric CMK to generate a data key. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If the operation succeeds, you will find the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_GenerateDataKeyWithoutPlaintext_402656789;
           body: JsonNode): Recallable =
  ## generateDataKeyWithoutPlaintext
  ## <p>Generates a unique symmetric data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. To request an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operations.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> is identical to the <a>GenerateDataKey</a> operation except that returns only the encrypted copy of the data key. This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key. </p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the keys are not related to the caller or CMK that is used to encrypt the private key.</p> <p>To generate a data key, you must specify the symmetric customer master key (CMK) that is used to encrypt the data key. You cannot use an asymmetric CMK to generate a data key. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If the operation succeeds, you will find the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var generateDataKeyWithoutPlaintext* = Call_GenerateDataKeyWithoutPlaintext_402656789(
    name: "generateDataKeyWithoutPlaintext", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyWithoutPlaintext",
    validator: validate_GenerateDataKeyWithoutPlaintext_402656790, base: "/",
    makeUrl: url_GenerateDataKeyWithoutPlaintext_402656791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateRandom_402656804 = ref object of OpenApiRestCall_402656044
proc url_GenerateRandom_402656806(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateRandom_402656805(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656807 = header.getOrDefault("X-Amz-Target")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true, default = newJString(
      "TrentService.GenerateRandom"))
  if valid_402656807 != nil:
    section.add "X-Amz-Target", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
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

proc call*(call_402656816: Call_GenerateRandom_402656804; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_GenerateRandom_402656804; body: JsonNode): Recallable =
  ## generateRandom
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656818 = newJObject()
  if body != nil:
    body_402656818 = body
  result = call_402656817.call(nil, nil, nil, nil, body_402656818)

var generateRandom* = Call_GenerateRandom_402656804(name: "generateRandom",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateRandom",
    validator: validate_GenerateRandom_402656805, base: "/",
    makeUrl: url_GenerateRandom_402656806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPolicy_402656819 = ref object of OpenApiRestCall_402656044
proc url_GetKeyPolicy_402656821(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetKeyPolicy_402656820(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Target")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true, default = newJString(
      "TrentService.GetKeyPolicy"))
  if valid_402656822 != nil:
    section.add "X-Amz-Target", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
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

proc call*(call_402656831: Call_GetKeyPolicy_402656819; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_GetKeyPolicy_402656819; body: JsonNode): Recallable =
  ## getKeyPolicy
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
  ##   
                                                                                                                                                  ## body: JObject (required)
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  result = call_402656832.call(nil, nil, nil, nil, body_402656833)

var getKeyPolicy* = Call_GetKeyPolicy_402656819(name: "getKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyPolicy",
    validator: validate_GetKeyPolicy_402656820, base: "/",
    makeUrl: url_GetKeyPolicy_402656821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyRotationStatus_402656834 = ref object of OpenApiRestCall_402656044
proc url_GetKeyRotationStatus_402656836(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetKeyRotationStatus_402656835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. The key rotation status for these CMKs is always <code>false</code>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656837 = header.getOrDefault("X-Amz-Target")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true, default = newJString(
      "TrentService.GetKeyRotationStatus"))
  if valid_402656837 != nil:
    section.add "X-Amz-Target", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Security-Token", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Signature")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Signature", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Algorithm", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Date")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Date", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Credential")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Credential", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656844
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

proc call*(call_402656846: Call_GetKeyRotationStatus_402656834;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. The key rotation status for these CMKs is always <code>false</code>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
                                                                                         ## 
  let valid = call_402656846.validator(path, query, header, formData, body, _)
  let scheme = call_402656846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656846.makeUrl(scheme.get, call_402656846.host, call_402656846.base,
                                   call_402656846.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656846, uri, valid, _)

proc call*(call_402656847: Call_GetKeyRotationStatus_402656834; body: JsonNode): Recallable =
  ## getKeyRotationStatus
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. The key rotation status for these CMKs is always <code>false</code>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656848 = newJObject()
  if body != nil:
    body_402656848 = body
  result = call_402656847.call(nil, nil, nil, nil, body_402656848)

var getKeyRotationStatus* = Call_GetKeyRotationStatus_402656834(
    name: "getKeyRotationStatus", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyRotationStatus",
    validator: validate_GetKeyRotationStatus_402656835, base: "/",
    makeUrl: url_GetKeyRotationStatus_402656836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersForImport_402656849 = ref object of OpenApiRestCall_402656044
proc url_GetParametersForImport_402656851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParametersForImport_402656850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the items you need to import key material into a symmetric, customer managed customer master key (CMK). For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the symmetric key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request.</p> <p>You must specify the key ID of the symmetric CMK into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account.</p> <p>To import key material, you must use the public key and import token from the same response. These items are valid for 24 hours. The expiration date and time appear in the <code>GetParametersForImport</code> response. You cannot use an expired token in an <a>ImportKeyMaterial</a> request. If your key and token expire, send another <code>GetParametersForImport</code> request.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656852 = header.getOrDefault("X-Amz-Target")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true, default = newJString(
      "TrentService.GetParametersForImport"))
  if valid_402656852 != nil:
    section.add "X-Amz-Target", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
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

proc call*(call_402656861: Call_GetParametersForImport_402656849;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the items you need to import key material into a symmetric, customer managed customer master key (CMK). For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the symmetric key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request.</p> <p>You must specify the key ID of the symmetric CMK into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account.</p> <p>To import key material, you must use the public key and import token from the same response. These items are valid for 24 hours. The expiration date and time appear in the <code>GetParametersForImport</code> response. You cannot use an expired token in an <a>ImportKeyMaterial</a> request. If your key and token expire, send another <code>GetParametersForImport</code> request.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656861.validator(path, query, header, formData, body, _)
  let scheme = call_402656861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656861.makeUrl(scheme.get, call_402656861.host, call_402656861.base,
                                   call_402656861.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656861, uri, valid, _)

proc call*(call_402656862: Call_GetParametersForImport_402656849; body: JsonNode): Recallable =
  ## getParametersForImport
  ## <p>Returns the items you need to import key material into a symmetric, customer managed customer master key (CMK). For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the symmetric key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request.</p> <p>You must specify the key ID of the symmetric CMK into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account.</p> <p>To import key material, you must use the public key and import token from the same response. These items are valid for 24 hours. The expiration date and time appear in the <code>GetParametersForImport</code> response. You cannot use an expired token in an <a>ImportKeyMaterial</a> request. If your key and token expire, send another <code>GetParametersForImport</code> request.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656863 = newJObject()
  if body != nil:
    body_402656863 = body
  result = call_402656862.call(nil, nil, nil, nil, body_402656863)

var getParametersForImport* = Call_GetParametersForImport_402656849(
    name: "getParametersForImport", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetParametersForImport",
    validator: validate_GetParametersForImport_402656850, base: "/",
    makeUrl: url_GetParametersForImport_402656851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey_402656864 = ref object of OpenApiRestCall_402656044
proc url_GetPublicKey_402656866(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublicKey_402656865(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the public key of an asymmetric CMK. Unlike the private key of a asymmetric CMK, which never leaves AWS KMS unencrypted, callers with <code>kms:GetPublicKey</code> permission can download the public key of an asymmetric CMK. You can share the public key to allow others to encrypt messages and verify signatures outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You do not need to download the public key. Instead, you can use the public key within AWS KMS by calling the <a>Encrypt</a>, <a>ReEncrypt</a>, or <a>Verify</a> operations with the identifier of an asymmetric CMK. When you use the public key within AWS KMS, you benefit from the authentication, authorization, and logging that are part of every AWS KMS operation. You also reduce of risk of encrypting data that cannot be decrypted. These features are not effective outside of AWS KMS. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/download-public-key.html#download-public-key-considerations">Special Considerations for Downloading Public Keys</a>.</p> <p>To help you use the public key safely outside of AWS KMS, <code>GetPublicKey</code> returns important information about the public key in the response, including:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-CustomerMasterKeySpec">CustomerMasterKeySpec</a>: The type of key material in the public key, such as <code>RSA_4096</code> or <code>ECC_NIST_P521</code>.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage">KeyUsage</a>: Whether the key is used for encryption or signing.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms">EncryptionAlgorithms</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms">SigningAlgorithms</a>: A list of the encryption algorithms or the signing algorithms for the key.</p> </li> </ul> <p>Although AWS KMS cannot enforce these restrictions on external operations, it is crucial that you use this information to prevent the public key from being used improperly. For example, you can prevent a public signing key from being used encrypt data, or prevent a public key from being used with an encryption algorithm that is not supported by AWS KMS. You can also avoid errors, such as using the wrong signing algorithm in a verification operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656867 = header.getOrDefault("X-Amz-Target")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true, default = newJString(
      "TrentService.GetPublicKey"))
  if valid_402656867 != nil:
    section.add "X-Amz-Target", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Security-Token", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Signature")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Signature", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Algorithm", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Date")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Date", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Credential")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Credential", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656874
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

proc call*(call_402656876: Call_GetPublicKey_402656864; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the public key of an asymmetric CMK. Unlike the private key of a asymmetric CMK, which never leaves AWS KMS unencrypted, callers with <code>kms:GetPublicKey</code> permission can download the public key of an asymmetric CMK. You can share the public key to allow others to encrypt messages and verify signatures outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You do not need to download the public key. Instead, you can use the public key within AWS KMS by calling the <a>Encrypt</a>, <a>ReEncrypt</a>, or <a>Verify</a> operations with the identifier of an asymmetric CMK. When you use the public key within AWS KMS, you benefit from the authentication, authorization, and logging that are part of every AWS KMS operation. You also reduce of risk of encrypting data that cannot be decrypted. These features are not effective outside of AWS KMS. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/download-public-key.html#download-public-key-considerations">Special Considerations for Downloading Public Keys</a>.</p> <p>To help you use the public key safely outside of AWS KMS, <code>GetPublicKey</code> returns important information about the public key in the response, including:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-CustomerMasterKeySpec">CustomerMasterKeySpec</a>: The type of key material in the public key, such as <code>RSA_4096</code> or <code>ECC_NIST_P521</code>.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage">KeyUsage</a>: Whether the key is used for encryption or signing.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms">EncryptionAlgorithms</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms">SigningAlgorithms</a>: A list of the encryption algorithms or the signing algorithms for the key.</p> </li> </ul> <p>Although AWS KMS cannot enforce these restrictions on external operations, it is crucial that you use this information to prevent the public key from being used improperly. For example, you can prevent a public signing key from being used encrypt data, or prevent a public key from being used with an encryption algorithm that is not supported by AWS KMS. You can also avoid errors, such as using the wrong signing algorithm in a verification operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656876.validator(path, query, header, formData, body, _)
  let scheme = call_402656876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656876.makeUrl(scheme.get, call_402656876.host, call_402656876.base,
                                   call_402656876.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656876, uri, valid, _)

proc call*(call_402656877: Call_GetPublicKey_402656864; body: JsonNode): Recallable =
  ## getPublicKey
  ## <p>Returns the public key of an asymmetric CMK. Unlike the private key of a asymmetric CMK, which never leaves AWS KMS unencrypted, callers with <code>kms:GetPublicKey</code> permission can download the public key of an asymmetric CMK. You can share the public key to allow others to encrypt messages and verify signatures outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You do not need to download the public key. Instead, you can use the public key within AWS KMS by calling the <a>Encrypt</a>, <a>ReEncrypt</a>, or <a>Verify</a> operations with the identifier of an asymmetric CMK. When you use the public key within AWS KMS, you benefit from the authentication, authorization, and logging that are part of every AWS KMS operation. You also reduce of risk of encrypting data that cannot be decrypted. These features are not effective outside of AWS KMS. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/download-public-key.html#download-public-key-considerations">Special Considerations for Downloading Public Keys</a>.</p> <p>To help you use the public key safely outside of AWS KMS, <code>GetPublicKey</code> returns important information about the public key in the response, including:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-CustomerMasterKeySpec">CustomerMasterKeySpec</a>: The type of key material in the public key, such as <code>RSA_4096</code> or <code>ECC_NIST_P521</code>.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage">KeyUsage</a>: Whether the key is used for encryption or signing.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms">EncryptionAlgorithms</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms">SigningAlgorithms</a>: A list of the encryption algorithms or the signing algorithms for the key.</p> </li> </ul> <p>Although AWS KMS cannot enforce these restrictions on external operations, it is crucial that you use this information to prevent the public key from being used improperly. For example, you can prevent a public signing key from being used encrypt data, or prevent a public key from being used with an encryption algorithm that is not supported by AWS KMS. You can also avoid errors, such as using the wrong signing algorithm in a verification operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656878 = newJObject()
  if body != nil:
    body_402656878 = body
  result = call_402656877.call(nil, nil, nil, nil, body_402656878)

var getPublicKey* = Call_GetPublicKey_402656864(name: "getPublicKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetPublicKey",
    validator: validate_GetPublicKey_402656865, base: "/",
    makeUrl: url_GetPublicKey_402656866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyMaterial_402656879 = ref object of OpenApiRestCall_402656044
proc url_ImportKeyMaterial_402656881(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportKeyMaterial_402656880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Imports key material into an existing symmetric AWS KMS customer master key (CMK) that was created without key material. After you successfully import key material into a CMK, you can <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#reimport-key-material">reimport the same key material</a> into that CMK, but you cannot import different key material.</p> <p>You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. You must use a public key and token from the same <code>GetParametersForImport</code> response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, AWS KMS deletes the key material from the CMK on the specified date, and the CMK becomes unusable. To use the CMK again, you must reimport the same key material. The only way to change an expiration date is by reimporting the same key material and specifying a new expiration date. </p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK.</p> <p>If this operation fails, use the exception to help determine the problem. If the error is related to the key material, the import token, or wrapping key, use <a>GetParametersForImport</a> to get a new public key and import token for the CMK and repeat the import procedure. For help, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#importing-keys-overview">How To Import Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656882 = header.getOrDefault("X-Amz-Target")
  valid_402656882 = validateParameter(valid_402656882, JString, required = true, default = newJString(
      "TrentService.ImportKeyMaterial"))
  if valid_402656882 != nil:
    section.add "X-Amz-Target", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Security-Token", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Signature")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Signature", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Algorithm", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Date")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Date", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Credential")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Credential", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656889
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

proc call*(call_402656891: Call_ImportKeyMaterial_402656879;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Imports key material into an existing symmetric AWS KMS customer master key (CMK) that was created without key material. After you successfully import key material into a CMK, you can <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#reimport-key-material">reimport the same key material</a> into that CMK, but you cannot import different key material.</p> <p>You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. You must use a public key and token from the same <code>GetParametersForImport</code> response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, AWS KMS deletes the key material from the CMK on the specified date, and the CMK becomes unusable. To use the CMK again, you must reimport the same key material. The only way to change an expiration date is by reimporting the same key material and specifying a new expiration date. </p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK.</p> <p>If this operation fails, use the exception to help determine the problem. If the error is related to the key material, the import token, or wrapping key, use <a>GetParametersForImport</a> to get a new public key and import token for the CMK and repeat the import procedure. For help, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#importing-keys-overview">How To Import Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656891.validator(path, query, header, formData, body, _)
  let scheme = call_402656891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656891.makeUrl(scheme.get, call_402656891.host, call_402656891.base,
                                   call_402656891.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656891, uri, valid, _)

proc call*(call_402656892: Call_ImportKeyMaterial_402656879; body: JsonNode): Recallable =
  ## importKeyMaterial
  ## <p>Imports key material into an existing symmetric AWS KMS customer master key (CMK) that was created without key material. After you successfully import key material into a CMK, you can <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#reimport-key-material">reimport the same key material</a> into that CMK, but you cannot import different key material.</p> <p>You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. You must use a public key and token from the same <code>GetParametersForImport</code> response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, AWS KMS deletes the key material from the CMK on the specified date, and the CMK becomes unusable. To use the CMK again, you must reimport the same key material. The only way to change an expiration date is by reimporting the same key material and specifying a new expiration date. </p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK.</p> <p>If this operation fails, use the exception to help determine the problem. If the error is related to the key material, the import token, or wrapping key, use <a>GetParametersForImport</a> to get a new public key and import token for the CMK and repeat the import procedure. For help, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#importing-keys-overview">How To Import Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656893 = newJObject()
  if body != nil:
    body_402656893 = body
  result = call_402656892.call(nil, nil, nil, nil, body_402656893)

var importKeyMaterial* = Call_ImportKeyMaterial_402656879(
    name: "importKeyMaterial", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ImportKeyMaterial",
    validator: validate_ImportKeyMaterial_402656880, base: "/",
    makeUrl: url_ImportKeyMaterial_402656881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_402656894 = ref object of OpenApiRestCall_402656044
proc url_ListAliases_402656896(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAliases_402656895(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases quota</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Pagination token
  ##   Limit: JString
                                                               ##        : Pagination limit
  section = newJObject()
  var valid_402656897 = query.getOrDefault("Marker")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "Marker", valid_402656897
  var valid_402656898 = query.getOrDefault("Limit")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "Limit", valid_402656898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656899 = header.getOrDefault("X-Amz-Target")
  valid_402656899 = validateParameter(valid_402656899, JString, required = true, default = newJString(
      "TrentService.ListAliases"))
  if valid_402656899 != nil:
    section.add "X-Amz-Target", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Security-Token", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Signature")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Signature", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Algorithm", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Date")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Date", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Credential")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Credential", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656906
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

proc call*(call_402656908: Call_ListAliases_402656894; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases quota</a>.</p>
                                                                                         ## 
  let valid = call_402656908.validator(path, query, header, formData, body, _)
  let scheme = call_402656908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656908.makeUrl(scheme.get, call_402656908.host, call_402656908.base,
                                   call_402656908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656908, uri, valid, _)

proc call*(call_402656909: Call_ListAliases_402656894; body: JsonNode;
           Marker: string = ""; Limit: string = ""): Recallable =
  ## listAliases
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases quota</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Marker: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Limit: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## limit
  var query_402656910 = newJObject()
  var body_402656911 = newJObject()
  add(query_402656910, "Marker", newJString(Marker))
  if body != nil:
    body_402656911 = body
  add(query_402656910, "Limit", newJString(Limit))
  result = call_402656909.call(nil, query_402656910, nil, nil, body_402656911)

var listAliases* = Call_ListAliases_402656894(name: "listAliases",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListAliases",
    validator: validate_ListAliases_402656895, base: "/",
    makeUrl: url_ListAliases_402656896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGrants_402656912 = ref object of OpenApiRestCall_402656044
proc url_ListGrants_402656914(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGrants_402656913(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Pagination token
  ##   Limit: JString
                                                               ##        : Pagination limit
  section = newJObject()
  var valid_402656915 = query.getOrDefault("Marker")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "Marker", valid_402656915
  var valid_402656916 = query.getOrDefault("Limit")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "Limit", valid_402656916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656917 = header.getOrDefault("X-Amz-Target")
  valid_402656917 = validateParameter(valid_402656917, JString, required = true, default = newJString(
      "TrentService.ListGrants"))
  if valid_402656917 != nil:
    section.add "X-Amz-Target", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Security-Token", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Signature")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Signature", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Algorithm", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Date")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Date", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Credential")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Credential", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656924
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

proc call*(call_402656926: Call_ListGrants_402656912; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
                                                                                         ## 
  let valid = call_402656926.validator(path, query, header, formData, body, _)
  let scheme = call_402656926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656926.makeUrl(scheme.get, call_402656926.host, call_402656926.base,
                                   call_402656926.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656926, uri, valid, _)

proc call*(call_402656927: Call_ListGrants_402656912; body: JsonNode;
           Marker: string = ""; Limit: string = ""): Recallable =
  ## listGrants
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   
                                                                                                                                                                                                                              ## Marker: string
                                                                                                                                                                                                                              ##         
                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                              ## Pagination 
                                                                                                                                                                                                                              ## token
  ##   
                                                                                                                                                                                                                                      ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                 ## Limit: string
                                                                                                                                                                                                                                                                 ##        
                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                 ## limit
  var query_402656928 = newJObject()
  var body_402656929 = newJObject()
  add(query_402656928, "Marker", newJString(Marker))
  if body != nil:
    body_402656929 = body
  add(query_402656928, "Limit", newJString(Limit))
  result = call_402656927.call(nil, query_402656928, nil, nil, body_402656929)

var listGrants* = Call_ListGrants_402656912(name: "listGrants",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListGrants",
    validator: validate_ListGrants_402656913, base: "/",
    makeUrl: url_ListGrants_402656914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPolicies_402656930 = ref object of OpenApiRestCall_402656044
proc url_ListKeyPolicies_402656932(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKeyPolicies_402656931(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Pagination token
  ##   Limit: JString
                                                               ##        : Pagination limit
  section = newJObject()
  var valid_402656933 = query.getOrDefault("Marker")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "Marker", valid_402656933
  var valid_402656934 = query.getOrDefault("Limit")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "Limit", valid_402656934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656935 = header.getOrDefault("X-Amz-Target")
  valid_402656935 = validateParameter(valid_402656935, JString, required = true, default = newJString(
      "TrentService.ListKeyPolicies"))
  if valid_402656935 != nil:
    section.add "X-Amz-Target", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Security-Token", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Signature")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Signature", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Algorithm", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-Date")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Date", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-Credential")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-Credential", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656942
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

proc call*(call_402656944: Call_ListKeyPolicies_402656930; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
                                                                                         ## 
  let valid = call_402656944.validator(path, query, header, formData, body, _)
  let scheme = call_402656944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656944.makeUrl(scheme.get, call_402656944.host, call_402656944.base,
                                   call_402656944.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656944, uri, valid, _)

proc call*(call_402656945: Call_ListKeyPolicies_402656930; body: JsonNode;
           Marker: string = ""; Limit: string = ""): Recallable =
  ## listKeyPolicies
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ##   
                                                                                                                                                                                                                                                                                                                                 ## Marker: string
                                                                                                                                                                                                                                                                                                                                 ##         
                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                                                                                 ## token
  ##   
                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                    ## Limit: string
                                                                                                                                                                                                                                                                                                                                                                    ##        
                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                    ## limit
  var query_402656946 = newJObject()
  var body_402656947 = newJObject()
  add(query_402656946, "Marker", newJString(Marker))
  if body != nil:
    body_402656947 = body
  add(query_402656946, "Limit", newJString(Limit))
  result = call_402656945.call(nil, query_402656946, nil, nil, body_402656947)

var listKeyPolicies* = Call_ListKeyPolicies_402656930(name: "listKeyPolicies",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListKeyPolicies",
    validator: validate_ListKeyPolicies_402656931, base: "/",
    makeUrl: url_ListKeyPolicies_402656932, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeys_402656948 = ref object of OpenApiRestCall_402656044
proc url_ListKeys_402656950(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKeys_402656949(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and Region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Pagination token
  ##   Limit: JString
                                                               ##        : Pagination limit
  section = newJObject()
  var valid_402656951 = query.getOrDefault("Marker")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "Marker", valid_402656951
  var valid_402656952 = query.getOrDefault("Limit")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "Limit", valid_402656952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656953 = header.getOrDefault("X-Amz-Target")
  valid_402656953 = validateParameter(valid_402656953, JString, required = true, default = newJString(
      "TrentService.ListKeys"))
  if valid_402656953 != nil:
    section.add "X-Amz-Target", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Security-Token", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Signature")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Signature", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Algorithm", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Date")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Date", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Credential")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Credential", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656960
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

proc call*(call_402656962: Call_ListKeys_402656948; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and Region.
                                                                                         ## 
  let valid = call_402656962.validator(path, query, header, formData, body, _)
  let scheme = call_402656962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656962.makeUrl(scheme.get, call_402656962.host, call_402656962.base,
                                   call_402656962.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656962, uri, valid, _)

proc call*(call_402656963: Call_ListKeys_402656948; body: JsonNode;
           Marker: string = ""; Limit: string = ""): Recallable =
  ## listKeys
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and Region.
  ##   
                                                                                           ## Marker: string
                                                                                           ##         
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## token
  ##   
                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                              ## Limit: string
                                                                                                                              ##        
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## limit
  var query_402656964 = newJObject()
  var body_402656965 = newJObject()
  add(query_402656964, "Marker", newJString(Marker))
  if body != nil:
    body_402656965 = body
  add(query_402656964, "Limit", newJString(Limit))
  result = call_402656963.call(nil, query_402656964, nil, nil, body_402656965)

var listKeys* = Call_ListKeys_402656948(name: "listKeys",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListKeys",
                                        validator: validate_ListKeys_402656949,
                                        base: "/", makeUrl: url_ListKeys_402656950,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceTags_402656966 = ref object of OpenApiRestCall_402656044
proc url_ListResourceTags_402656968(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceTags_402656967(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656969 = header.getOrDefault("X-Amz-Target")
  valid_402656969 = validateParameter(valid_402656969, JString, required = true, default = newJString(
      "TrentService.ListResourceTags"))
  if valid_402656969 != nil:
    section.add "X-Amz-Target", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Security-Token", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Signature")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Signature", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Algorithm", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Date")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Date", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Credential")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Credential", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656976
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

proc call*(call_402656978: Call_ListResourceTags_402656966;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
                                                                                         ## 
  let valid = call_402656978.validator(path, query, header, formData, body, _)
  let scheme = call_402656978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656978.makeUrl(scheme.get, call_402656978.host, call_402656978.base,
                                   call_402656978.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656978, uri, valid, _)

proc call*(call_402656979: Call_ListResourceTags_402656966; body: JsonNode): Recallable =
  ## listResourceTags
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
  ##   
                                                                                                                                                                 ## body: JObject (required)
  var body_402656980 = newJObject()
  if body != nil:
    body_402656980 = body
  result = call_402656979.call(nil, nil, nil, nil, body_402656980)

var listResourceTags* = Call_ListResourceTags_402656966(
    name: "listResourceTags", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListResourceTags",
    validator: validate_ListResourceTags_402656967, base: "/",
    makeUrl: url_ListResourceTags_402656968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRetirableGrants_402656981 = ref object of OpenApiRestCall_402656044
proc url_ListRetirableGrants_402656983(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRetirableGrants_402656982(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656984 = header.getOrDefault("X-Amz-Target")
  valid_402656984 = validateParameter(valid_402656984, JString, required = true, default = newJString(
      "TrentService.ListRetirableGrants"))
  if valid_402656984 != nil:
    section.add "X-Amz-Target", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Security-Token", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Signature")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Signature", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Algorithm", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Date")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Date", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Credential")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Credential", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656991
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

proc call*(call_402656993: Call_ListRetirableGrants_402656981;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
                                                                                         ## 
  let valid = call_402656993.validator(path, query, header, formData, body, _)
  let scheme = call_402656993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656993.makeUrl(scheme.get, call_402656993.host, call_402656993.base,
                                   call_402656993.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656993, uri, valid, _)

proc call*(call_402656994: Call_ListRetirableGrants_402656981; body: JsonNode): Recallable =
  ## listRetirableGrants
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
  ##   
                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656995 = newJObject()
  if body != nil:
    body_402656995 = body
  result = call_402656994.call(nil, nil, nil, nil, body_402656995)

var listRetirableGrants* = Call_ListRetirableGrants_402656981(
    name: "listRetirableGrants", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListRetirableGrants",
    validator: validate_ListRetirableGrants_402656982, base: "/",
    makeUrl: url_ListRetirableGrants_402656983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutKeyPolicy_402656996 = ref object of OpenApiRestCall_402656044
proc url_PutKeyPolicy_402656998(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutKeyPolicy_402656997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656999 = header.getOrDefault("X-Amz-Target")
  valid_402656999 = validateParameter(valid_402656999, JString, required = true, default = newJString(
      "TrentService.PutKeyPolicy"))
  if valid_402656999 != nil:
    section.add "X-Amz-Target", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Security-Token", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Signature")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Signature", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Algorithm", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Date")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Date", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Credential")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Credential", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657006
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

proc call*(call_402657008: Call_PutKeyPolicy_402656996; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657008.validator(path, query, header, formData, body, _)
  let scheme = call_402657008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657008.makeUrl(scheme.get, call_402657008.host, call_402657008.base,
                                   call_402657008.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657008, uri, valid, _)

proc call*(call_402657009: Call_PutKeyPolicy_402656996; body: JsonNode): Recallable =
  ## putKeyPolicy
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402657010 = newJObject()
  if body != nil:
    body_402657010 = body
  result = call_402657009.call(nil, nil, nil, nil, body_402657010)

var putKeyPolicy* = Call_PutKeyPolicy_402656996(name: "putKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.PutKeyPolicy",
    validator: validate_PutKeyPolicy_402656997, base: "/",
    makeUrl: url_PutKeyPolicy_402656998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReEncrypt_402657011 = ref object of OpenApiRestCall_402656044
proc url_ReEncrypt_402657013(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReEncrypt_402657012(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Decrypts ciphertext and then reencrypts it entirely within AWS KMS. You can use this operation to change the customer master key (CMK) under which data is encrypted, such as when you <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually">manually rotate</a> a CMK or change the CMK that protects a ciphertext. You can also use it to reencrypt ciphertext under the same CMK, such as to change the encryption context of a ciphertext. </p> <p>The <code>ReEncrypt</code> operation can decrypt ciphertext that was encrypted by using an AWS KMS CMK in an AWS KMS operation, such as <a>Encrypt</a> or <a>GenerateDataKey</a>. It can also decrypt ciphertext that was encrypted by using the public key of an asymmetric CMK outside of AWS KMS. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>When you use the <code>ReEncrypt</code> operation, you need to provide information for the decrypt operation and the subsequent encrypt operation.</p> <ul> <li> <p>If your ciphertext was encrypted under an asymmetric CMK, you must identify the <i>source CMK</i>, that is, the CMK that encrypted the ciphertext. You must also supply the encryption algorithm that was used. This information is required to decrypt the data.</p> </li> <li> <p>It is optional, but you can specify a source CMK even when the ciphertext was encrypted under a symmetric CMK. This ensures that the ciphertext is decrypted only by using a particular CMK. If the CMK that you specify cannot decrypt the ciphertext, the <code>ReEncrypt</code> operation fails.</p> </li> <li> <p>To reencrypt the data, you must specify the <i>destination CMK</i>, that is, the CMK that re-encrypts the data after it is decrypted. You can select a symmetric or asymmetric CMK. If the destination CMK is an asymmetric CMK, you must also provide the encryption algorithm. The algorithm that you choose must be compatible with the CMK.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> </li> </ul> <p>Unlike other AWS KMS API operations, <code>ReEncrypt</code> callers must have two permissions:</p> <ul> <li> <p> <code>kms:EncryptFrom</code> permission on the source CMK</p> </li> <li> <p> <code>kms:EncryptTo</code> permission on the destination CMK</p> </li> </ul> <p>To permit reencryption from</p> <p> or to a CMK, include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policy</a>. This permission is automatically included in the key policy when you use the console to create a CMK. But you must include it manually when you create a CMK programmatically or when you use the <a>PutKeyPolicy</a> operation set a key policy.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657014 = header.getOrDefault("X-Amz-Target")
  valid_402657014 = validateParameter(valid_402657014, JString, required = true, default = newJString(
      "TrentService.ReEncrypt"))
  if valid_402657014 != nil:
    section.add "X-Amz-Target", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Security-Token", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Signature")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Signature", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Algorithm", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Date")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Date", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Credential")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Credential", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657021
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

proc call*(call_402657023: Call_ReEncrypt_402657011; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Decrypts ciphertext and then reencrypts it entirely within AWS KMS. You can use this operation to change the customer master key (CMK) under which data is encrypted, such as when you <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually">manually rotate</a> a CMK or change the CMK that protects a ciphertext. You can also use it to reencrypt ciphertext under the same CMK, such as to change the encryption context of a ciphertext. </p> <p>The <code>ReEncrypt</code> operation can decrypt ciphertext that was encrypted by using an AWS KMS CMK in an AWS KMS operation, such as <a>Encrypt</a> or <a>GenerateDataKey</a>. It can also decrypt ciphertext that was encrypted by using the public key of an asymmetric CMK outside of AWS KMS. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>When you use the <code>ReEncrypt</code> operation, you need to provide information for the decrypt operation and the subsequent encrypt operation.</p> <ul> <li> <p>If your ciphertext was encrypted under an asymmetric CMK, you must identify the <i>source CMK</i>, that is, the CMK that encrypted the ciphertext. You must also supply the encryption algorithm that was used. This information is required to decrypt the data.</p> </li> <li> <p>It is optional, but you can specify a source CMK even when the ciphertext was encrypted under a symmetric CMK. This ensures that the ciphertext is decrypted only by using a particular CMK. If the CMK that you specify cannot decrypt the ciphertext, the <code>ReEncrypt</code> operation fails.</p> </li> <li> <p>To reencrypt the data, you must specify the <i>destination CMK</i>, that is, the CMK that re-encrypts the data after it is decrypted. You can select a symmetric or asymmetric CMK. If the destination CMK is an asymmetric CMK, you must also provide the encryption algorithm. The algorithm that you choose must be compatible with the CMK.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> </li> </ul> <p>Unlike other AWS KMS API operations, <code>ReEncrypt</code> callers must have two permissions:</p> <ul> <li> <p> <code>kms:EncryptFrom</code> permission on the source CMK</p> </li> <li> <p> <code>kms:EncryptTo</code> permission on the destination CMK</p> </li> </ul> <p>To permit reencryption from</p> <p> or to a CMK, include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policy</a>. This permission is automatically included in the key policy when you use the console to create a CMK. But you must include it manually when you create a CMK programmatically or when you use the <a>PutKeyPolicy</a> operation set a key policy.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657023.validator(path, query, header, formData, body, _)
  let scheme = call_402657023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657023.makeUrl(scheme.get, call_402657023.host, call_402657023.base,
                                   call_402657023.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657023, uri, valid, _)

proc call*(call_402657024: Call_ReEncrypt_402657011; body: JsonNode): Recallable =
  ## reEncrypt
  ## <p>Decrypts ciphertext and then reencrypts it entirely within AWS KMS. You can use this operation to change the customer master key (CMK) under which data is encrypted, such as when you <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually">manually rotate</a> a CMK or change the CMK that protects a ciphertext. You can also use it to reencrypt ciphertext under the same CMK, such as to change the encryption context of a ciphertext. </p> <p>The <code>ReEncrypt</code> operation can decrypt ciphertext that was encrypted by using an AWS KMS CMK in an AWS KMS operation, such as <a>Encrypt</a> or <a>GenerateDataKey</a>. It can also decrypt ciphertext that was encrypted by using the public key of an asymmetric CMK outside of AWS KMS. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>When you use the <code>ReEncrypt</code> operation, you need to provide information for the decrypt operation and the subsequent encrypt operation.</p> <ul> <li> <p>If your ciphertext was encrypted under an asymmetric CMK, you must identify the <i>source CMK</i>, that is, the CMK that encrypted the ciphertext. You must also supply the encryption algorithm that was used. This information is required to decrypt the data.</p> </li> <li> <p>It is optional, but you can specify a source CMK even when the ciphertext was encrypted under a symmetric CMK. This ensures that the ciphertext is decrypted only by using a particular CMK. If the CMK that you specify cannot decrypt the ciphertext, the <code>ReEncrypt</code> operation fails.</p> </li> <li> <p>To reencrypt the data, you must specify the <i>destination CMK</i>, that is, the CMK that re-encrypts the data after it is decrypted. You can select a symmetric or asymmetric CMK. If the destination CMK is an asymmetric CMK, you must also provide the encryption algorithm. The algorithm that you choose must be compatible with the CMK.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> </li> </ul> <p>Unlike other AWS KMS API operations, <code>ReEncrypt</code> callers must have two permissions:</p> <ul> <li> <p> <code>kms:EncryptFrom</code> permission on the source CMK</p> </li> <li> <p> <code>kms:EncryptTo</code> permission on the destination CMK</p> </li> </ul> <p>To permit reencryption from</p> <p> or to a CMK, include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policy</a>. This permission is automatically included in the key policy when you use the console to create a CMK. But you must include it manually when you create a CMK programmatically or when you use the <a>PutKeyPolicy</a> operation set a key policy.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402657025 = newJObject()
  if body != nil:
    body_402657025 = body
  result = call_402657024.call(nil, nil, nil, nil, body_402657025)

var reEncrypt* = Call_ReEncrypt_402657011(name: "reEncrypt",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ReEncrypt",
    validator: validate_ReEncrypt_402657012, base: "/", makeUrl: url_ReEncrypt_402657013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetireGrant_402657026 = ref object of OpenApiRestCall_402656044
proc url_RetireGrant_402657028(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RetireGrant_402657027(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657029 = header.getOrDefault("X-Amz-Target")
  valid_402657029 = validateParameter(valid_402657029, JString, required = true, default = newJString(
      "TrentService.RetireGrant"))
  if valid_402657029 != nil:
    section.add "X-Amz-Target", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Security-Token", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Signature")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Signature", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Algorithm", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Date")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Date", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Credential")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Credential", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657036
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

proc call*(call_402657038: Call_RetireGrant_402657026; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
                                                                                         ## 
  let valid = call_402657038.validator(path, query, header, formData, body, _)
  let scheme = call_402657038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657038.makeUrl(scheme.get, call_402657038.host, call_402657038.base,
                                   call_402657038.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657038, uri, valid, _)

proc call*(call_402657039: Call_RetireGrant_402657026; body: JsonNode): Recallable =
  ## retireGrant
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657040 = newJObject()
  if body != nil:
    body_402657040 = body
  result = call_402657039.call(nil, nil, nil, nil, body_402657040)

var retireGrant* = Call_RetireGrant_402657026(name: "retireGrant",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.RetireGrant",
    validator: validate_RetireGrant_402657027, base: "/",
    makeUrl: url_RetireGrant_402657028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeGrant_402657041 = ref object of OpenApiRestCall_402656044
proc url_RevokeGrant_402657043(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RevokeGrant_402657042(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657044 = header.getOrDefault("X-Amz-Target")
  valid_402657044 = validateParameter(valid_402657044, JString, required = true, default = newJString(
      "TrentService.RevokeGrant"))
  if valid_402657044 != nil:
    section.add "X-Amz-Target", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Security-Token", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Signature")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Signature", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Algorithm", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Date")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Date", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Credential")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Credential", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657051
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

proc call*(call_402657053: Call_RevokeGrant_402657041; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
                                                                                         ## 
  let valid = call_402657053.validator(path, query, header, formData, body, _)
  let scheme = call_402657053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657053.makeUrl(scheme.get, call_402657053.host, call_402657053.base,
                                   call_402657053.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657053, uri, valid, _)

proc call*(call_402657054: Call_RevokeGrant_402657041; body: JsonNode): Recallable =
  ## revokeGrant
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   
                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657055 = newJObject()
  if body != nil:
    body_402657055 = body
  result = call_402657054.call(nil, nil, nil, nil, body_402657055)

var revokeGrant* = Call_RevokeGrant_402657041(name: "revokeGrant",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.RevokeGrant",
    validator: validate_RevokeGrant_402657042, base: "/",
    makeUrl: url_RevokeGrant_402657043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleKeyDeletion_402657056 = ref object of OpenApiRestCall_402656044
proc url_ScheduleKeyDeletion_402657058(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScheduleKeyDeletion_402657057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657059 = header.getOrDefault("X-Amz-Target")
  valid_402657059 = validateParameter(valid_402657059, JString, required = true, default = newJString(
      "TrentService.ScheduleKeyDeletion"))
  if valid_402657059 != nil:
    section.add "X-Amz-Target", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Security-Token", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-Signature")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Signature", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Algorithm", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Date")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Date", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Credential")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Credential", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657066
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

proc call*(call_402657068: Call_ScheduleKeyDeletion_402657056;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657068.validator(path, query, header, formData, body, _)
  let scheme = call_402657068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657068.makeUrl(scheme.get, call_402657068.host, call_402657068.base,
                                   call_402657068.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657068, uri, valid, _)

proc call*(call_402657069: Call_ScheduleKeyDeletion_402657056; body: JsonNode): Recallable =
  ## scheduleKeyDeletion
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657070 = newJObject()
  if body != nil:
    body_402657070 = body
  result = call_402657069.call(nil, nil, nil, nil, body_402657070)

var scheduleKeyDeletion* = Call_ScheduleKeyDeletion_402657056(
    name: "scheduleKeyDeletion", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ScheduleKeyDeletion",
    validator: validate_ScheduleKeyDeletion_402657057, base: "/",
    makeUrl: url_ScheduleKeyDeletion_402657058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Sign_402657071 = ref object of OpenApiRestCall_402656044
proc url_Sign_402657073(protocol: Scheme; host: string; base: string;
                        route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Sign_402657072(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a <a href="https://en.wikipedia.org/wiki/Digital_signature">digital signature</a> for a message or message digest by using the private key in an asymmetric CMK. To verify the signature, use the <a>Verify</a> operation, or use the public key in the same asymmetric CMK outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Digital signatures are generated and verified by using asymmetric key pair, such as an RSA or ECC pair that is represented by an asymmetric customer master key (CMK). The key owner (or an authorized user) uses their private key to sign a message. Anyone with the public key can verify that the message was signed with that particular private key and that the message hasn't changed since it was signed. </p> <p>To use the <code>Sign</code> operation, provide the following information:</p> <ul> <li> <p>Use the <code>KeyId</code> parameter to identify an asymmetric CMK with a <code>KeyUsage</code> value of <code>SIGN_VERIFY</code>. To get the <code>KeyUsage</code> value of a CMK, use the <a>DescribeKey</a> operation. The caller must have <code>kms:Sign</code> permission on the CMK.</p> </li> <li> <p>Use the <code>Message</code> parameter to specify the message or message digest to sign. You can submit messages of up to 4096 bytes. To sign a larger message, generate a hash digest of the message, and then provide the hash digest in the <code>Message</code> parameter. To indicate whether the message is a full message or a digest, use the <code>MessageType</code> parameter.</p> </li> <li> <p>Choose a signing algorithm that is compatible with the CMK. </p> </li> </ul> <important> <p>When signing a message, be sure to record the CMK and the signing algorithm. This information is required to verify the signature.</p> </important> <p>To verify the signature that this operation generates, use the <a>Verify</a> operation. Or use the <a>GetPublicKey</a> operation to download the public key and then use the public key to verify the signature outside of AWS KMS. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657074 = header.getOrDefault("X-Amz-Target")
  valid_402657074 = validateParameter(valid_402657074, JString, required = true,
                                      default = newJString("TrentService.Sign"))
  if valid_402657074 != nil:
    section.add "X-Amz-Target", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Security-Token", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-Signature")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Signature", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Algorithm", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Date")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Date", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Credential")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Credential", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657081
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

proc call*(call_402657083: Call_Sign_402657071; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <a href="https://en.wikipedia.org/wiki/Digital_signature">digital signature</a> for a message or message digest by using the private key in an asymmetric CMK. To verify the signature, use the <a>Verify</a> operation, or use the public key in the same asymmetric CMK outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Digital signatures are generated and verified by using asymmetric key pair, such as an RSA or ECC pair that is represented by an asymmetric customer master key (CMK). The key owner (or an authorized user) uses their private key to sign a message. Anyone with the public key can verify that the message was signed with that particular private key and that the message hasn't changed since it was signed. </p> <p>To use the <code>Sign</code> operation, provide the following information:</p> <ul> <li> <p>Use the <code>KeyId</code> parameter to identify an asymmetric CMK with a <code>KeyUsage</code> value of <code>SIGN_VERIFY</code>. To get the <code>KeyUsage</code> value of a CMK, use the <a>DescribeKey</a> operation. The caller must have <code>kms:Sign</code> permission on the CMK.</p> </li> <li> <p>Use the <code>Message</code> parameter to specify the message or message digest to sign. You can submit messages of up to 4096 bytes. To sign a larger message, generate a hash digest of the message, and then provide the hash digest in the <code>Message</code> parameter. To indicate whether the message is a full message or a digest, use the <code>MessageType</code> parameter.</p> </li> <li> <p>Choose a signing algorithm that is compatible with the CMK. </p> </li> </ul> <important> <p>When signing a message, be sure to record the CMK and the signing algorithm. This information is required to verify the signature.</p> </important> <p>To verify the signature that this operation generates, use the <a>Verify</a> operation. Or use the <a>GetPublicKey</a> operation to download the public key and then use the public key to verify the signature outside of AWS KMS. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657083.validator(path, query, header, formData, body, _)
  let scheme = call_402657083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657083.makeUrl(scheme.get, call_402657083.host, call_402657083.base,
                                   call_402657083.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657083, uri, valid, _)

proc call*(call_402657084: Call_Sign_402657071; body: JsonNode): Recallable =
  ## sign
  ## <p>Creates a <a href="https://en.wikipedia.org/wiki/Digital_signature">digital signature</a> for a message or message digest by using the private key in an asymmetric CMK. To verify the signature, use the <a>Verify</a> operation, or use the public key in the same asymmetric CMK outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Digital signatures are generated and verified by using asymmetric key pair, such as an RSA or ECC pair that is represented by an asymmetric customer master key (CMK). The key owner (or an authorized user) uses their private key to sign a message. Anyone with the public key can verify that the message was signed with that particular private key and that the message hasn't changed since it was signed. </p> <p>To use the <code>Sign</code> operation, provide the following information:</p> <ul> <li> <p>Use the <code>KeyId</code> parameter to identify an asymmetric CMK with a <code>KeyUsage</code> value of <code>SIGN_VERIFY</code>. To get the <code>KeyUsage</code> value of a CMK, use the <a>DescribeKey</a> operation. The caller must have <code>kms:Sign</code> permission on the CMK.</p> </li> <li> <p>Use the <code>Message</code> parameter to specify the message or message digest to sign. You can submit messages of up to 4096 bytes. To sign a larger message, generate a hash digest of the message, and then provide the hash digest in the <code>Message</code> parameter. To indicate whether the message is a full message or a digest, use the <code>MessageType</code> parameter.</p> </li> <li> <p>Choose a signing algorithm that is compatible with the CMK. </p> </li> </ul> <important> <p>When signing a message, be sure to record the CMK and the signing algorithm. This information is required to verify the signature.</p> </important> <p>To verify the signature that this operation generates, use the <a>Verify</a> operation. Or use the <a>GetPublicKey</a> operation to download the public key and then use the public key to verify the signature outside of AWS KMS. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402657085 = newJObject()
  if body != nil:
    body_402657085 = body
  result = call_402657084.call(nil, nil, nil, nil, body_402657085)

var sign* = Call_Sign_402657071(name: "sign", meth: HttpMethod.HttpPost,
                                host: "kms.amazonaws.com",
                                route: "/#X-Amz-Target=TrentService.Sign",
                                validator: validate_Sign_402657072, base: "/",
                                makeUrl: url_Sign_402657073,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657086 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657088(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657087(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657089 = header.getOrDefault("X-Amz-Target")
  valid_402657089 = validateParameter(valid_402657089, JString, required = true, default = newJString(
      "TrentService.TagResource"))
  if valid_402657089 != nil:
    section.add "X-Amz-Target", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Security-Token", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-Signature")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-Signature", valid_402657091
  var valid_402657092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Algorithm", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Date")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Date", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Credential")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Credential", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657096
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

proc call*(call_402657098: Call_TagResource_402657086; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657098.validator(path, query, header, formData, body, _)
  let scheme = call_402657098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657098.makeUrl(scheme.get, call_402657098.host, call_402657098.base,
                                   call_402657098.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657098, uri, valid, _)

proc call*(call_402657099: Call_TagResource_402657086; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657100 = newJObject()
  if body != nil:
    body_402657100 = body
  result = call_402657099.call(nil, nil, nil, nil, body_402657100)

var tagResource* = Call_TagResource_402657086(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.TagResource",
    validator: validate_TagResource_402657087, base: "/",
    makeUrl: url_TagResource_402657088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657101 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657103(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657102(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657104 = header.getOrDefault("X-Amz-Target")
  valid_402657104 = validateParameter(valid_402657104, JString, required = true, default = newJString(
      "TrentService.UntagResource"))
  if valid_402657104 != nil:
    section.add "X-Amz-Target", valid_402657104
  var valid_402657105 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657105 = validateParameter(valid_402657105, JString,
                                      required = false, default = nil)
  if valid_402657105 != nil:
    section.add "X-Amz-Security-Token", valid_402657105
  var valid_402657106 = header.getOrDefault("X-Amz-Signature")
  valid_402657106 = validateParameter(valid_402657106, JString,
                                      required = false, default = nil)
  if valid_402657106 != nil:
    section.add "X-Amz-Signature", valid_402657106
  var valid_402657107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657107 = validateParameter(valid_402657107, JString,
                                      required = false, default = nil)
  if valid_402657107 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657107
  var valid_402657108 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Algorithm", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Date")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Date", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Credential")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Credential", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657111
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

proc call*(call_402657113: Call_UntagResource_402657101; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657113.validator(path, query, header, formData, body, _)
  let scheme = call_402657113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657113.makeUrl(scheme.get, call_402657113.host, call_402657113.base,
                                   call_402657113.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657113, uri, valid, _)

proc call*(call_402657114: Call_UntagResource_402657101; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657115 = newJObject()
  if body != nil:
    body_402657115 = body
  result = call_402657114.call(nil, nil, nil, nil, body_402657115)

var untagResource* = Call_UntagResource_402657101(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UntagResource",
    validator: validate_UntagResource_402657102, base: "/",
    makeUrl: url_UntagResource_402657103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_402657116 = ref object of OpenApiRestCall_402656044
proc url_UpdateAlias_402657118(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAlias_402657117(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Associates an existing AWS KMS alias with a different customer master key (CMK). Each alias is associated with only one CMK at a time, although a CMK can have multiple aliases. The alias and the CMK must be in the same AWS account and region. You cannot perform this operation on an alias in a different AWS account. </p> <p>The current and new CMK must be the same type (both symmetric or both asymmetric), and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents errors in code that uses aliases. If you must assign an alias to a different type of CMK, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>You cannot use <code>UpdateAlias</code> to change an alias name. To change an alias name, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657119 = header.getOrDefault("X-Amz-Target")
  valid_402657119 = validateParameter(valid_402657119, JString, required = true, default = newJString(
      "TrentService.UpdateAlias"))
  if valid_402657119 != nil:
    section.add "X-Amz-Target", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-Security-Token", valid_402657120
  var valid_402657121 = header.getOrDefault("X-Amz-Signature")
  valid_402657121 = validateParameter(valid_402657121, JString,
                                      required = false, default = nil)
  if valid_402657121 != nil:
    section.add "X-Amz-Signature", valid_402657121
  var valid_402657122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657122 = validateParameter(valid_402657122, JString,
                                      required = false, default = nil)
  if valid_402657122 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Algorithm", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-Date")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Date", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Credential")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Credential", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657126
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

proc call*(call_402657128: Call_UpdateAlias_402657116; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates an existing AWS KMS alias with a different customer master key (CMK). Each alias is associated with only one CMK at a time, although a CMK can have multiple aliases. The alias and the CMK must be in the same AWS account and region. You cannot perform this operation on an alias in a different AWS account. </p> <p>The current and new CMK must be the same type (both symmetric or both asymmetric), and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents errors in code that uses aliases. If you must assign an alias to a different type of CMK, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>You cannot use <code>UpdateAlias</code> to change an alias name. To change an alias name, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657128.validator(path, query, header, formData, body, _)
  let scheme = call_402657128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657128.makeUrl(scheme.get, call_402657128.host, call_402657128.base,
                                   call_402657128.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657128, uri, valid, _)

proc call*(call_402657129: Call_UpdateAlias_402657116; body: JsonNode): Recallable =
  ## updateAlias
  ## <p>Associates an existing AWS KMS alias with a different customer master key (CMK). Each alias is associated with only one CMK at a time, although a CMK can have multiple aliases. The alias and the CMK must be in the same AWS account and region. You cannot perform this operation on an alias in a different AWS account. </p> <p>The current and new CMK must be the same type (both symmetric or both asymmetric), and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents errors in code that uses aliases. If you must assign an alias to a different type of CMK, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>You cannot use <code>UpdateAlias</code> to change an alias name. To change an alias name, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657130 = newJObject()
  if body != nil:
    body_402657130 = body
  result = call_402657129.call(nil, nil, nil, nil, body_402657130)

var updateAlias* = Call_UpdateAlias_402657116(name: "updateAlias",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateAlias",
    validator: validate_UpdateAlias_402657117, base: "/",
    makeUrl: url_UpdateAlias_402657118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCustomKeyStore_402657131 = ref object of OpenApiRestCall_402656044
proc url_UpdateCustomKeyStore_402657133(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCustomKeyStore_402657132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657134 = header.getOrDefault("X-Amz-Target")
  valid_402657134 = validateParameter(valid_402657134, JString, required = true, default = newJString(
      "TrentService.UpdateCustomKeyStore"))
  if valid_402657134 != nil:
    section.add "X-Amz-Target", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Security-Token", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-Signature")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Signature", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Algorithm", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-Date")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-Date", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Credential")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Credential", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657141
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

proc call*(call_402657143: Call_UpdateCustomKeyStore_402657131;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
                                                                                         ## 
  let valid = call_402657143.validator(path, query, header, formData, body, _)
  let scheme = call_402657143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657143.makeUrl(scheme.get, call_402657143.host, call_402657143.base,
                                   call_402657143.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657143, uri, valid, _)

proc call*(call_402657144: Call_UpdateCustomKeyStore_402657131; body: JsonNode): Recallable =
  ## updateCustomKeyStore
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402657145 = newJObject()
  if body != nil:
    body_402657145 = body
  result = call_402657144.call(nil, nil, nil, nil, body_402657145)

var updateCustomKeyStore* = Call_UpdateCustomKeyStore_402657131(
    name: "updateCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateCustomKeyStore",
    validator: validate_UpdateCustomKeyStore_402657132, base: "/",
    makeUrl: url_UpdateCustomKeyStore_402657133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateKeyDescription_402657146 = ref object of OpenApiRestCall_402656044
proc url_UpdateKeyDescription_402657148(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateKeyDescription_402657147(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657149 = header.getOrDefault("X-Amz-Target")
  valid_402657149 = validateParameter(valid_402657149, JString, required = true, default = newJString(
      "TrentService.UpdateKeyDescription"))
  if valid_402657149 != nil:
    section.add "X-Amz-Target", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-Security-Token", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Signature")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Signature", valid_402657151
  var valid_402657152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Algorithm", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-Date")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Date", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Credential")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Credential", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657156
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

proc call*(call_402657158: Call_UpdateKeyDescription_402657146;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657158.validator(path, query, header, formData, body, _)
  let scheme = call_402657158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657158.makeUrl(scheme.get, call_402657158.host, call_402657158.base,
                                   call_402657158.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657158, uri, valid, _)

proc call*(call_402657159: Call_UpdateKeyDescription_402657146; body: JsonNode): Recallable =
  ## updateKeyDescription
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402657160 = newJObject()
  if body != nil:
    body_402657160 = body
  result = call_402657159.call(nil, nil, nil, nil, body_402657160)

var updateKeyDescription* = Call_UpdateKeyDescription_402657146(
    name: "updateKeyDescription", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateKeyDescription",
    validator: validate_UpdateKeyDescription_402657147, base: "/",
    makeUrl: url_UpdateKeyDescription_402657148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Verify_402657161 = ref object of OpenApiRestCall_402656044
proc url_Verify_402657163(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Verify_402657162(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Verifies a digital signature that was generated by the <a>Sign</a> operation. </p> <p/> <p>Verification confirms that an authorized user signed the message with the specified CMK and signing algorithm, and the message hasn't changed since it was signed. If the signature is verified, the value of the <code>SignatureValid</code> field in the response is <code>True</code>. If the signature verification fails, the <code>Verify</code> operation fails with an <code>KMSInvalidSignatureException</code> exception.</p> <p>A digital signature is generated by using the private key in an asymmetric CMK. The signature is verified by using the public key in the same asymmetric CMK. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To verify a digital signature, you can use the <code>Verify</code> operation. Specify the same asymmetric CMK, message, and signing algorithm that were used to produce the signature.</p> <p>You can also verify the digital signature by using the public key of the CMK outside of AWS KMS. Use the <a>GetPublicKey</a> operation to download the public key in the asymmetric CMK and then use the public key to verify the signature outside of AWS KMS. The advantage of using the <code>Verify</code> operation is that it is performed within AWS KMS. As a result, it's easy to call, the operation is performed within the FIPS boundary, it is logged in AWS CloudTrail, and you can use key policy and IAM policy to determine who is authorized to use the CMK to verify signatures.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657164 = header.getOrDefault("X-Amz-Target")
  valid_402657164 = validateParameter(valid_402657164, JString, required = true, default = newJString(
      "TrentService.Verify"))
  if valid_402657164 != nil:
    section.add "X-Amz-Target", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-Security-Token", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-Signature")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-Signature", valid_402657166
  var valid_402657167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Algorithm", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Date")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Date", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-Credential")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-Credential", valid_402657170
  var valid_402657171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false, default = nil)
  if valid_402657171 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657171
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

proc call*(call_402657173: Call_Verify_402657161; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Verifies a digital signature that was generated by the <a>Sign</a> operation. </p> <p/> <p>Verification confirms that an authorized user signed the message with the specified CMK and signing algorithm, and the message hasn't changed since it was signed. If the signature is verified, the value of the <code>SignatureValid</code> field in the response is <code>True</code>. If the signature verification fails, the <code>Verify</code> operation fails with an <code>KMSInvalidSignatureException</code> exception.</p> <p>A digital signature is generated by using the private key in an asymmetric CMK. The signature is verified by using the public key in the same asymmetric CMK. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To verify a digital signature, you can use the <code>Verify</code> operation. Specify the same asymmetric CMK, message, and signing algorithm that were used to produce the signature.</p> <p>You can also verify the digital signature by using the public key of the CMK outside of AWS KMS. Use the <a>GetPublicKey</a> operation to download the public key in the asymmetric CMK and then use the public key to verify the signature outside of AWS KMS. The advantage of using the <code>Verify</code> operation is that it is performed within AWS KMS. As a result, it's easy to call, the operation is performed within the FIPS boundary, it is logged in AWS CloudTrail, and you can use key policy and IAM policy to determine who is authorized to use the CMK to verify signatures.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657173.validator(path, query, header, formData, body, _)
  let scheme = call_402657173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657173.makeUrl(scheme.get, call_402657173.host, call_402657173.base,
                                   call_402657173.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657173, uri, valid, _)

proc call*(call_402657174: Call_Verify_402657161; body: JsonNode): Recallable =
  ## verify
  ## <p>Verifies a digital signature that was generated by the <a>Sign</a> operation. </p> <p/> <p>Verification confirms that an authorized user signed the message with the specified CMK and signing algorithm, and the message hasn't changed since it was signed. If the signature is verified, the value of the <code>SignatureValid</code> field in the response is <code>True</code>. If the signature verification fails, the <code>Verify</code> operation fails with an <code>KMSInvalidSignatureException</code> exception.</p> <p>A digital signature is generated by using the private key in an asymmetric CMK. The signature is verified by using the public key in the same asymmetric CMK. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To verify a digital signature, you can use the <code>Verify</code> operation. Specify the same asymmetric CMK, message, and signing algorithm that were used to produce the signature.</p> <p>You can also verify the digital signature by using the public key of the CMK outside of AWS KMS. Use the <a>GetPublicKey</a> operation to download the public key in the asymmetric CMK and then use the public key to verify the signature outside of AWS KMS. The advantage of using the <code>Verify</code> operation is that it is performed within AWS KMS. As a result, it's easy to call, the operation is performed within the FIPS boundary, it is logged in AWS CloudTrail, and you can use key policy and IAM policy to determine who is authorized to use the CMK to verify signatures.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402657175 = newJObject()
  if body != nil:
    body_402657175 = body
  result = call_402657174.call(nil, nil, nil, nil, body_402657175)

var verify* = Call_Verify_402657161(name: "verify", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.Verify",
                                    validator: validate_Verify_402657162,
                                    base: "/", makeUrl: url_Verify_402657163,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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