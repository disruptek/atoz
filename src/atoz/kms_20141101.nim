
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelKeyDeletion_602803 = ref object of OpenApiRestCall_602466
proc url_CancelKeyDeletion_602805(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelKeyDeletion_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "TrentService.CancelKeyDeletion"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_CancelKeyDeletion_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation is successful, the CMK is set to the <code>Disabled</code> state. To enable a CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_CancelKeyDeletion_602803; body: JsonNode): Recallable =
  ## cancelKeyDeletion
  ## <p>Cancels the deletion of a customer master key (CMK). When this operation is successful, the CMK is set to the <code>Disabled</code> state. To enable a CMK, use <a>EnableKey</a>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling and canceling deletion of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var cancelKeyDeletion* = Call_CancelKeyDeletion_602803(name: "cancelKeyDeletion",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CancelKeyDeletion",
    validator: validate_CancelKeyDeletion_602804, base: "/",
    url: url_CancelKeyDeletion_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectCustomKeyStore_603072 = ref object of OpenApiRestCall_602466
proc url_ConnectCustomKeyStore_603074(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ConnectCustomKeyStore_603073(path: JsonNode; query: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "TrentService.ConnectCustomKeyStore"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_ConnectCustomKeyStore_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU), and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_ConnectCustomKeyStore_603072; body: JsonNode): Recallable =
  ## connectCustomKeyStore
  ## <p>Connects or reconnects a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> to its associated AWS CloudHSM cluster.</p> <p>The custom key store must be connected before you can create customer master keys (CMKs) in the key store or use the CMKs it contains. You can disconnect and reconnect a custom key store at any time.</p> <p>To connect a custom key store, its associated AWS CloudHSM cluster must have at least one active HSM. To get the number of active HSMs in a cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html">DescribeClusters</a> operation. To add HSMs to the cluster, use the <a href="https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html">CreateHsm</a> operation.</p> <p>The connection process can take an extended amount of time to complete; up to 20 minutes. This operation starts the connection process, but it does not wait for it to complete. When it succeeds, this operation quickly returns an HTTP 200 response and a JSON object with no properties. However, this response does not indicate that the custom key store is connected. To get the connection state of the custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>During the connection process, AWS KMS finds the AWS CloudHSM cluster that is associated with the custom key store, creates the connection infrastructure, connects to the cluster, logs into the AWS CloudHSM client as the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user</a> (CU), and rotates its password.</p> <p>The <code>ConnectCustomKeyStore</code> operation might fail for various reasons. To find the reason, use the <a>DescribeCustomKeyStores</a> operation and see the <code>ConnectionErrorCode</code> in the response. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>To fix the failure, use the <a>DisconnectCustomKeyStore</a> operation to disconnect the custom key store, correct the error, use the <a>UpdateCustomKeyStore</a> operation if necessary, and then use <code>ConnectCustomKeyStore</code> again.</p> <p>If you are having trouble connecting or disconnecting a custom key store, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var connectCustomKeyStore* = Call_ConnectCustomKeyStore_603072(
    name: "connectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ConnectCustomKeyStore",
    validator: validate_ConnectCustomKeyStore_603073, base: "/",
    url: url_ConnectCustomKeyStore_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_603087 = ref object of OpenApiRestCall_602466
