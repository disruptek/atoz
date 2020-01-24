
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_606589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_606589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_606589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "kms.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kms.ap-southeast-1.amazonaws.com",
                           "us-west-2": "kms.us-west-2.amazonaws.com",
                           "eu-west-2": "kms.eu-west-2.amazonaws.com", "ap-northeast-3": "kms.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "kms.eu-central-1.amazonaws.com",
                           "us-east-2": "kms.us-east-2.amazonaws.com",
                           "us-east-1": "kms.us-east-1.amazonaws.com", "cn-northwest-1": "kms.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "kms.ap-south-1.amazonaws.com",
                           "eu-north-1": "kms.eu-north-1.amazonaws.com", "ap-northeast-2": "kms.ap-northeast-2.amazonaws.com",
                           "us-west-1": "kms.us-west-1.amazonaws.com",
                           "us-gov-east-1": "kms.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "kms.eu-west-3.amazonaws.com",
                           "cn-north-1": "kms.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "kms.sa-east-1.amazonaws.com",
                           "eu-west-1": "kms.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "kms.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kms.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "kms.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelKeyDeletion_606927 = ref object of OpenApiRestCall_606589
proc url_CancelKeyDeletion_606929(protocol: Scheme; host: string; base: string;
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

proc validate_CancelKeyDeletion_606928(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607054 = header.getOrDefault("X-Amz-Target")
  valid_607054 = validateParameter(valid_607054, JString, required = true, default = newJString(
      "TrentService.CancelKeyDeletion"))
  if valid_607054 != nil:
    section.add "X-Amz-Target", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-Signature")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Signature", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Content-Sha256", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Date")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Date", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Credential")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Credential", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Security-Token")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Security-Token", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Algorithm")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Algorithm", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-SignedHeaders", valid_607061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_CancelKeyDeletion_606927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation succeeds, the key state of the CMK is <code>Disabled</code>. To enable the CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607156: Call_CancelKeyDeletion_606927; body: JsonNode): Recallable =
  ## cancelKeyDeletion
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation succeeds, the key state of the CMK is <code>Disabled</code>. To enable the CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607157 = newJObject()
  if body != nil:
    body_607157 = body
  result = call_607156.call(nil, nil, nil, nil, body_607157)

var cancelKeyDeletion* = Call_CancelKeyDeletion_606927(name: "cancelKeyDeletion",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CancelKeyDeletion",
    validator: validate_CancelKeyDeletion_606928, base: "/",
    url: url_CancelKeyDeletion_606929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectCustomKeyStore_607196 = ref object of OpenApiRestCall_606589
proc url_ConnectCustomKeyStore_607198(protocol: Scheme; host: string; base: string;
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

proc validate_ConnectCustomKeyStore_607197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607199 = header.getOrDefault("X-Amz-Target")
  valid_607199 = validateParameter(valid_607199, JString, required = true, default = newJString(
      "TrentService.ConnectCustomKeyStore"))
  if valid_607199 != nil:
    section.add "X-Amz-Target", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Signature")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Signature", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Content-Sha256", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Date")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Date", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Credential")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Credential", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Security-Token")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Security-Token", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Algorithm")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Algorithm", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-SignedHeaders", valid_607206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607208: Call_ConnectCustomKeyStore_607196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation. Also, the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU) must not be logged into the cluster. This prevents AWS KMS from using this account to log in.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <code>kmsuser</code> CU, and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607208.validator(path, query, header, formData, body)
  let scheme = call_607208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607208.url(scheme.get, call_607208.host, call_607208.base,
                         call_607208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607208, url, valid)

proc call*(call_607209: Call_ConnectCustomKeyStore_607196; body: JsonNode): Recallable =
  ## connectCustomKeyStore
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation. Also, the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU) must not be logged into the cluster. This prevents AWS KMS from using this account to log in.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <code>kmsuser</code> CU, and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607210 = newJObject()
  if body != nil:
    body_607210 = body
  result = call_607209.call(nil, nil, nil, nil, body_607210)

var connectCustomKeyStore* = Call_ConnectCustomKeyStore_607196(
    name: "connectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ConnectCustomKeyStore",
    validator: validate_ConnectCustomKeyStore_607197, base: "/",
    url: url_ConnectCustomKeyStore_607198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_607211 = ref object of OpenApiRestCall_606589
proc url_CreateAlias_607213(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlias_607212(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607214 = header.getOrDefault("X-Amz-Target")
  valid_607214 = validateParameter(valid_607214, JString, required = true, default = newJString(
      "TrentService.CreateAlias"))
  if valid_607214 != nil:
    section.add "X-Amz-Target", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Signature")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Signature", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Content-Sha256", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Date")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Date", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Credential")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Credential", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Security-Token")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Security-Token", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Algorithm")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Algorithm", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-SignedHeaders", valid_607221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607223: Call_CreateAlias_607211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in cryptographic operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. You can change the CMK associated with the alias at any time.</p> <p>Aliases are easier to remember than key IDs. They can also help to simplify your applications. For example, if you use an alias in your code, you can change the CMK your code uses by associating a given alias with a different CMK. </p> <p>To run the same code in multiple AWS regions, use an alias in your code, such as <code>alias/ApplicationKey</code>. Then, in each AWS Region, create an <code>alias/ApplicationKey</code> alias that is associated with a CMK in that Region. When you run your code, it uses the <code>alias/ApplicationKey</code> CMK for that AWS Region without any Region-specific code.</p> <p>This operation does not return a response. To get the alias that you created, use the <a>ListAliases</a> operation.</p> <p>To use aliases successfully, be aware of the following information.</p> <ul> <li> <p>Each alias points to only one CMK at a time, although a single CMK can have multiple aliases. The alias and its associated CMK must be in the same AWS account and Region. </p> </li> <li> <p>You can associate an alias with any customer managed CMK in the same AWS account and Region. However, you do not have permission to associate an alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk">AWS owned CMK</a>. </p> </li> <li> <p>To change the CMK associated with an alias, use the <a>UpdateAlias</a> operation. The current CMK and the new CMK must be the same type (both symmetric or both asymmetric) and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents cryptographic errors in code that uses aliases.</p> </li> <li> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> </li> <li> <p>The alias name must be unique within an AWS Region. However, you can use the same alias name in multiple Regions of the same AWS account. Each instance of the alias is associated with a CMK in its Region.</p> </li> <li> <p>After you create an alias, you cannot change its alias name. However, you can use the <a>DeleteAlias</a> operation to delete the alias and then create a new alias with the desired name.</p> </li> <li> <p>You can use an alias name or alias ARN to identify a CMK in AWS KMS cryptographic operations and in the <a>DescribeKey</a> operation. However, you cannot use alias names or alias ARNs in API operations that manage CMKs, such as <a>DisableKey</a> or <a>GetKeyPolicy</a>. For information about the valid CMK identifiers for each AWS KMS API operation, see the descriptions of the <code>KeyId</code> parameter in the API operation documentation.</p> </li> </ul> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases and alias ARNs of CMKs in each AWS account and Region, use the <a>ListAliases</a> operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607223.validator(path, query, header, formData, body)
  let scheme = call_607223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607223.url(scheme.get, call_607223.host, call_607223.base,
                         call_607223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607223, url, valid)

proc call*(call_607224: Call_CreateAlias_607211; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in cryptographic operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. You can change the CMK associated with the alias at any time.</p> <p>Aliases are easier to remember than key IDs. They can also help to simplify your applications. For example, if you use an alias in your code, you can change the CMK your code uses by associating a given alias with a different CMK. </p> <p>To run the same code in multiple AWS regions, use an alias in your code, such as <code>alias/ApplicationKey</code>. Then, in each AWS Region, create an <code>alias/ApplicationKey</code> alias that is associated with a CMK in that Region. When you run your code, it uses the <code>alias/ApplicationKey</code> CMK for that AWS Region without any Region-specific code.</p> <p>This operation does not return a response. To get the alias that you created, use the <a>ListAliases</a> operation.</p> <p>To use aliases successfully, be aware of the following information.</p> <ul> <li> <p>Each alias points to only one CMK at a time, although a single CMK can have multiple aliases. The alias and its associated CMK must be in the same AWS account and Region. </p> </li> <li> <p>You can associate an alias with any customer managed CMK in the same AWS account and Region. However, you do not have permission to associate an alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-cmk">AWS owned CMK</a>. </p> </li> <li> <p>To change the CMK associated with an alias, use the <a>UpdateAlias</a> operation. The current CMK and the new CMK must be the same type (both symmetric or both asymmetric) and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents cryptographic errors in code that uses aliases.</p> </li> <li> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> </li> <li> <p>The alias name must be unique within an AWS Region. However, you can use the same alias name in multiple Regions of the same AWS account. Each instance of the alias is associated with a CMK in its Region.</p> </li> <li> <p>After you create an alias, you cannot change its alias name. However, you can use the <a>DeleteAlias</a> operation to delete the alias and then create a new alias with the desired name.</p> </li> <li> <p>You can use an alias name or alias ARN to identify a CMK in AWS KMS cryptographic operations and in the <a>DescribeKey</a> operation. However, you cannot use alias names or alias ARNs in API operations that manage CMKs, such as <a>DisableKey</a> or <a>GetKeyPolicy</a>. For information about the valid CMK identifiers for each AWS KMS API operation, see the descriptions of the <code>KeyId</code> parameter in the API operation documentation.</p> </li> </ul> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases and alias ARNs of CMKs in each AWS account and Region, use the <a>ListAliases</a> operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607225 = newJObject()
  if body != nil:
    body_607225 = body
  result = call_607224.call(nil, nil, nil, nil, body_607225)

var createAlias* = Call_CreateAlias_607211(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateAlias",
                                        validator: validate_CreateAlias_607212,
                                        base: "/", url: url_CreateAlias_607213,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomKeyStore_607226 = ref object of OpenApiRestCall_606589
proc url_CreateCustomKeyStore_607228(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCustomKeyStore_607227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607229 = header.getOrDefault("X-Amz-Target")
  valid_607229 = validateParameter(valid_607229, JString, required = true, default = newJString(
      "TrentService.CreateCustomKeyStore"))
  if valid_607229 != nil:
    section.add "X-Amz-Target", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Signature")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Signature", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Content-Sha256", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Date")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Date", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Credential")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Credential", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Security-Token")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Security-Token", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Algorithm")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Algorithm", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-SignedHeaders", valid_607236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607238: Call_CreateCustomKeyStore_607226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607238.validator(path, query, header, formData, body)
  let scheme = call_607238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607238.url(scheme.get, call_607238.host, call_607238.base,
                         call_607238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607238, url, valid)

proc call*(call_607239: Call_CreateCustomKeyStore_607226; body: JsonNode): Recallable =
  ## createCustomKeyStore
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607240 = newJObject()
  if body != nil:
    body_607240 = body
  result = call_607239.call(nil, nil, nil, nil, body_607240)

var createCustomKeyStore* = Call_CreateCustomKeyStore_607226(
    name: "createCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CreateCustomKeyStore",
    validator: validate_CreateCustomKeyStore_607227, base: "/",
    url: url_CreateCustomKeyStore_607228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGrant_607241 = ref object of OpenApiRestCall_606589
proc url_CreateGrant_607243(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGrant_607242(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607244 = header.getOrDefault("X-Amz-Target")
  valid_607244 = validateParameter(valid_607244, JString, required = true, default = newJString(
      "TrentService.CreateGrant"))
  if valid_607244 != nil:
    section.add "X-Amz-Target", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Signature")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Signature", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Content-Sha256", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Date")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Date", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Credential")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Credential", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Security-Token")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Security-Token", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Algorithm")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Algorithm", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-SignedHeaders", valid_607251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607253: Call_CreateGrant_607241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the request includes a particular <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">encryption context</a>, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>You can create grants on symmetric and asymmetric CMKs. However, if the grant allows an operation that the CMK does not support, <code>CreateGrant</code> fails with a <code>ValidationException</code>. </p> <ul> <li> <p>Grants for symmetric CMKs cannot allow operations that are not supported for symmetric CMKs, including <a>Sign</a>, <a>Verify</a>, and <a>GetPublicKey</a>. (There are limited exceptions to this rule for legacy operations, but you should not create a grant for an operation that AWS KMS does not support.)</p> </li> <li> <p>Grants for asymmetric CMKs cannot allow operations that are not supported for asymmetric CMKs, including operations that <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKey">generate data keys</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKeyPair">data key pairs</a>, or operations related to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic key rotation</a>, <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">imported key material</a>, or CMKs in <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a>.</p> </li> <li> <p>Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>ENCRYPT_DECRYPT</code> cannot allow the <a>Sign</a> or <a>Verify</a> operations. Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>SIGN_VERIFY</code> cannot allow the <a>Encrypt</a> or <a>Decrypt</a> operations.</p> </li> <li> <p>Grants for asymmetric CMKs cannot include an encryption context grant constraint. An encryption context is not supported on asymmetric CMKs.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607253.validator(path, query, header, formData, body)
  let scheme = call_607253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607253.url(scheme.get, call_607253.host, call_607253.base,
                         call_607253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607253, url, valid)

proc call*(call_607254: Call_CreateGrant_607241; body: JsonNode): Recallable =
  ## createGrant
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the request includes a particular <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">encryption context</a>, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>You can create grants on symmetric and asymmetric CMKs. However, if the grant allows an operation that the CMK does not support, <code>CreateGrant</code> fails with a <code>ValidationException</code>. </p> <ul> <li> <p>Grants for symmetric CMKs cannot allow operations that are not supported for symmetric CMKs, including <a>Sign</a>, <a>Verify</a>, and <a>GetPublicKey</a>. (There are limited exceptions to this rule for legacy operations, but you should not create a grant for an operation that AWS KMS does not support.)</p> </li> <li> <p>Grants for asymmetric CMKs cannot allow operations that are not supported for asymmetric CMKs, including operations that <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKey">generate data keys</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GenerateDataKeyPair">data key pairs</a>, or operations related to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic key rotation</a>, <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">imported key material</a>, or CMKs in <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a>.</p> </li> <li> <p>Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>ENCRYPT_DECRYPT</code> cannot allow the <a>Sign</a> or <a>Verify</a> operations. Grants for asymmetric CMKs with a <code>KeyUsage</code> of <code>SIGN_VERIFY</code> cannot allow the <a>Encrypt</a> or <a>Decrypt</a> operations.</p> </li> <li> <p>Grants for asymmetric CMKs cannot include an encryption context grant constraint. An encryption context is not supported on asymmetric CMKs.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607255 = newJObject()
  if body != nil:
    body_607255 = body
  result = call_607254.call(nil, nil, nil, nil, body_607255)

var createGrant* = Call_CreateGrant_607241(name: "createGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateGrant",
                                        validator: validate_CreateGrant_607242,
                                        base: "/", url: url_CreateGrant_607243,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKey_607256 = ref object of OpenApiRestCall_606589
proc url_CreateKey_607258(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateKey_607257(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607259 = header.getOrDefault("X-Amz-Target")
  valid_607259 = validateParameter(valid_607259, JString, required = true,
                                 default = newJString("TrentService.CreateKey"))
  if valid_607259 != nil:
    section.add "X-Amz-Target", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Signature")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Signature", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Content-Sha256", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Date")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Date", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Credential")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Credential", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Security-Token")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Security-Token", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Algorithm")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Algorithm", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-SignedHeaders", valid_607266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607268: Call_CreateKey_607256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a unique customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master-keys">customer master key</a> (CMK) in your AWS account and Region. You cannot use this operation to create a CMK in a different AWS account.</p> <p>You can use the <code>CreateKey</code> operation to create symmetric or asymmetric CMKs.</p> <ul> <li> <p> <b>Symmetric CMKs</b> contain a 256-bit symmetric key that never leaves AWS KMS unencrypted. To use the CMK, you must call AWS KMS. You can use a symmetric CMK to encrypt and decrypt small amounts of data, but they are typically used to generate <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> and <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-key-pairs">data keys pairs</a>. For details, see <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a>.</p> </li> <li> <p> <b>Asymmetric CMKs</b> can contain an RSA key pair or an Elliptic Curve (ECC) key pair. The private key in an asymmetric CMK never leaves AWS KMS unencrypted. However, you can use the <a>GetPublicKey</a> operation to download the public key so it can be used outside of AWS KMS. CMKs with RSA key pairs can be used to encrypt or decrypt data or sign and verify messages (but not both). CMKs with ECC key pairs can be used only to sign and verify messages.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To create different types of CMKs, use the following guidance:</p> <dl> <dt>Asymmetric CMKs</dt> <dd> <p>To create an asymmetric CMK, use the <code>CustomerMasterKeySpec</code> parameter to specify the type of key material in the CMK. Then, use the <code>KeyUsage</code> parameter to determine whether the CMK will be used to encrypt and decrypt or sign and verify. You can't change these properties after the CMK is created.</p> <p> </p> </dd> <dt>Symmetric CMKs</dt> <dd> <p>When creating a symmetric CMK, you don't need to specify the <code>CustomerMasterKeySpec</code> or <code>KeyUsage</code> parameters. The default value for <code>CustomerMasterKeySpec</code>, <code>SYMMETRIC_DEFAULT</code>, and the default value for <code>KeyUsage</code>, <code>ENCRYPT_DECRYPT</code>, are the only valid values for symmetric CMKs. </p> <p> </p> </dd> <dt>Imported Key Material</dt> <dd> <p>To import your own key material, begin by creating a symmetric CMK with no key material. To do this, use the <code>Origin</code> parameter of <code>CreateKey</code> with a value of <code>EXTERNAL</code>. Next, use <a>GetParametersForImport</a> operation to get a public key and import token, and use the public key to encrypt your key material. Then, use <a>ImportKeyMaterial</a> with your import token to import the key material. For step-by-step instructions, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>. You cannot import the key material into an asymmetric CMK.</p> <p> </p> </dd> <dt>Custom Key Stores</dt> <dd> <p>To create a symmetric CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region. </p> <p>You cannot create an asymmetric CMK in a custom key store. For information about custom key stores in AWS KMS see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Using Custom Key Stores</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> </dd> </dl>
  ## 
  let valid = call_607268.validator(path, query, header, formData, body)
  let scheme = call_607268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607268.url(scheme.get, call_607268.host, call_607268.base,
                         call_607268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607268, url, valid)

