
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CancelKeyDeletion_600768 = ref object of OpenApiRestCall_600426
proc url_CancelKeyDeletion_600770(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelKeyDeletion_600769(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation is successful, the CMK is set to the <code>Disabled</code> state. To enable a CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "TrentService.CancelKeyDeletion"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_CancelKeyDeletion_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation is successful, the CMK is set to the <code>Disabled</code> state. To enable a CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_CancelKeyDeletion_600768; body: JsonNode): Recallable =
  ## cancelKeyDeletion
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation is successful, the CMK is set to the <code>Disabled</code> state. To enable a CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var cancelKeyDeletion* = Call_CancelKeyDeletion_600768(name: "cancelKeyDeletion",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CancelKeyDeletion",
    validator: validate_CancelKeyDeletion_600769, base: "/",
    url: url_CancelKeyDeletion_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectCustomKeyStore_601037 = ref object of OpenApiRestCall_600426
proc url_ConnectCustomKeyStore_601039(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ConnectCustomKeyStore_601038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU), and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "TrentService.ConnectCustomKeyStore"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_ConnectCustomKeyStore_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU), and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_ConnectCustomKeyStore_601037; body: JsonNode): Recallable =
  ## connectCustomKeyStore
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU), and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var connectCustomKeyStore* = Call_ConnectCustomKeyStore_601037(
    name: "connectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ConnectCustomKeyStore",
    validator: validate_ConnectCustomKeyStore_601038, base: "/",
    url: url_ConnectCustomKeyStore_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_601052 = ref object of OpenApiRestCall_600426
proc url_CreateAlias_601054(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAlias_601053(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in selected operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. </p> <p>Each CMK can have multiple aliases, but each alias points to only one CMK. The alias name must be unique in the AWS account and region. To simplify code that runs in multiple regions, use the same alias name, but point it to a different CMK in each region. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation.</p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The alias and the CMK it is mapped to must be in the same AWS account and the same region. You cannot perform this operation on an alias in a different AWS account.</p> <p>To map an existing alias to a different CMK, call <a>UpdateAlias</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "TrentService.CreateAlias"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateAlias_601052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in selected operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. </p> <p>Each CMK can have multiple aliases, but each alias points to only one CMK. The alias name must be unique in the AWS account and region. To simplify code that runs in multiple regions, use the same alias name, but point it to a different CMK in each region. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation.</p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The alias and the CMK it is mapped to must be in the same AWS account and the same region. You cannot perform this operation on an alias in a different AWS account.</p> <p>To map an existing alias to a different CMK, call <a>UpdateAlias</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateAlias_601052; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in selected operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. </p> <p>Each CMK can have multiple aliases, but each alias points to only one CMK. The alias name must be unique in the AWS account and region. To simplify code that runs in multiple regions, use the same alias name, but point it to a different CMK in each region. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation.</p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The alias and the CMK it is mapped to must be in the same AWS account and the same region. You cannot perform this operation on an alias in a different AWS account.</p> <p>To map an existing alias to a different CMK, call <a>UpdateAlias</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createAlias* = Call_CreateAlias_601052(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateAlias",
                                        validator: validate_CreateAlias_601053,
                                        base: "/", url: url_CreateAlias_601054,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomKeyStore_601067 = ref object of OpenApiRestCall_600426
proc url_CreateCustomKeyStore_601069(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCustomKeyStore_601068(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "TrentService.CreateCustomKeyStore"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreateCustomKeyStore_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreateCustomKeyStore_601067; body: JsonNode): Recallable =
  ## createCustomKeyStore
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createCustomKeyStore* = Call_CreateCustomKeyStore_601067(
    name: "createCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CreateCustomKeyStore",
    validator: validate_CreateCustomKeyStore_601068, base: "/",
    url: url_CreateCustomKeyStore_601069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGrant_601082 = ref object of OpenApiRestCall_600426
proc url_CreateGrant_601084(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGrant_601083(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the encryption context in the operation request matches or includes a specified encryption context, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "TrentService.CreateGrant"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_CreateGrant_601082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the encryption context in the operation request matches or includes a specified encryption context, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_CreateGrant_601082; body: JsonNode): Recallable =
  ## createGrant
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the encryption context in the operation request matches or includes a specified encryption context, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var createGrant* = Call_CreateGrant_601082(name: "createGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateGrant",
                                        validator: validate_CreateGrant_601083,
                                        base: "/", url: url_CreateGrant_601084,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKey_601097 = ref object of OpenApiRestCall_600426
proc url_CreateKey_601099(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateKey_601098(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master key</a> (CMK) in your AWS account.</p> <p>You can use a CMK to encrypt small amounts of data (up to 4096 bytes) directly. But CMKs are more commonly used to encrypt the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> that are used to encrypt data.</p> <p>To create a CMK for imported key material, use the <code>Origin</code> parameter with a value of <code>EXTERNAL</code>.</p> <p>To create a CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region.</p> <p>You cannot use this operation to create a CMK in a different AWS account.</p>
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
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = newJString("TrentService.CreateKey"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_CreateKey_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master key</a> (CMK) in your AWS account.</p> <p>You can use a CMK to encrypt small amounts of data (up to 4096 bytes) directly. But CMKs are more commonly used to encrypt the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> that are used to encrypt data.</p> <p>To create a CMK for imported key material, use the <code>Origin</code> parameter with a value of <code>EXTERNAL</code>.</p> <p>To create a CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region.</p> <p>You cannot use this operation to create a CMK in a different AWS account.</p>
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_CreateKey_601097; body: JsonNode): Recallable =
  ## createKey
  ## <p>Creates a customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master key</a> (CMK) in your AWS account.</p> <p>You can use a CMK to encrypt small amounts of data (up to 4096 bytes) directly. But CMKs are more commonly used to encrypt the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> that are used to encrypt data.</p> <p>To create a CMK for imported key material, use the <code>Origin</code> parameter with a value of <code>EXTERNAL</code>.</p> <p>To create a CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region.</p> <p>You cannot use this operation to create a CMK in a different AWS account.</p>
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var createKey* = Call_CreateKey_601097(name: "createKey", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateKey",
                                    validator: validate_CreateKey_601098,
                                    base: "/", url: url_CreateKey_601099,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Decrypt_601112 = ref object of OpenApiRestCall_600426
proc url_Decrypt_601114(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_Decrypt_601113(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Decrypts ciphertext. Ciphertext is plaintext that has been previously encrypted by using any of the following operations:</p> <ul> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>Encrypt</a> </p> </li> </ul> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on the CMK, instead of IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = newJString("TrentService.Decrypt"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_Decrypt_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decrypts ciphertext. Ciphertext is plaintext that has been previously encrypted by using any of the following operations:</p> <ul> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>Encrypt</a> </p> </li> </ul> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on the CMK, instead of IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_Decrypt_601112; body: JsonNode): Recallable =
  ## decrypt
  ## <p>Decrypts ciphertext. Ciphertext is plaintext that has been previously encrypted by using any of the following operations:</p> <ul> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>Encrypt</a> </p> </li> </ul> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on the CMK, instead of IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var decrypt* = Call_Decrypt_601112(name: "decrypt", meth: HttpMethod.HttpPost,
                                host: "kms.amazonaws.com",
                                route: "/#X-Amz-Target=TrentService.Decrypt",
                                validator: validate_Decrypt_601113, base: "/",
                                url: url_Decrypt_601114,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_601127 = ref object of OpenApiRestCall_600426
proc url_DeleteAlias_601129(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAlias_601128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "TrentService.DeleteAlias"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DeleteAlias_601127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DeleteAlias_601127; body: JsonNode): Recallable =
  ## deleteAlias
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var deleteAlias* = Call_DeleteAlias_601127(name: "deleteAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DeleteAlias",
                                        validator: validate_DeleteAlias_601128,
                                        base: "/", url: url_DeleteAlias_601129,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomKeyStore_601142 = ref object of OpenApiRestCall_600426
proc url_DeleteCustomKeyStore_601144(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCustomKeyStore_601143(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "TrentService.DeleteCustomKeyStore"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_DeleteCustomKeyStore_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_DeleteCustomKeyStore_601142; body: JsonNode): Recallable =
  ## deleteCustomKeyStore
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var deleteCustomKeyStore* = Call_DeleteCustomKeyStore_601142(
    name: "deleteCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteCustomKeyStore",
    validator: validate_DeleteCustomKeyStore_601143, base: "/",
    url: url_DeleteCustomKeyStore_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImportedKeyMaterial_601157 = ref object of OpenApiRestCall_600426
proc url_DeleteImportedKeyMaterial_601159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteImportedKeyMaterial_601158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "TrentService.DeleteImportedKeyMaterial"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_DeleteImportedKeyMaterial_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DeleteImportedKeyMaterial_601157; body: JsonNode): Recallable =
  ## deleteImportedKeyMaterial
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var deleteImportedKeyMaterial* = Call_DeleteImportedKeyMaterial_601157(
    name: "deleteImportedKeyMaterial", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteImportedKeyMaterial",
    validator: validate_DeleteImportedKeyMaterial_601158, base: "/",
    url: url_DeleteImportedKeyMaterial_601159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCustomKeyStores_601172 = ref object of OpenApiRestCall_600426
proc url_DescribeCustomKeyStores_601174(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCustomKeyStores_601173(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "TrentService.DescribeCustomKeyStores"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_DescribeCustomKeyStores_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_DescribeCustomKeyStores_601172; body: JsonNode): Recallable =
  ## describeCustomKeyStores
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var describeCustomKeyStores* = Call_DescribeCustomKeyStores_601172(
    name: "describeCustomKeyStores", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DescribeCustomKeyStores",
    validator: validate_DescribeCustomKeyStores_601173, base: "/",
    url: url_DescribeCustomKeyStores_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKey_601187 = ref object of OpenApiRestCall_600426
proc url_DescribeKey_601189(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeKey_601188(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Provides detailed information about the specified customer master key (CMK).</p> <p>You can use <code>DescribeKey</code> on a predefined AWS alias, that is, an AWS alias with no key ID. When you do, AWS KMS associates the alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a> and returns its <code>KeyId</code> and <code>Arn</code> in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
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
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "TrentService.DescribeKey"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_DescribeKey_601187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides detailed information about the specified customer master key (CMK).</p> <p>You can use <code>DescribeKey</code> on a predefined AWS alias, that is, an AWS alias with no key ID. When you do, AWS KMS associates the alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a> and returns its <code>KeyId</code> and <code>Arn</code> in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_DescribeKey_601187; body: JsonNode): Recallable =
  ## describeKey
  ## <p>Provides detailed information about the specified customer master key (CMK).</p> <p>You can use <code>DescribeKey</code> on a predefined AWS alias, that is, an AWS alias with no key ID. When you do, AWS KMS associates the alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a> and returns its <code>KeyId</code> and <code>Arn</code> in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var describeKey* = Call_DescribeKey_601187(name: "describeKey",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DescribeKey",
                                        validator: validate_DescribeKey_601188,
                                        base: "/", url: url_DescribeKey_601189,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKey_601202 = ref object of OpenApiRestCall_600426
proc url_DisableKey_601204(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableKey_601203(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601207 = header.getOrDefault("X-Amz-Target")
  valid_601207 = validateParameter(valid_601207, JString, required = true, default = newJString(
      "TrentService.DisableKey"))
  if valid_601207 != nil:
    section.add "X-Amz-Target", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_DisableKey_601202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"))
  result = hook(call_601214, url, valid)

proc call*(call_601215: Call_DisableKey_601202; body: JsonNode): Recallable =
  ## disableKey
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var disableKey* = Call_DisableKey_601202(name: "disableKey",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DisableKey",
                                      validator: validate_DisableKey_601203,
                                      base: "/", url: url_DisableKey_601204,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKeyRotation_601217 = ref object of OpenApiRestCall_600426
proc url_DisableKeyRotation_601219(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableKeyRotation_601218(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "TrentService.DisableKeyRotation"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_DisableKeyRotation_601217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_DisableKeyRotation_601217; body: JsonNode): Recallable =
  ## disableKeyRotation
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var disableKeyRotation* = Call_DisableKeyRotation_601217(
    name: "disableKeyRotation", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisableKeyRotation",
    validator: validate_DisableKeyRotation_601218, base: "/",
    url: url_DisableKeyRotation_601219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectCustomKeyStore_601232 = ref object of OpenApiRestCall_600426
proc url_DisconnectCustomKeyStore_601234(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisconnectCustomKeyStore_601233(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601237 = header.getOrDefault("X-Amz-Target")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "TrentService.DisconnectCustomKeyStore"))
  if valid_601237 != nil:
    section.add "X-Amz-Target", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_DisconnectCustomKeyStore_601232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_DisconnectCustomKeyStore_601232; body: JsonNode): Recallable =
  ## disconnectCustomKeyStore
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var disconnectCustomKeyStore* = Call_DisconnectCustomKeyStore_601232(
    name: "disconnectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisconnectCustomKeyStore",
    validator: validate_DisconnectCustomKeyStore_601233, base: "/",
    url: url_DisconnectCustomKeyStore_601234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKey_601247 = ref object of OpenApiRestCall_600426
proc url_EnableKey_601249(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableKey_601248(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601252 = header.getOrDefault("X-Amz-Target")
  valid_601252 = validateParameter(valid_601252, JString, required = true,
                                 default = newJString("TrentService.EnableKey"))
  if valid_601252 != nil:
    section.add "X-Amz-Target", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_EnableKey_601247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_EnableKey_601247; body: JsonNode): Recallable =
  ## enableKey
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601261 = newJObject()
  if body != nil:
    body_601261 = body
  result = call_601260.call(nil, nil, nil, nil, body_601261)

var enableKey* = Call_EnableKey_601247(name: "enableKey", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.EnableKey",
                                    validator: validate_EnableKey_601248,
                                    base: "/", url: url_EnableKey_601249,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKeyRotation_601262 = ref object of OpenApiRestCall_600426
proc url_EnableKeyRotation_601264(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableKeyRotation_601263(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of CMKs with imported key material or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601267 = header.getOrDefault("X-Amz-Target")
  valid_601267 = validateParameter(valid_601267, JString, required = true, default = newJString(
      "TrentService.EnableKeyRotation"))
  if valid_601267 != nil:
    section.add "X-Amz-Target", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_EnableKeyRotation_601262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of CMKs with imported key material or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"))
  result = hook(call_601274, url, valid)

proc call*(call_601275: Call_EnableKeyRotation_601262; body: JsonNode): Recallable =
  ## enableKeyRotation
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of CMKs with imported key material or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601276 = newJObject()
  if body != nil:
    body_601276 = body
  result = call_601275.call(nil, nil, nil, nil, body_601276)

var enableKeyRotation* = Call_EnableKeyRotation_601262(name: "enableKeyRotation",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.EnableKeyRotation",
    validator: validate_EnableKeyRotation_601263, base: "/",
    url: url_EnableKeyRotation_601264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Encrypt_601277 = ref object of OpenApiRestCall_600426
proc url_Encrypt_601279(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_Encrypt_601278(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt up to 4 kilobytes (4096 bytes) of arbitrary data such as an RSA key, a database password, or other sensitive information.</p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need use this operation to encrypt a data key within a region. The <a>GenerateDataKey</a> and <a>GenerateDataKeyWithoutPlaintext</a> operations return an encrypted data key.</p> <p>Also, you don't need to use this operation to encrypt data in your application. You can use the plaintext and encrypted data keys that the <code>GenerateDataKey</code> operation returns.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
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
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true,
                                 default = newJString("TrentService.Encrypt"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_Encrypt_601277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt up to 4 kilobytes (4096 bytes) of arbitrary data such as an RSA key, a database password, or other sensitive information.</p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need use this operation to encrypt a data key within a region. The <a>GenerateDataKey</a> and <a>GenerateDataKeyWithoutPlaintext</a> operations return an encrypted data key.</p> <p>Also, you don't need to use this operation to encrypt data in your application. You can use the plaintext and encrypted data keys that the <code>GenerateDataKey</code> operation returns.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_Encrypt_601277; body: JsonNode): Recallable =
  ## encrypt
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt up to 4 kilobytes (4096 bytes) of arbitrary data such as an RSA key, a database password, or other sensitive information.</p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need use this operation to encrypt a data key within a region. The <a>GenerateDataKey</a> and <a>GenerateDataKeyWithoutPlaintext</a> operations return an encrypted data key.</p> <p>Also, you don't need to use this operation to encrypt data in your application. You can use the plaintext and encrypted data keys that the <code>GenerateDataKey</code> operation returns.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   body: JObject (required)
  var body_601291 = newJObject()
  if body != nil:
    body_601291 = body
  result = call_601290.call(nil, nil, nil, nil, body_601291)

var encrypt* = Call_Encrypt_601277(name: "encrypt", meth: HttpMethod.HttpPost,
                                host: "kms.amazonaws.com",
                                route: "/#X-Amz-Target=TrentService.Encrypt",
                                validator: validate_Encrypt_601278, base: "/",
                                url: url_Encrypt_601279,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKey_601292 = ref object of OpenApiRestCall_600426
proc url_GenerateDataKey_601294(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateDataKey_601293(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Generates a unique data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, you need to specify the customer master key (CMK) that will be used to encrypt the data key. You must also specify the length of the data key using either the <code>KeySpec</code> or <code>NumberOfBytes</code> field (but not both). For common key lengths (128-bit and 256-bit symmetric keys), we recommend that you use <code>KeySpec</code>. To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p> <p>You will find the plaintext copy of the data key in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to your encryption operation. When you specify an <code>EncryptionContext</code> in the <code>GenerateDataKey</code> operation, you must specify the same encryption context (a case-sensitive exact match) in your request to <a>Decrypt</a> the data key. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601297 = header.getOrDefault("X-Amz-Target")
  valid_601297 = validateParameter(valid_601297, JString, required = true, default = newJString(
      "TrentService.GenerateDataKey"))
  if valid_601297 != nil:
    section.add "X-Amz-Target", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_GenerateDataKey_601292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a unique data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, you need to specify the customer master key (CMK) that will be used to encrypt the data key. You must also specify the length of the data key using either the <code>KeySpec</code> or <code>NumberOfBytes</code> field (but not both). For common key lengths (128-bit and 256-bit symmetric keys), we recommend that you use <code>KeySpec</code>. To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p> <p>You will find the plaintext copy of the data key in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to your encryption operation. When you specify an <code>EncryptionContext</code> in the <code>GenerateDataKey</code> operation, you must specify the same encryption context (a case-sensitive exact match) in your request to <a>Decrypt</a> the data key. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_GenerateDataKey_601292; body: JsonNode): Recallable =
  ## generateDataKey
  ## <p>Generates a unique data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, you need to specify the customer master key (CMK) that will be used to encrypt the data key. You must also specify the length of the data key using either the <code>KeySpec</code> or <code>NumberOfBytes</code> field (but not both). For common key lengths (128-bit and 256-bit symmetric keys), we recommend that you use <code>KeySpec</code>. To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p> <p>You will find the plaintext copy of the data key in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to your encryption operation. When you specify an <code>EncryptionContext</code> in the <code>GenerateDataKey</code> operation, you must specify the same encryption context (a case-sensitive exact match) in your request to <a>Decrypt</a> the data key. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601306 = newJObject()
  if body != nil:
    body_601306 = body
  result = call_601305.call(nil, nil, nil, nil, body_601306)

var generateDataKey* = Call_GenerateDataKey_601292(name: "generateDataKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKey",
    validator: validate_GenerateDataKey_601293, base: "/", url: url_GenerateDataKey_601294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyWithoutPlaintext_601307 = ref object of OpenApiRestCall_600426
proc url_GenerateDataKeyWithoutPlaintext_601309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateDataKeyWithoutPlaintext_601308(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a unique data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. <code>GenerateDataKeyWithoutPlaintext</code> is identical to <a>GenerateDataKey</a> except that returns only the encrypted copy of the data key.</p> <p>Like <code>GenerateDataKey</code>, <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key.</p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601312 = header.getOrDefault("X-Amz-Target")
  valid_601312 = validateParameter(valid_601312, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyWithoutPlaintext"))
  if valid_601312 != nil:
    section.add "X-Amz-Target", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Content-Sha256", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Algorithm")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Algorithm", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Signature")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Signature", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-SignedHeaders", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Credential")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Credential", valid_601317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_GenerateDataKeyWithoutPlaintext_601307;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a unique data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. <code>GenerateDataKeyWithoutPlaintext</code> is identical to <a>GenerateDataKey</a> except that returns only the encrypted copy of the data key.</p> <p>Like <code>GenerateDataKey</code>, <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key.</p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"))
  result = hook(call_601319, url, valid)

proc call*(call_601320: Call_GenerateDataKeyWithoutPlaintext_601307; body: JsonNode): Recallable =
  ## generateDataKeyWithoutPlaintext
  ## <p>Generates a unique data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. <code>GenerateDataKeyWithoutPlaintext</code> is identical to <a>GenerateDataKey</a> except that returns only the encrypted copy of the data key.</p> <p>Like <code>GenerateDataKey</code>, <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key.</p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601321 = newJObject()
  if body != nil:
    body_601321 = body
  result = call_601320.call(nil, nil, nil, nil, body_601321)

var generateDataKeyWithoutPlaintext* = Call_GenerateDataKeyWithoutPlaintext_601307(
    name: "generateDataKeyWithoutPlaintext", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyWithoutPlaintext",
    validator: validate_GenerateDataKeyWithoutPlaintext_601308, base: "/",
    url: url_GenerateDataKeyWithoutPlaintext_601309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateRandom_601322 = ref object of OpenApiRestCall_600426
proc url_GenerateRandom_601324(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateRandom_601323(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601325 = header.getOrDefault("X-Amz-Date")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Date", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Security-Token")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Security-Token", valid_601326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601327 = header.getOrDefault("X-Amz-Target")
  valid_601327 = validateParameter(valid_601327, JString, required = true, default = newJString(
      "TrentService.GenerateRandom"))
  if valid_601327 != nil:
    section.add "X-Amz-Target", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601334: Call_GenerateRandom_601322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
  ## 
  let valid = call_601334.validator(path, query, header, formData, body)
  let scheme = call_601334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601334.url(scheme.get, call_601334.host, call_601334.base,
                         call_601334.route, valid.getOrDefault("path"))
  result = hook(call_601334, url, valid)

proc call*(call_601335: Call_GenerateRandom_601322; body: JsonNode): Recallable =
  ## generateRandom
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
  ##   body: JObject (required)
  var body_601336 = newJObject()
  if body != nil:
    body_601336 = body
  result = call_601335.call(nil, nil, nil, nil, body_601336)

var generateRandom* = Call_GenerateRandom_601322(name: "generateRandom",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateRandom",
    validator: validate_GenerateRandom_601323, base: "/", url: url_GenerateRandom_601324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPolicy_601337 = ref object of OpenApiRestCall_600426
proc url_GetKeyPolicy_601339(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetKeyPolicy_601338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601342 = header.getOrDefault("X-Amz-Target")
  valid_601342 = validateParameter(valid_601342, JString, required = true, default = newJString(
      "TrentService.GetKeyPolicy"))
  if valid_601342 != nil:
    section.add "X-Amz-Target", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_GetKeyPolicy_601337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_GetKeyPolicy_601337; body: JsonNode): Recallable =
  ## getKeyPolicy
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
  ##   body: JObject (required)
  var body_601351 = newJObject()
  if body != nil:
    body_601351 = body
  result = call_601350.call(nil, nil, nil, nil, body_601351)

var getKeyPolicy* = Call_GetKeyPolicy_601337(name: "getKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyPolicy",
    validator: validate_GetKeyPolicy_601338, base: "/", url: url_GetKeyPolicy_601339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyRotationStatus_601352 = ref object of OpenApiRestCall_600426
proc url_GetKeyRotationStatus_601354(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetKeyRotationStatus_601353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
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
  var valid_601355 = header.getOrDefault("X-Amz-Date")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Date", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Security-Token")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Security-Token", valid_601356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601357 = header.getOrDefault("X-Amz-Target")
  valid_601357 = validateParameter(valid_601357, JString, required = true, default = newJString(
      "TrentService.GetKeyRotationStatus"))
  if valid_601357 != nil:
    section.add "X-Amz-Target", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Algorithm")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Algorithm", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Signature")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Signature", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-SignedHeaders", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Credential")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Credential", valid_601362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601364: Call_GetKeyRotationStatus_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"))
  result = hook(call_601364, url, valid)

proc call*(call_601365: Call_GetKeyRotationStatus_601352; body: JsonNode): Recallable =
  ## getKeyRotationStatus
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   body: JObject (required)
  var body_601366 = newJObject()
  if body != nil:
    body_601366 = body
  result = call_601365.call(nil, nil, nil, nil, body_601366)

var getKeyRotationStatus* = Call_GetKeyRotationStatus_601352(
    name: "getKeyRotationStatus", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyRotationStatus",
    validator: validate_GetKeyRotationStatus_601353, base: "/",
    url: url_GetKeyRotationStatus_601354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersForImport_601367 = ref object of OpenApiRestCall_600426
proc url_GetParametersForImport_601369(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetParametersForImport_601368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the items you need in order to import key material into AWS KMS from your existing key management infrastructure. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You must specify the key ID of the customer master key (CMK) into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on a CMK in a different AWS account.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request. The public key and import token from the same response must be used together. These items are valid for 24 hours. When they expire, they cannot be used for a subsequent <a>ImportKeyMaterial</a> request. To get new ones, send another <code>GetParametersForImport</code> request.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601370 = header.getOrDefault("X-Amz-Date")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Date", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Security-Token")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Security-Token", valid_601371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601372 = header.getOrDefault("X-Amz-Target")
  valid_601372 = validateParameter(valid_601372, JString, required = true, default = newJString(
      "TrentService.GetParametersForImport"))
  if valid_601372 != nil:
    section.add "X-Amz-Target", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Content-Sha256", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Algorithm")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Algorithm", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Signature")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Signature", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-SignedHeaders", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Credential")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Credential", valid_601377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601379: Call_GetParametersForImport_601367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the items you need in order to import key material into AWS KMS from your existing key management infrastructure. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You must specify the key ID of the customer master key (CMK) into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on a CMK in a different AWS account.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request. The public key and import token from the same response must be used together. These items are valid for 24 hours. When they expire, they cannot be used for a subsequent <a>ImportKeyMaterial</a> request. To get new ones, send another <code>GetParametersForImport</code> request.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601379.validator(path, query, header, formData, body)
  let scheme = call_601379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601379.url(scheme.get, call_601379.host, call_601379.base,
                         call_601379.route, valid.getOrDefault("path"))
  result = hook(call_601379, url, valid)

proc call*(call_601380: Call_GetParametersForImport_601367; body: JsonNode): Recallable =
  ## getParametersForImport
  ## <p>Returns the items you need in order to import key material into AWS KMS from your existing key management infrastructure. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You must specify the key ID of the customer master key (CMK) into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on a CMK in a different AWS account.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request. The public key and import token from the same response must be used together. These items are valid for 24 hours. When they expire, they cannot be used for a subsequent <a>ImportKeyMaterial</a> request. To get new ones, send another <code>GetParametersForImport</code> request.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601381 = newJObject()
  if body != nil:
    body_601381 = body
  result = call_601380.call(nil, nil, nil, nil, body_601381)

var getParametersForImport* = Call_GetParametersForImport_601367(
    name: "getParametersForImport", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetParametersForImport",
    validator: validate_GetParametersForImport_601368, base: "/",
    url: url_GetParametersForImport_601369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyMaterial_601382 = ref object of OpenApiRestCall_600426
proc url_ImportKeyMaterial_601384(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportKeyMaterial_601383(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Imports key material into an existing AWS KMS customer master key (CMK) that was created without key material. You cannot perform this operation on a CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. This token and the public key used to encrypt the key material must have come from the same response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, you can change it only by reimporting the same key material and specifying a new expiration date. If the key material expires, AWS KMS deletes the key material and the CMK becomes unusable. To use the CMK again, you must reimport the same key material.</p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK. After you successfully import key material into a CMK, you can reimport the same key material into that CMK, but you cannot import different key material.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601385 = header.getOrDefault("X-Amz-Date")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Date", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Security-Token")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Security-Token", valid_601386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601387 = header.getOrDefault("X-Amz-Target")
  valid_601387 = validateParameter(valid_601387, JString, required = true, default = newJString(
      "TrentService.ImportKeyMaterial"))
  if valid_601387 != nil:
    section.add "X-Amz-Target", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Content-Sha256", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Algorithm")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Algorithm", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Signature")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Signature", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-SignedHeaders", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Credential")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Credential", valid_601392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601394: Call_ImportKeyMaterial_601382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports key material into an existing AWS KMS customer master key (CMK) that was created without key material. You cannot perform this operation on a CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. This token and the public key used to encrypt the key material must have come from the same response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, you can change it only by reimporting the same key material and specifying a new expiration date. If the key material expires, AWS KMS deletes the key material and the CMK becomes unusable. To use the CMK again, you must reimport the same key material.</p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK. After you successfully import key material into a CMK, you can reimport the same key material into that CMK, but you cannot import different key material.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"))
  result = hook(call_601394, url, valid)

proc call*(call_601395: Call_ImportKeyMaterial_601382; body: JsonNode): Recallable =
  ## importKeyMaterial
  ## <p>Imports key material into an existing AWS KMS customer master key (CMK) that was created without key material. You cannot perform this operation on a CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. This token and the public key used to encrypt the key material must have come from the same response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, you can change it only by reimporting the same key material and specifying a new expiration date. If the key material expires, AWS KMS deletes the key material and the CMK becomes unusable. To use the CMK again, you must reimport the same key material.</p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK. After you successfully import key material into a CMK, you can reimport the same key material into that CMK, but you cannot import different key material.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601396 = newJObject()
  if body != nil:
    body_601396 = body
  result = call_601395.call(nil, nil, nil, nil, body_601396)

var importKeyMaterial* = Call_ImportKeyMaterial_601382(name: "importKeyMaterial",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ImportKeyMaterial",
    validator: validate_ImportKeyMaterial_601383, base: "/",
    url: url_ImportKeyMaterial_601384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_601397 = ref object of OpenApiRestCall_600426
proc url_ListAliases_601399(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAliases_601398(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases limit</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601400 = query.getOrDefault("Limit")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "Limit", valid_601400
  var valid_601401 = query.getOrDefault("Marker")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "Marker", valid_601401
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
  var valid_601402 = header.getOrDefault("X-Amz-Date")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Date", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Security-Token")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Security-Token", valid_601403
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601404 = header.getOrDefault("X-Amz-Target")
  valid_601404 = validateParameter(valid_601404, JString, required = true, default = newJString(
      "TrentService.ListAliases"))
  if valid_601404 != nil:
    section.add "X-Amz-Target", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Content-Sha256", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Algorithm")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Algorithm", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Signature")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Signature", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-SignedHeaders", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Credential")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Credential", valid_601409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601411: Call_ListAliases_601397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases limit</a>.</p>
  ## 
  let valid = call_601411.validator(path, query, header, formData, body)
  let scheme = call_601411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601411.url(scheme.get, call_601411.host, call_601411.base,
                         call_601411.route, valid.getOrDefault("path"))
  result = hook(call_601411, url, valid)

proc call*(call_601412: Call_ListAliases_601397; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listAliases
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases limit</a>.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601413 = newJObject()
  var body_601414 = newJObject()
  add(query_601413, "Limit", newJString(Limit))
  add(query_601413, "Marker", newJString(Marker))
  if body != nil:
    body_601414 = body
  result = call_601412.call(nil, query_601413, nil, nil, body_601414)

var listAliases* = Call_ListAliases_601397(name: "listAliases",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListAliases",
                                        validator: validate_ListAliases_601398,
                                        base: "/", url: url_ListAliases_601399,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGrants_601416 = ref object of OpenApiRestCall_600426
proc url_ListGrants_601418(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGrants_601417(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601419 = query.getOrDefault("Limit")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "Limit", valid_601419
  var valid_601420 = query.getOrDefault("Marker")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "Marker", valid_601420
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
  var valid_601421 = header.getOrDefault("X-Amz-Date")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Date", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Security-Token")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Security-Token", valid_601422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601423 = header.getOrDefault("X-Amz-Target")
  valid_601423 = validateParameter(valid_601423, JString, required = true, default = newJString(
      "TrentService.ListGrants"))
  if valid_601423 != nil:
    section.add "X-Amz-Target", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Content-Sha256", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Algorithm")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Algorithm", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Signature")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Signature", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-SignedHeaders", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Credential")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Credential", valid_601428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601430: Call_ListGrants_601416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_601430.validator(path, query, header, formData, body)
  let scheme = call_601430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601430.url(scheme.get, call_601430.host, call_601430.base,
                         call_601430.route, valid.getOrDefault("path"))
  result = hook(call_601430, url, valid)

proc call*(call_601431: Call_ListGrants_601416; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listGrants
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601432 = newJObject()
  var body_601433 = newJObject()
  add(query_601432, "Limit", newJString(Limit))
  add(query_601432, "Marker", newJString(Marker))
  if body != nil:
    body_601433 = body
  result = call_601431.call(nil, query_601432, nil, nil, body_601433)

var listGrants* = Call_ListGrants_601416(name: "listGrants",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListGrants",
                                      validator: validate_ListGrants_601417,
                                      base: "/", url: url_ListGrants_601418,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPolicies_601434 = ref object of OpenApiRestCall_600426
proc url_ListKeyPolicies_601436(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListKeyPolicies_601435(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601437 = query.getOrDefault("Limit")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "Limit", valid_601437
  var valid_601438 = query.getOrDefault("Marker")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "Marker", valid_601438
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
  var valid_601439 = header.getOrDefault("X-Amz-Date")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Date", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Security-Token")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Security-Token", valid_601440
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601441 = header.getOrDefault("X-Amz-Target")
  valid_601441 = validateParameter(valid_601441, JString, required = true, default = newJString(
      "TrentService.ListKeyPolicies"))
  if valid_601441 != nil:
    section.add "X-Amz-Target", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Content-Sha256", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Algorithm")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Algorithm", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Signature")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Signature", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-SignedHeaders", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Credential")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Credential", valid_601446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601448: Call_ListKeyPolicies_601434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ## 
  let valid = call_601448.validator(path, query, header, formData, body)
  let scheme = call_601448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601448.url(scheme.get, call_601448.host, call_601448.base,
                         call_601448.route, valid.getOrDefault("path"))
  result = hook(call_601448, url, valid)

proc call*(call_601449: Call_ListKeyPolicies_601434; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listKeyPolicies
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601450 = newJObject()
  var body_601451 = newJObject()
  add(query_601450, "Limit", newJString(Limit))
  add(query_601450, "Marker", newJString(Marker))
  if body != nil:
    body_601451 = body
  result = call_601449.call(nil, query_601450, nil, nil, body_601451)

var listKeyPolicies* = Call_ListKeyPolicies_601434(name: "listKeyPolicies",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListKeyPolicies",
    validator: validate_ListKeyPolicies_601435, base: "/", url: url_ListKeyPolicies_601436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeys_601452 = ref object of OpenApiRestCall_600426
proc url_ListKeys_601454(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListKeys_601453(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601455 = query.getOrDefault("Limit")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "Limit", valid_601455
  var valid_601456 = query.getOrDefault("Marker")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "Marker", valid_601456
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
  var valid_601457 = header.getOrDefault("X-Amz-Date")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Date", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Security-Token")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Security-Token", valid_601458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601459 = header.getOrDefault("X-Amz-Target")
  valid_601459 = validateParameter(valid_601459, JString, required = true,
                                 default = newJString("TrentService.ListKeys"))
  if valid_601459 != nil:
    section.add "X-Amz-Target", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Content-Sha256", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Algorithm")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Algorithm", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Signature")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Signature", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-SignedHeaders", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Credential")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Credential", valid_601464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601466: Call_ListKeys_601452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and region.
  ## 
  let valid = call_601466.validator(path, query, header, formData, body)
  let scheme = call_601466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601466.url(scheme.get, call_601466.host, call_601466.base,
                         call_601466.route, valid.getOrDefault("path"))
  result = hook(call_601466, url, valid)

proc call*(call_601467: Call_ListKeys_601452; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listKeys
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and region.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601468 = newJObject()
  var body_601469 = newJObject()
  add(query_601468, "Limit", newJString(Limit))
  add(query_601468, "Marker", newJString(Marker))
  if body != nil:
    body_601469 = body
  result = call_601467.call(nil, query_601468, nil, nil, body_601469)

var listKeys* = Call_ListKeys_601452(name: "listKeys", meth: HttpMethod.HttpPost,
                                  host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListKeys",
                                  validator: validate_ListKeys_601453, base: "/",
                                  url: url_ListKeys_601454,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceTags_601470 = ref object of OpenApiRestCall_600426
proc url_ListResourceTags_601472(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListResourceTags_601471(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601473 = header.getOrDefault("X-Amz-Date")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Date", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Security-Token")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Security-Token", valid_601474
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601475 = header.getOrDefault("X-Amz-Target")
  valid_601475 = validateParameter(valid_601475, JString, required = true, default = newJString(
      "TrentService.ListResourceTags"))
  if valid_601475 != nil:
    section.add "X-Amz-Target", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Content-Sha256", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Algorithm")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Algorithm", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Signature")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Signature", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-SignedHeaders", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Credential")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Credential", valid_601480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601482: Call_ListResourceTags_601470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
  ## 
  let valid = call_601482.validator(path, query, header, formData, body)
  let scheme = call_601482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601482.url(scheme.get, call_601482.host, call_601482.base,
                         call_601482.route, valid.getOrDefault("path"))
  result = hook(call_601482, url, valid)

proc call*(call_601483: Call_ListResourceTags_601470; body: JsonNode): Recallable =
  ## listResourceTags
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
  ##   body: JObject (required)
  var body_601484 = newJObject()
  if body != nil:
    body_601484 = body
  result = call_601483.call(nil, nil, nil, nil, body_601484)

var listResourceTags* = Call_ListResourceTags_601470(name: "listResourceTags",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListResourceTags",
    validator: validate_ListResourceTags_601471, base: "/",
    url: url_ListResourceTags_601472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRetirableGrants_601485 = ref object of OpenApiRestCall_600426
proc url_ListRetirableGrants_601487(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRetirableGrants_601486(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601488 = header.getOrDefault("X-Amz-Date")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Date", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Security-Token")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Security-Token", valid_601489
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601490 = header.getOrDefault("X-Amz-Target")
  valid_601490 = validateParameter(valid_601490, JString, required = true, default = newJString(
      "TrentService.ListRetirableGrants"))
  if valid_601490 != nil:
    section.add "X-Amz-Target", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Content-Sha256", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Algorithm")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Algorithm", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Signature")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Signature", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-SignedHeaders", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Credential")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Credential", valid_601495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601497: Call_ListRetirableGrants_601485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
  ## 
  let valid = call_601497.validator(path, query, header, formData, body)
  let scheme = call_601497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601497.url(scheme.get, call_601497.host, call_601497.base,
                         call_601497.route, valid.getOrDefault("path"))
  result = hook(call_601497, url, valid)

proc call*(call_601498: Call_ListRetirableGrants_601485; body: JsonNode): Recallable =
  ## listRetirableGrants
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
  ##   body: JObject (required)
  var body_601499 = newJObject()
  if body != nil:
    body_601499 = body
  result = call_601498.call(nil, nil, nil, nil, body_601499)

var listRetirableGrants* = Call_ListRetirableGrants_601485(
    name: "listRetirableGrants", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListRetirableGrants",
    validator: validate_ListRetirableGrants_601486, base: "/",
    url: url_ListRetirableGrants_601487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutKeyPolicy_601500 = ref object of OpenApiRestCall_600426
proc url_PutKeyPolicy_601502(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutKeyPolicy_601501(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601503 = header.getOrDefault("X-Amz-Date")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Date", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Security-Token")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Security-Token", valid_601504
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601505 = header.getOrDefault("X-Amz-Target")
  valid_601505 = validateParameter(valid_601505, JString, required = true, default = newJString(
      "TrentService.PutKeyPolicy"))
  if valid_601505 != nil:
    section.add "X-Amz-Target", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Content-Sha256", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Algorithm")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Algorithm", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Signature")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Signature", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-SignedHeaders", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Credential")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Credential", valid_601510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601512: Call_PutKeyPolicy_601500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601512.validator(path, query, header, formData, body)
  let scheme = call_601512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601512.url(scheme.get, call_601512.host, call_601512.base,
                         call_601512.route, valid.getOrDefault("path"))
  result = hook(call_601512, url, valid)

proc call*(call_601513: Call_PutKeyPolicy_601500; body: JsonNode): Recallable =
  ## putKeyPolicy
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601514 = newJObject()
  if body != nil:
    body_601514 = body
  result = call_601513.call(nil, nil, nil, nil, body_601514)

var putKeyPolicy* = Call_PutKeyPolicy_601500(name: "putKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.PutKeyPolicy",
    validator: validate_PutKeyPolicy_601501, base: "/", url: url_PutKeyPolicy_601502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReEncrypt_601515 = ref object of OpenApiRestCall_600426
proc url_ReEncrypt_601517(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ReEncrypt_601516(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Encrypts data on the server side with a new customer master key (CMK) without exposing the plaintext of the data on the client side. The data is first decrypted and then reencrypted. You can also use this operation to change the encryption context of a ciphertext. </p> <p>You can reencrypt data using CMKs in different AWS accounts.</p> <p>Unlike other operations, <code>ReEncrypt</code> is authorized twice, once as <code>ReEncryptFrom</code> on the source CMK and once as <code>ReEncryptTo</code> on the destination CMK. We recommend that you include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policies</a> to permit reencryption from or to the CMK. This permission is automatically included in the key policy when you create a CMK through the console. But you must include it manually when you create a CMK programmatically or when you set a key policy with the <a>PutKeyPolicy</a> operation.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601518 = header.getOrDefault("X-Amz-Date")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Date", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Security-Token")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Security-Token", valid_601519
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601520 = header.getOrDefault("X-Amz-Target")
  valid_601520 = validateParameter(valid_601520, JString, required = true,
                                 default = newJString("TrentService.ReEncrypt"))
  if valid_601520 != nil:
    section.add "X-Amz-Target", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Content-Sha256", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Algorithm")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Algorithm", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Signature")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Signature", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-SignedHeaders", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Credential")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Credential", valid_601525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601527: Call_ReEncrypt_601515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Encrypts data on the server side with a new customer master key (CMK) without exposing the plaintext of the data on the client side. The data is first decrypted and then reencrypted. You can also use this operation to change the encryption context of a ciphertext. </p> <p>You can reencrypt data using CMKs in different AWS accounts.</p> <p>Unlike other operations, <code>ReEncrypt</code> is authorized twice, once as <code>ReEncryptFrom</code> on the source CMK and once as <code>ReEncryptTo</code> on the destination CMK. We recommend that you include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policies</a> to permit reencryption from or to the CMK. This permission is automatically included in the key policy when you create a CMK through the console. But you must include it manually when you create a CMK programmatically or when you set a key policy with the <a>PutKeyPolicy</a> operation.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601527.validator(path, query, header, formData, body)
  let scheme = call_601527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601527.url(scheme.get, call_601527.host, call_601527.base,
                         call_601527.route, valid.getOrDefault("path"))
  result = hook(call_601527, url, valid)

proc call*(call_601528: Call_ReEncrypt_601515; body: JsonNode): Recallable =
  ## reEncrypt
  ## <p>Encrypts data on the server side with a new customer master key (CMK) without exposing the plaintext of the data on the client side. The data is first decrypted and then reencrypted. You can also use this operation to change the encryption context of a ciphertext. </p> <p>You can reencrypt data using CMKs in different AWS accounts.</p> <p>Unlike other operations, <code>ReEncrypt</code> is authorized twice, once as <code>ReEncryptFrom</code> on the source CMK and once as <code>ReEncryptTo</code> on the destination CMK. We recommend that you include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policies</a> to permit reencryption from or to the CMK. This permission is automatically included in the key policy when you create a CMK through the console. But you must include it manually when you create a CMK programmatically or when you set a key policy with the <a>PutKeyPolicy</a> operation.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601529 = newJObject()
  if body != nil:
    body_601529 = body
  result = call_601528.call(nil, nil, nil, nil, body_601529)

var reEncrypt* = Call_ReEncrypt_601515(name: "reEncrypt", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ReEncrypt",
                                    validator: validate_ReEncrypt_601516,
                                    base: "/", url: url_ReEncrypt_601517,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetireGrant_601530 = ref object of OpenApiRestCall_600426
proc url_RetireGrant_601532(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RetireGrant_601531(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601533 = header.getOrDefault("X-Amz-Date")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Date", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Security-Token")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Security-Token", valid_601534
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601535 = header.getOrDefault("X-Amz-Target")
  valid_601535 = validateParameter(valid_601535, JString, required = true, default = newJString(
      "TrentService.RetireGrant"))
  if valid_601535 != nil:
    section.add "X-Amz-Target", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Content-Sha256", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Algorithm")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Algorithm", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Signature")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Signature", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-SignedHeaders", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Credential")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Credential", valid_601540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601542: Call_RetireGrant_601530; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
  ## 
  let valid = call_601542.validator(path, query, header, formData, body)
  let scheme = call_601542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601542.url(scheme.get, call_601542.host, call_601542.base,
                         call_601542.route, valid.getOrDefault("path"))
  result = hook(call_601542, url, valid)

proc call*(call_601543: Call_RetireGrant_601530; body: JsonNode): Recallable =
  ## retireGrant
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
  ##   body: JObject (required)
  var body_601544 = newJObject()
  if body != nil:
    body_601544 = body
  result = call_601543.call(nil, nil, nil, nil, body_601544)

var retireGrant* = Call_RetireGrant_601530(name: "retireGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.RetireGrant",
                                        validator: validate_RetireGrant_601531,
                                        base: "/", url: url_RetireGrant_601532,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeGrant_601545 = ref object of OpenApiRestCall_600426
proc url_RevokeGrant_601547(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RevokeGrant_601546(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601548 = header.getOrDefault("X-Amz-Date")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Date", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Security-Token")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Security-Token", valid_601549
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601550 = header.getOrDefault("X-Amz-Target")
  valid_601550 = validateParameter(valid_601550, JString, required = true, default = newJString(
      "TrentService.RevokeGrant"))
  if valid_601550 != nil:
    section.add "X-Amz-Target", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Content-Sha256", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Algorithm")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Algorithm", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Signature")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Signature", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-SignedHeaders", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Credential")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Credential", valid_601555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601557: Call_RevokeGrant_601545; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_601557.validator(path, query, header, formData, body)
  let scheme = call_601557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601557.url(scheme.get, call_601557.host, call_601557.base,
                         call_601557.route, valid.getOrDefault("path"))
  result = hook(call_601557, url, valid)

proc call*(call_601558: Call_RevokeGrant_601545; body: JsonNode): Recallable =
  ## revokeGrant
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   body: JObject (required)
  var body_601559 = newJObject()
  if body != nil:
    body_601559 = body
  result = call_601558.call(nil, nil, nil, nil, body_601559)

var revokeGrant* = Call_RevokeGrant_601545(name: "revokeGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.RevokeGrant",
                                        validator: validate_RevokeGrant_601546,
                                        base: "/", url: url_RevokeGrant_601547,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleKeyDeletion_601560 = ref object of OpenApiRestCall_600426
proc url_ScheduleKeyDeletion_601562(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ScheduleKeyDeletion_601561(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601563 = header.getOrDefault("X-Amz-Date")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Date", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Security-Token")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Security-Token", valid_601564
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601565 = header.getOrDefault("X-Amz-Target")
  valid_601565 = validateParameter(valid_601565, JString, required = true, default = newJString(
      "TrentService.ScheduleKeyDeletion"))
  if valid_601565 != nil:
    section.add "X-Amz-Target", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Content-Sha256", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Algorithm")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Algorithm", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Signature")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Signature", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-SignedHeaders", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Credential")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Credential", valid_601570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601572: Call_ScheduleKeyDeletion_601560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601572.validator(path, query, header, formData, body)
  let scheme = call_601572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601572.url(scheme.get, call_601572.host, call_601572.base,
                         call_601572.route, valid.getOrDefault("path"))
  result = hook(call_601572, url, valid)

proc call*(call_601573: Call_ScheduleKeyDeletion_601560; body: JsonNode): Recallable =
  ## scheduleKeyDeletion
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601574 = newJObject()
  if body != nil:
    body_601574 = body
  result = call_601573.call(nil, nil, nil, nil, body_601574)

var scheduleKeyDeletion* = Call_ScheduleKeyDeletion_601560(
    name: "scheduleKeyDeletion", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ScheduleKeyDeletion",
    validator: validate_ScheduleKeyDeletion_601561, base: "/",
    url: url_ScheduleKeyDeletion_601562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601575 = ref object of OpenApiRestCall_600426
proc url_TagResource_601577(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601576(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601578 = header.getOrDefault("X-Amz-Date")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Date", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Security-Token")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Security-Token", valid_601579
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601580 = header.getOrDefault("X-Amz-Target")
  valid_601580 = validateParameter(valid_601580, JString, required = true, default = newJString(
      "TrentService.TagResource"))
  if valid_601580 != nil:
    section.add "X-Amz-Target", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Content-Sha256", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Algorithm")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Algorithm", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Signature")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Signature", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-SignedHeaders", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Credential")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Credential", valid_601585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601587: Call_TagResource_601575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601587.validator(path, query, header, formData, body)
  let scheme = call_601587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601587.url(scheme.get, call_601587.host, call_601587.base,
                         call_601587.route, valid.getOrDefault("path"))
  result = hook(call_601587, url, valid)

proc call*(call_601588: Call_TagResource_601575; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601589 = newJObject()
  if body != nil:
    body_601589 = body
  result = call_601588.call(nil, nil, nil, nil, body_601589)

var tagResource* = Call_TagResource_601575(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.TagResource",
                                        validator: validate_TagResource_601576,
                                        base: "/", url: url_TagResource_601577,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601590 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601592(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601591(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601593 = header.getOrDefault("X-Amz-Date")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Date", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Security-Token")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Security-Token", valid_601594
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601595 = header.getOrDefault("X-Amz-Target")
  valid_601595 = validateParameter(valid_601595, JString, required = true, default = newJString(
      "TrentService.UntagResource"))
  if valid_601595 != nil:
    section.add "X-Amz-Target", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Content-Sha256", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Algorithm")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Algorithm", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Signature")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Signature", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-SignedHeaders", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Credential")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Credential", valid_601600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601602: Call_UntagResource_601590; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601602.validator(path, query, header, formData, body)
  let scheme = call_601602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601602.url(scheme.get, call_601602.host, call_601602.base,
                         call_601602.route, valid.getOrDefault("path"))
  result = hook(call_601602, url, valid)

proc call*(call_601603: Call_UntagResource_601590; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601604 = newJObject()
  if body != nil:
    body_601604 = body
  result = call_601603.call(nil, nil, nil, nil, body_601604)

var untagResource* = Call_UntagResource_601590(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UntagResource",
    validator: validate_UntagResource_601591, base: "/", url: url_UntagResource_601592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_601605 = ref object of OpenApiRestCall_600426
proc url_UpdateAlias_601607(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAlias_601606(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates an existing alias with a different customer master key (CMK). Each CMK can have multiple aliases, but the aliases must be unique within the account and region. You cannot perform this operation on an alias in a different AWS account.</p> <p>This operation works only on existing aliases. To change the alias of a CMK to a new value, use <a>CreateAlias</a> to create a new alias and <a>DeleteAlias</a> to delete the old alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601608 = header.getOrDefault("X-Amz-Date")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Date", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Security-Token")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Security-Token", valid_601609
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601610 = header.getOrDefault("X-Amz-Target")
  valid_601610 = validateParameter(valid_601610, JString, required = true, default = newJString(
      "TrentService.UpdateAlias"))
  if valid_601610 != nil:
    section.add "X-Amz-Target", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Content-Sha256", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Algorithm")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Algorithm", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Signature")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Signature", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-SignedHeaders", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Credential")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Credential", valid_601615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601617: Call_UpdateAlias_601605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an existing alias with a different customer master key (CMK). Each CMK can have multiple aliases, but the aliases must be unique within the account and region. You cannot perform this operation on an alias in a different AWS account.</p> <p>This operation works only on existing aliases. To change the alias of a CMK to a new value, use <a>CreateAlias</a> to create a new alias and <a>DeleteAlias</a> to delete the old alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601617.validator(path, query, header, formData, body)
  let scheme = call_601617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601617.url(scheme.get, call_601617.host, call_601617.base,
                         call_601617.route, valid.getOrDefault("path"))
  result = hook(call_601617, url, valid)

proc call*(call_601618: Call_UpdateAlias_601605; body: JsonNode): Recallable =
  ## updateAlias
  ## <p>Associates an existing alias with a different customer master key (CMK). Each CMK can have multiple aliases, but the aliases must be unique within the account and region. You cannot perform this operation on an alias in a different AWS account.</p> <p>This operation works only on existing aliases. To change the alias of a CMK to a new value, use <a>CreateAlias</a> to create a new alias and <a>DeleteAlias</a> to delete the old alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601619 = newJObject()
  if body != nil:
    body_601619 = body
  result = call_601618.call(nil, nil, nil, nil, body_601619)

var updateAlias* = Call_UpdateAlias_601605(name: "updateAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.UpdateAlias",
                                        validator: validate_UpdateAlias_601606,
                                        base: "/", url: url_UpdateAlias_601607,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCustomKeyStore_601620 = ref object of OpenApiRestCall_600426
proc url_UpdateCustomKeyStore_601622(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateCustomKeyStore_601621(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601623 = header.getOrDefault("X-Amz-Date")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Date", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Security-Token")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Security-Token", valid_601624
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601625 = header.getOrDefault("X-Amz-Target")
  valid_601625 = validateParameter(valid_601625, JString, required = true, default = newJString(
      "TrentService.UpdateCustomKeyStore"))
  if valid_601625 != nil:
    section.add "X-Amz-Target", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Content-Sha256", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Algorithm")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Algorithm", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Signature")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Signature", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-SignedHeaders", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Credential")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Credential", valid_601630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601632: Call_UpdateCustomKeyStore_601620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_601632.validator(path, query, header, formData, body)
  let scheme = call_601632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601632.url(scheme.get, call_601632.host, call_601632.base,
                         call_601632.route, valid.getOrDefault("path"))
  result = hook(call_601632, url, valid)

proc call*(call_601633: Call_UpdateCustomKeyStore_601620; body: JsonNode): Recallable =
  ## updateCustomKeyStore
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_601634 = newJObject()
  if body != nil:
    body_601634 = body
  result = call_601633.call(nil, nil, nil, nil, body_601634)

var updateCustomKeyStore* = Call_UpdateCustomKeyStore_601620(
    name: "updateCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateCustomKeyStore",
    validator: validate_UpdateCustomKeyStore_601621, base: "/",
    url: url_UpdateCustomKeyStore_601622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateKeyDescription_601635 = ref object of OpenApiRestCall_600426
proc url_UpdateKeyDescription_601637(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateKeyDescription_601636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
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
  var valid_601638 = header.getOrDefault("X-Amz-Date")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Date", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Security-Token")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Security-Token", valid_601639
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601640 = header.getOrDefault("X-Amz-Target")
  valid_601640 = validateParameter(valid_601640, JString, required = true, default = newJString(
      "TrentService.UpdateKeyDescription"))
  if valid_601640 != nil:
    section.add "X-Amz-Target", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Content-Sha256", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Algorithm")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Algorithm", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Signature")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Signature", valid_601643
  var valid_601644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-SignedHeaders", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Credential")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Credential", valid_601645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601647: Call_UpdateKeyDescription_601635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_601647.validator(path, query, header, formData, body)
  let scheme = call_601647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601647.url(scheme.get, call_601647.host, call_601647.base,
                         call_601647.route, valid.getOrDefault("path"))
  result = hook(call_601647, url, valid)

proc call*(call_601648: Call_UpdateKeyDescription_601635; body: JsonNode): Recallable =
  ## updateKeyDescription
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601649 = newJObject()
  if body != nil:
    body_601649 = body
  result = call_601648.call(nil, nil, nil, nil, body_601649)

var updateKeyDescription* = Call_UpdateKeyDescription_601635(
    name: "updateKeyDescription", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateKeyDescription",
    validator: validate_UpdateKeyDescription_601636, base: "/",
    url: url_UpdateKeyDescription_601637, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