proc url_CreateAlias_603089(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAlias_603088(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "TrentService.CreateAlias"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreateAlias_603087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in selected operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. </p> <p>Each CMK can have multiple aliases, but each alias points to only one CMK. The alias name must be unique in the AWS account and region. To simplify code that runs in multiple regions, use the same alias name, but point it to a different CMK in each region. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation.</p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The alias and the CMK it is mapped to must be in the same AWS account and the same region. You cannot perform this operation on an alias in a different AWS account.</p> <p>To map an existing alias to a different CMK, call <a>UpdateAlias</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateAlias_603087; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates a display name for a customer managed customer master key (CMK). You can use an alias to identify a CMK in selected operations, such as <a>Encrypt</a> and <a>GenerateDataKey</a>. </p> <p>Each CMK can have multiple aliases, but each alias points to only one CMK. The alias name must be unique in the AWS account and region. To simplify code that runs in multiple regions, use the same alias name, but point it to a different CMK in each region. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation.</p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The alias and the CMK it is mapped to must be in the same AWS account and the same region. You cannot perform this operation on an alias in a different AWS account.</p> <p>To map an existing alias to a different CMK, call <a>UpdateAlias</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createAlias* = Call_CreateAlias_603087(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateAlias",
                                        validator: validate_CreateAlias_603088,
                                        base: "/", url: url_CreateAlias_603089,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomKeyStore_603102 = ref object of OpenApiRestCall_602466
proc url_CreateCustomKeyStore_603104(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCustomKeyStore_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "TrentService.CreateCustomKeyStore"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateCustomKeyStore_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateCustomKeyStore_603102; body: JsonNode): Recallable =
  ## createCustomKeyStore
  ## <p>Creates a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> that is associated with an <a href="https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html">AWS CloudHSM cluster</a> that you own and manage.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>Before you create the custom key store, you must assemble the required elements, including an AWS CloudHSM cluster that fulfills the requirements for a custom key store. For details about the required elements, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore">Assemble the Prerequisites</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>When the operation completes successfully, it returns the ID of the new custom key store. Before you can use your new custom key store, you need to use the <a>ConnectCustomKeyStore</a> operation to connect the new key store to its AWS CloudHSM cluster. Even if you are not going to use your custom key store immediately, you might want to connect it to verify that all settings are correct and then disconnect it until you are ready to use it.</p> <p>For help with failures, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting a Custom Key Store</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createCustomKeyStore* = Call_CreateCustomKeyStore_603102(
    name: "createCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.CreateCustomKeyStore",
    validator: validate_CreateCustomKeyStore_603103, base: "/",
    url: url_CreateCustomKeyStore_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGrant_603117 = ref object of OpenApiRestCall_602466
proc url_CreateGrant_603119(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGrant_603118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "TrentService.CreateGrant"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateGrant_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the encryption context in the operation request matches or includes a specified encryption context, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateGrant_603117; body: JsonNode): Recallable =
  ## createGrant
  ## <p>Adds a grant to a customer master key (CMK). The grant allows the grantee principal to use the CMK when the conditions specified in the grant are met. When setting permissions, grants are an alternative to key policies. </p> <p>To create a grant that allows a cryptographic operation only when the encryption context in the operation request matches or includes a specified encryption context, use the <code>Constraints</code> parameter. For details, see <a>GrantConstraints</a>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter. For more information about grants, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/grants.html">Grants</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createGrant* = Call_CreateGrant_603117(name: "createGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateGrant",
                                        validator: validate_CreateGrant_603118,
                                        base: "/", url: url_CreateGrant_603119,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateKey_603132 = ref object of OpenApiRestCall_602466
proc url_CreateKey_603134(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateKey_603133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true,
                                 default = newJString("TrentService.CreateKey"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateKey_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master key</a> (CMK) in your AWS account.</p> <p>You can use a CMK to encrypt small amounts of data (up to 4096 bytes) directly. But CMKs are more commonly used to encrypt the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> that are used to encrypt data.</p> <p>To create a CMK for imported key material, use the <code>Origin</code> parameter with a value of <code>EXTERNAL</code>.</p> <p>To create a CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region.</p> <p>You cannot use this operation to create a CMK in a different AWS account.</p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateKey_603132; body: JsonNode): Recallable =
  ## createKey
  ## <p>Creates a customer managed <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master key</a> (CMK) in your AWS account.</p> <p>You can use a CMK to encrypt small amounts of data (up to 4096 bytes) directly. But CMKs are more commonly used to encrypt the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#data-keys">data keys</a> that are used to encrypt data.</p> <p>To create a CMK for imported key material, use the <code>Origin</code> parameter with a value of <code>EXTERNAL</code>.</p> <p>To create a CMK in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, use the <code>CustomKeyStoreId</code> parameter to specify the custom key store. You must also use the <code>Origin</code> parameter with a value of <code>AWS_CLOUDHSM</code>. The AWS CloudHSM cluster that is associated with the custom key store must have at least two active HSMs in different Availability Zones in the AWS Region.</p> <p>You cannot use this operation to create a CMK in a different AWS account.</p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createKey* = Call_CreateKey_603132(name: "createKey", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.CreateKey",
                                    validator: validate_CreateKey_603133,
                                    base: "/", url: url_CreateKey_603134,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Decrypt_603147 = ref object of OpenApiRestCall_602466
proc url_Decrypt_603149(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Decrypt_603148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = newJString("TrentService.Decrypt"))
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

proc call*(call_603159: Call_Decrypt_603147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Decrypts ciphertext. Ciphertext is plaintext that has been previously encrypted by using any of the following operations:</p> <ul> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>Encrypt</a> </p> </li> </ul> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on the CMK, instead of IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_Decrypt_603147; body: JsonNode): Recallable =
  ## decrypt
  ## <p>Decrypts ciphertext. Ciphertext is plaintext that has been previously encrypted by using any of the following operations:</p> <ul> <li> <p> <a>GenerateDataKey</a> </p> </li> <li> <p> <a>GenerateDataKeyWithoutPlaintext</a> </p> </li> <li> <p> <a>Encrypt</a> </p> </li> </ul> <p>Whenever possible, use key policies to give users permission to call the Decrypt operation on the CMK, instead of IAM policies. Otherwise, you might create an IAM user policy that gives the user Decrypt permission on all CMKs. This user could decrypt ciphertext that was encrypted by CMKs in other accounts if the key policy for the cross-account CMK permits it. If you must use an IAM policy for <code>Decrypt</code> permissions, limit the user to particular CMKs or particular trusted accounts.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var decrypt* = Call_Decrypt_603147(name: "decrypt", meth: HttpMethod.HttpPost,
                                host: "kms.amazonaws.com",
                                route: "/#X-Amz-Target=TrentService.Decrypt",
                                validator: validate_Decrypt_603148, base: "/",
                                url: url_Decrypt_603149,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_603162 = ref object of OpenApiRestCall_602466
proc url_DeleteAlias_603164(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAlias_603163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "TrentService.DeleteAlias"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DeleteAlias_603162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DeleteAlias_603162; body: JsonNode): Recallable =
  ## deleteAlias
  ## <p>Deletes the specified alias. You cannot perform this operation on an alias in a different AWS account. </p> <p>Because an alias is not a property of a CMK, you can delete and change the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs, use the <a>ListAliases</a> operation. </p> <p>Each CMK can have multiple aliases. To change the alias of a CMK, use <a>DeleteAlias</a> to delete the current alias and <a>CreateAlias</a> to create a new alias. To associate an existing alias with a different customer master key (CMK), call <a>UpdateAlias</a>.</p>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var deleteAlias* = Call_DeleteAlias_603162(name: "deleteAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DeleteAlias",
                                        validator: validate_DeleteAlias_603163,
                                        base: "/", url: url_DeleteAlias_603164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomKeyStore_603177 = ref object of OpenApiRestCall_602466
proc url_DeleteCustomKeyStore_603179(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCustomKeyStore_603178(path: JsonNode; query: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "TrentService.DeleteCustomKeyStore"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DeleteCustomKeyStore_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DeleteCustomKeyStore_603177; body: JsonNode): Recallable =
  ## deleteCustomKeyStore
  ## <p>Deletes a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>. This operation does not delete the AWS CloudHSM cluster that is associated with the custom key store, or affect any users or keys in the cluster.</p> <p>The custom key store that you delete cannot contain any AWS KMS <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">customer master keys (CMKs)</a>. Before deleting the key store, verify that you will never need to use any of the CMKs in the key store for any cryptographic operations. Then, use <a>ScheduleKeyDeletion</a> to delete the AWS KMS customer master keys (CMKs) from the key store. When the scheduled waiting period expires, the <code>ScheduleKeyDeletion</code> operation deletes the CMKs. Then it makes a best effort to delete the key material from the associated cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>After all CMKs are deleted from AWS KMS, use <a>DisconnectCustomKeyStore</a> to disconnect the key store from AWS KMS. Then, you can delete the custom key store.</p> <p>Instead of deleting the custom key store, consider using <a>DisconnectCustomKeyStore</a> to disconnect it from AWS KMS. While the key store is disconnected, you cannot create or use the CMKs in the key store. But, you do not need to delete CMKs and you can reconnect a disconnected custom key store at any time.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var deleteCustomKeyStore* = Call_DeleteCustomKeyStore_603177(
    name: "deleteCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteCustomKeyStore",
    validator: validate_DeleteCustomKeyStore_603178, base: "/",
    url: url_DeleteCustomKeyStore_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImportedKeyMaterial_603192 = ref object of OpenApiRestCall_602466
proc url_DeleteImportedKeyMaterial_603194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteImportedKeyMaterial_603193(path: JsonNode; query: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "TrentService.DeleteImportedKeyMaterial"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DeleteImportedKeyMaterial_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DeleteImportedKeyMaterial_603192; body: JsonNode): Recallable =
  ## deleteImportedKeyMaterial
  ## <p>Deletes key material that you previously imported. This operation makes the specified customer master key (CMK) unusable. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>. You cannot perform this operation on a CMK in a different AWS account.</p> <p>When the specified CMK is in the <code>PendingDeletion</code> state, this operation does not change the CMK's state. Otherwise, it changes the CMK's state to <code>PendingImport</code>.</p> <p>After you delete key material, you can use <a>ImportKeyMaterial</a> to reimport the same key material into the CMK.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var deleteImportedKeyMaterial* = Call_DeleteImportedKeyMaterial_603192(
    name: "deleteImportedKeyMaterial", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DeleteImportedKeyMaterial",
    validator: validate_DeleteImportedKeyMaterial_603193, base: "/",
    url: url_DeleteImportedKeyMaterial_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCustomKeyStores_603207 = ref object of OpenApiRestCall_602466
proc url_DescribeCustomKeyStores_603209(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCustomKeyStores_603208(path: JsonNode; query: JsonNode;
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "TrentService.DescribeCustomKeyStores"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DescribeCustomKeyStores_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DescribeCustomKeyStores_603207; body: JsonNode): Recallable =
  ## describeCustomKeyStores
  ## <p>Gets information about <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key stores</a> in the account and region.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p> <p>By default, this operation returns information about all custom key stores in the account and region. To get only information about a particular custom key store, use either the <code>CustomKeyStoreName</code> or <code>CustomKeyStoreId</code> parameter (but not both).</p> <p>To determine whether the custom key store is connected to its AWS CloudHSM cluster, use the <code>ConnectionState</code> element in the response. If an attempt to connect the custom key store failed, the <code>ConnectionState</code> value is <code>FAILED</code> and the <code>ConnectionErrorCode</code> element in the response indicates the cause of the failure. For help interpreting the <code>ConnectionErrorCode</code>, see <a>CustomKeyStoresListEntry</a>.</p> <p>Custom key stores have a <code>DISCONNECTED</code> connection state if the key store has never been connected or you use the <a>DisconnectCustomKeyStore</a> operation to disconnect it. If your custom key store state is <code>CONNECTED</code> but you are having trouble using it, make sure that its associated AWS CloudHSM cluster is active and contains the minimum number of HSMs required for the operation, if any.</p> <p> For help repairing your custom key store, see the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html">Troubleshooting Custom Key Stores</a> topic in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var describeCustomKeyStores* = Call_DescribeCustomKeyStores_603207(
    name: "describeCustomKeyStores", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DescribeCustomKeyStores",
    validator: validate_DescribeCustomKeyStores_603208, base: "/",
    url: url_DescribeCustomKeyStores_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeKey_603222 = ref object of OpenApiRestCall_602466
proc url_DescribeKey_603224(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeKey_603223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "TrentService.DescribeKey"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DescribeKey_603222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides detailed information about the specified customer master key (CMK).</p> <p>You can use <code>DescribeKey</code> on a predefined AWS alias, that is, an AWS alias with no key ID. When you do, AWS KMS associates the alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a> and returns its <code>KeyId</code> and <code>Arn</code> in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DescribeKey_603222; body: JsonNode): Recallable =
  ## describeKey
  ## <p>Provides detailed information about the specified customer master key (CMK).</p> <p>You can use <code>DescribeKey</code> on a predefined AWS alias, that is, an AWS alias with no key ID. When you do, AWS KMS associates the alias with an <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys">AWS managed CMK</a> and returns its <code>KeyId</code> and <code>Arn</code> in the response.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var describeKey* = Call_DescribeKey_603222(name: "describeKey",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DescribeKey",
                                        validator: validate_DescribeKey_603223,
                                        base: "/", url: url_DescribeKey_603224,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKey_603237 = ref object of OpenApiRestCall_602466
proc url_DisableKey_603239(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableKey_603238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "TrentService.DisableKey"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DisableKey_603237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DisableKey_603237; body: JsonNode): Recallable =
  ## disableKey
  ## <p>Sets the state of a customer master key (CMK) to disabled, thereby preventing its use for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about how key state affects the use of a CMK, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects the Use of a Customer Master Key</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var disableKey* = Call_DisableKey_603237(name: "disableKey",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.DisableKey",
                                      validator: validate_DisableKey_603238,
                                      base: "/", url: url_DisableKey_603239,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableKeyRotation_603252 = ref object of OpenApiRestCall_602466
proc url_DisableKeyRotation_603254(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableKeyRotation_603253(path: JsonNode; query: JsonNode;
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "TrentService.DisableKeyRotation"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_DisableKeyRotation_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_DisableKeyRotation_603252; body: JsonNode): Recallable =
  ## disableKeyRotation
  ## <p>Disables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var disableKeyRotation* = Call_DisableKeyRotation_603252(
    name: "disableKeyRotation", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisableKeyRotation",
    validator: validate_DisableKeyRotation_603253, base: "/",
    url: url_DisableKeyRotation_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectCustomKeyStore_603267 = ref object of OpenApiRestCall_602466
proc url_DisconnectCustomKeyStore_603269(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisconnectCustomKeyStore_603268(path: JsonNode; query: JsonNode;
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "TrentService.DisconnectCustomKeyStore"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_DisconnectCustomKeyStore_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_DisconnectCustomKeyStore_603267; body: JsonNode): Recallable =
  ## disconnectCustomKeyStore
  ## <p>Disconnects the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a> from its associated AWS CloudHSM cluster. While a custom key store is disconnected, you can manage the custom key store and its customer master keys (CMKs), but you cannot create or use CMKs in the custom key store. You can reconnect the custom key store at any time.</p> <note> <p>While a custom key store is disconnected, all attempts to create customer master keys (CMKs) in the custom key store or to use existing CMKs in cryptographic operations will fail. This action can prevent users from storing and accessing sensitive data.</p> </note> <p/> <p>To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation. To reconnect a custom key store, use the <a>ConnectCustomKeyStore</a> operation.</p> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var disconnectCustomKeyStore* = Call_DisconnectCustomKeyStore_603267(
    name: "disconnectCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.DisconnectCustomKeyStore",
    validator: validate_DisconnectCustomKeyStore_603268, base: "/",
    url: url_DisconnectCustomKeyStore_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKey_603282 = ref object of OpenApiRestCall_602466
proc url_EnableKey_603284(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableKey_603283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = newJString("TrentService.EnableKey"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_EnableKey_603282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_EnableKey_603282; body: JsonNode): Recallable =
  ## enableKey
  ## <p>Sets the key state of a customer master key (CMK) to enabled. This allows you to use the CMK for cryptographic operations. You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var enableKey* = Call_EnableKey_603282(name: "enableKey", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.EnableKey",
                                    validator: validate_EnableKey_603283,
                                    base: "/", url: url_EnableKey_603284,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableKeyRotation_603297 = ref object of OpenApiRestCall_602466
proc url_EnableKeyRotation_603299(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableKeyRotation_603298(path: JsonNode; query: JsonNode;
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "TrentService.EnableKeyRotation"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_EnableKeyRotation_603297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of CMKs with imported key material or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_EnableKeyRotation_603297; body: JsonNode): Recallable =
  ## enableKeyRotation
  ## <p>Enables <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> for the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>You cannot enable automatic rotation of CMKs with imported key material or CMKs in a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var enableKeyRotation* = Call_EnableKeyRotation_603297(name: "enableKeyRotation",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.EnableKeyRotation",
    validator: validate_EnableKeyRotation_603298, base: "/",
    url: url_EnableKeyRotation_603299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Encrypt_603312 = ref object of OpenApiRestCall_602466
proc url_Encrypt_603314(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Encrypt_603313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true,
                                 default = newJString("TrentService.Encrypt"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_Encrypt_603312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt up to 4 kilobytes (4096 bytes) of arbitrary data such as an RSA key, a database password, or other sensitive information.</p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need use this operation to encrypt a data key within a region. The <a>GenerateDataKey</a> and <a>GenerateDataKeyWithoutPlaintext</a> operations return an encrypted data key.</p> <p>Also, you don't need to use this operation to encrypt data in your application. You can use the plaintext and encrypted data keys that the <code>GenerateDataKey</code> operation returns.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_Encrypt_603312; body: JsonNode): Recallable =
  ## encrypt
  ## <p>Encrypts plaintext into ciphertext by using a customer master key (CMK). The <code>Encrypt</code> operation has two primary use cases:</p> <ul> <li> <p>You can encrypt up to 4 kilobytes (4096 bytes) of arbitrary data such as an RSA key, a database password, or other sensitive information.</p> </li> <li> <p>You can use the <code>Encrypt</code> operation to move encrypted data from one AWS region to another. In the first region, generate a data key and use the plaintext key to encrypt the data. Then, in the new region, call the <code>Encrypt</code> method on same plaintext data key. Now, you can safely move the encrypted data and encrypted data key to the new region, and decrypt in the new region when necessary.</p> </li> </ul> <p>You don't need use this operation to encrypt a data key within a region. The <a>GenerateDataKey</a> and <a>GenerateDataKeyWithoutPlaintext</a> operations return an encrypted data key.</p> <p>Also, you don't need to use this operation to encrypt data in your application. You can use the plaintext and encrypted data keys that the <code>GenerateDataKey</code> operation returns.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p>
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var encrypt* = Call_Encrypt_603312(name: "encrypt", meth: HttpMethod.HttpPost,
                                host: "kms.amazonaws.com",
                                route: "/#X-Amz-Target=TrentService.Encrypt",
                                validator: validate_Encrypt_603313, base: "/",
                                url: url_Encrypt_603314,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKey_603327 = ref object of OpenApiRestCall_602466
proc url_GenerateDataKey_603329(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateDataKey_603328(path: JsonNode; query: JsonNode;
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "TrentService.GenerateDataKey"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_GenerateDataKey_603327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a unique data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, you need to specify the customer master key (CMK) that will be used to encrypt the data key. You must also specify the length of the data key using either the <code>KeySpec</code> or <code>NumberOfBytes</code> field (but not both). For common key lengths (128-bit and 256-bit symmetric keys), we recommend that you use <code>KeySpec</code>. To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p> <p>You will find the plaintext copy of the data key in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to your encryption operation. When you specify an <code>EncryptionContext</code> in the <code>GenerateDataKey</code> operation, you must specify the same encryption context (a case-sensitive exact match) in your request to <a>Decrypt</a> the data key. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_GenerateDataKey_603327; body: JsonNode): Recallable =
  ## generateDataKey
  ## <p>Generates a unique data key. This operation returns a plaintext copy of the data key and a copy that is encrypted under a customer master key (CMK) that you specify. You can use the plaintext key to encrypt your data outside of KMS and store the encrypted data key with the encrypted data.</p> <p> <code>GenerateDataKey</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>To generate a data key, you need to specify the customer master key (CMK) that will be used to encrypt the data key. You must also specify the length of the data key using either the <code>KeySpec</code> or <code>NumberOfBytes</code> field (but not both). For common key lengths (128-bit and 256-bit symmetric keys), we recommend that you use <code>KeySpec</code>. To perform this operation on a CMK in a different AWS account, specify the key ARN or alias ARN in the value of the KeyId parameter.</p> <p>You will find the plaintext copy of the data key in the <code>Plaintext</code> field of the response, and the encrypted copy of the data key in the <code>CiphertextBlob</code> field.</p> <p>We recommend that you use the following pattern to encrypt data locally in your application:</p> <ol> <li> <p>Use the <code>GenerateDataKey</code> operation to get a data encryption key.</p> </li> <li> <p>Use the plaintext data key (returned in the <code>Plaintext</code> field of the response) to encrypt data locally, then erase the plaintext data key from memory.</p> </li> <li> <p>Store the encrypted data key (returned in the <code>CiphertextBlob</code> field of the response) alongside the locally encrypted data.</p> </li> </ol> <p>To decrypt data locally:</p> <ol> <li> <p>Use the <a>Decrypt</a> operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.</p> </li> <li> <p>Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.</p> </li> </ol> <p>To get only an encrypted copy of the data key, use <a>GenerateDataKeyWithoutPlaintext</a>. To get a cryptographically secure random byte string, use <a>GenerateRandom</a>.</p> <p>You can use the optional encryption context to add additional security to your encryption operation. When you specify an <code>EncryptionContext</code> in the <code>GenerateDataKey</code> operation, you must specify the same encryption context (a case-sensitive exact match) in your request to <a>Decrypt</a> the data key. Otherwise, the request to decrypt fails with an <code>InvalidCiphertextException</code>. For more information, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context">Encryption Context</a> in the <i> <i>AWS Key Management Service Developer Guide</i> </i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var generateDataKey* = Call_GenerateDataKey_603327(name: "generateDataKey",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKey",
    validator: validate_GenerateDataKey_603328, base: "/", url: url_GenerateDataKey_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateDataKeyWithoutPlaintext_603342 = ref object of OpenApiRestCall_602466
proc url_GenerateDataKeyWithoutPlaintext_603344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateDataKeyWithoutPlaintext_603343(path: JsonNode;
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "TrentService.GenerateDataKeyWithoutPlaintext"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_GenerateDataKeyWithoutPlaintext_603342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a unique data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. <code>GenerateDataKeyWithoutPlaintext</code> is identical to <a>GenerateDataKey</a> except that returns only the encrypted copy of the data key.</p> <p>Like <code>GenerateDataKey</code>, <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key.</p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_GenerateDataKeyWithoutPlaintext_603342; body: JsonNode): Recallable =
  ## generateDataKeyWithoutPlaintext
  ## <p>Generates a unique data key. This operation returns a data key that is encrypted under a customer master key (CMK) that you specify. <code>GenerateDataKeyWithoutPlaintext</code> is identical to <a>GenerateDataKey</a> except that returns only the encrypted copy of the data key.</p> <p>Like <code>GenerateDataKey</code>, <code>GenerateDataKeyWithoutPlaintext</code> returns a unique data key for each request. The bytes in the key are not related to the caller or CMK that is used to encrypt the data key.</p> <p>This operation is useful for systems that need to encrypt data at some point, but not immediately. When you need to encrypt the data, you call the <a>Decrypt</a> operation on the encrypted copy of the key.</p> <p>It's also useful in distributed systems with different levels of trust. For example, you might store encrypted data in containers. One component of your system creates new containers and stores an encrypted data key with each container. Then, a different component puts the data into the containers. That component first decrypts the data key, uses the plaintext data key to encrypt data, puts the encrypted data into the container, and then destroys the plaintext data key. In this system, the component that creates the containers never sees the plaintext data key.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var generateDataKeyWithoutPlaintext* = Call_GenerateDataKeyWithoutPlaintext_603342(
    name: "generateDataKeyWithoutPlaintext", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateDataKeyWithoutPlaintext",
    validator: validate_GenerateDataKeyWithoutPlaintext_603343, base: "/",
    url: url_GenerateDataKeyWithoutPlaintext_603344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateRandom_603357 = ref object of OpenApiRestCall_602466
proc url_GenerateRandom_603359(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateRandom_603358(path: JsonNode; query: JsonNode;
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
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "TrentService.GenerateRandom"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_GenerateRandom_603357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_GenerateRandom_603357; body: JsonNode): Recallable =
  ## generateRandom
  ## <p>Returns a random byte string that is cryptographically secure.</p> <p>By default, the random byte string is generated in AWS KMS. To generate the byte string in the AWS CloudHSM cluster that is associated with a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, specify the custom key store ID.</p> <p>For more information about entropy and random number generation, see the <a href="https://d0.awsstatic.com/whitepapers/KMS-Cryptographic-Details.pdf">AWS Key Management Service Cryptographic Details</a> whitepaper.</p>
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var generateRandom* = Call_GenerateRandom_603357(name: "generateRandom",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GenerateRandom",
    validator: validate_GenerateRandom_603358, base: "/", url: url_GenerateRandom_603359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyPolicy_603372 = ref object of OpenApiRestCall_602466
proc url_GetKeyPolicy_603374(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetKeyPolicy_603373(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "TrentService.GetKeyPolicy"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_GetKeyPolicy_603372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_GetKeyPolicy_603372; body: JsonNode): Recallable =
  ## getKeyPolicy
  ## Gets a key policy attached to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var getKeyPolicy* = Call_GetKeyPolicy_603372(name: "getKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyPolicy",
    validator: validate_GetKeyPolicy_603373, base: "/", url: url_GetKeyPolicy_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetKeyRotationStatus_603387 = ref object of OpenApiRestCall_602466
proc url_GetKeyRotationStatus_603389(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetKeyRotationStatus_603388(path: JsonNode; query: JsonNode;
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
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "TrentService.GetKeyRotationStatus"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_GetKeyRotationStatus_603387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_GetKeyRotationStatus_603387; body: JsonNode): Recallable =
  ## getKeyRotationStatus
  ## <p>Gets a Boolean value that indicates whether <a href="https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html">automatic rotation of the key material</a> is enabled for the specified customer master key (CMK).</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <ul> <li> <p>Disabled: The key rotation status does not change when you disable a CMK. However, while the CMK is disabled, AWS KMS does not rotate the backing key.</p> </li> <li> <p>Pending deletion: While a CMK is pending deletion, its key rotation status is <code>false</code> and AWS KMS does not rotate the backing key. If you cancel the deletion, the original key rotation status is restored.</p> </li> </ul> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var getKeyRotationStatus* = Call_GetKeyRotationStatus_603387(
    name: "getKeyRotationStatus", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetKeyRotationStatus",
    validator: validate_GetKeyRotationStatus_603388, base: "/",
    url: url_GetKeyRotationStatus_603389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersForImport_603402 = ref object of OpenApiRestCall_602466
proc url_GetParametersForImport_603404(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetParametersForImport_603403(path: JsonNode; query: JsonNode;
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
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "TrentService.GetParametersForImport"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_GetParametersForImport_603402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the items you need in order to import key material into AWS KMS from your existing key management infrastructure. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You must specify the key ID of the customer master key (CMK) into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on a CMK in a different AWS account.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request. The public key and import token from the same response must be used together. These items are valid for 24 hours. When they expire, they cannot be used for a subsequent <a>ImportKeyMaterial</a> request. To get new ones, send another <code>GetParametersForImport</code> request.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_GetParametersForImport_603402; body: JsonNode): Recallable =
  ## getParametersForImport
  ## <p>Returns the items you need in order to import key material into AWS KMS from your existing key management infrastructure. For more information about importing key material into AWS KMS, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>You must specify the key ID of the customer master key (CMK) into which you will import key material. This CMK's <code>Origin</code> must be <code>EXTERNAL</code>. You must also specify the wrapping algorithm and type of wrapping key (public key) that you will use to encrypt the key material. You cannot perform this operation on a CMK in a different AWS account.</p> <p>This operation returns a public key and an import token. Use the public key to encrypt the key material. Store the import token to send with a subsequent <a>ImportKeyMaterial</a> request. The public key and import token from the same response must be used together. These items are valid for 24 hours. When they expire, they cannot be used for a subsequent <a>ImportKeyMaterial</a> request. To get new ones, send another <code>GetParametersForImport</code> request.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var getParametersForImport* = Call_GetParametersForImport_603402(
    name: "getParametersForImport", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.GetParametersForImport",
    validator: validate_GetParametersForImport_603403, base: "/",
    url: url_GetParametersForImport_603404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportKeyMaterial_603417 = ref object of OpenApiRestCall_602466
proc url_ImportKeyMaterial_603419(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportKeyMaterial_603418(path: JsonNode; query: JsonNode;
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
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true, default = newJString(
      "TrentService.ImportKeyMaterial"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_ImportKeyMaterial_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports key material into an existing AWS KMS customer master key (CMK) that was created without key material. You cannot perform this operation on a CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. This token and the public key used to encrypt the key material must have come from the same response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, you can change it only by reimporting the same key material and specifying a new expiration date. If the key material expires, AWS KMS deletes the key material and the CMK becomes unusable. To use the CMK again, you must reimport the same key material.</p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK. After you successfully import key material into a CMK, you can reimport the same key material into that CMK, but you cannot import different key material.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_ImportKeyMaterial_603417; body: JsonNode): Recallable =
  ## importKeyMaterial
  ## <p>Imports key material into an existing AWS KMS customer master key (CMK) that was created without key material. You cannot perform this operation on a CMK in a different AWS account. For more information about creating CMKs with no key material and then importing key material, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html">Importing Key Material</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>Before using this operation, call <a>GetParametersForImport</a>. Its response includes a public key and an import token. Use the public key to encrypt the key material. Then, submit the import token from the same <code>GetParametersForImport</code> response.</p> <p>When calling this operation, you must specify the following values:</p> <ul> <li> <p>The key ID or key ARN of a CMK with no key material. Its <code>Origin</code> must be <code>EXTERNAL</code>.</p> <p>To create a CMK with no key material, call <a>CreateKey</a> and set the value of its <code>Origin</code> parameter to <code>EXTERNAL</code>. To get the <code>Origin</code> of a CMK, call <a>DescribeKey</a>.)</p> </li> <li> <p>The encrypted key material. To get the public key to encrypt the key material, call <a>GetParametersForImport</a>.</p> </li> <li> <p>The import token that <a>GetParametersForImport</a> returned. This token and the public key used to encrypt the key material must have come from the same response.</p> </li> <li> <p>Whether the key material expires and if so, when. If you set an expiration date, you can change it only by reimporting the same key material and specifying a new expiration date. If the key material expires, AWS KMS deletes the key material and the CMK becomes unusable. To use the CMK again, you must reimport the same key material.</p> </li> </ul> <p>When this operation is successful, the key state of the CMK changes from <code>PendingImport</code> to <code>Enabled</code>, and you can use the CMK. After you successfully import key material into a CMK, you can reimport the same key material into that CMK, but you cannot import different key material.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603431 = newJObject()
  if body != nil:
    body_603431 = body
  result = call_603430.call(nil, nil, nil, nil, body_603431)

var importKeyMaterial* = Call_ImportKeyMaterial_603417(name: "importKeyMaterial",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ImportKeyMaterial",
    validator: validate_ImportKeyMaterial_603418, base: "/",
    url: url_ImportKeyMaterial_603419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_603432 = ref object of OpenApiRestCall_602466
proc url_ListAliases_603434(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAliases_603433(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603435 = query.getOrDefault("Limit")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "Limit", valid_603435
  var valid_603436 = query.getOrDefault("Marker")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "Marker", valid_603436
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
  var valid_603437 = header.getOrDefault("X-Amz-Date")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Date", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Security-Token")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Security-Token", valid_603438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603439 = header.getOrDefault("X-Amz-Target")
  valid_603439 = validateParameter(valid_603439, JString, required = true, default = newJString(
      "TrentService.ListAliases"))
  if valid_603439 != nil:
    section.add "X-Amz-Target", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Content-Sha256", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Algorithm")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Algorithm", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Signature")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Signature", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-SignedHeaders", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Credential")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Credential", valid_603444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603446: Call_ListAliases_603432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases limit</a>.</p>
  ## 
  let valid = call_603446.validator(path, query, header, formData, body)
  let scheme = call_603446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603446.url(scheme.get, call_603446.host, call_603446.base,
                         call_603446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603446, url, valid)

proc call*(call_603447: Call_ListAliases_603432; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listAliases
  ## <p>Gets a list of aliases in the caller's AWS account and region. You cannot list aliases in other accounts. For more information about aliases, see <a>CreateAlias</a>.</p> <p>By default, the ListAliases command returns all aliases in the account and region. To get only the aliases that point to a particular customer master key (CMK), use the <code>KeyId</code> parameter.</p> <p>The <code>ListAliases</code> response can include aliases that you created and associated with your customer managed CMKs, and aliases that AWS created and associated with AWS managed CMKs in your account. You can recognize AWS aliases because their names have the format <code>aws/&lt;service-name&gt;</code>, such as <code>aws/dynamodb</code>.</p> <p>The response might also include aliases that have no <code>TargetKeyId</code> field. These are predefined aliases that AWS has created but has not yet associated with a CMK. Aliases that AWS creates in your account, including predefined aliases, do not count against your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#aliases-limit">AWS KMS aliases limit</a>.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603448 = newJObject()
  var body_603449 = newJObject()
  add(query_603448, "Limit", newJString(Limit))
  add(query_603448, "Marker", newJString(Marker))
  if body != nil:
    body_603449 = body
  result = call_603447.call(nil, query_603448, nil, nil, body_603449)

var listAliases* = Call_ListAliases_603432(name: "listAliases",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListAliases",
                                        validator: validate_ListAliases_603433,
                                        base: "/", url: url_ListAliases_603434,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGrants_603451 = ref object of OpenApiRestCall_602466
proc url_ListGrants_603453(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGrants_603452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603454 = query.getOrDefault("Limit")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "Limit", valid_603454
  var valid_603455 = query.getOrDefault("Marker")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "Marker", valid_603455
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
  var valid_603456 = header.getOrDefault("X-Amz-Date")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Date", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Security-Token")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Security-Token", valid_603457
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603458 = header.getOrDefault("X-Amz-Target")
  valid_603458 = validateParameter(valid_603458, JString, required = true, default = newJString(
      "TrentService.ListGrants"))
  if valid_603458 != nil:
    section.add "X-Amz-Target", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Content-Sha256", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Algorithm")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Algorithm", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Signature")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Signature", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-SignedHeaders", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Credential")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Credential", valid_603463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603465: Call_ListGrants_603451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_603465.validator(path, query, header, formData, body)
  let scheme = call_603465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603465.url(scheme.get, call_603465.host, call_603465.base,
                         call_603465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603465, url, valid)

proc call*(call_603466: Call_ListGrants_603451; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listGrants
  ## <p>Gets a list of all grants for the specified customer master key (CMK).</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603467 = newJObject()
  var body_603468 = newJObject()
  add(query_603467, "Limit", newJString(Limit))
  add(query_603467, "Marker", newJString(Marker))
  if body != nil:
    body_603468 = body
  result = call_603466.call(nil, query_603467, nil, nil, body_603468)

var listGrants* = Call_ListGrants_603451(name: "listGrants",
                                      meth: HttpMethod.HttpPost,
                                      host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListGrants",
                                      validator: validate_ListGrants_603452,
                                      base: "/", url: url_ListGrants_603453,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeyPolicies_603469 = ref object of OpenApiRestCall_602466
proc url_ListKeyPolicies_603471(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListKeyPolicies_603470(path: JsonNode; query: JsonNode;
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
  var valid_603472 = query.getOrDefault("Limit")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "Limit", valid_603472
  var valid_603473 = query.getOrDefault("Marker")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "Marker", valid_603473
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
  var valid_603474 = header.getOrDefault("X-Amz-Date")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Date", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Security-Token")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Security-Token", valid_603475
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603476 = header.getOrDefault("X-Amz-Target")
  valid_603476 = validateParameter(valid_603476, JString, required = true, default = newJString(
      "TrentService.ListKeyPolicies"))
  if valid_603476 != nil:
    section.add "X-Amz-Target", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Content-Sha256", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Algorithm")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Algorithm", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Signature")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Signature", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-SignedHeaders", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Credential")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Credential", valid_603481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603483: Call_ListKeyPolicies_603469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ## 
  let valid = call_603483.validator(path, query, header, formData, body)
  let scheme = call_603483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603483.url(scheme.get, call_603483.host, call_603483.base,
                         call_603483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603483, url, valid)

proc call*(call_603484: Call_ListKeyPolicies_603469; body: JsonNode;
          Limit: string = ""; Marker: string = ""): Recallable =
  ## listKeyPolicies
  ## Gets the names of the key policies that are attached to a customer master key (CMK). This operation is designed to get policy names that you can use in a <a>GetKeyPolicy</a> operation. However, the only valid policy name is <code>default</code>. You cannot perform this operation on a CMK in a different AWS account.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603485 = newJObject()
  var body_603486 = newJObject()
  add(query_603485, "Limit", newJString(Limit))
  add(query_603485, "Marker", newJString(Marker))
  if body != nil:
    body_603486 = body
  result = call_603484.call(nil, query_603485, nil, nil, body_603486)

var listKeyPolicies* = Call_ListKeyPolicies_603469(name: "listKeyPolicies",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListKeyPolicies",
    validator: validate_ListKeyPolicies_603470, base: "/", url: url_ListKeyPolicies_603471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKeys_603487 = ref object of OpenApiRestCall_602466
proc url_ListKeys_603489(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListKeys_603488(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603490 = query.getOrDefault("Limit")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "Limit", valid_603490
  var valid_603491 = query.getOrDefault("Marker")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "Marker", valid_603491
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
  var valid_603492 = header.getOrDefault("X-Amz-Date")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Date", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Security-Token")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Security-Token", valid_603493
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603494 = header.getOrDefault("X-Amz-Target")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = newJString("TrentService.ListKeys"))
  if valid_603494 != nil:
    section.add "X-Amz-Target", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Content-Sha256", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Algorithm")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Algorithm", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Signature")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Signature", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-SignedHeaders", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Credential")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Credential", valid_603499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603501: Call_ListKeys_603487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and region.
  ## 
  let valid = call_603501.validator(path, query, header, formData, body)
  let scheme = call_603501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603501.url(scheme.get, call_603501.host, call_603501.base,
                         call_603501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603501, url, valid)

proc call*(call_603502: Call_ListKeys_603487; body: JsonNode; Limit: string = "";
          Marker: string = ""): Recallable =
  ## listKeys
  ## Gets a list of all customer master keys (CMKs) in the caller's AWS account and region.
  ##   Limit: string
  ##        : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603503 = newJObject()
  var body_603504 = newJObject()
  add(query_603503, "Limit", newJString(Limit))
  add(query_603503, "Marker", newJString(Marker))
  if body != nil:
    body_603504 = body
  result = call_603502.call(nil, query_603503, nil, nil, body_603504)

var listKeys* = Call_ListKeys_603487(name: "listKeys", meth: HttpMethod.HttpPost,
                                  host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ListKeys",
                                  validator: validate_ListKeys_603488, base: "/",
                                  url: url_ListKeys_603489,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceTags_603505 = ref object of OpenApiRestCall_602466
proc url_ListResourceTags_603507(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourceTags_603506(path: JsonNode; query: JsonNode;
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
  var valid_603508 = header.getOrDefault("X-Amz-Date")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Date", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Security-Token")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Security-Token", valid_603509
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603510 = header.getOrDefault("X-Amz-Target")
  valid_603510 = validateParameter(valid_603510, JString, required = true, default = newJString(
      "TrentService.ListResourceTags"))
  if valid_603510 != nil:
    section.add "X-Amz-Target", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Content-Sha256", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Algorithm")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Algorithm", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Signature")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Signature", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-SignedHeaders", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Credential")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Credential", valid_603515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603517: Call_ListResourceTags_603505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
  ## 
  let valid = call_603517.validator(path, query, header, formData, body)
  let scheme = call_603517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603517.url(scheme.get, call_603517.host, call_603517.base,
                         call_603517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603517, url, valid)

proc call*(call_603518: Call_ListResourceTags_603505; body: JsonNode): Recallable =
  ## listResourceTags
  ## <p>Returns a list of all tags for the specified customer master key (CMK).</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p>
  ##   body: JObject (required)
  var body_603519 = newJObject()
  if body != nil:
    body_603519 = body
  result = call_603518.call(nil, nil, nil, nil, body_603519)

var listResourceTags* = Call_ListResourceTags_603505(name: "listResourceTags",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListResourceTags",
    validator: validate_ListResourceTags_603506, base: "/",
    url: url_ListResourceTags_603507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRetirableGrants_603520 = ref object of OpenApiRestCall_602466
proc url_ListRetirableGrants_603522(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRetirableGrants_603521(path: JsonNode; query: JsonNode;
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
  var valid_603523 = header.getOrDefault("X-Amz-Date")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Date", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Security-Token")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Security-Token", valid_603524
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603525 = header.getOrDefault("X-Amz-Target")
  valid_603525 = validateParameter(valid_603525, JString, required = true, default = newJString(
      "TrentService.ListRetirableGrants"))
  if valid_603525 != nil:
    section.add "X-Amz-Target", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Content-Sha256", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Algorithm")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Algorithm", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Signature")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Signature", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-SignedHeaders", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Credential")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Credential", valid_603530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603532: Call_ListRetirableGrants_603520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
  ## 
  let valid = call_603532.validator(path, query, header, formData, body)
  let scheme = call_603532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603532.url(scheme.get, call_603532.host, call_603532.base,
                         call_603532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603532, url, valid)

proc call*(call_603533: Call_ListRetirableGrants_603520; body: JsonNode): Recallable =
  ## listRetirableGrants
  ## <p>Returns a list of all grants for which the grant's <code>RetiringPrincipal</code> matches the one specified.</p> <p>A typical use is to list all grants that you are able to retire. To retire a grant, use <a>RetireGrant</a>.</p>
  ##   body: JObject (required)
  var body_603534 = newJObject()
  if body != nil:
    body_603534 = body
  result = call_603533.call(nil, nil, nil, nil, body_603534)

var listRetirableGrants* = Call_ListRetirableGrants_603520(
    name: "listRetirableGrants", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ListRetirableGrants",
    validator: validate_ListRetirableGrants_603521, base: "/",
    url: url_ListRetirableGrants_603522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutKeyPolicy_603535 = ref object of OpenApiRestCall_602466
proc url_PutKeyPolicy_603537(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutKeyPolicy_603536(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603538 = header.getOrDefault("X-Amz-Date")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Date", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Security-Token")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Security-Token", valid_603539
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603540 = header.getOrDefault("X-Amz-Target")
  valid_603540 = validateParameter(valid_603540, JString, required = true, default = newJString(
      "TrentService.PutKeyPolicy"))
  if valid_603540 != nil:
    section.add "X-Amz-Target", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Content-Sha256", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Algorithm")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Algorithm", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Signature")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Signature", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-SignedHeaders", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Credential")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Credential", valid_603545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603547: Call_PutKeyPolicy_603535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603547.validator(path, query, header, formData, body)
  let scheme = call_603547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603547.url(scheme.get, call_603547.host, call_603547.base,
                         call_603547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603547, url, valid)

proc call*(call_603548: Call_PutKeyPolicy_603535; body: JsonNode): Recallable =
  ## putKeyPolicy
  ## <p>Attaches a key policy to the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about key policies, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">Key Policies</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603549 = newJObject()
  if body != nil:
    body_603549 = body
  result = call_603548.call(nil, nil, nil, nil, body_603549)

var putKeyPolicy* = Call_PutKeyPolicy_603535(name: "putKeyPolicy",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.PutKeyPolicy",
    validator: validate_PutKeyPolicy_603536, base: "/", url: url_PutKeyPolicy_603537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReEncrypt_603550 = ref object of OpenApiRestCall_602466
proc url_ReEncrypt_603552(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ReEncrypt_603551(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603553 = header.getOrDefault("X-Amz-Date")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Date", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Security-Token")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Security-Token", valid_603554
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603555 = header.getOrDefault("X-Amz-Target")
  valid_603555 = validateParameter(valid_603555, JString, required = true,
                                 default = newJString("TrentService.ReEncrypt"))
  if valid_603555 != nil:
    section.add "X-Amz-Target", valid_603555
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_ReEncrypt_603550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Encrypts data on the server side with a new customer master key (CMK) without exposing the plaintext of the data on the client side. The data is first decrypted and then reencrypted. You can also use this operation to change the encryption context of a ciphertext. </p> <p>You can reencrypt data using CMKs in different AWS accounts.</p> <p>Unlike other operations, <code>ReEncrypt</code> is authorized twice, once as <code>ReEncryptFrom</code> on the source CMK and once as <code>ReEncryptTo</code> on the destination CMK. We recommend that you include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policies</a> to permit reencryption from or to the CMK. This permission is automatically included in the key policy when you create a CMK through the console. But you must include it manually when you create a CMK programmatically or when you set a key policy with the <a>PutKeyPolicy</a> operation.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603562, url, valid)

proc call*(call_603563: Call_ReEncrypt_603550; body: JsonNode): Recallable =
  ## reEncrypt
  ## <p>Encrypts data on the server side with a new customer master key (CMK) without exposing the plaintext of the data on the client side. The data is first decrypted and then reencrypted. You can also use this operation to change the encryption context of a ciphertext. </p> <p>You can reencrypt data using CMKs in different AWS accounts.</p> <p>Unlike other operations, <code>ReEncrypt</code> is authorized twice, once as <code>ReEncryptFrom</code> on the source CMK and once as <code>ReEncryptTo</code> on the destination CMK. We recommend that you include the <code>"kms:ReEncrypt*"</code> permission in your <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html">key policies</a> to permit reencryption from or to the CMK. This permission is automatically included in the key policy when you create a CMK through the console. But you must include it manually when you create a CMK programmatically or when you set a key policy with the <a>PutKeyPolicy</a> operation.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603564 = newJObject()
  if body != nil:
    body_603564 = body
  result = call_603563.call(nil, nil, nil, nil, body_603564)

var reEncrypt* = Call_ReEncrypt_603550(name: "reEncrypt", meth: HttpMethod.HttpPost,
                                    host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.ReEncrypt",
                                    validator: validate_ReEncrypt_603551,
                                    base: "/", url: url_ReEncrypt_603552,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetireGrant_603565 = ref object of OpenApiRestCall_602466
proc url_RetireGrant_603567(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RetireGrant_603566(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603568 = header.getOrDefault("X-Amz-Date")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Date", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Security-Token")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Security-Token", valid_603569
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603570 = header.getOrDefault("X-Amz-Target")
  valid_603570 = validateParameter(valid_603570, JString, required = true, default = newJString(
      "TrentService.RetireGrant"))
  if valid_603570 != nil:
    section.add "X-Amz-Target", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Content-Sha256", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Algorithm")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Algorithm", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Signature")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Signature", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-SignedHeaders", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Credential")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Credential", valid_603575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603577: Call_RetireGrant_603565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
  ## 
  let valid = call_603577.validator(path, query, header, formData, body)
  let scheme = call_603577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603577.url(scheme.get, call_603577.host, call_603577.base,
                         call_603577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603577, url, valid)

proc call*(call_603578: Call_RetireGrant_603565; body: JsonNode): Recallable =
  ## retireGrant
  ## <p>Retires a grant. To clean up, you can retire a grant when you're done using it. You should revoke a grant when you intend to actively deny operations that depend on it. The following are permitted to call this API:</p> <ul> <li> <p>The AWS account (root user) under which the grant was created</p> </li> <li> <p>The <code>RetiringPrincipal</code>, if present in the grant</p> </li> <li> <p>The <code>GranteePrincipal</code>, if <code>RetireGrant</code> is an operation specified in the grant</p> </li> </ul> <p>You must identify the grant to retire by its grant token or by a combination of the grant ID and the Amazon Resource Name (ARN) of the customer master key (CMK). A grant token is a unique variable-length base64-encoded string. A grant ID is a 64 character unique identifier of a grant. The <a>CreateGrant</a> operation returns both.</p>
  ##   body: JObject (required)
  var body_603579 = newJObject()
  if body != nil:
    body_603579 = body
  result = call_603578.call(nil, nil, nil, nil, body_603579)

var retireGrant* = Call_RetireGrant_603565(name: "retireGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.RetireGrant",
                                        validator: validate_RetireGrant_603566,
                                        base: "/", url: url_RetireGrant_603567,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeGrant_603580 = ref object of OpenApiRestCall_602466
proc url_RevokeGrant_603582(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RevokeGrant_603581(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603583 = header.getOrDefault("X-Amz-Date")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Date", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Security-Token")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Security-Token", valid_603584
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603585 = header.getOrDefault("X-Amz-Target")
  valid_603585 = validateParameter(valid_603585, JString, required = true, default = newJString(
      "TrentService.RevokeGrant"))
  if valid_603585 != nil:
    section.add "X-Amz-Target", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Algorithm")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Algorithm", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Signature")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Signature", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Credential")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Credential", valid_603590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_RevokeGrant_603580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ## 
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_RevokeGrant_603580; body: JsonNode): Recallable =
  ## revokeGrant
  ## <p>Revokes the specified grant for the specified customer master key (CMK). You can revoke a grant to actively deny operations that depend on it.</p> <p>To perform this operation on a CMK in a different AWS account, specify the key ARN in the value of the <code>KeyId</code> parameter.</p>
  ##   body: JObject (required)
  var body_603594 = newJObject()
  if body != nil:
    body_603594 = body
  result = call_603593.call(nil, nil, nil, nil, body_603594)

var revokeGrant* = Call_RevokeGrant_603580(name: "revokeGrant",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.RevokeGrant",
                                        validator: validate_RevokeGrant_603581,
                                        base: "/", url: url_RevokeGrant_603582,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScheduleKeyDeletion_603595 = ref object of OpenApiRestCall_602466
proc url_ScheduleKeyDeletion_603597(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ScheduleKeyDeletion_603596(path: JsonNode; query: JsonNode;
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
  var valid_603598 = header.getOrDefault("X-Amz-Date")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Date", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Security-Token")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Security-Token", valid_603599
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603600 = header.getOrDefault("X-Amz-Target")
  valid_603600 = validateParameter(valid_603600, JString, required = true, default = newJString(
      "TrentService.ScheduleKeyDeletion"))
  if valid_603600 != nil:
    section.add "X-Amz-Target", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Algorithm")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Algorithm", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Signature")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Signature", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-SignedHeaders", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Credential")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Credential", valid_603605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603607: Call_ScheduleKeyDeletion_603595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603607.validator(path, query, header, formData, body)
  let scheme = call_603607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603607.url(scheme.get, call_603607.host, call_603607.base,
                         call_603607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603607, url, valid)

proc call*(call_603608: Call_ScheduleKeyDeletion_603595; body: JsonNode): Recallable =
  ## scheduleKeyDeletion
  ## <p>Schedules the deletion of a customer master key (CMK). You may provide a waiting period, specified in days, before deletion occurs. If you do not provide a waiting period, the default period of 30 days is used. When this operation is successful, the key state of the CMK changes to <code>PendingDeletion</code>. Before the waiting period ends, you can use <a>CancelKeyDeletion</a> to cancel the deletion of the CMK. After the waiting period ends, AWS KMS deletes the CMK and all AWS KMS data associated with it, including all aliases that refer to it.</p> <important> <p>Deleting a CMK is a destructive and potentially dangerous operation. When a CMK is deleted, all data that was encrypted under the CMK is unrecoverable. To prevent the use of a CMK without deleting it, use <a>DisableKey</a>.</p> </important> <p>If you schedule deletion of a CMK from a <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">custom key store</a>, when the waiting period expires, <code>ScheduleKeyDeletion</code> deletes the CMK from AWS KMS. Then AWS KMS makes a best effort to delete the key material from the associated AWS CloudHSM cluster. However, you might need to manually <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key">delete the orphaned key material</a> from the cluster and its backups.</p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>For more information about scheduling a CMK for deletion, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html">Deleting Customer Master Keys</a> in the <i>AWS Key Management Service Developer Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603609 = newJObject()
  if body != nil:
    body_603609 = body
  result = call_603608.call(nil, nil, nil, nil, body_603609)

var scheduleKeyDeletion* = Call_ScheduleKeyDeletion_603595(
    name: "scheduleKeyDeletion", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.ScheduleKeyDeletion",
    validator: validate_ScheduleKeyDeletion_603596, base: "/",
    url: url_ScheduleKeyDeletion_603597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603610 = ref object of OpenApiRestCall_602466
proc url_TagResource_603612(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603611(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603613 = header.getOrDefault("X-Amz-Date")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Date", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Security-Token")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Security-Token", valid_603614
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603615 = header.getOrDefault("X-Amz-Target")
  valid_603615 = validateParameter(valid_603615, JString, required = true, default = newJString(
      "TrentService.TagResource"))
  if valid_603615 != nil:
    section.add "X-Amz-Target", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Content-Sha256", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Algorithm")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Algorithm", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Signature")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Signature", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-SignedHeaders", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Credential")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Credential", valid_603620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_TagResource_603610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603622, url, valid)

proc call*(call_603623: Call_TagResource_603610; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty (null) strings.</p> <p>You can only use a tag key once for each CMK. If you use the tag key again, AWS KMS replaces the current tag value with the specified value.</p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603624 = newJObject()
  if body != nil:
    body_603624 = body
  result = call_603623.call(nil, nil, nil, nil, body_603624)

var tagResource* = Call_TagResource_603610(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.TagResource",
                                        validator: validate_TagResource_603611,
                                        base: "/", url: url_TagResource_603612,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603625 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603627(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603626(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603628 = header.getOrDefault("X-Amz-Date")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Date", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Security-Token")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Security-Token", valid_603629
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603630 = header.getOrDefault("X-Amz-Target")
  valid_603630 = validateParameter(valid_603630, JString, required = true, default = newJString(
      "TrentService.UntagResource"))
  if valid_603630 != nil:
    section.add "X-Amz-Target", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Content-Sha256", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Algorithm")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Algorithm", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Signature")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Signature", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-SignedHeaders", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Credential")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Credential", valid_603635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603637: Call_UntagResource_603625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603637.validator(path, query, header, formData, body)
  let scheme = call_603637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603637.url(scheme.get, call_603637.host, call_603637.base,
                         call_603637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603637, url, valid)

proc call*(call_603638: Call_UntagResource_603625; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified customer master key (CMK). You cannot perform this operation on a CMK in a different AWS account.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a>TagResource</a>.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603639 = newJObject()
  if body != nil:
    body_603639 = body
  result = call_603638.call(nil, nil, nil, nil, body_603639)

var untagResource* = Call_UntagResource_603625(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UntagResource",
    validator: validate_UntagResource_603626, base: "/", url: url_UntagResource_603627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_603640 = ref object of OpenApiRestCall_602466
proc url_UpdateAlias_603642(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAlias_603641(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603643 = header.getOrDefault("X-Amz-Date")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Date", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Security-Token")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Security-Token", valid_603644
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603645 = header.getOrDefault("X-Amz-Target")
  valid_603645 = validateParameter(valid_603645, JString, required = true, default = newJString(
      "TrentService.UpdateAlias"))
  if valid_603645 != nil:
    section.add "X-Amz-Target", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Content-Sha256", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Algorithm")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Algorithm", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Signature")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Signature", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-SignedHeaders", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Credential")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Credential", valid_603650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603652: Call_UpdateAlias_603640; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an existing alias with a different customer master key (CMK). Each CMK can have multiple aliases, but the aliases must be unique within the account and region. You cannot perform this operation on an alias in a different AWS account.</p> <p>This operation works only on existing aliases. To change the alias of a CMK to a new value, use <a>CreateAlias</a> to create a new alias and <a>DeleteAlias</a> to delete the old alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603652.validator(path, query, header, formData, body)
  let scheme = call_603652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603652.url(scheme.get, call_603652.host, call_603652.base,
                         call_603652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603652, url, valid)

proc call*(call_603653: Call_UpdateAlias_603640; body: JsonNode): Recallable =
  ## updateAlias
  ## <p>Associates an existing alias with a different customer master key (CMK). Each CMK can have multiple aliases, but the aliases must be unique within the account and region. You cannot perform this operation on an alias in a different AWS account.</p> <p>This operation works only on existing aliases. To change the alias of a CMK to a new value, use <a>CreateAlias</a> to create a new alias and <a>DeleteAlias</a> to delete the old alias.</p> <p>Because an alias is not a property of a CMK, you can create, update, and delete the aliases of a CMK without affecting the CMK. Also, aliases do not appear in the response from the <a>DescribeKey</a> operation. To get the aliases of all CMKs in the account, use the <a>ListAliases</a> operation. </p> <p>The alias name must begin with <code>alias/</code> followed by a name, such as <code>alias/ExampleAlias</code>. It can contain only alphanumeric characters, forward slashes (/), underscores (_), and dashes (-). The alias name cannot begin with <code>alias/aws/</code>. The <code>alias/aws/</code> prefix is reserved for <a href="https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk">AWS managed CMKs</a>. </p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603654 = newJObject()
  if body != nil:
    body_603654 = body
  result = call_603653.call(nil, nil, nil, nil, body_603654)

var updateAlias* = Call_UpdateAlias_603640(name: "updateAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "kms.amazonaws.com", route: "/#X-Amz-Target=TrentService.UpdateAlias",
                                        validator: validate_UpdateAlias_603641,
                                        base: "/", url: url_UpdateAlias_603642,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCustomKeyStore_603655 = ref object of OpenApiRestCall_602466
proc url_UpdateCustomKeyStore_603657(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCustomKeyStore_603656(path: JsonNode; query: JsonNode;
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
  var valid_603658 = header.getOrDefault("X-Amz-Date")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Date", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Security-Token")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Security-Token", valid_603659
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603660 = header.getOrDefault("X-Amz-Target")
  valid_603660 = validateParameter(valid_603660, JString, required = true, default = newJString(
      "TrentService.UpdateCustomKeyStore"))
  if valid_603660 != nil:
    section.add "X-Amz-Target", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Content-Sha256", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Algorithm")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Algorithm", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Signature")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Signature", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-SignedHeaders", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Credential")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Credential", valid_603665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603667: Call_UpdateCustomKeyStore_603655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ## 
  let valid = call_603667.validator(path, query, header, formData, body)
  let scheme = call_603667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603667.url(scheme.get, call_603667.host, call_603667.base,
                         call_603667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603667, url, valid)

proc call*(call_603668: Call_UpdateCustomKeyStore_603655; body: JsonNode): Recallable =
  ## updateCustomKeyStore
  ## <p>Changes the properties of a custom key store. Use the <code>CustomKeyStoreId</code> parameter to identify the custom key store you want to edit. Use the remaining parameters to change the properties of the custom key store.</p> <p>You can only update a custom key store that is disconnected. To disconnect the custom key store, use <a>DisconnectCustomKeyStore</a>. To reconnect the custom key store after the update completes, use <a>ConnectCustomKeyStore</a>. To find the connection state of a custom key store, use the <a>DescribeCustomKeyStores</a> operation.</p> <p>Use the parameters of <code>UpdateCustomKeyStore</code> to edit your keystore settings.</p> <ul> <li> <p>Use the <b>NewCustomKeyStoreName</b> parameter to change the friendly name of the custom key store to the value that you specify.</p> <p> </p> </li> <li> <p>Use the <b>KeyStorePassword</b> parameter tell AWS KMS the current password of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-store-concepts.html#concept-kmsuser"> <code>kmsuser</code> crypto user (CU)</a> in the associated AWS CloudHSM cluster. You can use this parameter to <a href="https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-password">fix connection failures</a> that occur when AWS KMS cannot log into the associated cluster because the <code>kmsuser</code> password has changed. This value does not change the password in the AWS CloudHSM cluster.</p> <p> </p> </li> <li> <p>Use the <b>CloudHsmClusterId</b> parameter to associate the custom key store with a different, but related, AWS CloudHSM cluster. You can use this parameter to repair a custom key store if its AWS CloudHSM cluster becomes corrupted or is deleted, or when you need to create or restore a cluster from a backup. </p> </li> </ul> <p>If the operation succeeds, it returns a JSON object with no properties.</p> <p>This operation is part of the <a href="https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html">Custom Key Store feature</a> feature in AWS KMS, which combines the convenience and extensive integration of AWS KMS with the isolation and control of a single-tenant key store.</p>
  ##   body: JObject (required)
  var body_603669 = newJObject()
  if body != nil:
    body_603669 = body
  result = call_603668.call(nil, nil, nil, nil, body_603669)

var updateCustomKeyStore* = Call_UpdateCustomKeyStore_603655(
    name: "updateCustomKeyStore", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateCustomKeyStore",
    validator: validate_UpdateCustomKeyStore_603656, base: "/",
    url: url_UpdateCustomKeyStore_603657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateKeyDescription_603670 = ref object of OpenApiRestCall_602466
proc url_UpdateKeyDescription_603672(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateKeyDescription_603671(path: JsonNode; query: JsonNode;
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
  var valid_603673 = header.getOrDefault("X-Amz-Date")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Date", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Security-Token")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Security-Token", valid_603674
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603675 = header.getOrDefault("X-Amz-Target")
  valid_603675 = validateParameter(valid_603675, JString, required = true, default = newJString(
      "TrentService.UpdateKeyDescription"))
  if valid_603675 != nil:
    section.add "X-Amz-Target", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Content-Sha256", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Algorithm")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Algorithm", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Signature")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Signature", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-SignedHeaders", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Credential")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Credential", valid_603680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603682: Call_UpdateKeyDescription_603670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ## 
  let valid = call_603682.validator(path, query, header, formData, body)
  let scheme = call_603682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603682.url(scheme.get, call_603682.host, call_603682.base,
                         call_603682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603682, url, valid)

proc call*(call_603683: Call_UpdateKeyDescription_603670; body: JsonNode): Recallable =
  ## updateKeyDescription
  ## <p>Updates the description of a customer master key (CMK). To see the description of a CMK, use <a>DescribeKey</a>. </p> <p>You cannot perform this operation on a CMK in a different AWS account.</p> <p>The result of this operation varies with the key state of the CMK. For details, see <a href="https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html">How Key State Affects Use of a Customer Master Key</a> in the <i>AWS Key Management Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603684 = newJObject()
  if body != nil:
    body_603684 = body
  result = call_603683.call(nil, nil, nil, nil, body_603684)

var updateKeyDescription* = Call_UpdateKeyDescription_603670(
    name: "updateKeyDescription", meth: HttpMethod.HttpPost,
    host: "kms.amazonaws.com",
    route: "/#X-Amz-Target=TrentService.UpdateKeyDescription",
    validator: validate_UpdateKeyDescription_603671, base: "/",
    url: url_UpdateKeyDescription_603672, schemes: {Scheme.Https, Scheme.Http})
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