proc call*(call_607269: Call_CreateKey_607256; body: JsonNode): Recallable =
  ## createKey
  ## <p>Creates a unique customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master-keys">customer master key</a> (CMK) in your AWS account and Region. You cannot use this operation to create a CMK in a different AWS account.</p> <p>You can use the <code>CreateKey</code> operation to create symmetric or asymmetric CMKs.</p> <ul> <li> <p> <b>Symmetric CMKs</b> contain a 256-bit symmetric key that never leaves AWS KMS unencrypted. To use the CMK, you must call AWS KMS. You can use a symmetric CMK to encrypt and decrypt small amounts of data, but they are typically used to generate <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> and <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-key-pairs">data keys pairs</a>. For details, see <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a>.</p> </li> <li> <p> <b>Asymmetric CMKs</b> can contain an RSA key pair or an Elliptic Curve (ECC) key pair. The private key in an asymmetric CMK never leaves AWS KMS unencrypted. However, you can use the <a>GetPublicKey</a> operation to download the public key so it can be used outside of AWS KMS. CMKs with RSA key pairs can be used to encrypt or decrypt data or sign and verify messages (but not both). CMKs with ECC key pairs can be used only to sign and verify messages.</p> </li> </ul> <p>For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To create different types of CMKs, use the following guidance:</p> <dl> <dt>Asymmetric CMKs</dt> <dd> <p>To create an asymmetric CMK, use the <code>CustomerMasterKeySpec</code> parameter to specify the type of key material in the CMK. Then, use the <code>KeyUsage</code> parameter to determine whether the CMK will be used to encrypt and decrypt or sign and verify. You can't change these properties after the CMK is created.</p> <p> </p> </dd> <dt>Symmetric CMKs</dt> <dd> <p>When creating a symmetric CMK, you don't need to specify the <code>CustomerMasterKeySpec</code> or <code>KeyUsage</code> parameters. The default value for <code>CustomerMasterKeySpec</code>, <code>SYMMETRIC_DEFAULT</code>, and the default value for <code>KeyUsage</code>, <code>ENCRYPT_DECRYPT</code>, are the only valid values for symmetric CMKs. </p> <p> </p> </dd> <dt>Imported Key Material</dt> <dd> <p>To import your own key material, begin by creating a symmetric CMK with no key material. To do this, use the <code>Origin</code> parameter of <code>CreateKey</code> with a value of <code>EXTERNAL</code>. Next, use <a>GetParametersForImport</a> operation to get a public key and import token, and use the public key to encrypt your key material. Then, use <a>ImportKeyMaterial</a> with your import token to import the key material. For step-by-step instructions, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>. You cannot import the key material into an asymmetric CMK.</p> <p> </p> </dd> <dt>Custom Key Stores</dt> <dd> <p>To create a symmetric CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region. </p> <p>You cannot create an asymmetric CMK in a custom key store. For information about custom key stores in AWS KMS see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Using Custom Key Stores</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> </dd> </dl>
  ##   body: JObject (required)
  var body_607270 = newJObject()
  if body != nil:
    body_607270 = body
  result = call_607269.call(nil, nil, nil, nil, body_607270)

var createKey* = Call_CreateKey_607256(name: "createKey", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateKey",
                                    validator: validate_CreateKey_607257,
                                    base: "/", url: url_CreateKey_607258,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Decrypt_607271 = ref object of OpenApiRestCall_606589
proc url_Decrypt_607273(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Decrypt_607272(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607274 = header.getOrDefault("X-Amz-Target")
  valid_607274 = validateParameter(valid_607274, JString, required = true,
                                 default = newJString("TrentService.Decrypt"))
  if valid_607274 != nil:
    section.add "X-Amz-Target", valid_607274
  var valid_607275 = header.getOrDefault("X-Amz-Signature")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Signature", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Content-Sha256", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Date")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Date", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Credential")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Credential", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Security-Token")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Security-Token", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Algorithm")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Algorithm", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-SignedHeaders", valid_607281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607283: Call_Decrypt_607271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decrypts ciphertext that was encrypted by a AWS KMS customer master key (CMK) using any of the following operations:</p> <ul> <li> <p> <a>Encrypt</a> </p> </li> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyPair</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>GenerateDataKeyPairWithoutPlaintext</a> </p> </li> </ul> <p>You can use this operation to decrypt ciphertext that was encrypted under a symmetric or asymmetric CMK. When the CMK is asymmetric, you must specify the CMK and the encryption algorithm that was used to encrypt the ciphertext. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The Decrypt operation also decrypts ciphertext that was encrypted outside of AWS KMS by the public key in an AWS KMS asymmetric CMK. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>If the ciphertext was encrypted under a symmetric CMK, you do not need to specify the CMK or the encryption algorithm. AWS KMS can get this information from metadata that it adds to the symmetric ciphertext blob. However, if you prefer, you can specify the <code>KeyId</code> to ensure that a particular CMK is used to decrypt the ciphertext. If you specify a different CMK than the one used to encrypt the ciphertext, the <code>Decrypt</code> operation fails.</p> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on a particular CMK, instead of using IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607283.validator(path, query, header, formData, body)
  let scheme = call_607283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607283.url(scheme.get, call_607283.host, call_607283.base,
                         call_607283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607283, url, valid)

proc call*(call_607284: Call_Decrypt_607271; body: JsonNode): Recallable =
  ## decrypt
  ## <p>Decrypts ciphertext that was encrypted by a AWS KMS customer master key (CMK) using any of the following operations:</p> <ul> <li> <p> <a>Encrypt</a> </p> </li> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyPair</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>GenerateDataKeyPairWithoutPlaintext</a> </p> </li> </ul> <p>You can use this operation to decrypt ciphertext that was encrypted under a symmetric or asymmetric CMK. When the CMK is asymmetric, you must specify the CMK and the encryption algorithm that was used to encrypt the ciphertext. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The Decrypt operation also decrypts ciphertext that was encrypted outside of AWS KMS by the public key in an AWS KMS asymmetric CMK. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>If the ciphertext was encrypted under a symmetric CMK, you do not need to specify the CMK or the encryption algorithm. AWS KMS can get this information from metadata that it adds to the symmetric ciphertext blob. However, if you prefer, you can specify the <code>KeyId</code> to ensure that a particular CMK is used to decrypt the ciphertext. If you specify a different CMK than the one used to encrypt the ciphertext, the <code>Decrypt</code> operation fails.</p> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on a particular CMK, instead of using IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607285 = newJObject()
  if body != nil:
    body_607285 = body
  result = call_607284.call(nil, nil, nil, nil, body_607285)

var decrypt* = Call_Decrypt_607271(name: "decrypt", meth: HttpMethod.HttpPost,
                                host: "kms.amazonaws.com",
                                route: "/#X-Amz-Target=TrentService.Decrypt",
                                validator: validate_Decrypt_607272, base: "/",
                                url: url_Decrypt_607273,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_607286 = ref object of OpenApiRestCall_606589
proc url_DeleteAlias_607288(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAlias_607287(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607289 = header.getOrDefault("X-Amz-Target")
  valid_607289 = validateParameter(valid_607289, JString, required = true, default = newJString(
      "TrentService.DeleteAlias"))
  if valid_607289 != nil:
    section.add "X-Amz-Target", valid_607289
  var valid_607290 = header.getOrDefault("X-Amz-Signature")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Signature", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Content-Sha256", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Date")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Date", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Credential")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Credential", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Security-Token")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Security-Token", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Algorithm")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Algorithm", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-SignedHeaders", valid_607296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607298: Call_DeleteAlias_607286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
  ## 
  let valid = call_607298.validator(path, query, header, formData, body)
  let scheme = call_607298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607298.url(scheme.get, call_607298.host, call_607298.base,
                         call_607298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607298, url, valid)

proc call*(call_607299: Call_DeleteAlias_607286; body: JsonNode): Recallable =
  ## deleteAlias
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
  ##   body: JObject (required)
  var body_607300 = newJObject()
  if body != nil:
    body_607300 = body
  result = call_607299.call(nil, nil, nil, nil, body_607300)

var deleteAlias* = Call_DeleteAlias_607286(name: "deleteAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DeleteAlias",
                                        validator: validate_DeleteAlias_607287,
                                        base: "/", url: url_DeleteAlias_607288,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomKeyStore_607301 = ref object of OpenApiRestCall_606589
proc url_DeleteCustomKeyStore_607303(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCustomKeyStore_607302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607304 = header.getOrDefault("X-Amz-Target")
  valid_607304 = validateParameter(valid_607304, JString, required = true, default = newJString(
      "TrentService.DeleteCustomKeyStore"))
  if valid_607304 != nil:
    section.add "X-Amz-Target", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Signature")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Signature", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Content-Sha256", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Date")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Date", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Credential")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Credential", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Security-Token")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Security-Token", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Algorithm")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Algorithm", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-SignedHeaders", valid_607311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607313: Call_DeleteCustomKeyStore_607301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_607313.validator(path, query, header, formData, body)
  let scheme = call_607313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607313.url(scheme.get, call_607313.host, call_607313.base,
                         call_607313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607313, url, valid)

proc call*(call_607314: Call_DeleteCustomKeyStore_607301; body: JsonNode): Recallable =
  ## deleteCustomKeyStore
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_607315 = newJObject()
  if body != nil:
    body_607315 = body
  result = call_607314.call(nil, nil, nil, nil, body_607315)

var deleteCustomKeyStore* = Call_DeleteCustomKeyStore_607301(
    name: "deleteCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteCustomKeyStore",
    validator: validate_DeleteCustomKeyStore_607302, base: "/",
    url: url_DeleteCustomKeyStore_607303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImportedKeyMaterial_607316 = ref object of OpenApiRestCall_606589
proc url_DeleteImportedKeyMaterial_607318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImportedKeyMaterial_607317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607319 = header.getOrDefault("X-Amz-Target")
  valid_607319 = validateParameter(valid_607319, JString, required = true, default = newJString(
      "TrentService.DeleteImportedKeyMaterial"))
  if valid_607319 != nil:
    section.add "X-Amz-Target", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Signature")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Signature", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Content-Sha256", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Date")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Date", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Credential")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Credential", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Security-Token")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Security-Token", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Algorithm")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Algorithm", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-SignedHeaders", valid_607326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_DeleteImportedKeyMaterial_607316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_DeleteImportedKeyMaterial_607316; body: JsonNode): Recallable =
  ## deleteImportedKeyMaterial
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607330 = newJObject()
  if body != nil:
    body_607330 = body
  result = call_607329.call(nil, nil, nil, nil, body_607330)

var deleteImportedKeyMaterial* = Call_DeleteImportedKeyMaterial_607316(
    name: "deleteImportedKeyMaterial", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteImportedKeyMaterial",
    validator: validate_DeleteImportedKeyMaterial_607317, base: "/",
    url: url_DeleteImportedKeyMaterial_607318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCustomKeyStores_607331 = ref object of OpenApiRestCall_606589
proc url_DescribeCustomKeyStores_607333(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_DescribeCustomKeyStores_607332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607334 = header.getOrDefault("X-Amz-Target")
  valid_607334 = validateParameter(valid_607334, JString, required = true, default = newJString(
      "TrentService.DescribeCustomKeyStores"))
  if valid_607334 != nil:
    section.add "X-Amz-Target", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Signature")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Signature", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Content-Sha256", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Date")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Date", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Credential")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Credential", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Security-Token")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Security-Token", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Algorithm")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Algorithm", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-SignedHeaders", valid_607341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607343: Call_DescribeCustomKeyStores_607331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607343.validator(path, query, header, formData, body)
  let scheme = call_607343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607343.url(scheme.get, call_607343.host, call_607343.base,
                         call_607343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607343, url, valid)

proc call*(call_607344: Call_DescribeCustomKeyStores_607331; body: JsonNode): Recallable =
  ## describeCustomKeyStores
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607345 = newJObject()
  if body != nil:
    body_607345 = body
  result = call_607344.call(nil, nil, nil, nil, body_607345)

var describeCustomKeyStores* = Call_DescribeCustomKeyStores_607331(
    name: "describeCustomKeyStores", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DescribeCustomKeyStores",
    validator: validate_DescribeCustomKeyStores_607332, base: "/",
    url: url_DescribeCustomKeyStores_607333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKey_607346 = ref object of OpenApiRestCall_606589
proc url_DescribeKey_607348(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeKey_607347(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607349 = header.getOrDefault("X-Amz-Target")
  valid_607349 = validateParameter(valid_607349, JString, required = true, default = newJString(
      "TrentService.DescribeKey"))
  if valid_607349 != nil:
    section.add "X-Amz-Target", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Signature")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Signature", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Content-Sha256", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Date")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Date", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Credential")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Credential", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Security-Token")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Security-Token", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Algorithm")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Algorithm", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-SignedHeaders", valid_607356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607358: Call_DescribeKey_607346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides detailed information about a customer master key (CMK). You can run <code>DescribeKey</code> on a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk">customer managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a>.</p> <p>This detailed information includes the key ARN, creation date (and deletion date, if applicable), the key state, and the origin and expiration date (if any) of the key material. For CMKs in custom key stores, it includes information about the custom key store, such as the key store ID and the AWS CloudHSM cluster ID. It includes fields, like <code>KeySpec</code>, that help you distinguish symmetric from asymmetric CMKs. It also provides information that is particularly important to asymmetric CMKs, such as the key usage (encryption or signing) and the encryption algorithms or signing algorithms that the CMK supports.</p> <p> <code>DescribeKey</code> does not return the following information:</p> <ul> <li> <p>Aliases associated with the CMK. To get this information, use <a>ListAliases</a>.</p> </li> <li> <p>Whether automatic key rotation is enabled on the CMK. To get this information, use <a>GetKeyRotationStatus</a>. Also, some key states prevent a CMK from being automatically rotated. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works">How Automatic Key Rotation Works</a> in <i>AWS Key Management Service Developer Guide</i>.</p> </li> <li> <p>Tags on the CMK. To get this information, use <a>ListResourceTags</a>.</p> </li> <li> <p>Key policies and grants on the CMK. To get this information, use <a>GetKeyPolicy</a> and <a>ListGrants</a>.</p> </li> </ul> <p>If you call the <code>DescribeKey</code> operation on a <i>predefined AWS alias</i>, that is, an AWS alias with no key ID, AWS KMS creates an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a>. Then, it associates the alias with the new CMK, and returns the <code>KeyId</code> and <code>Arn</code> of the new CMK in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ## 
  let valid = call_607358.validator(path, query, header, formData, body)
  let scheme = call_607358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607358.url(scheme.get, call_607358.host, call_607358.base,
                         call_607358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607358, url, valid)

proc call*(call_607359: Call_DescribeKey_607346; body: JsonNode): Recallable =
  ## describeKey
  ## <p>Provides detailed information about a customer master key (CMK). You can run <code>DescribeKey</code> on a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk">customer managed CMK</a> or an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMK</a>.</p> <p>This detailed information includes the key ARN, creation date (and deletion date, if applicable), the key state, and the origin and expiration date (if any) of the key material. For CMKs in custom key stores, it includes information about the custom key store, such as the key store ID and the AWS CloudHSM cluster ID. It includes fields, like <code>KeySpec</code>, that help you distinguish symmetric from asymmetric CMKs. It also provides information that is particularly important to asymmetric CMKs, such as the key usage (encryption or signing) and the encryption algorithms or signing algorithms that the CMK supports.</p> <p> <code>DescribeKey</code> does not return the following information:</p> <ul> <li> <p>Aliases associated with the CMK. To get this information, use <a>ListAliases</a>.</p> </li> <li> <p>Whether automatic key rotation is enabled on the CMK. To get this information, use <a>GetKeyRotationStatus</a>. Also, some key states prevent a CMK from being automatically rotated. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works">How Automatic Key Rotation Works</a> in <i>AWS Key Management Service Developer Guide</i>.</p> </li> <li> <p>Tags on the CMK. To get this information, use <a>ListResourceTags</a>.</p> </li> <li> <p>Key policies and grants on the CMK. To get this information, use <a>GetKeyPolicy</a> and <a>ListGrants</a>.</p> </li> </ul> <p>If you call the <code>DescribeKey</code> operation on a <i>predefined AWS alias</i>, that is, an AWS alias with no key ID, AWS KMS creates an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a>. Then, it associates the alias with the new CMK, and returns the <code>KeyId</code> and <code>Arn</code> of the new CMK in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   body: JObject (required)
  var body_607360 = newJObject()
  if body != nil:
    body_607360 = body
  result = call_607359.call(nil, nil, nil, nil, body_607360)

var describeKey* = Call_DescribeKey_607346(name: "describeKey",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DescribeKey",
                                        validator: validate_DescribeKey_607347,
                                        base: "/", url: url_DescribeKey_607348,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKey_607361 = ref object of OpenApiRestCall_606589
proc url_DisableKey_607363(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableKey_607362(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607364 = header.getOrDefault("X-Amz-Target")
  valid_607364 = validateParameter(valid_607364, JString, required = true, default = newJString(
      "TrentService.DisableKey"))
  if valid_607364 != nil:
    section.add "X-Amz-Target", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Signature")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Signature", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Content-Sha256", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Date")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Date", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Credential")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Credential", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Security-Token")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Security-Token", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Algorithm")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Algorithm", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-SignedHeaders", valid_607371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607373: Call_DisableKey_607361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607373.validator(path, query, header, formData, body)
  let scheme = call_607373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607373.url(scheme.get, call_607373.host, call_607373.base,
                         call_607373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607373, url, valid)

proc call*(call_607374: Call_DisableKey_607361; body: JsonNode): Recallable =
  ## disableKey
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607375 = newJObject()
  if body != nil:
    body_607375 = body
  result = call_607374.call(nil, nil, nil, nil, body_607375)

var disableKey* = Call_DisableKey_607361(name: "disableKey",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DisableKey",
                                      validator: validate_DisableKey_607362,
                                      base: "/", url: url_DisableKey_607363,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKeyRotation_607376 = ref object of OpenApiRestCall_606589
proc url_DisableKeyRotation_607378(protocol: Scheme; host: string; base: string;
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

proc validate_DisableKeyRotation_607377(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607379 = header.getOrDefault("X-Amz-Target")
  valid_607379 = validateParameter(valid_607379, JString, required = true, default = newJString(
      "TrentService.DisableKeyRotation"))
  if valid_607379 != nil:
    section.add "X-Amz-Target", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-Signature")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Signature", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Content-Sha256", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Date")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Date", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Credential")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Credential", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Security-Token")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Security-Token", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Algorithm")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Algorithm", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-SignedHeaders", valid_607386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607388: Call_DisableKeyRotation_607376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK).</p> <p> You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607388.validator(path, query, header, formData, body)
  let scheme = call_607388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607388.url(scheme.get, call_607388.host, call_607388.base,
                         call_607388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607388, url, valid)

proc call*(call_607389: Call_DisableKeyRotation_607376; body: JsonNode): Recallable =
  ## disableKeyRotation
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK).</p> <p> You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607390 = newJObject()
  if body != nil:
    body_607390 = body
  result = call_607389.call(nil, nil, nil, nil, body_607390)

var disableKeyRotation* = Call_DisableKeyRotation_607376(
    name: "disableKeyRotation", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisableKeyRotation",
    validator: validate_DisableKeyRotation_607377, base: "/",
    url: url_DisableKeyRotation_607378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectCustomKeyStore_607391 = ref object of OpenApiRestCall_606589
proc url_DisconnectCustomKeyStore_607393(protocol: Scheme; host: string;
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

proc validate_DisconnectCustomKeyStore_607392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607394 = header.getOrDefault("X-Amz-Target")
  valid_607394 = validateParameter(valid_607394, JString, required = true, default = newJString(
      "TrentService.DisconnectCustomKeyStore"))
  if valid_607394 != nil:
    section.add "X-Amz-Target", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-Signature")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-Signature", valid_607395
  var valid_607396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607396 = validateParameter(valid_607396, JString, required = false,
                                 default = nil)
  if valid_607396 != nil:
    section.add "X-Amz-Content-Sha256", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Date")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Date", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Credential")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Credential", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Security-Token")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Security-Token", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Algorithm")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Algorithm", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-SignedHeaders", valid_607401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607403: Call_DisconnectCustomKeyStore_607391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_607403.validator(path, query, header, formData, body)
  let scheme = call_607403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607403.url(scheme.get, call_607403.host, call_607403.base,
                         call_607403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607403, url, valid)

proc call*(call_607404: Call_DisconnectCustomKeyStore_607391; body: JsonNode): Recallable =
  ## disconnectCustomKeyStore
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_607405 = newJObject()
  if body != nil:
    body_607405 = body
  result = call_607404.call(nil, nil, nil, nil, body_607405)

var disconnectCustomKeyStore* = Call_DisconnectCustomKeyStore_607391(
    name: "disconnectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisconnectCustomKeyStore",
    validator: validate_DisconnectCustomKeyStore_607392, base: "/",
    url: url_DisconnectCustomKeyStore_607393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKey_607406 = ref object of OpenApiRestCall_606589
proc url_EnableKey_607408(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableKey_607407(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607409 = header.getOrDefault("X-Amz-Target")
  valid_607409 = validateParameter(valid_607409, JString, required = true,
                                 default = newJString("TrentService.EnableKey"))
  if valid_607409 != nil:
    section.add "X-Amz-Target", valid_607409
  var valid_607410 = header.getOrDefault("X-Amz-Signature")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "X-Amz-Signature", valid_607410
  var valid_607411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607411 = validateParameter(valid_607411, JString, required = false,
                                 default = nil)
  if valid_607411 != nil:
    section.add "X-Amz-Content-Sha256", valid_607411
  var valid_607412 = header.getOrDefault("X-Amz-Date")
  valid_607412 = validateParameter(valid_607412, JString, required = false,
                                 default = nil)
  if valid_607412 != nil:
    section.add "X-Amz-Date", valid_607412
  var valid_607413 = header.getOrDefault("X-Amz-Credential")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "X-Amz-Credential", valid_607413
  var valid_607414 = header.getOrDefault("X-Amz-Security-Token")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "X-Amz-Security-Token", valid_607414
  var valid_607415 = header.getOrDefault("X-Amz-Algorithm")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "X-Amz-Algorithm", valid_607415
  var valid_607416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-SignedHeaders", valid_607416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607418: Call_EnableKey_607406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607418.validator(path, query, header, formData, body)
  let scheme = call_607418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607418.url(scheme.get, call_607418.host, call_607418.base,
                         call_607418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607418, url, valid)

proc call*(call_607419: Call_EnableKey_607406; body: JsonNode): Recallable =
  ## enableKey
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607420 = newJObject()
  if body != nil:
    body_607420 = body
  result = call_607419.call(nil, nil, nil, nil, body_607420)

var enableKey* = Call_EnableKey_607406(name: "enableKey", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.EnableKey",
                                    validator: validate_EnableKey_607407,
                                    base: "/", url: url_EnableKey_607408,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKeyRotation_607421 = ref object of OpenApiRestCall_606589
proc url_EnableKeyRotation_607423(protocol: Scheme; host: string; base: string;
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

proc validate_EnableKeyRotation_607422(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607424 = header.getOrDefault("X-Amz-Target")
  valid_607424 = validateParameter(valid_607424, JString, required = true, default = newJString(
      "TrentService.EnableKeyRotation"))
  if valid_607424 != nil:
    section.add "X-Amz-Target", valid_607424
  var valid_607425 = header.getOrDefault("X-Amz-Signature")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Signature", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-Content-Sha256", valid_607426
  var valid_607427 = header.getOrDefault("X-Amz-Date")
  valid_607427 = validateParameter(valid_607427, JString, required = false,
                                 default = nil)
  if valid_607427 != nil:
    section.add "X-Amz-Date", valid_607427
  var valid_607428 = header.getOrDefault("X-Amz-Credential")
  valid_607428 = validateParameter(valid_607428, JString, required = false,
                                 default = nil)
  if valid_607428 != nil:
    section.add "X-Amz-Credential", valid_607428
  var valid_607429 = header.getOrDefault("X-Amz-Security-Token")
  valid_607429 = validateParameter(valid_607429, JString, required = false,
                                 default = nil)
  if valid_607429 != nil:
    section.add "X-Amz-Security-Token", valid_607429
  var valid_607430 = header.getOrDefault("X-Amz-Algorithm")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Algorithm", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-SignedHeaders", valid_607431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607433: Call_EnableKeyRotation_607421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607433.validator(path, query, header, formData, body)
  let scheme = call_607433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607433.url(scheme.get, call_607433.host, call_607433.base,
                         call_607433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607433, url, valid)

proc call*(call_607434: Call_EnableKeyRotation_607421; body: JsonNode): Recallable =
  ## enableKeyRotation
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified symmetric customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607435 = newJObject()
  if body != nil:
    body_607435 = body
  result = call_607434.call(nil, nil, nil, nil, body_607435)

var enableKeyRotation* = Call_EnableKeyRotation_607421(name: "enableKeyRotation",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.EnableKeyRotation",
    validator: validate_EnableKeyRotation_607422, base: "/",
    url: url_EnableKeyRotation_607423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Encrypt_607436 = ref object of OpenApiRestCall_606589
proc url_Encrypt_607438(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Encrypt_607437(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607439 = header.getOrDefault("X-Amz-Target")
  valid_607439 = validateParameter(valid_607439, JString, required = true,
                                 default = newJString("TrentService.Encrypt"))
  if valid_607439 != nil:
    section.add "X-Amz-Target", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Signature")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Signature", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Content-Sha256", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Date")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Date", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Credential")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Credential", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-Security-Token")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-Security-Token", valid_607444
  var valid_607445 = header.getOrDefault("X-Amz-Algorithm")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-Algorithm", valid_607445
  var valid_607446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "X-Amz-SignedHeaders", valid_607446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607448: Call_Encrypt_607436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt small amounts of arbitrary data, such as a personal identifier or database password, or other sensitive information. </p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need to use the <code>Encrypt</code> operation to encrypt a data key. The <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a> operations return a plaintext data key and an encrypted copy of that data key.</p> <p>When you encrypt data, you must specify a symmetric or asymmetric CMK to use in the encryption operation. The CMK must have a <code>KeyUsage</code> value of <code>ENCRYPT_DECRYPT.</code> To find the <code>KeyUsage</code> of a CMK, use the <a>DescribeKey</a> operation. </p> <p>If you use a symmetric CMK, you can use an encryption context to add additional security to your encryption operation. If you specify an <code>EncryptionContext</code> when encrypting data, you must specify the same encryption context (a case-sensitive exact match) when decrypting the data. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>If you specify an asymmetric CMK, you must also specify the encryption algorithm. The algorithm must be compatible with the CMK type.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> <p>The maximum size of the data that you can encrypt varies with the type of CMK and the encryption algorithm that you choose.</p> <ul> <li> <p>Symmetric CMKs</p> <ul> <li> <p> <code>SYMMETRIC_DEFAULT</code>: 4096 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_2048</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 214 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 190 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_3072</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 342 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 318 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_4096</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 470 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 446 bytes</p> </li> </ul> </li> </ul> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ## 
  let valid = call_607448.validator(path, query, header, formData, body)
  let scheme = call_607448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607448.url(scheme.get, call_607448.host, call_607448.base,
                         call_607448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607448, url, valid)

proc call*(call_607449: Call_Encrypt_607436; body: JsonNode): Recallable =
  ## encrypt
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt small amounts of arbitrary data, such as a personal identifier or database password, or other sensitive information. </p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need to use the <code>Encrypt</code> operation to encrypt a data key. The <a>GenerateDataKey</a> and <a>GenerateDataKeyPair</a> operations return a plaintext data key and an encrypted copy of that data key.</p> <p>When you encrypt data, you must specify a symmetric or asymmetric CMK to use in the encryption operation. The CMK must have a <code>KeyUsage</code> value of <code>ENCRYPT_DECRYPT.</code> To find the <code>KeyUsage</code> of a CMK, use the <a>DescribeKey</a> operation. </p> <p>If you use a symmetric CMK, you can use an encryption context to add additional security to your encryption operation. If you specify an <code>EncryptionContext</code> when encrypting data, you must specify the same encryption context (a case-sensitive exact match) when decrypting the data. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>If you specify an asymmetric CMK, you must also specify the encryption algorithm. The algorithm must be compatible with the CMK type.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> <p>The maximum size of the data that you can encrypt varies with the type of CMK and the encryption algorithm that you choose.</p> <ul> <li> <p>Symmetric CMKs</p> <ul> <li> <p> <code>SYMMETRIC_DEFAULT</code>: 4096 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_2048</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 214 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 190 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_3072</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 342 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 318 bytes</p> </li> </ul> </li> <li> <p> <code>RSA_4096</code> </p> <ul> <li> <p> <code>RSAES_OAEP_SHA_1</code>: 470 bytes</p> </li> <li> <p> <code>RSAES_OAEP_SHA_256</code>: 446 bytes</p> </li> </ul> </li> </ul> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   body: JObject (required)
  var body_607450 = newJObject()
  if body != nil:
    body_607450 = body
  result = call_607449.call(nil, nil, nil, nil, body_607450)

var encrypt* = Call_Encrypt_607436(name: "encrypt", meth: HttpMethod.HttpPost,
                                host: "kms.amazonaws.com",
                                route: "/#X-Amz-Target=TrentService.Encrypt",
                                validator: validate_Encrypt_607437, base: "/",
                                url: url_Encrypt_607438,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKey_607451 = ref object of OpenApiRestCall_606589
proc url_GenerateDataKey_607453(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateDataKey_607452(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607454 = header.getOrDefault("X-Amz-Target")
  valid_607454 = validateParameter(valid_607454, JString, required = true, default = newJString(
      "TrentService.GenerateDataKey"))
  if valid_607454 != nil:
    section.add "X-Amz-Target", valid_607454
  var valid_607455 = header.getOrDefault("X-Amz-Signature")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "X-Amz-Signature", valid_607455
  var valid_607456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "X-Amz-Content-Sha256", valid_607456
  var valid_607457 = header.getOrDefault("X-Amz-Date")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "X-Amz-Date", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-Credential")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-Credential", valid_607458
  var valid_607459 = header.getOrDefault("X-Amz-Security-Token")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "X-Amz-Security-Token", valid_607459
  var valid_607460 = header.getOrDefault("X-Amz-Algorithm")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "X-Amz-Algorithm", valid_607460
  var valid_607461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "X-Amz-SignedHeaders", valid_607461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607463: Call_GenerateDataKey_607451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a unique symmetric data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of AWS KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, specify the symmetric CMK that will be used to encrypt the data key. You cannot use an asymmetric CMK to generate data keys. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>You must also specify the length of the data key. Use either the <code>KeySpec</code> or <code>NumberOfBytes</code> parameters (but not both). For 128-bit and 256-bit data keys, use the <code>KeySpec</code> parameter. </p> <p>If the operation succeeds, the plaintext copy of the data key is in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To generate an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operation. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol>
  ## 
  let valid = call_607463.validator(path, query, header, formData, body)
  let scheme = call_607463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607463.url(scheme.get, call_607463.host, call_607463.base,
                         call_607463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607463, url, valid)

proc call*(call_607464: Call_GenerateDataKey_607451; body: JsonNode): Recallable =
  ## generateDataKey
  ## <p>Generates a unique symmetric data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of AWS KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, specify the symmetric CMK that will be used to encrypt the data key. You cannot use an asymmetric CMK to generate data keys. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>You must also specify the length of the data key. Use either the <code>KeySpec</code> or <code>NumberOfBytes</code> parameters (but not both). For 128-bit and 256-bit data keys, use the <code>KeySpec</code> parameter. </p> <p>If the operation succeeds, the plaintext copy of the data key is in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To generate an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operation. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol>
  ##   body: JObject (required)
  var body_607465 = newJObject()
  if body != nil:
    body_607465 = body
  result = call_607464.call(nil, nil, nil, nil, body_607465)

var generateDataKey* = Call_GenerateDataKey_607451(name: "generateDataKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKey",
    validator: validate_GenerateDataKey_607452, base: "/", url: url_GenerateDataKey_607453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyPair_607466 = ref object of OpenApiRestCall_606589
proc url_GenerateDataKeyPair_607468(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateDataKeyPair_607467(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607469 = header.getOrDefault("X-Amz-Target")
  valid_607469 = validateParameter(valid_607469, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyPair"))
  if valid_607469 != nil:
    section.add "X-Amz-Target", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-Signature")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Signature", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Content-Sha256", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-Date")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-Date", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-Credential")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-Credential", valid_607473
  var valid_607474 = header.getOrDefault("X-Amz-Security-Token")
  valid_607474 = validateParameter(valid_607474, JString, required = false,
                                 default = nil)
  if valid_607474 != nil:
    section.add "X-Amz-Security-Token", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Algorithm")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Algorithm", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-SignedHeaders", valid_607476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607478: Call_GenerateDataKeyPair_607466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPair</code> operation returns a plaintext public key, a plaintext private key, and a copy of the private key that is encrypted under the symmetric CMK you specify. You can use the data key pair to perform asymmetric cryptography outside of AWS KMS.</p> <p> <code>GenerateDataKeyPair</code> returns a unique data key pair for each request. The bytes in the keys are not related to the caller or the CMK that is used to encrypt the private key.</p> <p>You can use the public key that <code>GenerateDataKeyPair</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in a data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If you are using the data key pair to encrypt data, or for any operation where you don't immediately need a private key, consider using the <a>GenerateDataKeyPairWithoutPlaintext</a> operation. <code>GenerateDataKeyPairWithoutPlaintext</code> returns a plaintext public key and an encrypted private key, but omits the plaintext private key that you need only to decrypt ciphertext or sign a message. Later, when you need to decrypt the data or sign a message, use the <a>Decrypt</a> operation to decrypt the encrypted private key in the data key pair.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607478.validator(path, query, header, formData, body)
  let scheme = call_607478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607478.url(scheme.get, call_607478.host, call_607478.base,
                         call_607478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607478, url, valid)

proc call*(call_607479: Call_GenerateDataKeyPair_607466; body: JsonNode): Recallable =
  ## generateDataKeyPair
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPair</code> operation returns a plaintext public key, a plaintext private key, and a copy of the private key that is encrypted under the symmetric CMK you specify. You can use the data key pair to perform asymmetric cryptography outside of AWS KMS.</p> <p> <code>GenerateDataKeyPair</code> returns a unique data key pair for each request. The bytes in the keys are not related to the caller or the CMK that is used to encrypt the private key.</p> <p>You can use the public key that <code>GenerateDataKeyPair</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in a data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If you are using the data key pair to encrypt data, or for any operation where you don't immediately need a private key, consider using the <a>GenerateDataKeyPairWithoutPlaintext</a> operation. <code>GenerateDataKeyPairWithoutPlaintext</code> returns a plaintext public key and an encrypted private key, but omits the plaintext private key that you need only to decrypt ciphertext or sign a message. Later, when you need to decrypt the data or sign a message, use the <a>Decrypt</a> operation to decrypt the encrypted private key in the data key pair.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607480 = newJObject()
  if body != nil:
    body_607480 = body
  result = call_607479.call(nil, nil, nil, nil, body_607480)

var generateDataKeyPair* = Call_GenerateDataKeyPair_607466(
    name: "generateDataKeyPair", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyPair",
    validator: validate_GenerateDataKeyPair_607467, base: "/",
    url: url_GenerateDataKeyPair_607468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyPairWithoutPlaintext_607481 = ref object of OpenApiRestCall_606589
proc url_GenerateDataKeyPairWithoutPlaintext_607483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateDataKeyPairWithoutPlaintext_607482(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607484 = header.getOrDefault("X-Amz-Target")
  valid_607484 = validateParameter(valid_607484, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyPairWithoutPlaintext"))
  if valid_607484 != nil:
    section.add "X-Amz-Target", valid_607484
  var valid_607485 = header.getOrDefault("X-Amz-Signature")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "X-Amz-Signature", valid_607485
  var valid_607486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "X-Amz-Content-Sha256", valid_607486
  var valid_607487 = header.getOrDefault("X-Amz-Date")
  valid_607487 = validateParameter(valid_607487, JString, required = false,
                                 default = nil)
  if valid_607487 != nil:
    section.add "X-Amz-Date", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-Credential")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-Credential", valid_607488
  var valid_607489 = header.getOrDefault("X-Amz-Security-Token")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-Security-Token", valid_607489
  var valid_607490 = header.getOrDefault("X-Amz-Algorithm")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Algorithm", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-SignedHeaders", valid_607491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607493: Call_GenerateDataKeyPairWithoutPlaintext_607481;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPairWithoutPlaintext</code> operation returns a plaintext public key and a copy of the private key that is encrypted under the symmetric CMK you specify. Unlike <a>GenerateDataKeyPair</a>, this operation does not return a plaintext private key. </p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in the data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <code>KeySpec</code> field in the <a>DescribeKey</a> response.</p> <p>You can use the public key that <code>GenerateDataKeyPairWithoutPlaintext</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p> <code>GenerateDataKeyPairWithoutPlaintext</code> returns a unique data key pair for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the private key.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607493.validator(path, query, header, formData, body)
  let scheme = call_607493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607493.url(scheme.get, call_607493.host, call_607493.base,
                         call_607493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607493, url, valid)

proc call*(call_607494: Call_GenerateDataKeyPairWithoutPlaintext_607481;
          body: JsonNode): Recallable =
  ## generateDataKeyPairWithoutPlaintext
  ## <p>Generates a unique asymmetric data key pair. The <code>GenerateDataKeyPairWithoutPlaintext</code> operation returns a plaintext public key and a copy of the private key that is encrypted under the symmetric CMK you specify. Unlike <a>GenerateDataKeyPair</a>, this operation does not return a plaintext private key. </p> <p>To generate a data key pair, you must specify a symmetric customer master key (CMK) to encrypt the private key in the data key pair. You cannot use an asymmetric CMK. To get the type of your CMK, use the <code>KeySpec</code> field in the <a>DescribeKey</a> response.</p> <p>You can use the public key that <code>GenerateDataKeyPairWithoutPlaintext</code> returns to encrypt data or verify a signature outside of AWS KMS. Then, store the encrypted private key with the data. When you are ready to decrypt data or sign a message, you can use the <a>Decrypt</a> operation to decrypt the encrypted private key.</p> <p> <code>GenerateDataKeyPairWithoutPlaintext</code> returns a unique data key pair for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the private key.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607495 = newJObject()
  if body != nil:
    body_607495 = body
  result = call_607494.call(nil, nil, nil, nil, body_607495)

var generateDataKeyPairWithoutPlaintext* = Call_GenerateDataKeyPairWithoutPlaintext_607481(
    name: "generateDataKeyPairWithoutPlaintext", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyPairWithoutPlaintext",
    validator: validate_GenerateDataKeyPairWithoutPlaintext_607482, base: "/",
    url: url_GenerateDataKeyPairWithoutPlaintext_607483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyWithoutPlaintext_607496 = ref object of OpenApiRestCall_606589
proc url_GenerateDataKeyWithoutPlaintext_607498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateDataKeyWithoutPlaintext_607497(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607499 = header.getOrDefault("X-Amz-Target")
  valid_607499 = validateParameter(valid_607499, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyWithoutPlaintext"))
  if valid_607499 != nil:
    section.add "X-Amz-Target", valid_607499
  var valid_607500 = header.getOrDefault("X-Amz-Signature")
  valid_607500 = validateParameter(valid_607500, JString, required = false,
                                 default = nil)
  if valid_607500 != nil:
    section.add "X-Amz-Signature", valid_607500
  var valid_607501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607501 = validateParameter(valid_607501, JString, required = false,
                                 default = nil)
  if valid_607501 != nil:
    section.add "X-Amz-Content-Sha256", valid_607501
  var valid_607502 = header.getOrDefault("X-Amz-Date")
  valid_607502 = validateParameter(valid_607502, JString, required = false,
                                 default = nil)
  if valid_607502 != nil:
    section.add "X-Amz-Date", valid_607502
  var valid_607503 = header.getOrDefault("X-Amz-Credential")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "X-Amz-Credential", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Security-Token")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Security-Token", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-Algorithm")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-Algorithm", valid_607505
  var valid_607506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-SignedHeaders", valid_607506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607508: Call_GenerateDataKeyWithoutPlaintext_607496;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a unique symmetric data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. To request an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operations.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> is identical to the <a>GenerateDataKey</a> operation except that returns only the encrypted copy of the data key. This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key. </p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the keys are not related to the caller or CMK that is used to encrypt the private key.</p> <p>To generate a data key, you must specify the symmetric customer master key (CMK) that is used to encrypt the data key. You cannot use an asymmetric CMK to generate a data key. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If the operation succeeds, you will find the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607508.validator(path, query, header, formData, body)
  let scheme = call_607508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607508.url(scheme.get, call_607508.host, call_607508.base,
                         call_607508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607508, url, valid)

proc call*(call_607509: Call_GenerateDataKeyWithoutPlaintext_607496; body: JsonNode): Recallable =
  ## generateDataKeyWithoutPlaintext
  ## <p>Generates a unique symmetric data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. To request an asymmetric data key pair, use the <a>GenerateDataKeyPair</a> or <a>GenerateDataKeyPairWithoutPlaintext</a> operations.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> is identical to the <a>GenerateDataKey</a> operation except that returns only the encrypted copy of the data key. This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key. </p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p> <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the keys are not related to the caller or CMK that is used to encrypt the private key.</p> <p>To generate a data key, you must specify the symmetric customer master key (CMK) that is used to encrypt the data key. You cannot use an asymmetric CMK to generate a data key. To get the type of your CMK, use the <a>DescribeKey</a> operation.</p> <p>If the operation succeeds, you will find the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>You can use the optional encryption context to add additional security to the encryption operation. If you specify an <code>EncryptionContext</code>, you must specify the same encryption context (a case-sensitive exact match) when decrypting the encrypted data key. Otherwise, the request to decrypt fails with an InvalidCiphertextException. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607510 = newJObject()
  if body != nil:
    body_607510 = body
  result = call_607509.call(nil, nil, nil, nil, body_607510)

var generateDataKeyWithoutPlaintext* = Call_GenerateDataKeyWithoutPlaintext_607496(
    name: "generateDataKeyWithoutPlaintext", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyWithoutPlaintext",
    validator: validate_GenerateDataKeyWithoutPlaintext_607497, base: "/",
    url: url_GenerateDataKeyWithoutPlaintext_607498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateRandom_607511 = ref object of OpenApiRestCall_606589
proc url_GenerateRandom_607513(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateRandom_607512(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607514 = header.getOrDefault("X-Amz-Target")
  valid_607514 = validateParameter(valid_607514, JString, required = true, default = newJString(
      "TrentService.GenerateRandom"))
  if valid_607514 != nil:
    section.add "X-Amz-Target", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Signature")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Signature", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Content-Sha256", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-Date")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-Date", valid_607517
  var valid_607518 = header.getOrDefault("X-Amz-Credential")
  valid_607518 = validateParameter(valid_607518, JString, required = false,
                                 default = nil)
  if valid_607518 != nil:
    section.add "X-Amz-Credential", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Security-Token")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Security-Token", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Algorithm")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Algorithm", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-SignedHeaders", valid_607521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607523: Call_GenerateRandom_607511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
  ## 
  let valid = call_607523.validator(path, query, header, formData, body)
  let scheme = call_607523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607523.url(scheme.get, call_607523.host, call_607523.base,
                         call_607523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607523, url, valid)

proc call*(call_607524: Call_GenerateRandom_607511; body: JsonNode): Recallable =
  ## generateRandom
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
  ##   body: JObject (required)
  var body_607525 = newJObject()
  if body != nil:
    body_607525 = body
  result = call_607524.call(nil, nil, nil, nil, body_607525)

var generateRandom* = Call_GenerateRandom_607511(name: "generateRandom",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateRandom",
    validator: validate_GenerateRandom_607512, base: "/", url: url_GenerateRandom_607513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPolicy_607526 = ref object of OpenApiRestCall_606589
proc url_GetKeyPolicy_607528(protocol: Scheme; host: string; base: string;
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

proc validate_GetKeyPolicy_607527(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607529 = header.getOrDefault("X-Amz-Target")
  valid_607529 = validateParameter(valid_607529, JString, required = true, default = newJString(
      "TrentService.GetKeyPolicy"))
  if valid_607529 != nil:
    section.add "X-Amz-Target", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Signature")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Signature", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-Content-Sha256", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-Date")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-Date", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-Credential")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Credential", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Security-Token")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Security-Token", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Algorithm")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Algorithm", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-SignedHeaders", valid_607536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607538: Call_GetKeyPolicy_607526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
  ## 
  let valid = call_607538.validator(path, query, header, formData, body)
  let scheme = call_607538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607538.url(scheme.get, call_607538.host, call_607538.base,
                         call_607538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607538, url, valid)

proc call*(call_607539: Call_GetKeyPolicy_607526; body: JsonNode): Recallable =
  ## getKeyPolicy
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
  ##   body: JObject (required)
  var body_607540 = newJObject()
  if body != nil:
    body_607540 = body
  result = call_607539.call(nil, nil, nil, nil, body_607540)

var getKeyPolicy* = Call_GetKeyPolicy_607526(name: "getKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyPolicy",
    validator: validate_GetKeyPolicy_607527, base: "/", url: url_GetKeyPolicy_607528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyRotationStatus_607541 = ref object of OpenApiRestCall_606589
proc url_GetKeyRotationStatus_607543(protocol: Scheme; host: string; base: string;
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

proc validate_GetKeyRotationStatus_607542(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607544 = header.getOrDefault("X-Amz-Target")
  valid_607544 = validateParameter(valid_607544, JString, required = true, default = newJString(
      "TrentService.GetKeyRotationStatus"))
  if valid_607544 != nil:
    section.add "X-Amz-Target", valid_607544
  var valid_607545 = header.getOrDefault("X-Amz-Signature")
  valid_607545 = validateParameter(valid_607545, JString, required = false,
                                 default = nil)
  if valid_607545 != nil:
    section.add "X-Amz-Signature", valid_607545
  var valid_607546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607546 = validateParameter(valid_607546, JString, required = false,
                                 default = nil)
  if valid_607546 != nil:
    section.add "X-Amz-Content-Sha256", valid_607546
  var valid_607547 = header.getOrDefault("X-Amz-Date")
  valid_607547 = validateParameter(valid_607547, JString, required = false,
                                 default = nil)
  if valid_607547 != nil:
    section.add "X-Amz-Date", valid_607547
  var valid_607548 = header.getOrDefault("X-Amz-Credential")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Credential", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Security-Token")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Security-Token", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Algorithm")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Algorithm", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-SignedHeaders", valid_607551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607553: Call_GetKeyRotationStatus_607541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. The key rotation status for these CMKs is always <code>false</code>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_607553.validator(path, query, header, formData, body)
  let scheme = call_607553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607553.url(scheme.get, call_607553.host, call_607553.base,
                         call_607553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607553, url, valid)

proc call*(call_607554: Call_GetKeyRotationStatus_607541; body: JsonNode): Recallable =
  ## getKeyRotationStatus
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>You cannot enable automatic rotation of asymmetric CMKs, CMKs with imported key material, or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. The key rotation status for these CMKs is always <code>false</code>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   body: JObject (required)
  var body_607555 = newJObject()
  if body != nil:
    body_607555 = body
  result = call_607554.call(nil, nil, nil, nil, body_607555)

var getKeyRotationStatus* = Call_GetKeyRotationStatus_607541(
    name: "getKeyRotationStatus", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyRotationStatus",
    validator: validate_GetKeyRotationStatus_607542, base: "/",
    url: url_GetKeyRotationStatus_607543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersForImport_607556 = ref object of OpenApiRestCall_606589
proc url_GetParametersForImport_607558(protocol: Scheme; host: string; base: string;
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

proc validate_GetParametersForImport_607557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607559 = header.getOrDefault("X-Amz-Target")
  valid_607559 = validateParameter(valid_607559, JString, required = true, default = newJString(
      "TrentService.GetParametersForImport"))
  if valid_607559 != nil:
    section.add "X-Amz-Target", valid_607559
  var valid_607560 = header.getOrDefault("X-Amz-Signature")
  valid_607560 = validateParameter(valid_607560, JString, required = false,
                                 default = nil)
  if valid_607560 != nil:
    section.add "X-Amz-Signature", valid_607560
  var valid_607561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607561 = validateParameter(valid_607561, JString, required = false,
                                 default = nil)
  if valid_607561 != nil:
    section.add "X-Amz-Content-Sha256", valid_607561
  var valid_607562 = header.getOrDefault("X-Amz-Date")
  valid_607562 = validateParameter(valid_607562, JString, required = false,
                                 default = nil)
  if valid_607562 != nil:
    section.add "X-Amz-Date", valid_607562
  var valid_607563 = header.getOrDefault("X-Amz-Credential")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "X-Amz-Credential", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-Security-Token")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-Security-Token", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Algorithm")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Algorithm", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-SignedHeaders", valid_607566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607568: Call_GetParametersForImport_607556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the items you need to import key material into a symmetric, customer managed customer master key (CMK). For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the symmetric key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request.</p> <p>You must specify the key ID of the symmetric CMK into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account.</p> <p>To import key material, you must use the public key and import token from the same response. These items are valid for 24 hours. The expiration date and time appear in the <code>GetParametersForImport</code> response. You cannot use an expired token in an <a>ImportKeyMaterial</a> request. If your key and token expire, send another <code>GetParametersForImport</code> request.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607568.validator(path, query, header, formData, body)
  let scheme = call_607568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607568.url(scheme.get, call_607568.host, call_607568.base,
                         call_607568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607568, url, valid)

proc call*(call_607569: Call_GetParametersForImport_607556; body: JsonNode): Recallable =
  ## getParametersForImport
  ## <p>Returns the items you need to import key material into a symmetric, customer managed customer master key (CMK). For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the symmetric key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request.</p> <p>You must specify the key ID of the symmetric CMK into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account.</p> <p>To import key material, you must use the public key and import token from the same response. These items are valid for 24 hours. The expiration date and time appear in the <code>GetParametersForImport</code> response. You cannot use an expired token in an <a>ImportKeyMaterial</a> request. If your key and token expire, send another <code>GetParametersForImport</code> request.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607570 = newJObject()
  if body != nil:
    body_607570 = body
  result = call_607569.call(nil, nil, nil, nil, body_607570)

var getParametersForImport* = Call_GetParametersForImport_607556(
    name: "getParametersForImport", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetParametersForImport",
    validator: validate_GetParametersForImport_607557, base: "/",
    url: url_GetParametersForImport_607558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey_607571 = ref object of OpenApiRestCall_606589
proc url_GetPublicKey_607573(protocol: Scheme; host: string; base: string;
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

proc validate_GetPublicKey_607572(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607574 = header.getOrDefault("X-Amz-Target")
  valid_607574 = validateParameter(valid_607574, JString, required = true, default = newJString(
      "TrentService.GetPublicKey"))
  if valid_607574 != nil:
    section.add "X-Amz-Target", valid_607574
  var valid_607575 = header.getOrDefault("X-Amz-Signature")
  valid_607575 = validateParameter(valid_607575, JString, required = false,
                                 default = nil)
  if valid_607575 != nil:
    section.add "X-Amz-Signature", valid_607575
  var valid_607576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607576 = validateParameter(valid_607576, JString, required = false,
                                 default = nil)
  if valid_607576 != nil:
    section.add "X-Amz-Content-Sha256", valid_607576
  var valid_607577 = header.getOrDefault("X-Amz-Date")
  valid_607577 = validateParameter(valid_607577, JString, required = false,
                                 default = nil)
  if valid_607577 != nil:
    section.add "X-Amz-Date", valid_607577
  var valid_607578 = header.getOrDefault("X-Amz-Credential")
  valid_607578 = validateParameter(valid_607578, JString, required = false,
                                 default = nil)
  if valid_607578 != nil:
    section.add "X-Amz-Credential", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-Security-Token")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-Security-Token", valid_607579
  var valid_607580 = header.getOrDefault("X-Amz-Algorithm")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "X-Amz-Algorithm", valid_607580
  var valid_607581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-SignedHeaders", valid_607581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607583: Call_GetPublicKey_607571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the public key of an asymmetric CMK. Unlike the private key of a asymmetric CMK, which never leaves AWS KMS unencrypted, callers with <code>kms:GetPublicKey</code> permission can download the public key of an asymmetric CMK. You can share the public key to allow others to encrypt messages and verify signatures outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You do not need to download the public key. Instead, you can use the public key within AWS KMS by calling the <a>Encrypt</a>, <a>ReEncrypt</a>, or <a>Verify</a> operations with the identifier of an asymmetric CMK. When you use the public key within AWS KMS, you benefit from the authentication, authorization, and logging that are part of every AWS KMS operation. You also reduce of risk of encrypting data that cannot be decrypted. These features are not effective outside of AWS KMS. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/download-public-key.html#download-public-key-considerations">Special Considerations for Downloading Public Keys</a>.</p> <p>To help you use the public key safely outside of AWS KMS, <code>GetPublicKey</code> returns important information about the public key in the response, including:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-CustomerMasterKeySpec">CustomerMasterKeySpec</a>: The type of key material in the public key, such as <code>RSA_4096</code> or <code>ECC_NIST_P521</code>.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage">KeyUsage</a>: Whether the key is used for encryption or signing.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms">EncryptionAlgorithms</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms">SigningAlgorithms</a>: A list of the encryption algorithms or the signing algorithms for the key.</p> </li> </ul> <p>Although AWS KMS cannot enforce these restrictions on external operations, it is crucial that you use this information to prevent the public key from being used improperly. For example, you can prevent a public signing key from being used encrypt data, or prevent a public key from being used with an encryption algorithm that is not supported by AWS KMS. You can also avoid errors, such as using the wrong signing algorithm in a verification operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607583.validator(path, query, header, formData, body)
  let scheme = call_607583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607583.url(scheme.get, call_607583.host, call_607583.base,
                         call_607583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607583, url, valid)

proc call*(call_607584: Call_GetPublicKey_607571; body: JsonNode): Recallable =
  ## getPublicKey
  ## <p>Returns the public key of an asymmetric CMK. Unlike the private key of a asymmetric CMK, which never leaves AWS KMS unencrypted, callers with <code>kms:GetPublicKey</code> permission can download the public key of an asymmetric CMK. You can share the public key to allow others to encrypt messages and verify signatures outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You do not need to download the public key. Instead, you can use the public key within AWS KMS by calling the <a>Encrypt</a>, <a>ReEncrypt</a>, or <a>Verify</a> operations with the identifier of an asymmetric CMK. When you use the public key within AWS KMS, you benefit from the authentication, authorization, and logging that are part of every AWS KMS operation. You also reduce of risk of encrypting data that cannot be decrypted. These features are not effective outside of AWS KMS. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/download-public-key.html#download-public-key-considerations">Special Considerations for Downloading Public Keys</a>.</p> <p>To help you use the public key safely outside of AWS KMS, <code>GetPublicKey</code> returns important information about the public key in the response, including:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-CustomerMasterKeySpec">CustomerMasterKeySpec</a>: The type of key material in the public key, such as <code>RSA_4096</code> or <code>ECC_NIST_P521</code>.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage">KeyUsage</a>: Whether the key is used for encryption or signing.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms">EncryptionAlgorithms</a> or <a href="https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms">SigningAlgorithms</a>: A list of the encryption algorithms or the signing algorithms for the key.</p> </li> </ul> <p>Although AWS KMS cannot enforce these restrictions on external operations, it is crucial that you use this information to prevent the public key from being used improperly. For example, you can prevent a public signing key from being used encrypt data, or prevent a public key from being used with an encryption algorithm that is not supported by AWS KMS. You can also avoid errors, such as using the wrong signing algorithm in a verification operation.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607585 = newJObject()
  if body != nil:
    body_607585 = body
  result = call_607584.call(nil, nil, nil, nil, body_607585)

var getPublicKey* = Call_GetPublicKey_607571(name: "getPublicKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetPublicKey",
    validator: validate_GetPublicKey_607572, base: "/", url: url_GetPublicKey_607573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyMaterial_607586 = ref object of OpenApiRestCall_606589
proc url_ImportKeyMaterial_607588(protocol: Scheme; host: string; base: string;
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

proc validate_ImportKeyMaterial_607587(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607589 = header.getOrDefault("X-Amz-Target")
  valid_607589 = validateParameter(valid_607589, JString, required = true, default = newJString(
      "TrentService.ImportKeyMaterial"))
  if valid_607589 != nil:
    section.add "X-Amz-Target", valid_607589
  var valid_607590 = header.getOrDefault("X-Amz-Signature")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "X-Amz-Signature", valid_607590
  var valid_607591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607591 = validateParameter(valid_607591, JString, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "X-Amz-Content-Sha256", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Date")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Date", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-Credential")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-Credential", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-Security-Token")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-Security-Token", valid_607594
  var valid_607595 = header.getOrDefault("X-Amz-Algorithm")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "X-Amz-Algorithm", valid_607595
  var valid_607596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "X-Amz-SignedHeaders", valid_607596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607598: Call_ImportKeyMaterial_607586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports key material into an existing symmetric AWS KMS customer master key (CMK) that was created without key material. After you successfully import key material into a CMK, you can <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#reimport-key-material">reimport the same key material</a> into that CMK, but you cannot import different key material.</p> <p>You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. You must use a public key and token from the same <code>GetParametersForImport</code> response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, AWS KMS deletes the key material from the CMK on the specified date, and the CMK becomes unusable. To use the CMK again, you must reimport the same key material. The only way to change an expiration date is by reimporting the same key material and specifying a new expiration date. </p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK.</p> <p>If this operation fails, use the exception to help determine the problem. If the error is related to the key material, the import token, or wrapping key, use <a>GetParametersForImport</a> to get a new public key and import token for the CMK and repeat the import procedure. For help, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#importing-keys-overview">How To Import Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607598.validator(path, query, header, formData, body)
  let scheme = call_607598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607598.url(scheme.get, call_607598.host, call_607598.base,
                         call_607598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607598, url, valid)

proc call*(call_607599: Call_ImportKeyMaterial_607586; body: JsonNode): Recallable =
  ## importKeyMaterial
  ## <p>Imports key material into an existing symmetric AWS KMS customer master key (CMK) that was created without key material. After you successfully import key material into a CMK, you can <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#reimport-key-material">reimport the same key material</a> into that CMK, but you cannot import different key material.</p> <p>You cannot perform this operation on an asymmetric CMK or on any CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. You must use a public key and token from the same <code>GetParametersForImport</code> response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, AWS KMS deletes the key material from the CMK on the specified date, and the CMK becomes unusable. To use the CMK again, you must reimport the same key material. The only way to change an expiration date is by reimporting the same key material and specifying a new expiration date. </p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK.</p> <p>If this operation fails, use the exception to help determine the problem. If the error is related to the key material, the import token, or wrapping key, use <a>GetParametersForImport</a> to get a new public key and import token for the CMK and repeat the import procedure. For help, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html#importing-keys-overview">How To Import Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607600 = newJObject()
  if body != nil:
    body_607600 = body
  result = call_607599.call(nil, nil, nil, nil, body_607600)

var importKeyMaterial* = Call_ImportKeyMaterial_607586(name: "importKeyMaterial",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ImportKeyMaterial",
    validator: validate_ImportKeyMaterial_607587, base: "/",
    url: url_ImportKeyMaterial_607588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_607601 = ref object of OpenApiRestCall_606589
proc url_ListAliases_607603(protocol: Scheme; host: string; base: string;
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

proc validate_ListAliases_607602(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_607604 = query.getOrDefault("Marker")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "Marker", valid_607604
  var valid_607605 = query.getOrDefault("Limit")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "Limit", valid_607605
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
  var valid_607606 = header.getOrDefault("X-Amz-Target")
  valid_607606 = validateParameter(valid_607606, JString, required = true, default = newJString(
      "TrentService.ListAliases"))
  if valid_607606 != nil:
    section.add "X-Amz-Target", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-Signature")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Signature", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Content-Sha256", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-Date")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-Date", valid_607609
  var valid_607610 = header.getOrDefault("X-Amz-Credential")
  valid_607610 = validateParameter(valid_607610, JString, required = false,
                                 default = nil)
  if valid_607610 != nil:
    section.add "X-Amz-Credential", valid_607610
  var valid_607611 = header.getOrDefault("X-Amz-Security-Token")
  valid_607611 = validateParameter(valid_607611, JString, required = false,
                                 default = nil)
  if valid_607611 != nil:
    section.add "X-Amz-Security-Token", valid_607611
  var valid_607612 = header.getOrDefault("X-Amz-Algorithm")
  valid_607612 = validateParameter(valid_607612, JString, required = false,
                                 default = nil)
  if valid_607612 != nil:
    section.add "X-Amz-Algorithm", valid_607612
  var valid_607613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607613 = validateParameter(valid_607613, JString, required = false,
                                 default = nil)
  if valid_607613 != nil:
    section.add "X-Amz-SignedHeaders", valid_607613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607615: Call_ListAliases_607601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases quota</a>.</p>
  ## 
  let valid = call_607615.validator(path, query, header, formData, body)
  let scheme = call_607615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607615.url(scheme.get, call_607615.host, call_607615.base,
                         call_607615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607615, url, valid)

proc call*(call_607616: Call_ListAliases_607601; body: JsonNode; Marker: string = "";
          Limit: string = ""): Recallable =
  ## listAliases
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases quota</a>.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_607617 = newJObject()
  var body_607618 = newJObject()
  add(query_607617, "Marker", newJString(Marker))
  add(query_607617, "Limit", newJString(Limit))
  if body != nil:
    body_607618 = body
  result = call_607616.call(nil, query_607617, nil, nil, body_607618)

var listAliases* = Call_ListAliases_607601(name: "listAliases",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListAliases",
                                        validator: validate_ListAliases_607602,
                                        base: "/", url: url_ListAliases_607603,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGrants_607620 = ref object of OpenApiRestCall_606589
proc url_ListGrants_607622(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGrants_607621(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_607623 = query.getOrDefault("Marker")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "Marker", valid_607623
  var valid_607624 = query.getOrDefault("Limit")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "Limit", valid_607624
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
  var valid_607625 = header.getOrDefault("X-Amz-Target")
  valid_607625 = validateParameter(valid_607625, JString, required = true, default = newJString(
      "TrentService.ListGrants"))
  if valid_607625 != nil:
    section.add "X-Amz-Target", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-Signature")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Signature", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Content-Sha256", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-Date")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-Date", valid_607628
  var valid_607629 = header.getOrDefault("X-Amz-Credential")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "X-Amz-Credential", valid_607629
  var valid_607630 = header.getOrDefault("X-Amz-Security-Token")
  valid_607630 = validateParameter(valid_607630, JString, required = false,
                                 default = nil)
  if valid_607630 != nil:
    section.add "X-Amz-Security-Token", valid_607630
  var valid_607631 = header.getOrDefault("X-Amz-Algorithm")
  valid_607631 = validateParameter(valid_607631, JString, required = false,
                                 default = nil)
  if valid_607631 != nil:
    section.add "X-Amz-Algorithm", valid_607631
  var valid_607632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607632 = validateParameter(valid_607632, JString, required = false,
                                 default = nil)
  if valid_607632 != nil:
    section.add "X-Amz-SignedHeaders", valid_607632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607634: Call_ListGrants_607620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_607634.validator(path, query, header, formData, body)
  let scheme = call_607634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607634.url(scheme.get, call_607634.host, call_607634.base,
                         call_607634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607634, url, valid)

proc call*(call_607635: Call_ListGrants_607620; body: JsonNode; Marker: string = "";
          Limit: string = ""): Recallable =
  ## listGrants
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_607636 = newJObject()
  var body_607637 = newJObject()
  add(query_607636, "Marker", newJString(Marker))
  add(query_607636, "Limit", newJString(Limit))
  if body != nil:
    body_607637 = body
  result = call_607635.call(nil, query_607636, nil, nil, body_607637)

var listGrants* = Call_ListGrants_607620(name: "listGrants",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListGrants",
                                      validator: validate_ListGrants_607621,
                                      base: "/", url: url_ListGrants_607622,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPolicies_607638 = ref object of OpenApiRestCall_606589
proc url_ListKeyPolicies_607640(protocol: Scheme; host: string; base: string;
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

proc validate_ListKeyPolicies_607639(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_607641 = query.getOrDefault("Marker")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "Marker", valid_607641
  var valid_607642 = query.getOrDefault("Limit")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "Limit", valid_607642
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
  var valid_607643 = header.getOrDefault("X-Amz-Target")
  valid_607643 = validateParameter(valid_607643, JString, required = true, default = newJString(
      "TrentService.ListKeyPolicies"))
  if valid_607643 != nil:
    section.add "X-Amz-Target", valid_607643
  var valid_607644 = header.getOrDefault("X-Amz-Signature")
  valid_607644 = validateParameter(valid_607644, JString, required = false,
                                 default = nil)
  if valid_607644 != nil:
    section.add "X-Amz-Signature", valid_607644
  var valid_607645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607645 = validateParameter(valid_607645, JString, required = false,
                                 default = nil)
  if valid_607645 != nil:
    section.add "X-Amz-Content-Sha256", valid_607645
  var valid_607646 = header.getOrDefault("X-Amz-Date")
  valid_607646 = validateParameter(valid_607646, JString, required = false,
                                 default = nil)
  if valid_607646 != nil:
    section.add "X-Amz-Date", valid_607646
  var valid_607647 = header.getOrDefault("X-Amz-Credential")
  valid_607647 = validateParameter(valid_607647, JString, required = false,
                                 default = nil)
  if valid_607647 != nil:
    section.add "X-Amz-Credential", valid_607647
  var valid_607648 = header.getOrDefault("X-Amz-Security-Token")
  valid_607648 = validateParameter(valid_607648, JString, required = false,
                                 default = nil)
  if valid_607648 != nil:
    section.add "X-Amz-Security-Token", valid_607648
  var valid_607649 = header.getOrDefault("X-Amz-Algorithm")
  valid_607649 = validateParameter(valid_607649, JString, required = false,
                                 default = nil)
  if valid_607649 != nil:
    section.add "X-Amz-Algorithm", valid_607649
  var valid_607650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607650 = validateParameter(valid_607650, JString, required = false,
                                 default = nil)
  if valid_607650 != nil:
    section.add "X-Amz-SignedHeaders", valid_607650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607652: Call_ListKeyPolicies_607638; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ## 
  let valid = call_607652.validator(path, query, header, formData, body)
  let scheme = call_607652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607652.url(scheme.get, call_607652.host, call_607652.base,
                         call_607652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607652, url, valid)

proc call*(call_607653: Call_ListKeyPolicies_607638; body: JsonNode;
          Marker: string = ""; Limit: string = ""): Recallable =
  ## listKeyPolicies
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ##   Marker: string
  ##         : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_607654 = newJObject()
  var body_607655 = newJObject()
  add(query_607654, "Marker", newJString(Marker))
  add(query_607654, "Limit", newJString(Limit))
  if body != nil:
    body_607655 = body
  result = call_607653.call(nil, query_607654, nil, nil, body_607655)

var listKeyPolicies* = Call_ListKeyPolicies_607638(name: "listKeyPolicies",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListKeyPolicies",
    validator: validate_ListKeyPolicies_607639, base: "/", url: url_ListKeyPolicies_607640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeys_607656 = ref object of OpenApiRestCall_606589
proc url_ListKeys_607658(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKeys_607657(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_607659 = query.getOrDefault("Marker")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "Marker", valid_607659
  var valid_607660 = query.getOrDefault("Limit")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "Limit", valid_607660
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
  var valid_607661 = header.getOrDefault("X-Amz-Target")
  valid_607661 = validateParameter(valid_607661, JString, required = true,
                                 default = newJString("TrentService.ListKeys"))
  if valid_607661 != nil:
    section.add "X-Amz-Target", valid_607661
  var valid_607662 = header.getOrDefault("X-Amz-Signature")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-Signature", valid_607662
  var valid_607663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607663 = validateParameter(valid_607663, JString, required = false,
                                 default = nil)
  if valid_607663 != nil:
    section.add "X-Amz-Content-Sha256", valid_607663
  var valid_607664 = header.getOrDefault("X-Amz-Date")
  valid_607664 = validateParameter(valid_607664, JString, required = false,
                                 default = nil)
  if valid_607664 != nil:
    section.add "X-Amz-Date", valid_607664
  var valid_607665 = header.getOrDefault("X-Amz-Credential")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-Credential", valid_607665
  var valid_607666 = header.getOrDefault("X-Amz-Security-Token")
  valid_607666 = validateParameter(valid_607666, JString, required = false,
                                 default = nil)
  if valid_607666 != nil:
    section.add "X-Amz-Security-Token", valid_607666
  var valid_607667 = header.getOrDefault("X-Amz-Algorithm")
  valid_607667 = validateParameter(valid_607667, JString, required = false,
                                 default = nil)
  if valid_607667 != nil:
    section.add "X-Amz-Algorithm", valid_607667
  var valid_607668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607668 = validateParameter(valid_607668, JString, required = false,
                                 default = nil)
  if valid_607668 != nil:
    section.add "X-Amz-SignedHeaders", valid_607668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607670: Call_ListKeys_607656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and Region.
  ## 
  let valid = call_607670.validator(path, query, header, formData, body)
  let scheme = call_607670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607670.url(scheme.get, call_607670.host, call_607670.base,
                         call_607670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607670, url, valid)

proc call*(call_607671: Call_ListKeys_607656; body: JsonNode; Marker: string = "";
          Limit: string = ""): Recallable =
  ## listKeys
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and Region.
  ##   Marker: string
  ##         : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_607672 = newJObject()
  var body_607673 = newJObject()
  add(query_607672, "Marker", newJString(Marker))
  add(query_607672, "Limit", newJString(Limit))
  if body != nil:
    body_607673 = body
  result = call_607671.call(nil, query_607672, nil, nil, body_607673)

var listKeys* = Call_ListKeys_607656(name: "listKeys", meth: HttpMethod.HttpPost,
                                  host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListKeys",
                                  validator: validate_ListKeys_607657, base: "/",
                                  url: url_ListKeys_607658,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceTags_607674 = ref object of OpenApiRestCall_606589
proc url_ListResourceTags_607676(protocol: Scheme; host: string; base: string;
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

proc validate_ListResourceTags_607675(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607677 = header.getOrDefault("X-Amz-Target")
  valid_607677 = validateParameter(valid_607677, JString, required = true, default = newJString(
      "TrentService.ListResourceTags"))
  if valid_607677 != nil:
    section.add "X-Amz-Target", valid_607677
  var valid_607678 = header.getOrDefault("X-Amz-Signature")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "X-Amz-Signature", valid_607678
  var valid_607679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607679 = validateParameter(valid_607679, JString, required = false,
                                 default = nil)
  if valid_607679 != nil:
    section.add "X-Amz-Content-Sha256", valid_607679
  var valid_607680 = header.getOrDefault("X-Amz-Date")
  valid_607680 = validateParameter(valid_607680, JString, required = false,
                                 default = nil)
  if valid_607680 != nil:
    section.add "X-Amz-Date", valid_607680
  var valid_607681 = header.getOrDefault("X-Amz-Credential")
  valid_607681 = validateParameter(valid_607681, JString, required = false,
                                 default = nil)
  if valid_607681 != nil:
    section.add "X-Amz-Credential", valid_607681
  var valid_607682 = header.getOrDefault("X-Amz-Security-Token")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "X-Amz-Security-Token", valid_607682
  var valid_607683 = header.getOrDefault("X-Amz-Algorithm")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "X-Amz-Algorithm", valid_607683
  var valid_607684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607684 = validateParameter(valid_607684, JString, required = false,
                                 default = nil)
  if valid_607684 != nil:
    section.add "X-Amz-SignedHeaders", valid_607684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607686: Call_ListResourceTags_607674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
  ## 
  let valid = call_607686.validator(path, query, header, formData, body)
  let scheme = call_607686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607686.url(scheme.get, call_607686.host, call_607686.base,
                         call_607686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607686, url, valid)

proc call*(call_607687: Call_ListResourceTags_607674; body: JsonNode): Recallable =
  ## listResourceTags
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
  ##   body: JObject (required)
  var body_607688 = newJObject()
  if body != nil:
    body_607688 = body
  result = call_607687.call(nil, nil, nil, nil, body_607688)

var listResourceTags* = Call_ListResourceTags_607674(name: "listResourceTags",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListResourceTags",
    validator: validate_ListResourceTags_607675, base: "/",
    url: url_ListResourceTags_607676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRetirableGrants_607689 = ref object of OpenApiRestCall_606589
proc url_ListRetirableGrants_607691(protocol: Scheme; host: string; base: string;
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

proc validate_ListRetirableGrants_607690(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607692 = header.getOrDefault("X-Amz-Target")
  valid_607692 = validateParameter(valid_607692, JString, required = true, default = newJString(
      "TrentService.ListRetirableGrants"))
  if valid_607692 != nil:
    section.add "X-Amz-Target", valid_607692
  var valid_607693 = header.getOrDefault("X-Amz-Signature")
  valid_607693 = validateParameter(valid_607693, JString, required = false,
                                 default = nil)
  if valid_607693 != nil:
    section.add "X-Amz-Signature", valid_607693
  var valid_607694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607694 = validateParameter(valid_607694, JString, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "X-Amz-Content-Sha256", valid_607694
  var valid_607695 = header.getOrDefault("X-Amz-Date")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Date", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Credential")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Credential", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-Security-Token")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Security-Token", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Algorithm")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Algorithm", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-SignedHeaders", valid_607699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607701: Call_ListRetirableGrants_607689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
  ## 
  let valid = call_607701.validator(path, query, header, formData, body)
  let scheme = call_607701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607701.url(scheme.get, call_607701.host, call_607701.base,
                         call_607701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607701, url, valid)

proc call*(call_607702: Call_ListRetirableGrants_607689; body: JsonNode): Recallable =
  ## listRetirableGrants
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
  ##   body: JObject (required)
  var body_607703 = newJObject()
  if body != nil:
    body_607703 = body
  result = call_607702.call(nil, nil, nil, nil, body_607703)

var listRetirableGrants* = Call_ListRetirableGrants_607689(
    name: "listRetirableGrants", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListRetirableGrants",
    validator: validate_ListRetirableGrants_607690, base: "/",
    url: url_ListRetirableGrants_607691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutKeyPolicy_607704 = ref object of OpenApiRestCall_606589
proc url_PutKeyPolicy_607706(protocol: Scheme; host: string; base: string;
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

proc validate_PutKeyPolicy_607705(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607707 = header.getOrDefault("X-Amz-Target")
  valid_607707 = validateParameter(valid_607707, JString, required = true, default = newJString(
      "TrentService.PutKeyPolicy"))
  if valid_607707 != nil:
    section.add "X-Amz-Target", valid_607707
  var valid_607708 = header.getOrDefault("X-Amz-Signature")
  valid_607708 = validateParameter(valid_607708, JString, required = false,
                                 default = nil)
  if valid_607708 != nil:
    section.add "X-Amz-Signature", valid_607708
  var valid_607709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Content-Sha256", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Date")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Date", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Credential")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Credential", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Security-Token")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Security-Token", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Algorithm")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Algorithm", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-SignedHeaders", valid_607714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607716: Call_PutKeyPolicy_607704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607716.validator(path, query, header, formData, body)
  let scheme = call_607716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607716.url(scheme.get, call_607716.host, call_607716.base,
                         call_607716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607716, url, valid)

proc call*(call_607717: Call_PutKeyPolicy_607704; body: JsonNode): Recallable =
  ## putKeyPolicy
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607718 = newJObject()
  if body != nil:
    body_607718 = body
  result = call_607717.call(nil, nil, nil, nil, body_607718)

var putKeyPolicy* = Call_PutKeyPolicy_607704(name: "putKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.PutKeyPolicy",
    validator: validate_PutKeyPolicy_607705, base: "/", url: url_PutKeyPolicy_607706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReEncrypt_607719 = ref object of OpenApiRestCall_606589
proc url_ReEncrypt_607721(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReEncrypt_607720(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607722 = header.getOrDefault("X-Amz-Target")
  valid_607722 = validateParameter(valid_607722, JString, required = true,
                                 default = newJString("TrentService.ReEncrypt"))
  if valid_607722 != nil:
    section.add "X-Amz-Target", valid_607722
  var valid_607723 = header.getOrDefault("X-Amz-Signature")
  valid_607723 = validateParameter(valid_607723, JString, required = false,
                                 default = nil)
  if valid_607723 != nil:
    section.add "X-Amz-Signature", valid_607723
  var valid_607724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "X-Amz-Content-Sha256", valid_607724
  var valid_607725 = header.getOrDefault("X-Amz-Date")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "X-Amz-Date", valid_607725
  var valid_607726 = header.getOrDefault("X-Amz-Credential")
  valid_607726 = validateParameter(valid_607726, JString, required = false,
                                 default = nil)
  if valid_607726 != nil:
    section.add "X-Amz-Credential", valid_607726
  var valid_607727 = header.getOrDefault("X-Amz-Security-Token")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "X-Amz-Security-Token", valid_607727
  var valid_607728 = header.getOrDefault("X-Amz-Algorithm")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "X-Amz-Algorithm", valid_607728
  var valid_607729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607729 = validateParameter(valid_607729, JString, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "X-Amz-SignedHeaders", valid_607729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607731: Call_ReEncrypt_607719; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decrypts ciphertext and then reencrypts it entirely within AWS KMS. You can use this operation to change the customer master key (CMK) under which data is encrypted, such as when you <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually">manually rotate</a> a CMK or change the CMK that protects a ciphertext. You can also use it to reencrypt ciphertext under the same CMK, such as to change the encryption context of a ciphertext. </p> <p>The <code>ReEncrypt</code> operation can decrypt ciphertext that was encrypted by using an AWS KMS CMK in an AWS KMS operation, such as <a>Encrypt</a> or <a>GenerateDataKey</a>. It can also decrypt ciphertext that was encrypted by using the public key of an asymmetric CMK outside of AWS KMS. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>When you use the <code>ReEncrypt</code> operation, you need to provide information for the decrypt operation and the subsequent encrypt operation.</p> <ul> <li> <p>If your ciphertext was encrypted under an asymmetric CMK, you must identify the <i>source CMK</i>, that is, the CMK that encrypted the ciphertext. You must also supply the encryption algorithm that was used. This information is required to decrypt the data.</p> </li> <li> <p>It is optional, but you can specify a source CMK even when the ciphertext was encrypted under a symmetric CMK. This ensures that the ciphertext is decrypted only by using a particular CMK. If the CMK that you specify cannot decrypt the ciphertext, the <code>ReEncrypt</code> operation fails.</p> </li> <li> <p>To reencrypt the data, you must specify the <i>destination CMK</i>, that is, the CMK that re-encrypts the data after it is decrypted. You can select a symmetric or asymmetric CMK. If the destination CMK is an asymmetric CMK, you must also provide the encryption algorithm. The algorithm that you choose must be compatible with the CMK.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> </li> </ul> <p>Unlike other AWS KMS API operations, <code>ReEncrypt</code> callers must have two permissions:</p> <ul> <li> <p> <code>kms:EncryptFrom</code> permission on the source CMK</p> </li> <li> <p> <code>kms:EncryptTo</code> permission on the destination CMK</p> </li> </ul> <p>To permit reencryption from</p> <p> or to a CMK, include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policy</a>. This permission is automatically included in the key policy when you use the console to create a CMK. But you must include it manually when you create a CMK programmatically or when you use the <a>PutKeyPolicy</a> operation set a key policy.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607731.validator(path, query, header, formData, body)
  let scheme = call_607731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607731.url(scheme.get, call_607731.host, call_607731.base,
                         call_607731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607731, url, valid)

proc call*(call_607732: Call_ReEncrypt_607719; body: JsonNode): Recallable =
  ## reEncrypt
  ## <p>Decrypts ciphertext and then reencrypts it entirely within AWS KMS. You can use this operation to change the customer master key (CMK) under which data is encrypted, such as when you <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually">manually rotate</a> a CMK or change the CMK that protects a ciphertext. You can also use it to reencrypt ciphertext under the same CMK, such as to change the encryption context of a ciphertext. </p> <p>The <code>ReEncrypt</code> operation can decrypt ciphertext that was encrypted by using an AWS KMS CMK in an AWS KMS operation, such as <a>Encrypt</a> or <a>GenerateDataKey</a>. It can also decrypt ciphertext that was encrypted by using the public key of an asymmetric CMK outside of AWS KMS. However, it cannot decrypt ciphertext produced by other libraries, such as the <a href="https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/">AWS Encryption SDK</a> or <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html">Amazon S3 client-side encryption</a>. These libraries return a ciphertext format that is incompatible with AWS KMS.</p> <p>When you use the <code>ReEncrypt</code> operation, you need to provide information for the decrypt operation and the subsequent encrypt operation.</p> <ul> <li> <p>If your ciphertext was encrypted under an asymmetric CMK, you must identify the <i>source CMK</i>, that is, the CMK that encrypted the ciphertext. You must also supply the encryption algorithm that was used. This information is required to decrypt the data.</p> </li> <li> <p>It is optional, but you can specify a source CMK even when the ciphertext was encrypted under a symmetric CMK. This ensures that the ciphertext is decrypted only by using a particular CMK. If the CMK that you specify cannot decrypt the ciphertext, the <code>ReEncrypt</code> operation fails.</p> </li> <li> <p>To reencrypt the data, you must specify the <i>destination CMK</i>, that is, the CMK that re-encrypts the data after it is decrypted. You can select a symmetric or asymmetric CMK. If the destination CMK is an asymmetric CMK, you must also provide the encryption algorithm. The algorithm that you choose must be compatible with the CMK.</p> <important> <p>When you use an asymmetric CMK to encrypt or reencrypt data, be sure to record the CMK and encryption algorithm that you choose. You will be required to provide the same CMK and encryption algorithm when you decrypt the data. If the CMK and algorithm do not match the values used to encrypt the data, the decrypt operation fails.</p> <p>You are not required to supply the CMK ID and encryption algorithm when you decrypt with symmetric CMKs because AWS KMS stores this information in the ciphertext blob. AWS KMS cannot store metadata in ciphertext generated with asymmetric keys. The standard format for asymmetric key ciphertext does not include configurable fields.</p> </important> </li> </ul> <p>Unlike other AWS KMS API operations, <code>ReEncrypt</code> callers must have two permissions:</p> <ul> <li> <p> <code>kms:EncryptFrom</code> permission on the source CMK</p> </li> <li> <p> <code>kms:EncryptTo</code> permission on the destination CMK</p> </li> </ul> <p>To permit reencryption from</p> <p> or to a CMK, include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policy</a>. This permission is automatically included in the key policy when you use the console to create a CMK. But you must include it manually when you create a CMK programmatically or when you use the <a>PutKeyPolicy</a> operation set a key policy.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607733 = newJObject()
  if body != nil:
    body_607733 = body
  result = call_607732.call(nil, nil, nil, nil, body_607733)

var reEncrypt* = Call_ReEncrypt_607719(name: "reEncrypt", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ReEncrypt",
                                    validator: validate_ReEncrypt_607720,
                                    base: "/", url: url_ReEncrypt_607721,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetireGrant_607734 = ref object of OpenApiRestCall_606589
proc url_RetireGrant_607736(protocol: Scheme; host: string; base: string;
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

proc validate_RetireGrant_607735(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607737 = header.getOrDefault("X-Amz-Target")
  valid_607737 = validateParameter(valid_607737, JString, required = true, default = newJString(
      "TrentService.RetireGrant"))
  if valid_607737 != nil:
    section.add "X-Amz-Target", valid_607737
  var valid_607738 = header.getOrDefault("X-Amz-Signature")
  valid_607738 = validateParameter(valid_607738, JString, required = false,
                                 default = nil)
  if valid_607738 != nil:
    section.add "X-Amz-Signature", valid_607738
  var valid_607739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607739 = validateParameter(valid_607739, JString, required = false,
                                 default = nil)
  if valid_607739 != nil:
    section.add "X-Amz-Content-Sha256", valid_607739
  var valid_607740 = header.getOrDefault("X-Amz-Date")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "X-Amz-Date", valid_607740
  var valid_607741 = header.getOrDefault("X-Amz-Credential")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Credential", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-Security-Token")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-Security-Token", valid_607742
  var valid_607743 = header.getOrDefault("X-Amz-Algorithm")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "X-Amz-Algorithm", valid_607743
  var valid_607744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607744 = validateParameter(valid_607744, JString, required = false,
                                 default = nil)
  if valid_607744 != nil:
    section.add "X-Amz-SignedHeaders", valid_607744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607746: Call_RetireGrant_607734; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
  ## 
  let valid = call_607746.validator(path, query, header, formData, body)
  let scheme = call_607746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607746.url(scheme.get, call_607746.host, call_607746.base,
                         call_607746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607746, url, valid)

proc call*(call_607747: Call_RetireGrant_607734; body: JsonNode): Recallable =
  ## retireGrant
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
  ##   body: JObject (required)
  var body_607748 = newJObject()
  if body != nil:
    body_607748 = body
  result = call_607747.call(nil, nil, nil, nil, body_607748)

var retireGrant* = Call_RetireGrant_607734(name: "retireGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.RetireGrant",
                                        validator: validate_RetireGrant_607735,
                                        base: "/", url: url_RetireGrant_607736,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeGrant_607749 = ref object of OpenApiRestCall_606589
proc url_RevokeGrant_607751(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeGrant_607750(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607752 = header.getOrDefault("X-Amz-Target")
  valid_607752 = validateParameter(valid_607752, JString, required = true, default = newJString(
      "TrentService.RevokeGrant"))
  if valid_607752 != nil:
    section.add "X-Amz-Target", valid_607752
  var valid_607753 = header.getOrDefault("X-Amz-Signature")
  valid_607753 = validateParameter(valid_607753, JString, required = false,
                                 default = nil)
  if valid_607753 != nil:
    section.add "X-Amz-Signature", valid_607753
  var valid_607754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607754 = validateParameter(valid_607754, JString, required = false,
                                 default = nil)
  if valid_607754 != nil:
    section.add "X-Amz-Content-Sha256", valid_607754
  var valid_607755 = header.getOrDefault("X-Amz-Date")
  valid_607755 = validateParameter(valid_607755, JString, required = false,
                                 default = nil)
  if valid_607755 != nil:
    section.add "X-Amz-Date", valid_607755
  var valid_607756 = header.getOrDefault("X-Amz-Credential")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Credential", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-Security-Token")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-Security-Token", valid_607757
  var valid_607758 = header.getOrDefault("X-Amz-Algorithm")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "X-Amz-Algorithm", valid_607758
  var valid_607759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-SignedHeaders", valid_607759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607761: Call_RevokeGrant_607749; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_607761.validator(path, query, header, formData, body)
  let scheme = call_607761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607761.url(scheme.get, call_607761.host, call_607761.base,
                         call_607761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607761, url, valid)

proc call*(call_607762: Call_RevokeGrant_607749; body: JsonNode): Recallable =
  ## revokeGrant
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   body: JObject (required)
  var body_607763 = newJObject()
  if body != nil:
    body_607763 = body
  result = call_607762.call(nil, nil, nil, nil, body_607763)

var revokeGrant* = Call_RevokeGrant_607749(name: "revokeGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.RevokeGrant",
                                        validator: validate_RevokeGrant_607750,
                                        base: "/", url: url_RevokeGrant_607751,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleKeyDeletion_607764 = ref object of OpenApiRestCall_606589
proc url_ScheduleKeyDeletion_607766(protocol: Scheme; host: string; base: string;
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

proc validate_ScheduleKeyDeletion_607765(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607767 = header.getOrDefault("X-Amz-Target")
  valid_607767 = validateParameter(valid_607767, JString, required = true, default = newJString(
      "TrentService.ScheduleKeyDeletion"))
  if valid_607767 != nil:
    section.add "X-Amz-Target", valid_607767
  var valid_607768 = header.getOrDefault("X-Amz-Signature")
  valid_607768 = validateParameter(valid_607768, JString, required = false,
                                 default = nil)
  if valid_607768 != nil:
    section.add "X-Amz-Signature", valid_607768
  var valid_607769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607769 = validateParameter(valid_607769, JString, required = false,
                                 default = nil)
  if valid_607769 != nil:
    section.add "X-Amz-Content-Sha256", valid_607769
  var valid_607770 = header.getOrDefault("X-Amz-Date")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "X-Amz-Date", valid_607770
  var valid_607771 = header.getOrDefault("X-Amz-Credential")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "X-Amz-Credential", valid_607771
  var valid_607772 = header.getOrDefault("X-Amz-Security-Token")
  valid_607772 = validateParameter(valid_607772, JString, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "X-Amz-Security-Token", valid_607772
  var valid_607773 = header.getOrDefault("X-Amz-Algorithm")
  valid_607773 = validateParameter(valid_607773, JString, required = false,
                                 default = nil)
  if valid_607773 != nil:
    section.add "X-Amz-Algorithm", valid_607773
  var valid_607774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-SignedHeaders", valid_607774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607776: Call_ScheduleKeyDeletion_607764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607776.validator(path, query, header, formData, body)
  let scheme = call_607776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607776.url(scheme.get, call_607776.host, call_607776.base,
                         call_607776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607776, url, valid)

proc call*(call_607777: Call_ScheduleKeyDeletion_607764; body: JsonNode): Recallable =
  ## scheduleKeyDeletion
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607778 = newJObject()
  if body != nil:
    body_607778 = body
  result = call_607777.call(nil, nil, nil, nil, body_607778)

var scheduleKeyDeletion* = Call_ScheduleKeyDeletion_607764(
    name: "scheduleKeyDeletion", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ScheduleKeyDeletion",
    validator: validate_ScheduleKeyDeletion_607765, base: "/",
    url: url_ScheduleKeyDeletion_607766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Sign_607779 = ref object of OpenApiRestCall_606589
proc url_Sign_607781(protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Sign_607780(path: JsonNode; query: JsonNode; header: JsonNode;
                         formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607782 = header.getOrDefault("X-Amz-Target")
  valid_607782 = validateParameter(valid_607782, JString, required = true,
                                 default = newJString("TrentService.Sign"))
  if valid_607782 != nil:
    section.add "X-Amz-Target", valid_607782
  var valid_607783 = header.getOrDefault("X-Amz-Signature")
  valid_607783 = validateParameter(valid_607783, JString, required = false,
                                 default = nil)
  if valid_607783 != nil:
    section.add "X-Amz-Signature", valid_607783
  var valid_607784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607784 = validateParameter(valid_607784, JString, required = false,
                                 default = nil)
  if valid_607784 != nil:
    section.add "X-Amz-Content-Sha256", valid_607784
  var valid_607785 = header.getOrDefault("X-Amz-Date")
  valid_607785 = validateParameter(valid_607785, JString, required = false,
                                 default = nil)
  if valid_607785 != nil:
    section.add "X-Amz-Date", valid_607785
  var valid_607786 = header.getOrDefault("X-Amz-Credential")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Credential", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-Security-Token")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-Security-Token", valid_607787
  var valid_607788 = header.getOrDefault("X-Amz-Algorithm")
  valid_607788 = validateParameter(valid_607788, JString, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "X-Amz-Algorithm", valid_607788
  var valid_607789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-SignedHeaders", valid_607789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607791: Call_Sign_607779; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://en.wikipedia.org/wiki/Digital_signature">digital signature</a> for a message or message digest by using the private key in an asymmetric CMK. To verify the signature, use the <a>Verify</a> operation, or use the public key in the same asymmetric CMK outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Digital signatures are generated and verified by using asymmetric key pair, such as an RSA or ECC pair that is represented by an asymmetric customer master key (CMK). The key owner (or an authorized user) uses their private key to sign a message. Anyone with the public key can verify that the message was signed with that particular private key and that the message hasn't changed since it was signed. </p> <p>To use the <code>Sign</code> operation, provide the following information:</p> <ul> <li> <p>Use the <code>KeyId</code> parameter to identify an asymmetric CMK with a <code>KeyUsage</code> value of <code>SIGN_VERIFY</code>. To get the <code>KeyUsage</code> value of a CMK, use the <a>DescribeKey</a> operation. The caller must have <code>kms:Sign</code> permission on the CMK.</p> </li> <li> <p>Use the <code>Message</code> parameter to specify the message or message digest to sign. You can submit messages of up to 4096 bytes. To sign a larger message, generate a hash digest of the message, and then provide the hash digest in the <code>Message</code> parameter. To indicate whether the message is a full message or a digest, use the <code>MessageType</code> parameter.</p> </li> <li> <p>Choose a signing algorithm that is compatible with the CMK. </p> </li> </ul> <important> <p>When signing a message, be sure to record the CMK and the signing algorithm. This information is required to verify the signature.</p> </important> <p>To verify the signature that this operation generates, use the <a>Verify</a> operation. Or use the <a>GetPublicKey</a> operation to download the public key and then use the public key to verify the signature outside of AWS KMS. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607791.validator(path, query, header, formData, body)
  let scheme = call_607791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607791.url(scheme.get, call_607791.host, call_607791.base,
                         call_607791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607791, url, valid)

proc call*(call_607792: Call_Sign_607779; body: JsonNode): Recallable =
  ## sign
  ## <p>Creates a <a href="https://en.wikipedia.org/wiki/Digital_signature">digital signature</a> for a message or message digest by using the private key in an asymmetric CMK. To verify the signature, use the <a>Verify</a> operation, or use the public key in the same asymmetric CMK outside of AWS KMS. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Digital signatures are generated and verified by using asymmetric key pair, such as an RSA or ECC pair that is represented by an asymmetric customer master key (CMK). The key owner (or an authorized user) uses their private key to sign a message. Anyone with the public key can verify that the message was signed with that particular private key and that the message hasn't changed since it was signed. </p> <p>To use the <code>Sign</code> operation, provide the following information:</p> <ul> <li> <p>Use the <code>KeyId</code> parameter to identify an asymmetric CMK with a <code>KeyUsage</code> value of <code>SIGN_VERIFY</code>. To get the <code>KeyUsage</code> value of a CMK, use the <a>DescribeKey</a> operation. The caller must have <code>kms:Sign</code> permission on the CMK.</p> </li> <li> <p>Use the <code>Message</code> parameter to specify the message or message digest to sign. You can submit messages of up to 4096 bytes. To sign a larger message, generate a hash digest of the message, and then provide the hash digest in the <code>Message</code> parameter. To indicate whether the message is a full message or a digest, use the <code>MessageType</code> parameter.</p> </li> <li> <p>Choose a signing algorithm that is compatible with the CMK. </p> </li> </ul> <important> <p>When signing a message, be sure to record the CMK and the signing algorithm. This information is required to verify the signature.</p> </important> <p>To verify the signature that this operation generates, use the <a>Verify</a> operation. Or use the <a>GetPublicKey</a> operation to download the public key and then use the public key to verify the signature outside of AWS KMS. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607793 = newJObject()
  if body != nil:
    body_607793 = body
  result = call_607792.call(nil, nil, nil, nil, body_607793)

var sign* = Call_Sign_607779(name: "sign", meth: HttpMethod.HttpPost,
                          host: "kms.amazonaws.com",
                          route: "/#X-Amz-Target=TrentService.Sign",
                          validator: validate_Sign_607780, base: "/", url: url_Sign_607781,
                          schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607794 = ref object of OpenApiRestCall_606589
proc url_TagResource_607796(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607795(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607797 = header.getOrDefault("X-Amz-Target")
  valid_607797 = validateParameter(valid_607797, JString, required = true, default = newJString(
      "TrentService.TagResource"))
  if valid_607797 != nil:
    section.add "X-Amz-Target", valid_607797
  var valid_607798 = header.getOrDefault("X-Amz-Signature")
  valid_607798 = validateParameter(valid_607798, JString, required = false,
                                 default = nil)
  if valid_607798 != nil:
    section.add "X-Amz-Signature", valid_607798
  var valid_607799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607799 = validateParameter(valid_607799, JString, required = false,
                                 default = nil)
  if valid_607799 != nil:
    section.add "X-Amz-Content-Sha256", valid_607799
  var valid_607800 = header.getOrDefault("X-Amz-Date")
  valid_607800 = validateParameter(valid_607800, JString, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "X-Amz-Date", valid_607800
  var valid_607801 = header.getOrDefault("X-Amz-Credential")
  valid_607801 = validateParameter(valid_607801, JString, required = false,
                                 default = nil)
  if valid_607801 != nil:
    section.add "X-Amz-Credential", valid_607801
  var valid_607802 = header.getOrDefault("X-Amz-Security-Token")
  valid_607802 = validateParameter(valid_607802, JString, required = false,
                                 default = nil)
  if valid_607802 != nil:
    section.add "X-Amz-Security-Token", valid_607802
  var valid_607803 = header.getOrDefault("X-Amz-Algorithm")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Algorithm", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-SignedHeaders", valid_607804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607806: Call_TagResource_607794; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607806.validator(path, query, header, formData, body)
  let scheme = call_607806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607806.url(scheme.get, call_607806.host, call_607806.base,
                         call_607806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607806, url, valid)

proc call*(call_607807: Call_TagResource_607794; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607808 = newJObject()
  if body != nil:
    body_607808 = body
  result = call_607807.call(nil, nil, nil, nil, body_607808)

var tagResource* = Call_TagResource_607794(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.TagResource",
                                        validator: validate_TagResource_607795,
                                        base: "/", url: url_TagResource_607796,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607809 = ref object of OpenApiRestCall_606589
proc url_UntagResource_607811(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607810(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607812 = header.getOrDefault("X-Amz-Target")
  valid_607812 = validateParameter(valid_607812, JString, required = true, default = newJString(
      "TrentService.UntagResource"))
  if valid_607812 != nil:
    section.add "X-Amz-Target", valid_607812
  var valid_607813 = header.getOrDefault("X-Amz-Signature")
  valid_607813 = validateParameter(valid_607813, JString, required = false,
                                 default = nil)
  if valid_607813 != nil:
    section.add "X-Amz-Signature", valid_607813
  var valid_607814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607814 = validateParameter(valid_607814, JString, required = false,
                                 default = nil)
  if valid_607814 != nil:
    section.add "X-Amz-Content-Sha256", valid_607814
  var valid_607815 = header.getOrDefault("X-Amz-Date")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "X-Amz-Date", valid_607815
  var valid_607816 = header.getOrDefault("X-Amz-Credential")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = nil)
  if valid_607816 != nil:
    section.add "X-Amz-Credential", valid_607816
  var valid_607817 = header.getOrDefault("X-Amz-Security-Token")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "X-Amz-Security-Token", valid_607817
  var valid_607818 = header.getOrDefault("X-Amz-Algorithm")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Algorithm", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-SignedHeaders", valid_607819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607821: Call_UntagResource_607809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607821.validator(path, query, header, formData, body)
  let scheme = call_607821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607821.url(scheme.get, call_607821.host, call_607821.base,
                         call_607821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607821, url, valid)

proc call*(call_607822: Call_UntagResource_607809; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607823 = newJObject()
  if body != nil:
    body_607823 = body
  result = call_607822.call(nil, nil, nil, nil, body_607823)

var untagResource* = Call_UntagResource_607809(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UntagResource",
    validator: validate_UntagResource_607810, base: "/", url: url_UntagResource_607811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_607824 = ref object of OpenApiRestCall_606589
proc url_UpdateAlias_607826(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAlias_607825(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607827 = header.getOrDefault("X-Amz-Target")
  valid_607827 = validateParameter(valid_607827, JString, required = true, default = newJString(
      "TrentService.UpdateAlias"))
  if valid_607827 != nil:
    section.add "X-Amz-Target", valid_607827
  var valid_607828 = header.getOrDefault("X-Amz-Signature")
  valid_607828 = validateParameter(valid_607828, JString, required = false,
                                 default = nil)
  if valid_607828 != nil:
    section.add "X-Amz-Signature", valid_607828
  var valid_607829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607829 = validateParameter(valid_607829, JString, required = false,
                                 default = nil)
  if valid_607829 != nil:
    section.add "X-Amz-Content-Sha256", valid_607829
  var valid_607830 = header.getOrDefault("X-Amz-Date")
  valid_607830 = validateParameter(valid_607830, JString, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "X-Amz-Date", valid_607830
  var valid_607831 = header.getOrDefault("X-Amz-Credential")
  valid_607831 = validateParameter(valid_607831, JString, required = false,
                                 default = nil)
  if valid_607831 != nil:
    section.add "X-Amz-Credential", valid_607831
  var valid_607832 = header.getOrDefault("X-Amz-Security-Token")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "X-Amz-Security-Token", valid_607832
  var valid_607833 = header.getOrDefault("X-Amz-Algorithm")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "X-Amz-Algorithm", valid_607833
  var valid_607834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-SignedHeaders", valid_607834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607836: Call_UpdateAlias_607824; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an existing AWS KMS alias with a different customer master key (CMK). Each alias is associated with only one CMK at a time, although a CMK can have multiple aliases. The alias and the CMK must be in the same AWS account and region. You cannot perform this operation on an alias in a different AWS account. </p> <p>The current and new CMK must be the same type (both symmetric or both asymmetric), and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents errors in code that uses aliases. If you must assign an alias to a different type of CMK, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>You cannot use <code>UpdateAlias</code> to change an alias name. To change an alias name, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607836.validator(path, query, header, formData, body)
  let scheme = call_607836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607836.url(scheme.get, call_607836.host, call_607836.base,
                         call_607836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607836, url, valid)

proc call*(call_607837: Call_UpdateAlias_607824; body: JsonNode): Recallable =
  ## updateAlias
  ## <p>Associates an existing AWS KMS alias with a different customer master key (CMK). Each alias is associated with only one CMK at a time, although a CMK can have multiple aliases. The alias and the CMK must be in the same AWS account and region. You cannot perform this operation on an alias in a different AWS account. </p> <p>The current and new CMK must be the same type (both symmetric or both asymmetric), and they must have the same key usage (<code>ENCRYPT_DECRYPT</code> or <code>SIGN_VERIFY</code>). This restriction prevents errors in code that uses aliases. If you must assign an alias to a different type of CMK, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>You cannot use <code>UpdateAlias</code> to change an alias name. To change an alias name, use <a>DeleteAlias</a> to delete the old alias and <a>CreateAlias</a> to create a new alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607838 = newJObject()
  if body != nil:
    body_607838 = body
  result = call_607837.call(nil, nil, nil, nil, body_607838)

var updateAlias* = Call_UpdateAlias_607824(name: "updateAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.UpdateAlias",
                                        validator: validate_UpdateAlias_607825,
                                        base: "/", url: url_UpdateAlias_607826,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCustomKeyStore_607839 = ref object of OpenApiRestCall_606589
proc url_UpdateCustomKeyStore_607841(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCustomKeyStore_607840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607842 = header.getOrDefault("X-Amz-Target")
  valid_607842 = validateParameter(valid_607842, JString, required = true, default = newJString(
      "TrentService.UpdateCustomKeyStore"))
  if valid_607842 != nil:
    section.add "X-Amz-Target", valid_607842
  var valid_607843 = header.getOrDefault("X-Amz-Signature")
  valid_607843 = validateParameter(valid_607843, JString, required = false,
                                 default = nil)
  if valid_607843 != nil:
    section.add "X-Amz-Signature", valid_607843
  var valid_607844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607844 = validateParameter(valid_607844, JString, required = false,
                                 default = nil)
  if valid_607844 != nil:
    section.add "X-Amz-Content-Sha256", valid_607844
  var valid_607845 = header.getOrDefault("X-Amz-Date")
  valid_607845 = validateParameter(valid_607845, JString, required = false,
                                 default = nil)
  if valid_607845 != nil:
    section.add "X-Amz-Date", valid_607845
  var valid_607846 = header.getOrDefault("X-Amz-Credential")
  valid_607846 = validateParameter(valid_607846, JString, required = false,
                                 default = nil)
  if valid_607846 != nil:
    section.add "X-Amz-Credential", valid_607846
  var valid_607847 = header.getOrDefault("X-Amz-Security-Token")
  valid_607847 = validateParameter(valid_607847, JString, required = false,
                                 default = nil)
  if valid_607847 != nil:
    section.add "X-Amz-Security-Token", valid_607847
  var valid_607848 = header.getOrDefault("X-Amz-Algorithm")
  valid_607848 = validateParameter(valid_607848, JString, required = false,
                                 default = nil)
  if valid_607848 != nil:
    section.add "X-Amz-Algorithm", valid_607848
  var valid_607849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-SignedHeaders", valid_607849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607851: Call_UpdateCustomKeyStore_607839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_607851.validator(path, query, header, formData, body)
  let scheme = call_607851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607851.url(scheme.get, call_607851.host, call_607851.base,
                         call_607851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607851, url, valid)

proc call*(call_607852: Call_UpdateCustomKeyStore_607839; body: JsonNode): Recallable =
  ## updateCustomKeyStore
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_607853 = newJObject()
  if body != nil:
    body_607853 = body
  result = call_607852.call(nil, nil, nil, nil, body_607853)

var updateCustomKeyStore* = Call_UpdateCustomKeyStore_607839(
    name: "updateCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateCustomKeyStore",
    validator: validate_UpdateCustomKeyStore_607840, base: "/",
    url: url_UpdateCustomKeyStore_607841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateKeyDescription_607854 = ref object of OpenApiRestCall_606589
proc url_UpdateKeyDescription_607856(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateKeyDescription_607855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607857 = header.getOrDefault("X-Amz-Target")
  valid_607857 = validateParameter(valid_607857, JString, required = true, default = newJString(
      "TrentService.UpdateKeyDescription"))
  if valid_607857 != nil:
    section.add "X-Amz-Target", valid_607857
  var valid_607858 = header.getOrDefault("X-Amz-Signature")
  valid_607858 = validateParameter(valid_607858, JString, required = false,
                                 default = nil)
  if valid_607858 != nil:
    section.add "X-Amz-Signature", valid_607858
  var valid_607859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607859 = validateParameter(valid_607859, JString, required = false,
                                 default = nil)
  if valid_607859 != nil:
    section.add "X-Amz-Content-Sha256", valid_607859
  var valid_607860 = header.getOrDefault("X-Amz-Date")
  valid_607860 = validateParameter(valid_607860, JString, required = false,
                                 default = nil)
  if valid_607860 != nil:
    section.add "X-Amz-Date", valid_607860
  var valid_607861 = header.getOrDefault("X-Amz-Credential")
  valid_607861 = validateParameter(valid_607861, JString, required = false,
                                 default = nil)
  if valid_607861 != nil:
    section.add "X-Amz-Credential", valid_607861
  var valid_607862 = header.getOrDefault("X-Amz-Security-Token")
  valid_607862 = validateParameter(valid_607862, JString, required = false,
                                 default = nil)
  if valid_607862 != nil:
    section.add "X-Amz-Security-Token", valid_607862
  var valid_607863 = header.getOrDefault("X-Amz-Algorithm")
  valid_607863 = validateParameter(valid_607863, JString, required = false,
                                 default = nil)
  if valid_607863 != nil:
    section.add "X-Amz-Algorithm", valid_607863
  var valid_607864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607864 = validateParameter(valid_607864, JString, required = false,
                                 default = nil)
  if valid_607864 != nil:
    section.add "X-Amz-SignedHeaders", valid_607864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607866: Call_UpdateKeyDescription_607854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607866.validator(path, query, header, formData, body)
  let scheme = call_607866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607866.url(scheme.get, call_607866.host, call_607866.base,
                         call_607866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607866, url, valid)

proc call*(call_607867: Call_UpdateKeyDescription_607854; body: JsonNode): Recallable =
  ## updateKeyDescription
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607868 = newJObject()
  if body != nil:
    body_607868 = body
  result = call_607867.call(nil, nil, nil, nil, body_607868)

var updateKeyDescription* = Call_UpdateKeyDescription_607854(
    name: "updateKeyDescription", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateKeyDescription",
    validator: validate_UpdateKeyDescription_607855, base: "/",
    url: url_UpdateKeyDescription_607856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Verify_607869 = ref object of OpenApiRestCall_606589
proc url_Verify_607871(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Verify_607870(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607872 = header.getOrDefault("X-Amz-Target")
  valid_607872 = validateParameter(valid_607872, JString, required = true,
                                 default = newJString("TrentService.Verify"))
  if valid_607872 != nil:
    section.add "X-Amz-Target", valid_607872
  var valid_607873 = header.getOrDefault("X-Amz-Signature")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "X-Amz-Signature", valid_607873
  var valid_607874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607874 = validateParameter(valid_607874, JString, required = false,
                                 default = nil)
  if valid_607874 != nil:
    section.add "X-Amz-Content-Sha256", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-Date")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-Date", valid_607875
  var valid_607876 = header.getOrDefault("X-Amz-Credential")
  valid_607876 = validateParameter(valid_607876, JString, required = false,
                                 default = nil)
  if valid_607876 != nil:
    section.add "X-Amz-Credential", valid_607876
  var valid_607877 = header.getOrDefault("X-Amz-Security-Token")
  valid_607877 = validateParameter(valid_607877, JString, required = false,
                                 default = nil)
  if valid_607877 != nil:
    section.add "X-Amz-Security-Token", valid_607877
  var valid_607878 = header.getOrDefault("X-Amz-Algorithm")
  valid_607878 = validateParameter(valid_607878, JString, required = false,
                                 default = nil)
  if valid_607878 != nil:
    section.add "X-Amz-Algorithm", valid_607878
  var valid_607879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607879 = validateParameter(valid_607879, JString, required = false,
                                 default = nil)
  if valid_607879 != nil:
    section.add "X-Amz-SignedHeaders", valid_607879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607881: Call_Verify_607869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Verifies a digital signature that was generated by the <a>Sign</a> operation. </p> <p/> <p>Verification confirms that an authorized user signed the message with the specified CMK and signing algorithm, and the message hasn't changed since it was signed. If the signature is verified, the value of the <code>SignatureValid</code> field in the response is <code>True</code>. If the signature verification fails, the <code>Verify</code> operation fails with an <code>KMSInvalidSignatureException</code> exception.</p> <p>A digital signature is generated by using the private key in an asymmetric CMK. The signature is verified by using the public key in the same asymmetric CMK. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To verify a digital signature, you can use the <code>Verify</code> operation. Specify the same asymmetric CMK, message, and signing algorithm that were used to produce the signature.</p> <p>You can also verify the digital signature by using the public key of the CMK outside of AWS KMS. Use the <a>GetPublicKey</a> operation to download the public key in the asymmetric CMK and then use the public key to verify the signature outside of AWS KMS. The advantage of using the <code>Verify</code> operation is that it is performed within AWS KMS. As a result, it's easy to call, the operation is performed within the FIPS boundary, it is logged in AWS CloudTrail, and you can use key policy and IAM policy to determine who is authorized to use the CMK to verify signatures.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_607881.validator(path, query, header, formData, body)
  let scheme = call_607881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607881.url(scheme.get, call_607881.host, call_607881.base,
                         call_607881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607881, url, valid)

proc call*(call_607882: Call_Verify_607869; body: JsonNode): Recallable =
  ## verify
  ## <p>Verifies a digital signature that was generated by the <a>Sign</a> operation. </p> <p/> <p>Verification confirms that an authorized user signed the message with the specified CMK and signing algorithm, and the message hasn't changed since it was signed. If the signature is verified, the value of the <code>SignatureValid</code> field in the response is <code>True</code>. If the signature verification fails, the <code>Verify</code> operation fails with an <code>KMSInvalidSignatureException</code> exception.</p> <p>A digital signature is generated by using the private key in an asymmetric CMK. The signature is verified by using the public key in the same asymmetric CMK. For information about symmetric and asymmetric CMKs, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html">Using Symmetric and Asymmetric CMKs</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To verify a digital signature, you can use the <code>Verify</code> operation. Specify the same asymmetric CMK, message, and signing algorithm that were used to produce the signature.</p> <p>You can also verify the digital signature by using the public key of the CMK outside of AWS KMS. Use the <a>GetPublicKey</a> operation to download the public key in the asymmetric CMK and then use the public key to verify the signature outside of AWS KMS. The advantage of using the <code>Verify</code> operation is that it is performed within AWS KMS. As a result, it's easy to call, the operation is performed within the FIPS boundary, it is logged in AWS CloudTrail, and you can use key policy and IAM policy to determine who is authorized to use the CMK to verify signatures.</p> <p>The CMK that you use for this operation must be in a compatible key state. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_607883 = newJObject()
  if body != nil:
    body_607883 = body
  result = call_607882.call(nil, nil, nil, nil, body_607883)

var verify* = Call_Verify_607869(name: "verify", meth: HttpMethod.HttpPost,
                              host: "kms.amazonaws.com",
                              route: "/#X-Amz-Target=TrentService.Verify",
                              validator: validate_Verify_607870, base: "/",
                              url: url_Verify_607871,
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
