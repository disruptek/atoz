
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Glacier
## version: 2012-06-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p> Amazon S3 Glacier (Glacier) is a storage solution for "cold data."</p> <p>Glacier is an extremely low-cost storage service that provides secure, durable, and easy-to-use storage for data backup and archival. With Glacier, customers can store their data cost effectively for months, years, or decades. Glacier also enables customers to offload the administrative burdens of operating and scaling storage to AWS, so they don't have to worry about capacity planning, hardware provisioning, data replication, hardware failure and recovery, or time-consuming hardware migrations.</p> <p>Glacier is a great storage choice when low storage cost is paramount and your data is rarely retrieved. If your application requires fast or frequent access to your data, consider using Amazon S3. For more information, see <a href="http://aws.amazon.com/s3/">Amazon Simple Storage Service (Amazon S3)</a>.</p> <p>You can store any kind of data in any format. There is no maximum limit on the total amount of data you can store in Glacier.</p> <p>If you are a first-time user of Glacier, we recommend that you begin by reading the following sections in the <i>Amazon S3 Glacier Developer Guide</i>:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/introduction.html">What is Amazon S3 Glacier</a> - This section of the Developer Guide describes the underlying data model, the operations it supports, and the AWS SDKs that you can use to interact with the service.</p> </li> <li> <p> <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/amazon-glacier-getting-started.html">Getting Started with Amazon S3 Glacier</a> - The Getting Started section walks you through the process of creating a vault, uploading archives, creating jobs to download archives, retrieving the job output, and deleting archives.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/glacier/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "glacier.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glacier.ap-southeast-1.amazonaws.com",
                           "us-west-2": "glacier.us-west-2.amazonaws.com",
                           "eu-west-2": "glacier.eu-west-2.amazonaws.com", "ap-northeast-3": "glacier.ap-northeast-3.amazonaws.com", "eu-central-1": "glacier.eu-central-1.amazonaws.com",
                           "us-east-2": "glacier.us-east-2.amazonaws.com",
                           "us-east-1": "glacier.us-east-1.amazonaws.com", "cn-northwest-1": "glacier.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "glacier.ap-south-1.amazonaws.com",
                           "eu-north-1": "glacier.eu-north-1.amazonaws.com", "ap-northeast-2": "glacier.ap-northeast-2.amazonaws.com",
                           "us-west-1": "glacier.us-west-1.amazonaws.com", "us-gov-east-1": "glacier.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "glacier.eu-west-3.amazonaws.com",
                           "cn-north-1": "glacier.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "glacier.sa-east-1.amazonaws.com",
                           "eu-west-1": "glacier.eu-west-1.amazonaws.com", "us-gov-west-1": "glacier.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glacier.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "glacier.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "glacier.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "glacier.ap-southeast-1.amazonaws.com",
      "us-west-2": "glacier.us-west-2.amazonaws.com",
      "eu-west-2": "glacier.eu-west-2.amazonaws.com",
      "ap-northeast-3": "glacier.ap-northeast-3.amazonaws.com",
      "eu-central-1": "glacier.eu-central-1.amazonaws.com",
      "us-east-2": "glacier.us-east-2.amazonaws.com",
      "us-east-1": "glacier.us-east-1.amazonaws.com",
      "cn-northwest-1": "glacier.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "glacier.ap-south-1.amazonaws.com",
      "eu-north-1": "glacier.eu-north-1.amazonaws.com",
      "ap-northeast-2": "glacier.ap-northeast-2.amazonaws.com",
      "us-west-1": "glacier.us-west-1.amazonaws.com",
      "us-gov-east-1": "glacier.us-gov-east-1.amazonaws.com",
      "eu-west-3": "glacier.eu-west-3.amazonaws.com",
      "cn-north-1": "glacier.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "glacier.sa-east-1.amazonaws.com",
      "eu-west-1": "glacier.eu-west-1.amazonaws.com",
      "us-gov-west-1": "glacier.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "glacier.ap-southeast-2.amazonaws.com",
      "ca-central-1": "glacier.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "glacier"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_UploadMultipartPart_603078 = ref object of OpenApiRestCall_602466
proc url_UploadMultipartPart_603080(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "uploadId" in path, "`uploadId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/multipart-uploads/"),
               (kind: VariableSegment, value: "uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UploadMultipartPart_603079(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>This operation uploads a part of an archive. You can upload archive parts in any order. You can also upload them in parallel. You can upload up to 10,000 parts for a multipart upload.</p> <p>Amazon Glacier rejects your upload part request if any of the following conditions is true:</p> <ul> <li> <p> <b>SHA256 tree hash does not match</b>To ensure that part data is not corrupted in transmission, you compute a SHA256 tree hash of the part and include it in your request. Upon receiving the part data, Amazon S3 Glacier also computes a SHA256 tree hash. If these hash values don't match, the operation fails. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>.</p> </li> <li> <p> <b>Part size does not match</b>The size of each part except the last must match the size specified in the corresponding <a>InitiateMultipartUpload</a> request. The size of the last part must be the same size as, or smaller than, the specified size.</p> <note> <p>If you upload a part whose size is smaller than the part size you specified in your initiate multipart upload request and that part is not the last part, then the upload part request will succeed. However, the subsequent Complete Multipart Upload request will fail.</p> </note> </li> <li> <p> <b>Range does not align</b>The byte range value in the request does not align with the part size specified in the corresponding initiate request. For example, if you specify a part size of 4194304 bytes (4 MB), then 0 to 4194303 bytes (4 MB - 1) and 4194304 (4 MB) to 8388607 (8 MB - 1) are valid part ranges. However, if you set a range value of 2 MB to 6 MB, the range does not align with the part size and the upload will fail. </p> </li> </ul> <p>This operation is idempotent. If you upload the same part multiple times, the data included in the most recent request overwrites the previously uploaded data.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-upload-part.html">Upload Part </a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   uploadId: JString (required)
  ##           : The upload ID of the multipart upload.
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `uploadId` field"
  var valid_603081 = path.getOrDefault("uploadId")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = nil)
  if valid_603081 != nil:
    section.add "uploadId", valid_603081
  var valid_603082 = path.getOrDefault("accountId")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = nil)
  if valid_603082 != nil:
    section.add "accountId", valid_603082
  var valid_603083 = path.getOrDefault("vaultName")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = nil)
  if valid_603083 != nil:
    section.add "vaultName", valid_603083
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
  ##   X-Amz-Credential: JString
  ##   x-amz-sha256-tree-hash: JString
  ##                         : The SHA256 tree hash of the data being uploaded.
  ##   Content-Range: JString
  ##                : Identifies the range of bytes in the assembled archive that will be uploaded in this part. Amazon S3 Glacier uses this information to assemble the archive in the proper sequence. The format of this header follows RFC 2616. An example header is Content-Range:bytes 0-4194303/*.
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
  var valid_603091 = header.getOrDefault("x-amz-sha256-tree-hash")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "x-amz-sha256-tree-hash", valid_603091
  var valid_603092 = header.getOrDefault("Content-Range")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "Content-Range", valid_603092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_UploadMultipartPart_603078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation uploads a part of an archive. You can upload archive parts in any order. You can also upload them in parallel. You can upload up to 10,000 parts for a multipart upload.</p> <p>Amazon Glacier rejects your upload part request if any of the following conditions is true:</p> <ul> <li> <p> <b>SHA256 tree hash does not match</b>To ensure that part data is not corrupted in transmission, you compute a SHA256 tree hash of the part and include it in your request. Upon receiving the part data, Amazon S3 Glacier also computes a SHA256 tree hash. If these hash values don't match, the operation fails. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>.</p> </li> <li> <p> <b>Part size does not match</b>The size of each part except the last must match the size specified in the corresponding <a>InitiateMultipartUpload</a> request. The size of the last part must be the same size as, or smaller than, the specified size.</p> <note> <p>If you upload a part whose size is smaller than the part size you specified in your initiate multipart upload request and that part is not the last part, then the upload part request will succeed. However, the subsequent Complete Multipart Upload request will fail.</p> </note> </li> <li> <p> <b>Range does not align</b>The byte range value in the request does not align with the part size specified in the corresponding initiate request. For example, if you specify a part size of 4194304 bytes (4 MB), then 0 to 4194303 bytes (4 MB - 1) and 4194304 (4 MB) to 8388607 (8 MB - 1) are valid part ranges. However, if you set a range value of 2 MB to 6 MB, the range does not align with the part size and the upload will fail. </p> </li> </ul> <p>This operation is idempotent. If you upload the same part multiple times, the data included in the most recent request overwrites the previously uploaded data.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-upload-part.html">Upload Part </a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603094, url, valid)

proc call*(call_603095: Call_UploadMultipartPart_603078; uploadId: string;
          accountId: string; vaultName: string; body: JsonNode): Recallable =
  ## uploadMultipartPart
  ## <p>This operation uploads a part of an archive. You can upload archive parts in any order. You can also upload them in parallel. You can upload up to 10,000 parts for a multipart upload.</p> <p>Amazon Glacier rejects your upload part request if any of the following conditions is true:</p> <ul> <li> <p> <b>SHA256 tree hash does not match</b>To ensure that part data is not corrupted in transmission, you compute a SHA256 tree hash of the part and include it in your request. Upon receiving the part data, Amazon S3 Glacier also computes a SHA256 tree hash. If these hash values don't match, the operation fails. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>.</p> </li> <li> <p> <b>Part size does not match</b>The size of each part except the last must match the size specified in the corresponding <a>InitiateMultipartUpload</a> request. The size of the last part must be the same size as, or smaller than, the specified size.</p> <note> <p>If you upload a part whose size is smaller than the part size you specified in your initiate multipart upload request and that part is not the last part, then the upload part request will succeed. However, the subsequent Complete Multipart Upload request will fail.</p> </note> </li> <li> <p> <b>Range does not align</b>The byte range value in the request does not align with the part size specified in the corresponding initiate request. For example, if you specify a part size of 4194304 bytes (4 MB), then 0 to 4194303 bytes (4 MB - 1) and 4194304 (4 MB) to 8388607 (8 MB - 1) are valid part ranges. However, if you set a range value of 2 MB to 6 MB, the range does not align with the part size and the upload will fail. </p> </li> </ul> <p>This operation is idempotent. If you upload the same part multiple times, the data included in the most recent request overwrites the previously uploaded data.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-upload-part.html">Upload Part </a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ##   uploadId: string (required)
  ##           : The upload ID of the multipart upload.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   body: JObject (required)
  var path_603096 = newJObject()
  var body_603097 = newJObject()
  add(path_603096, "uploadId", newJString(uploadId))
  add(path_603096, "accountId", newJString(accountId))
  add(path_603096, "vaultName", newJString(vaultName))
  if body != nil:
    body_603097 = body
  result = call_603095.call(path_603096, nil, nil, nil, body_603097)

var uploadMultipartPart* = Call_UploadMultipartPart_603078(
    name: "uploadMultipartPart", meth: HttpMethod.HttpPut,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}",
    validator: validate_UploadMultipartPart_603079, base: "/",
    url: url_UploadMultipartPart_603080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteMultipartUpload_603098 = ref object of OpenApiRestCall_602466
proc url_CompleteMultipartUpload_603100(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "uploadId" in path, "`uploadId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/multipart-uploads/"),
               (kind: VariableSegment, value: "uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CompleteMultipartUpload_603099(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>You call this operation to inform Amazon S3 Glacier (Glacier) that all the archive parts have been uploaded and that Glacier can now assemble the archive from the uploaded parts. After assembling and saving the archive to the vault, Glacier returns the URI path of the newly created archive resource. Using the URI path, you can then access the archive. After you upload an archive, you should save the archive ID returned to retrieve the archive at a later point. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see <a>InitiateJob</a>.</p> <p>In the request, you must include the computed SHA256 tree hash of the entire archive you have uploaded. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>. On the server side, Glacier also constructs the SHA256 tree hash of the assembled archive. If the values match, Glacier saves the archive to the vault; otherwise, it returns an error, and the operation fails. The <a>ListParts</a> operation returns a list of parts uploaded for a specific multipart upload. It includes checksum information for each uploaded part that can be used to debug a bad checksum issue.</p> <p>Additionally, Glacier also checks for any missing content ranges when assembling the archive, if missing content ranges are found, Glacier returns an error and the operation fails.</p> <p>Complete Multipart Upload is an idempotent operation. After your first successful complete multipart upload, if you call the operation again within a short period, the operation will succeed and return the same archive ID. This is useful in the event you experience a network issue that causes an aborted connection or receive a 500 server error, in which case you can repeat your Complete Multipart Upload request and get the same archive ID without creating duplicate archives. Note, however, that after the multipart upload completes, you cannot call the List Parts operation and the multipart upload will not appear in List Multipart Uploads response, even if idempotent complete is possible.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-complete-upload.html">Complete Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   uploadId: JString (required)
  ##           : The upload ID of the multipart upload.
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `uploadId` field"
  var valid_603101 = path.getOrDefault("uploadId")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = nil)
  if valid_603101 != nil:
    section.add "uploadId", valid_603101
  var valid_603102 = path.getOrDefault("accountId")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = nil)
  if valid_603102 != nil:
    section.add "accountId", valid_603102
  var valid_603103 = path.getOrDefault("vaultName")
  valid_603103 = validateParameter(valid_603103, JString, required = true,
                                 default = nil)
  if valid_603103 != nil:
    section.add "vaultName", valid_603103
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
  ##   x-amz-archive-size: JString
  ##                     : The total size, in bytes, of the entire archive. This value should be the sum of all the sizes of the individual parts that you uploaded.
  ##   X-Amz-Credential: JString
  ##   x-amz-sha256-tree-hash: JString
  ##                         : The SHA256 tree hash of the entire archive. It is the tree hash of SHA256 tree hash of the individual parts. If the value you specify in the request does not match the SHA256 tree hash of the final assembled archive as computed by Amazon S3 Glacier (Glacier), Glacier returns an error and the request fails.
  section = newJObject()
  var valid_603104 = header.getOrDefault("X-Amz-Date")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Date", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Security-Token")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Security-Token", valid_603105
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
  var valid_603110 = header.getOrDefault("x-amz-archive-size")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "x-amz-archive-size", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Credential")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Credential", valid_603111
  var valid_603112 = header.getOrDefault("x-amz-sha256-tree-hash")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "x-amz-sha256-tree-hash", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603113: Call_CompleteMultipartUpload_603098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You call this operation to inform Amazon S3 Glacier (Glacier) that all the archive parts have been uploaded and that Glacier can now assemble the archive from the uploaded parts. After assembling and saving the archive to the vault, Glacier returns the URI path of the newly created archive resource. Using the URI path, you can then access the archive. After you upload an archive, you should save the archive ID returned to retrieve the archive at a later point. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see <a>InitiateJob</a>.</p> <p>In the request, you must include the computed SHA256 tree hash of the entire archive you have uploaded. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>. On the server side, Glacier also constructs the SHA256 tree hash of the assembled archive. If the values match, Glacier saves the archive to the vault; otherwise, it returns an error, and the operation fails. The <a>ListParts</a> operation returns a list of parts uploaded for a specific multipart upload. It includes checksum information for each uploaded part that can be used to debug a bad checksum issue.</p> <p>Additionally, Glacier also checks for any missing content ranges when assembling the archive, if missing content ranges are found, Glacier returns an error and the operation fails.</p> <p>Complete Multipart Upload is an idempotent operation. After your first successful complete multipart upload, if you call the operation again within a short period, the operation will succeed and return the same archive ID. This is useful in the event you experience a network issue that causes an aborted connection or receive a 500 server error, in which case you can repeat your Complete Multipart Upload request and get the same archive ID without creating duplicate archives. Note, however, that after the multipart upload completes, you cannot call the List Parts operation and the multipart upload will not appear in List Multipart Uploads response, even if idempotent complete is possible.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-complete-upload.html">Complete Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603113.validator(path, query, header, formData, body)
  let scheme = call_603113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603113.url(scheme.get, call_603113.host, call_603113.base,
                         call_603113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603113, url, valid)

proc call*(call_603114: Call_CompleteMultipartUpload_603098; uploadId: string;
          accountId: string; vaultName: string): Recallable =
  ## completeMultipartUpload
  ## <p>You call this operation to inform Amazon S3 Glacier (Glacier) that all the archive parts have been uploaded and that Glacier can now assemble the archive from the uploaded parts. After assembling and saving the archive to the vault, Glacier returns the URI path of the newly created archive resource. Using the URI path, you can then access the archive. After you upload an archive, you should save the archive ID returned to retrieve the archive at a later point. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see <a>InitiateJob</a>.</p> <p>In the request, you must include the computed SHA256 tree hash of the entire archive you have uploaded. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>. On the server side, Glacier also constructs the SHA256 tree hash of the assembled archive. If the values match, Glacier saves the archive to the vault; otherwise, it returns an error, and the operation fails. The <a>ListParts</a> operation returns a list of parts uploaded for a specific multipart upload. It includes checksum information for each uploaded part that can be used to debug a bad checksum issue.</p> <p>Additionally, Glacier also checks for any missing content ranges when assembling the archive, if missing content ranges are found, Glacier returns an error and the operation fails.</p> <p>Complete Multipart Upload is an idempotent operation. After your first successful complete multipart upload, if you call the operation again within a short period, the operation will succeed and return the same archive ID. This is useful in the event you experience a network issue that causes an aborted connection or receive a 500 server error, in which case you can repeat your Complete Multipart Upload request and get the same archive ID without creating duplicate archives. Note, however, that after the multipart upload completes, you cannot call the List Parts operation and the multipart upload will not appear in List Multipart Uploads response, even if idempotent complete is possible.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-complete-upload.html">Complete Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   uploadId: string (required)
  ##           : The upload ID of the multipart upload.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603115 = newJObject()
  add(path_603115, "uploadId", newJString(uploadId))
  add(path_603115, "accountId", newJString(accountId))
  add(path_603115, "vaultName", newJString(vaultName))
  result = call_603114.call(path_603115, nil, nil, nil, nil)

var completeMultipartUpload* = Call_CompleteMultipartUpload_603098(
    name: "completeMultipartUpload", meth: HttpMethod.HttpPost,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}",
    validator: validate_CompleteMultipartUpload_603099, base: "/",
    url: url_CompleteMultipartUpload_603100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListParts_602803 = ref object of OpenApiRestCall_602466
proc url_ListParts_602805(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "uploadId" in path, "`uploadId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/multipart-uploads/"),
               (kind: VariableSegment, value: "uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListParts_602804(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation lists the parts of an archive that have been uploaded in a specific multipart upload. You can make this request at any time during an in-progress multipart upload before you complete the upload (see <a>CompleteMultipartUpload</a>. List Parts returns an error for completed uploads. The list returned in the List Parts response is sorted by part range. </p> <p>The List Parts operation supports pagination. By default, this operation returns up to 50 uploaded parts in the response. You should always check the response for a <code>marker</code> at which to continue the list; if there are no more items the <code>marker</code> is <code>null</code>. To return a list of parts that begins at a specific part, set the <code>marker</code> request parameter to the value you obtained from a previous List Parts request. You can also limit the number of parts returned in the response by specifying the <code>limit</code> parameter in the request. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-parts.html">List Parts</a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   uploadId: JString (required)
  ##           : The upload ID of the multipart upload.
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `uploadId` field"
  var valid_602931 = path.getOrDefault("uploadId")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "uploadId", valid_602931
  var valid_602932 = path.getOrDefault("accountId")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "accountId", valid_602932
  var valid_602933 = path.getOrDefault("vaultName")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = nil)
  if valid_602933 != nil:
    section.add "vaultName", valid_602933
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : An opaque string used for pagination. This value specifies the part at which the listing of parts should begin. Get the marker value from the response of a previous List Parts response. You need only include the marker if you are continuing the pagination of results started in a previous List Parts request.
  ##   limit: JString
  ##        : The maximum number of parts to be returned. The default limit is 50. The number of parts returned might be fewer than the specified limit, but the number of returned parts never exceeds the limit.
  section = newJObject()
  var valid_602934 = query.getOrDefault("marker")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "marker", valid_602934
  var valid_602935 = query.getOrDefault("limit")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "limit", valid_602935
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
  var valid_602936 = header.getOrDefault("X-Amz-Date")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Date", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Security-Token")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Security-Token", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Content-Sha256", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Algorithm")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Algorithm", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Signature")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Signature", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-SignedHeaders", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Credential")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Credential", valid_602942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602965: Call_ListParts_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation lists the parts of an archive that have been uploaded in a specific multipart upload. You can make this request at any time during an in-progress multipart upload before you complete the upload (see <a>CompleteMultipartUpload</a>. List Parts returns an error for completed uploads. The list returned in the List Parts response is sorted by part range. </p> <p>The List Parts operation supports pagination. By default, this operation returns up to 50 uploaded parts in the response. You should always check the response for a <code>marker</code> at which to continue the list; if there are no more items the <code>marker</code> is <code>null</code>. To return a list of parts that begins at a specific part, set the <code>marker</code> request parameter to the value you obtained from a previous List Parts request. You can also limit the number of parts returned in the response by specifying the <code>limit</code> parameter in the request. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-parts.html">List Parts</a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  let valid = call_602965.validator(path, query, header, formData, body)
  let scheme = call_602965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602965.url(scheme.get, call_602965.host, call_602965.base,
                         call_602965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602965, url, valid)

proc call*(call_603036: Call_ListParts_602803; uploadId: string; accountId: string;
          vaultName: string; marker: string = ""; limit: string = ""): Recallable =
  ## listParts
  ## <p>This operation lists the parts of an archive that have been uploaded in a specific multipart upload. You can make this request at any time during an in-progress multipart upload before you complete the upload (see <a>CompleteMultipartUpload</a>. List Parts returns an error for completed uploads. The list returned in the List Parts response is sorted by part range. </p> <p>The List Parts operation supports pagination. By default, this operation returns up to 50 uploaded parts in the response. You should always check the response for a <code>marker</code> at which to continue the list; if there are no more items the <code>marker</code> is <code>null</code>. To return a list of parts that begins at a specific part, set the <code>marker</code> request parameter to the value you obtained from a previous List Parts request. You can also limit the number of parts returned in the response by specifying the <code>limit</code> parameter in the request. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-parts.html">List Parts</a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ##   uploadId: string (required)
  ##           : The upload ID of the multipart upload.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   marker: string
  ##         : An opaque string used for pagination. This value specifies the part at which the listing of parts should begin. Get the marker value from the response of a previous List Parts response. You need only include the marker if you are continuing the pagination of results started in a previous List Parts request.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   limit: string
  ##        : The maximum number of parts to be returned. The default limit is 50. The number of parts returned might be fewer than the specified limit, but the number of returned parts never exceeds the limit.
  var path_603037 = newJObject()
  var query_603039 = newJObject()
  add(path_603037, "uploadId", newJString(uploadId))
  add(path_603037, "accountId", newJString(accountId))
  add(query_603039, "marker", newJString(marker))
  add(path_603037, "vaultName", newJString(vaultName))
  add(query_603039, "limit", newJString(limit))
  result = call_603036.call(path_603037, query_603039, nil, nil, nil)

var listParts* = Call_ListParts_602803(name: "listParts", meth: HttpMethod.HttpGet,
                                    host: "glacier.amazonaws.com", route: "/{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}",
                                    validator: validate_ListParts_602804,
                                    base: "/", url: url_ListParts_602805,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortMultipartUpload_603116 = ref object of OpenApiRestCall_602466
proc url_AbortMultipartUpload_603118(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "uploadId" in path, "`uploadId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/multipart-uploads/"),
               (kind: VariableSegment, value: "uploadId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AbortMultipartUpload_603117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation aborts a multipart upload identified by the upload ID.</p> <p>After the Abort Multipart Upload request succeeds, you cannot upload any more parts to the multipart upload or complete the multipart upload. Aborting a completed upload fails. However, aborting an already-aborted upload will succeed, for a short time. For more information about uploading a part and completing a multipart upload, see <a>UploadMultipartPart</a> and <a>CompleteMultipartUpload</a>.</p> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-abort-upload.html">Abort Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   uploadId: JString (required)
  ##           : The upload ID of the multipart upload to delete.
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `uploadId` field"
  var valid_603119 = path.getOrDefault("uploadId")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = nil)
  if valid_603119 != nil:
    section.add "uploadId", valid_603119
  var valid_603120 = path.getOrDefault("accountId")
  valid_603120 = validateParameter(valid_603120, JString, required = true,
                                 default = nil)
  if valid_603120 != nil:
    section.add "accountId", valid_603120
  var valid_603121 = path.getOrDefault("vaultName")
  valid_603121 = validateParameter(valid_603121, JString, required = true,
                                 default = nil)
  if valid_603121 != nil:
    section.add "vaultName", valid_603121
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603122 = header.getOrDefault("X-Amz-Date")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Date", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Security-Token")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Security-Token", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Content-Sha256", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Algorithm")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Algorithm", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Signature")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Signature", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_AbortMultipartUpload_603116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation aborts a multipart upload identified by the upload ID.</p> <p>After the Abort Multipart Upload request succeeds, you cannot upload any more parts to the multipart upload or complete the multipart upload. Aborting a completed upload fails. However, aborting an already-aborted upload will succeed, for a short time. For more information about uploading a part and completing a multipart upload, see <a>UploadMultipartPart</a> and <a>CompleteMultipartUpload</a>.</p> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-abort-upload.html">Abort Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_AbortMultipartUpload_603116; uploadId: string;
          accountId: string; vaultName: string): Recallable =
  ## abortMultipartUpload
  ## <p>This operation aborts a multipart upload identified by the upload ID.</p> <p>After the Abort Multipart Upload request succeeds, you cannot upload any more parts to the multipart upload or complete the multipart upload. Aborting a completed upload fails. However, aborting an already-aborted upload will succeed, for a short time. For more information about uploading a part and completing a multipart upload, see <a>UploadMultipartPart</a> and <a>CompleteMultipartUpload</a>.</p> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-abort-upload.html">Abort Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   uploadId: string (required)
  ##           : The upload ID of the multipart upload to delete.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603131 = newJObject()
  add(path_603131, "uploadId", newJString(uploadId))
  add(path_603131, "accountId", newJString(accountId))
  add(path_603131, "vaultName", newJString(vaultName))
  result = call_603130.call(path_603131, nil, nil, nil, nil)

var abortMultipartUpload* = Call_AbortMultipartUpload_603116(
    name: "abortMultipartUpload", meth: HttpMethod.HttpDelete,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/multipart-uploads/{uploadId}",
    validator: validate_AbortMultipartUpload_603117, base: "/",
    url: url_AbortMultipartUpload_603118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateVaultLock_603147 = ref object of OpenApiRestCall_602466
proc url_InitiateVaultLock_603149(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/lock-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_InitiateVaultLock_603148(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>This operation initiates the vault locking process by doing the following:</p> <ul> <li> <p>Installing a vault lock policy on the specified vault.</p> </li> <li> <p>Setting the lock state of vault lock to <code>InProgress</code>.</p> </li> <li> <p>Returning a lock ID, which is used to complete the vault locking process.</p> </li> </ul> <p>You can set one vault lock policy for each vault and this policy can be up to 20 KB in size. For more information about vault lock policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p> <p>You must complete the vault locking process within 24 hours after the vault lock enters the <code>InProgress</code> state. After the 24 hour window ends, the lock ID expires, the vault automatically exits the <code>InProgress</code> state, and the vault lock policy is removed from the vault. You call <a>CompleteVaultLock</a> to complete the vault locking process by setting the state of the vault lock to <code>Locked</code>. </p> <p>After a vault lock is in the <code>Locked</code> state, you cannot initiate a new vault lock for the vault.</p> <p>You can abort the vault locking process by calling <a>AbortVaultLock</a>. You can get the state of the vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>.</p> <p>If this operation is called when the vault lock is in the <code>InProgress</code> state, the operation returns an <code>AccessDeniedException</code> error. When the vault lock is in the <code>InProgress</code> state you must call <a>AbortVaultLock</a> before you can initiate a new vault lock policy. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603150 = path.getOrDefault("accountId")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = nil)
  if valid_603150 != nil:
    section.add "accountId", valid_603150
  var valid_603151 = path.getOrDefault("vaultName")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = nil)
  if valid_603151 != nil:
    section.add "vaultName", valid_603151
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603152 = header.getOrDefault("X-Amz-Date")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Date", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Security-Token")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Security-Token", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Content-Sha256", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Algorithm")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Algorithm", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Signature")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Signature", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-SignedHeaders", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Credential")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Credential", valid_603158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_InitiateVaultLock_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation initiates the vault locking process by doing the following:</p> <ul> <li> <p>Installing a vault lock policy on the specified vault.</p> </li> <li> <p>Setting the lock state of vault lock to <code>InProgress</code>.</p> </li> <li> <p>Returning a lock ID, which is used to complete the vault locking process.</p> </li> </ul> <p>You can set one vault lock policy for each vault and this policy can be up to 20 KB in size. For more information about vault lock policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p> <p>You must complete the vault locking process within 24 hours after the vault lock enters the <code>InProgress</code> state. After the 24 hour window ends, the lock ID expires, the vault automatically exits the <code>InProgress</code> state, and the vault lock policy is removed from the vault. You call <a>CompleteVaultLock</a> to complete the vault locking process by setting the state of the vault lock to <code>Locked</code>. </p> <p>After a vault lock is in the <code>Locked</code> state, you cannot initiate a new vault lock for the vault.</p> <p>You can abort the vault locking process by calling <a>AbortVaultLock</a>. You can get the state of the vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>.</p> <p>If this operation is called when the vault lock is in the <code>InProgress</code> state, the operation returns an <code>AccessDeniedException</code> error. When the vault lock is in the <code>InProgress</code> state you must call <a>AbortVaultLock</a> before you can initiate a new vault lock policy. </p>
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603160, url, valid)

proc call*(call_603161: Call_InitiateVaultLock_603147; accountId: string;
          vaultName: string; body: JsonNode): Recallable =
  ## initiateVaultLock
  ## <p>This operation initiates the vault locking process by doing the following:</p> <ul> <li> <p>Installing a vault lock policy on the specified vault.</p> </li> <li> <p>Setting the lock state of vault lock to <code>InProgress</code>.</p> </li> <li> <p>Returning a lock ID, which is used to complete the vault locking process.</p> </li> </ul> <p>You can set one vault lock policy for each vault and this policy can be up to 20 KB in size. For more information about vault lock policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p> <p>You must complete the vault locking process within 24 hours after the vault lock enters the <code>InProgress</code> state. After the 24 hour window ends, the lock ID expires, the vault automatically exits the <code>InProgress</code> state, and the vault lock policy is removed from the vault. You call <a>CompleteVaultLock</a> to complete the vault locking process by setting the state of the vault lock to <code>Locked</code>. </p> <p>After a vault lock is in the <code>Locked</code> state, you cannot initiate a new vault lock for the vault.</p> <p>You can abort the vault locking process by calling <a>AbortVaultLock</a>. You can get the state of the vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>.</p> <p>If this operation is called when the vault lock is in the <code>InProgress</code> state, the operation returns an <code>AccessDeniedException</code> error. When the vault lock is in the <code>InProgress</code> state you must call <a>AbortVaultLock</a> before you can initiate a new vault lock policy. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   body: JObject (required)
  var path_603162 = newJObject()
  var body_603163 = newJObject()
  add(path_603162, "accountId", newJString(accountId))
  add(path_603162, "vaultName", newJString(vaultName))
  if body != nil:
    body_603163 = body
  result = call_603161.call(path_603162, nil, nil, nil, body_603163)

var initiateVaultLock* = Call_InitiateVaultLock_603147(name: "initiateVaultLock",
    meth: HttpMethod.HttpPost, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/lock-policy",
    validator: validate_InitiateVaultLock_603148, base: "/",
    url: url_InitiateVaultLock_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVaultLock_603132 = ref object of OpenApiRestCall_602466
proc url_GetVaultLock_603134(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/lock-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetVaultLock_603133(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation retrieves the following attributes from the <code>lock-policy</code> subresource set on the specified vault: </p> <ul> <li> <p>The vault lock policy set on the vault.</p> </li> <li> <p>The state of the vault lock, which is either <code>InProgess</code> or <code>Locked</code>.</p> </li> <li> <p>When the lock ID expires. The lock ID is used to complete the vault locking process.</p> </li> <li> <p>When the vault lock was initiated and put into the <code>InProgress</code> state.</p> </li> </ul> <p>A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. A vault lock is put into the <code>Locked</code> state by calling <a>CompleteVaultLock</a>. You can abort the vault locking process by calling <a>AbortVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. </p> <p>If there is no vault lock policy set on the vault, the operation returns a <code>404 Not found</code> error. For more information about vault lock policies, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603135 = path.getOrDefault("accountId")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = nil)
  if valid_603135 != nil:
    section.add "accountId", valid_603135
  var valid_603136 = path.getOrDefault("vaultName")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = nil)
  if valid_603136 != nil:
    section.add "vaultName", valid_603136
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603137 = header.getOrDefault("X-Amz-Date")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Date", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Security-Token")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Security-Token", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Content-Sha256", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Algorithm")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Algorithm", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Signature")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Signature", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Credential")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Credential", valid_603143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_GetVaultLock_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation retrieves the following attributes from the <code>lock-policy</code> subresource set on the specified vault: </p> <ul> <li> <p>The vault lock policy set on the vault.</p> </li> <li> <p>The state of the vault lock, which is either <code>InProgess</code> or <code>Locked</code>.</p> </li> <li> <p>When the lock ID expires. The lock ID is used to complete the vault locking process.</p> </li> <li> <p>When the vault lock was initiated and put into the <code>InProgress</code> state.</p> </li> </ul> <p>A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. A vault lock is put into the <code>Locked</code> state by calling <a>CompleteVaultLock</a>. You can abort the vault locking process by calling <a>AbortVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. </p> <p>If there is no vault lock policy set on the vault, the operation returns a <code>404 Not found</code> error. For more information about vault lock policies, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_GetVaultLock_603132; accountId: string;
          vaultName: string): Recallable =
  ## getVaultLock
  ## <p>This operation retrieves the following attributes from the <code>lock-policy</code> subresource set on the specified vault: </p> <ul> <li> <p>The vault lock policy set on the vault.</p> </li> <li> <p>The state of the vault lock, which is either <code>InProgess</code> or <code>Locked</code>.</p> </li> <li> <p>When the lock ID expires. The lock ID is used to complete the vault locking process.</p> </li> <li> <p>When the vault lock was initiated and put into the <code>InProgress</code> state.</p> </li> </ul> <p>A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. A vault lock is put into the <code>Locked</code> state by calling <a>CompleteVaultLock</a>. You can abort the vault locking process by calling <a>AbortVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. </p> <p>If there is no vault lock policy set on the vault, the operation returns a <code>404 Not found</code> error. For more information about vault lock policies, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603146 = newJObject()
  add(path_603146, "accountId", newJString(accountId))
  add(path_603146, "vaultName", newJString(vaultName))
  result = call_603145.call(path_603146, nil, nil, nil, nil)

var getVaultLock* = Call_GetVaultLock_603132(name: "getVaultLock",
    meth: HttpMethod.HttpGet, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/lock-policy",
    validator: validate_GetVaultLock_603133, base: "/", url: url_GetVaultLock_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortVaultLock_603164 = ref object of OpenApiRestCall_602466
proc url_AbortVaultLock_603166(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/lock-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AbortVaultLock_603165(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>This operation aborts the vault locking process if the vault lock is not in the <code>Locked</code> state. If the vault lock is in the <code>Locked</code> state when this operation is requested, the operation returns an <code>AccessDeniedException</code> error. Aborting the vault locking process removes the vault lock policy from the specified vault. </p> <p>A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. A vault lock is put into the <code>Locked</code> state by calling <a>CompleteVaultLock</a>. You can get the state of a vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. For more information about vault lock policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p> <p>This operation is idempotent. You can successfully invoke this operation multiple times, if the vault lock is in the <code>InProgress</code> state or if there is no policy associated with the vault.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603167 = path.getOrDefault("accountId")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = nil)
  if valid_603167 != nil:
    section.add "accountId", valid_603167
  var valid_603168 = path.getOrDefault("vaultName")
  valid_603168 = validateParameter(valid_603168, JString, required = true,
                                 default = nil)
  if valid_603168 != nil:
    section.add "vaultName", valid_603168
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
  var valid_603171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Content-Sha256", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Algorithm")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Algorithm", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Signature")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Signature", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Credential")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Credential", valid_603175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603176: Call_AbortVaultLock_603164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation aborts the vault locking process if the vault lock is not in the <code>Locked</code> state. If the vault lock is in the <code>Locked</code> state when this operation is requested, the operation returns an <code>AccessDeniedException</code> error. Aborting the vault locking process removes the vault lock policy from the specified vault. </p> <p>A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. A vault lock is put into the <code>Locked</code> state by calling <a>CompleteVaultLock</a>. You can get the state of a vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. For more information about vault lock policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p> <p>This operation is idempotent. You can successfully invoke this operation multiple times, if the vault lock is in the <code>InProgress</code> state or if there is no policy associated with the vault.</p>
  ## 
  let valid = call_603176.validator(path, query, header, formData, body)
  let scheme = call_603176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603176.url(scheme.get, call_603176.host, call_603176.base,
                         call_603176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603176, url, valid)

proc call*(call_603177: Call_AbortVaultLock_603164; accountId: string;
          vaultName: string): Recallable =
  ## abortVaultLock
  ## <p>This operation aborts the vault locking process if the vault lock is not in the <code>Locked</code> state. If the vault lock is in the <code>Locked</code> state when this operation is requested, the operation returns an <code>AccessDeniedException</code> error. Aborting the vault locking process removes the vault lock policy from the specified vault. </p> <p>A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. A vault lock is put into the <code>Locked</code> state by calling <a>CompleteVaultLock</a>. You can get the state of a vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. For more information about vault lock policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html">Amazon Glacier Access Control with Vault Lock Policies</a>. </p> <p>This operation is idempotent. You can successfully invoke this operation multiple times, if the vault lock is in the <code>InProgress</code> state or if there is no policy associated with the vault.</p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603178 = newJObject()
  add(path_603178, "accountId", newJString(accountId))
  add(path_603178, "vaultName", newJString(vaultName))
  result = call_603177.call(path_603178, nil, nil, nil, nil)

var abortVaultLock* = Call_AbortVaultLock_603164(name: "abortVaultLock",
    meth: HttpMethod.HttpDelete, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/lock-policy",
    validator: validate_AbortVaultLock_603165, base: "/", url: url_AbortVaultLock_603166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToVault_603179 = ref object of OpenApiRestCall_602466
proc url_AddTagsToVault_603181(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/tags#operation=add")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AddTagsToVault_603180(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation adds the specified tags to a vault. Each tag is composed of a key and a value. Each vault can have up to 10 tags. If your request would cause the tag limit for the vault to be exceeded, the operation throws the <code>LimitExceededException</code> error. If a tag already exists on the vault under a specified key, the existing key value will be overwritten. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603182 = path.getOrDefault("accountId")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = nil)
  if valid_603182 != nil:
    section.add "accountId", valid_603182
  var valid_603183 = path.getOrDefault("vaultName")
  valid_603183 = validateParameter(valid_603183, JString, required = true,
                                 default = nil)
  if valid_603183 != nil:
    section.add "vaultName", valid_603183
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603197 = query.getOrDefault("operation")
  valid_603197 = validateParameter(valid_603197, JString, required = true,
                                 default = newJString("add"))
  if valid_603197 != nil:
    section.add "operation", valid_603197
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
  var valid_603198 = header.getOrDefault("X-Amz-Date")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Date", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Security-Token")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Security-Token", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Content-Sha256", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Algorithm")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Algorithm", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Signature")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Signature", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-SignedHeaders", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Credential")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Credential", valid_603204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603206: Call_AddTagsToVault_603179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation adds the specified tags to a vault. Each tag is composed of a key and a value. Each vault can have up to 10 tags. If your request would cause the tag limit for the vault to be exceeded, the operation throws the <code>LimitExceededException</code> error. If a tag already exists on the vault under a specified key, the existing key value will be overwritten. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>. 
  ## 
  let valid = call_603206.validator(path, query, header, formData, body)
  let scheme = call_603206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603206.url(scheme.get, call_603206.host, call_603206.base,
                         call_603206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603206, url, valid)

proc call*(call_603207: Call_AddTagsToVault_603179; accountId: string;
          vaultName: string; body: JsonNode; operation: string = "add"): Recallable =
  ## addTagsToVault
  ## This operation adds the specified tags to a vault. Each tag is composed of a key and a value. Each vault can have up to 10 tags. If your request would cause the tag limit for the vault to be exceeded, the operation throws the <code>LimitExceededException</code> error. If a tag already exists on the vault under a specified key, the existing key value will be overwritten. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>. 
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603208 = newJObject()
  var query_603209 = newJObject()
  var body_603210 = newJObject()
  add(path_603208, "accountId", newJString(accountId))
  add(path_603208, "vaultName", newJString(vaultName))
  add(query_603209, "operation", newJString(operation))
  if body != nil:
    body_603210 = body
  result = call_603207.call(path_603208, query_603209, nil, nil, body_603210)

var addTagsToVault* = Call_AddTagsToVault_603179(name: "addTagsToVault",
    meth: HttpMethod.HttpPost, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/tags#operation=add",
    validator: validate_AddTagsToVault_603180, base: "/", url: url_AddTagsToVault_603181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteVaultLock_603211 = ref object of OpenApiRestCall_602466
proc url_CompleteVaultLock_603213(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "lockId" in path, "`lockId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/lock-policy/"),
               (kind: VariableSegment, value: "lockId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CompleteVaultLock_603212(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>This operation completes the vault locking process by transitioning the vault lock from the <code>InProgress</code> state to the <code>Locked</code> state, which causes the vault lock policy to become unchangeable. A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. You can obtain the state of the vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. </p> <p>This operation is idempotent. This request is always successful if the vault lock is in the <code>Locked</code> state and the provided lock ID matches the lock ID originally used to lock the vault.</p> <p>If an invalid lock ID is passed in the request when the vault lock is in the <code>Locked</code> state, the operation returns an <code>AccessDeniedException</code> error. If an invalid lock ID is passed in the request when the vault lock is in the <code>InProgress</code> state, the operation throws an <code>InvalidParameter</code> error.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   lockId: JString (required)
  ##         : The <code>lockId</code> value is the lock ID obtained from a <a>InitiateVaultLock</a> request.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603214 = path.getOrDefault("accountId")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = nil)
  if valid_603214 != nil:
    section.add "accountId", valid_603214
  var valid_603215 = path.getOrDefault("lockId")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = nil)
  if valid_603215 != nil:
    section.add "lockId", valid_603215
  var valid_603216 = path.getOrDefault("vaultName")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "vaultName", valid_603216
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603217 = header.getOrDefault("X-Amz-Date")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Date", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Security-Token")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Security-Token", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Content-Sha256", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Algorithm")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Algorithm", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Signature")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Signature", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-SignedHeaders", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Credential")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Credential", valid_603223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603224: Call_CompleteVaultLock_603211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation completes the vault locking process by transitioning the vault lock from the <code>InProgress</code> state to the <code>Locked</code> state, which causes the vault lock policy to become unchangeable. A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. You can obtain the state of the vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. </p> <p>This operation is idempotent. This request is always successful if the vault lock is in the <code>Locked</code> state and the provided lock ID matches the lock ID originally used to lock the vault.</p> <p>If an invalid lock ID is passed in the request when the vault lock is in the <code>Locked</code> state, the operation returns an <code>AccessDeniedException</code> error. If an invalid lock ID is passed in the request when the vault lock is in the <code>InProgress</code> state, the operation throws an <code>InvalidParameter</code> error.</p>
  ## 
  let valid = call_603224.validator(path, query, header, formData, body)
  let scheme = call_603224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603224.url(scheme.get, call_603224.host, call_603224.base,
                         call_603224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603224, url, valid)

proc call*(call_603225: Call_CompleteVaultLock_603211; accountId: string;
          lockId: string; vaultName: string): Recallable =
  ## completeVaultLock
  ## <p>This operation completes the vault locking process by transitioning the vault lock from the <code>InProgress</code> state to the <code>Locked</code> state, which causes the vault lock policy to become unchangeable. A vault lock is put into the <code>InProgress</code> state by calling <a>InitiateVaultLock</a>. You can obtain the state of the vault lock by calling <a>GetVaultLock</a>. For more information about the vault locking process, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock.html">Amazon Glacier Vault Lock</a>. </p> <p>This operation is idempotent. This request is always successful if the vault lock is in the <code>Locked</code> state and the provided lock ID matches the lock ID originally used to lock the vault.</p> <p>If an invalid lock ID is passed in the request when the vault lock is in the <code>Locked</code> state, the operation returns an <code>AccessDeniedException</code> error. If an invalid lock ID is passed in the request when the vault lock is in the <code>InProgress</code> state, the operation throws an <code>InvalidParameter</code> error.</p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   lockId: string (required)
  ##         : The <code>lockId</code> value is the lock ID obtained from a <a>InitiateVaultLock</a> request.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603226 = newJObject()
  add(path_603226, "accountId", newJString(accountId))
  add(path_603226, "lockId", newJString(lockId))
  add(path_603226, "vaultName", newJString(vaultName))
  result = call_603225.call(path_603226, nil, nil, nil, nil)

var completeVaultLock* = Call_CompleteVaultLock_603211(name: "completeVaultLock",
    meth: HttpMethod.HttpPost, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/lock-policy/{lockId}",
    validator: validate_CompleteVaultLock_603212, base: "/",
    url: url_CompleteVaultLock_603213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVault_603242 = ref object of OpenApiRestCall_602466
proc url_CreateVault_603244(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVault_603243(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation creates a new vault with the specified name. The name of the vault must be unique within a region for an AWS account. You can create up to 1,000 vaults per account. If you need to create more vaults, contact Amazon S3 Glacier.</p> <p>You must use the following guidelines when naming a vault.</p> <ul> <li> <p>Names can be between 1 and 255 characters long.</p> </li> <li> <p>Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), and '.' (period).</p> </li> </ul> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/creating-vaults.html">Creating a Vault in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-put.html">Create Vault </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603245 = path.getOrDefault("accountId")
  valid_603245 = validateParameter(valid_603245, JString, required = true,
                                 default = nil)
  if valid_603245 != nil:
    section.add "accountId", valid_603245
  var valid_603246 = path.getOrDefault("vaultName")
  valid_603246 = validateParameter(valid_603246, JString, required = true,
                                 default = nil)
  if valid_603246 != nil:
    section.add "vaultName", valid_603246
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603247 = header.getOrDefault("X-Amz-Date")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Date", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Security-Token")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Security-Token", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Content-Sha256", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Algorithm")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Algorithm", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Signature")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Signature", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-SignedHeaders", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Credential")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Credential", valid_603253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603254: Call_CreateVault_603242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation creates a new vault with the specified name. The name of the vault must be unique within a region for an AWS account. You can create up to 1,000 vaults per account. If you need to create more vaults, contact Amazon S3 Glacier.</p> <p>You must use the following guidelines when naming a vault.</p> <ul> <li> <p>Names can be between 1 and 255 characters long.</p> </li> <li> <p>Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), and '.' (period).</p> </li> </ul> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/creating-vaults.html">Creating a Vault in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-put.html">Create Vault </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603254.validator(path, query, header, formData, body)
  let scheme = call_603254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603254.url(scheme.get, call_603254.host, call_603254.base,
                         call_603254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603254, url, valid)

proc call*(call_603255: Call_CreateVault_603242; accountId: string; vaultName: string): Recallable =
  ## createVault
  ## <p>This operation creates a new vault with the specified name. The name of the vault must be unique within a region for an AWS account. You can create up to 1,000 vaults per account. If you need to create more vaults, contact Amazon S3 Glacier.</p> <p>You must use the following guidelines when naming a vault.</p> <ul> <li> <p>Names can be between 1 and 255 characters long.</p> </li> <li> <p>Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (hyphen), and '.' (period).</p> </li> </ul> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/creating-vaults.html">Creating a Vault in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-put.html">Create Vault </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603256 = newJObject()
  add(path_603256, "accountId", newJString(accountId))
  add(path_603256, "vaultName", newJString(vaultName))
  result = call_603255.call(path_603256, nil, nil, nil, nil)

var createVault* = Call_CreateVault_603242(name: "createVault",
                                        meth: HttpMethod.HttpPut,
                                        host: "glacier.amazonaws.com", route: "/{accountId}/vaults/{vaultName}",
                                        validator: validate_CreateVault_603243,
                                        base: "/", url: url_CreateVault_603244,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVault_603227 = ref object of OpenApiRestCall_602466
proc url_DescribeVault_603229(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeVault_603228(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation returns information about a vault, including the vault's Amazon Resource Name (ARN), the date the vault was created, the number of archives it contains, and the total size of all the archives in the vault. The number of archives and their total size are as of the last inventory generation. This means that if you add or remove an archive from a vault, and then immediately use Describe Vault, the change in contents will not be immediately reflected. If you want to retrieve the latest inventory of the vault, use <a>InitiateJob</a>. Amazon S3 Glacier generates vault inventories approximately daily. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html">Downloading a Vault Inventory in Amazon S3 Glacier</a>. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html">Retrieving Vault Metadata in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-get.html">Describe Vault </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603230 = path.getOrDefault("accountId")
  valid_603230 = validateParameter(valid_603230, JString, required = true,
                                 default = nil)
  if valid_603230 != nil:
    section.add "accountId", valid_603230
  var valid_603231 = path.getOrDefault("vaultName")
  valid_603231 = validateParameter(valid_603231, JString, required = true,
                                 default = nil)
  if valid_603231 != nil:
    section.add "vaultName", valid_603231
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603232 = header.getOrDefault("X-Amz-Date")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Date", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Security-Token")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Security-Token", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Content-Sha256", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Algorithm")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Algorithm", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Signature")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Signature", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-SignedHeaders", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Credential")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Credential", valid_603238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603239: Call_DescribeVault_603227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns information about a vault, including the vault's Amazon Resource Name (ARN), the date the vault was created, the number of archives it contains, and the total size of all the archives in the vault. The number of archives and their total size are as of the last inventory generation. This means that if you add or remove an archive from a vault, and then immediately use Describe Vault, the change in contents will not be immediately reflected. If you want to retrieve the latest inventory of the vault, use <a>InitiateJob</a>. Amazon S3 Glacier generates vault inventories approximately daily. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html">Downloading a Vault Inventory in Amazon S3 Glacier</a>. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html">Retrieving Vault Metadata in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-get.html">Describe Vault </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_DescribeVault_603227; accountId: string;
          vaultName: string): Recallable =
  ## describeVault
  ## <p>This operation returns information about a vault, including the vault's Amazon Resource Name (ARN), the date the vault was created, the number of archives it contains, and the total size of all the archives in the vault. The number of archives and their total size are as of the last inventory generation. This means that if you add or remove an archive from a vault, and then immediately use Describe Vault, the change in contents will not be immediately reflected. If you want to retrieve the latest inventory of the vault, use <a>InitiateJob</a>. Amazon S3 Glacier generates vault inventories approximately daily. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html">Downloading a Vault Inventory in Amazon S3 Glacier</a>. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html">Retrieving Vault Metadata in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-get.html">Describe Vault </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603241 = newJObject()
  add(path_603241, "accountId", newJString(accountId))
  add(path_603241, "vaultName", newJString(vaultName))
  result = call_603240.call(path_603241, nil, nil, nil, nil)

var describeVault* = Call_DescribeVault_603227(name: "describeVault",
    meth: HttpMethod.HttpGet, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}", validator: validate_DescribeVault_603228,
    base: "/", url: url_DescribeVault_603229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVault_603257 = ref object of OpenApiRestCall_602466
proc url_DeleteVault_603259(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVault_603258(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation deletes a vault. Amazon S3 Glacier will delete a vault only if there are no archives in the vault as of the last inventory and there have been no writes to the vault since the last inventory. If either of these conditions is not satisfied, the vault deletion fails (that is, the vault is not removed) and Amazon S3 Glacier returns an error. You can use <a>DescribeVault</a> to return the number of archives in a vault, and you can use <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html">Initiate a Job (POST jobs)</a> to initiate a new inventory retrieval for a vault. The inventory contains the archive IDs you use to delete archives using <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html">Delete Archive (DELETE archive)</a>.</p> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-vaults.html">Deleting a Vault in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-delete.html">Delete Vault </a> in the <i>Amazon S3 Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603260 = path.getOrDefault("accountId")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = nil)
  if valid_603260 != nil:
    section.add "accountId", valid_603260
  var valid_603261 = path.getOrDefault("vaultName")
  valid_603261 = validateParameter(valid_603261, JString, required = true,
                                 default = nil)
  if valid_603261 != nil:
    section.add "vaultName", valid_603261
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603269: Call_DeleteVault_603257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation deletes a vault. Amazon S3 Glacier will delete a vault only if there are no archives in the vault as of the last inventory and there have been no writes to the vault since the last inventory. If either of these conditions is not satisfied, the vault deletion fails (that is, the vault is not removed) and Amazon S3 Glacier returns an error. You can use <a>DescribeVault</a> to return the number of archives in a vault, and you can use <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html">Initiate a Job (POST jobs)</a> to initiate a new inventory retrieval for a vault. The inventory contains the archive IDs you use to delete archives using <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html">Delete Archive (DELETE archive)</a>.</p> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-vaults.html">Deleting a Vault in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-delete.html">Delete Vault </a> in the <i>Amazon S3 Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603269.validator(path, query, header, formData, body)
  let scheme = call_603269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603269.url(scheme.get, call_603269.host, call_603269.base,
                         call_603269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603269, url, valid)

proc call*(call_603270: Call_DeleteVault_603257; accountId: string; vaultName: string): Recallable =
  ## deleteVault
  ## <p>This operation deletes a vault. Amazon S3 Glacier will delete a vault only if there are no archives in the vault as of the last inventory and there have been no writes to the vault since the last inventory. If either of these conditions is not satisfied, the vault deletion fails (that is, the vault is not removed) and Amazon S3 Glacier returns an error. You can use <a>DescribeVault</a> to return the number of archives in a vault, and you can use <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html">Initiate a Job (POST jobs)</a> to initiate a new inventory retrieval for a vault. The inventory contains the archive IDs you use to delete archives using <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html">Delete Archive (DELETE archive)</a>.</p> <p>This operation is idempotent.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-vaults.html">Deleting a Vault in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-delete.html">Delete Vault </a> in the <i>Amazon S3 Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603271 = newJObject()
  add(path_603271, "accountId", newJString(accountId))
  add(path_603271, "vaultName", newJString(vaultName))
  result = call_603270.call(path_603271, nil, nil, nil, nil)

var deleteVault* = Call_DeleteVault_603257(name: "deleteVault",
                                        meth: HttpMethod.HttpDelete,
                                        host: "glacier.amazonaws.com", route: "/{accountId}/vaults/{vaultName}",
                                        validator: validate_DeleteVault_603258,
                                        base: "/", url: url_DeleteVault_603259,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteArchive_603272 = ref object of OpenApiRestCall_602466
proc url_DeleteArchive_603274(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "archiveId" in path, "`archiveId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/archives/"),
               (kind: VariableSegment, value: "archiveId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteArchive_603273(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation deletes an archive from a vault. Subsequent requests to initiate a retrieval of this archive will fail. Archive retrievals that are in progress for this archive ID may or may not succeed according to the following scenarios:</p> <ul> <li> <p>If the archive retrieval job is actively preparing the data for download when Amazon S3 Glacier receives the delete archive request, the archival retrieval operation might fail.</p> </li> <li> <p>If the archive retrieval job has successfully prepared the archive for download when Amazon S3 Glacier receives the delete archive request, you will be able to download the output.</p> </li> </ul> <p>This operation is idempotent. Attempting to delete an already-deleted archive does not result in an error.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-an-archive.html">Deleting an Archive in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html">Delete Archive</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  ##   archiveId: JString (required)
  ##            : The ID of the archive to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603275 = path.getOrDefault("accountId")
  valid_603275 = validateParameter(valid_603275, JString, required = true,
                                 default = nil)
  if valid_603275 != nil:
    section.add "accountId", valid_603275
  var valid_603276 = path.getOrDefault("vaultName")
  valid_603276 = validateParameter(valid_603276, JString, required = true,
                                 default = nil)
  if valid_603276 != nil:
    section.add "vaultName", valid_603276
  var valid_603277 = path.getOrDefault("archiveId")
  valid_603277 = validateParameter(valid_603277, JString, required = true,
                                 default = nil)
  if valid_603277 != nil:
    section.add "archiveId", valid_603277
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603278 = header.getOrDefault("X-Amz-Date")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Date", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Security-Token")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Security-Token", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Content-Sha256", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Algorithm")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Algorithm", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Signature")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Signature", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-SignedHeaders", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Credential")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Credential", valid_603284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603285: Call_DeleteArchive_603272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation deletes an archive from a vault. Subsequent requests to initiate a retrieval of this archive will fail. Archive retrievals that are in progress for this archive ID may or may not succeed according to the following scenarios:</p> <ul> <li> <p>If the archive retrieval job is actively preparing the data for download when Amazon S3 Glacier receives the delete archive request, the archival retrieval operation might fail.</p> </li> <li> <p>If the archive retrieval job has successfully prepared the archive for download when Amazon S3 Glacier receives the delete archive request, you will be able to download the output.</p> </li> </ul> <p>This operation is idempotent. Attempting to delete an already-deleted archive does not result in an error.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-an-archive.html">Deleting an Archive in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html">Delete Archive</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603285.validator(path, query, header, formData, body)
  let scheme = call_603285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603285.url(scheme.get, call_603285.host, call_603285.base,
                         call_603285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603285, url, valid)

proc call*(call_603286: Call_DeleteArchive_603272; accountId: string;
          vaultName: string; archiveId: string): Recallable =
  ## deleteArchive
  ## <p>This operation deletes an archive from a vault. Subsequent requests to initiate a retrieval of this archive will fail. Archive retrievals that are in progress for this archive ID may or may not succeed according to the following scenarios:</p> <ul> <li> <p>If the archive retrieval job is actively preparing the data for download when Amazon S3 Glacier receives the delete archive request, the archival retrieval operation might fail.</p> </li> <li> <p>If the archive retrieval job has successfully prepared the archive for download when Amazon S3 Glacier receives the delete archive request, you will be able to download the output.</p> </li> </ul> <p>This operation is idempotent. Attempting to delete an already-deleted archive does not result in an error.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/deleting-an-archive.html">Deleting an Archive in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html">Delete Archive</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   archiveId: string (required)
  ##            : The ID of the archive to delete.
  var path_603287 = newJObject()
  add(path_603287, "accountId", newJString(accountId))
  add(path_603287, "vaultName", newJString(vaultName))
  add(path_603287, "archiveId", newJString(archiveId))
  result = call_603286.call(path_603287, nil, nil, nil, nil)

var deleteArchive* = Call_DeleteArchive_603272(name: "deleteArchive",
    meth: HttpMethod.HttpDelete, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/archives/{archiveId}",
    validator: validate_DeleteArchive_603273, base: "/", url: url_DeleteArchive_603274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetVaultAccessPolicy_603303 = ref object of OpenApiRestCall_602466
proc url_SetVaultAccessPolicy_603305(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_SetVaultAccessPolicy_603304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation configures an access policy for a vault and will overwrite an existing policy. To configure a vault access policy, send a PUT request to the <code>access-policy</code> subresource of the vault. An access policy is specific to a vault and is also called a vault subresource. You can set one access policy per vault and the policy can be up to 20 KB in size. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603306 = path.getOrDefault("accountId")
  valid_603306 = validateParameter(valid_603306, JString, required = true,
                                 default = nil)
  if valid_603306 != nil:
    section.add "accountId", valid_603306
  var valid_603307 = path.getOrDefault("vaultName")
  valid_603307 = validateParameter(valid_603307, JString, required = true,
                                 default = nil)
  if valid_603307 != nil:
    section.add "vaultName", valid_603307
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603308 = header.getOrDefault("X-Amz-Date")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Date", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Security-Token")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Security-Token", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Content-Sha256", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Algorithm")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Algorithm", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Signature")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Signature", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-SignedHeaders", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Credential")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Credential", valid_603314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603316: Call_SetVaultAccessPolicy_603303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation configures an access policy for a vault and will overwrite an existing policy. To configure a vault access policy, send a PUT request to the <code>access-policy</code> subresource of the vault. An access policy is specific to a vault and is also called a vault subresource. You can set one access policy per vault and the policy can be up to 20 KB in size. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>. 
  ## 
  let valid = call_603316.validator(path, query, header, formData, body)
  let scheme = call_603316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603316.url(scheme.get, call_603316.host, call_603316.base,
                         call_603316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603316, url, valid)

proc call*(call_603317: Call_SetVaultAccessPolicy_603303; accountId: string;
          vaultName: string; body: JsonNode): Recallable =
  ## setVaultAccessPolicy
  ## This operation configures an access policy for a vault and will overwrite an existing policy. To configure a vault access policy, send a PUT request to the <code>access-policy</code> subresource of the vault. An access policy is specific to a vault and is also called a vault subresource. You can set one access policy per vault and the policy can be up to 20 KB in size. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>. 
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   body: JObject (required)
  var path_603318 = newJObject()
  var body_603319 = newJObject()
  add(path_603318, "accountId", newJString(accountId))
  add(path_603318, "vaultName", newJString(vaultName))
  if body != nil:
    body_603319 = body
  result = call_603317.call(path_603318, nil, nil, nil, body_603319)

var setVaultAccessPolicy* = Call_SetVaultAccessPolicy_603303(
    name: "setVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/access-policy",
    validator: validate_SetVaultAccessPolicy_603304, base: "/",
    url: url_SetVaultAccessPolicy_603305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVaultAccessPolicy_603288 = ref object of OpenApiRestCall_602466
proc url_GetVaultAccessPolicy_603290(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetVaultAccessPolicy_603289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation retrieves the <code>access-policy</code> subresource set on the vault; for more information on setting this subresource, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-SetVaultAccessPolicy.html">Set Vault Access Policy (PUT access-policy)</a>. If there is no access policy set on the vault, the operation returns a <code>404 Not found</code> error. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603291 = path.getOrDefault("accountId")
  valid_603291 = validateParameter(valid_603291, JString, required = true,
                                 default = nil)
  if valid_603291 != nil:
    section.add "accountId", valid_603291
  var valid_603292 = path.getOrDefault("vaultName")
  valid_603292 = validateParameter(valid_603292, JString, required = true,
                                 default = nil)
  if valid_603292 != nil:
    section.add "vaultName", valid_603292
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603293 = header.getOrDefault("X-Amz-Date")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Date", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Security-Token")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Security-Token", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Content-Sha256", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Algorithm")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Algorithm", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Signature")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Signature", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-SignedHeaders", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Credential")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Credential", valid_603299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603300: Call_GetVaultAccessPolicy_603288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation retrieves the <code>access-policy</code> subresource set on the vault; for more information on setting this subresource, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-SetVaultAccessPolicy.html">Set Vault Access Policy (PUT access-policy)</a>. If there is no access policy set on the vault, the operation returns a <code>404 Not found</code> error. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>.
  ## 
  let valid = call_603300.validator(path, query, header, formData, body)
  let scheme = call_603300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603300.url(scheme.get, call_603300.host, call_603300.base,
                         call_603300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603300, url, valid)

proc call*(call_603301: Call_GetVaultAccessPolicy_603288; accountId: string;
          vaultName: string): Recallable =
  ## getVaultAccessPolicy
  ## This operation retrieves the <code>access-policy</code> subresource set on the vault; for more information on setting this subresource, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-SetVaultAccessPolicy.html">Set Vault Access Policy (PUT access-policy)</a>. If there is no access policy set on the vault, the operation returns a <code>404 Not found</code> error. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603302 = newJObject()
  add(path_603302, "accountId", newJString(accountId))
  add(path_603302, "vaultName", newJString(vaultName))
  result = call_603301.call(path_603302, nil, nil, nil, nil)

var getVaultAccessPolicy* = Call_GetVaultAccessPolicy_603288(
    name: "getVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/access-policy",
    validator: validate_GetVaultAccessPolicy_603289, base: "/",
    url: url_GetVaultAccessPolicy_603290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVaultAccessPolicy_603320 = ref object of OpenApiRestCall_602466
proc url_DeleteVaultAccessPolicy_603322(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVaultAccessPolicy_603321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation deletes the access policy associated with the specified vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely remove the access policy, and you might still see the effect of the policy for a short time after you send the delete request.</p> <p>This operation is idempotent. You can invoke delete multiple times, even if there is no policy associated with the vault. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603323 = path.getOrDefault("accountId")
  valid_603323 = validateParameter(valid_603323, JString, required = true,
                                 default = nil)
  if valid_603323 != nil:
    section.add "accountId", valid_603323
  var valid_603324 = path.getOrDefault("vaultName")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = nil)
  if valid_603324 != nil:
    section.add "vaultName", valid_603324
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603325 = header.getOrDefault("X-Amz-Date")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Date", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Security-Token")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Security-Token", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Content-Sha256", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Algorithm")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Algorithm", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Signature")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Signature", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-SignedHeaders", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Credential")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Credential", valid_603331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603332: Call_DeleteVaultAccessPolicy_603320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation deletes the access policy associated with the specified vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely remove the access policy, and you might still see the effect of the policy for a short time after you send the delete request.</p> <p>This operation is idempotent. You can invoke delete multiple times, even if there is no policy associated with the vault. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>. </p>
  ## 
  let valid = call_603332.validator(path, query, header, formData, body)
  let scheme = call_603332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603332.url(scheme.get, call_603332.host, call_603332.base,
                         call_603332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603332, url, valid)

proc call*(call_603333: Call_DeleteVaultAccessPolicy_603320; accountId: string;
          vaultName: string): Recallable =
  ## deleteVaultAccessPolicy
  ## <p>This operation deletes the access policy associated with the specified vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely remove the access policy, and you might still see the effect of the policy for a short time after you send the delete request.</p> <p>This operation is idempotent. You can invoke delete multiple times, even if there is no policy associated with the vault. For more information about vault access policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-access-policy.html">Amazon Glacier Access Control with Vault Access Policies</a>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603334 = newJObject()
  add(path_603334, "accountId", newJString(accountId))
  add(path_603334, "vaultName", newJString(vaultName))
  result = call_603333.call(path_603334, nil, nil, nil, nil)

var deleteVaultAccessPolicy* = Call_DeleteVaultAccessPolicy_603320(
    name: "deleteVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/access-policy",
    validator: validate_DeleteVaultAccessPolicy_603321, base: "/",
    url: url_DeleteVaultAccessPolicy_603322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetVaultNotifications_603350 = ref object of OpenApiRestCall_602466
proc url_SetVaultNotifications_603352(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_SetVaultNotifications_603351(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation configures notifications that will be sent when specific events happen to a vault. By default, you don't get any notifications.</p> <p>To configure vault notifications, send a PUT request to the <code>notification-configuration</code> subresource of the vault. The request should include a JSON document that provides an Amazon SNS topic and specific events for which you want Amazon S3 Glacier to send notifications to the topic.</p> <p>Amazon SNS topics must grant permission to the vault to be allowed to publish notifications to the topic. You can configure a vault to publish a notification for the following vault events:</p> <ul> <li> <p> <b>ArchiveRetrievalCompleted</b> This event occurs when a job that was initiated for an archive retrieval is completed (<a>InitiateJob</a>). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from <a>DescribeJob</a>. </p> </li> <li> <p> <b>InventoryRetrievalCompleted</b> This event occurs when a job that was initiated for an inventory retrieval is completed (<a>InitiateJob</a>). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from <a>DescribeJob</a>. </p> </li> </ul> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-put.html">Set Vault Notification Configuration </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603353 = path.getOrDefault("accountId")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = nil)
  if valid_603353 != nil:
    section.add "accountId", valid_603353
  var valid_603354 = path.getOrDefault("vaultName")
  valid_603354 = validateParameter(valid_603354, JString, required = true,
                                 default = nil)
  if valid_603354 != nil:
    section.add "vaultName", valid_603354
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603355 = header.getOrDefault("X-Amz-Date")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Date", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Security-Token")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Security-Token", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Content-Sha256", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Algorithm")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Algorithm", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Signature")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Signature", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-SignedHeaders", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Credential")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Credential", valid_603361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603363: Call_SetVaultNotifications_603350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation configures notifications that will be sent when specific events happen to a vault. By default, you don't get any notifications.</p> <p>To configure vault notifications, send a PUT request to the <code>notification-configuration</code> subresource of the vault. The request should include a JSON document that provides an Amazon SNS topic and specific events for which you want Amazon S3 Glacier to send notifications to the topic.</p> <p>Amazon SNS topics must grant permission to the vault to be allowed to publish notifications to the topic. You can configure a vault to publish a notification for the following vault events:</p> <ul> <li> <p> <b>ArchiveRetrievalCompleted</b> This event occurs when a job that was initiated for an archive retrieval is completed (<a>InitiateJob</a>). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from <a>DescribeJob</a>. </p> </li> <li> <p> <b>InventoryRetrievalCompleted</b> This event occurs when a job that was initiated for an inventory retrieval is completed (<a>InitiateJob</a>). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from <a>DescribeJob</a>. </p> </li> </ul> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-put.html">Set Vault Notification Configuration </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603363.validator(path, query, header, formData, body)
  let scheme = call_603363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603363.url(scheme.get, call_603363.host, call_603363.base,
                         call_603363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603363, url, valid)

proc call*(call_603364: Call_SetVaultNotifications_603350; accountId: string;
          vaultName: string; body: JsonNode): Recallable =
  ## setVaultNotifications
  ## <p>This operation configures notifications that will be sent when specific events happen to a vault. By default, you don't get any notifications.</p> <p>To configure vault notifications, send a PUT request to the <code>notification-configuration</code> subresource of the vault. The request should include a JSON document that provides an Amazon SNS topic and specific events for which you want Amazon S3 Glacier to send notifications to the topic.</p> <p>Amazon SNS topics must grant permission to the vault to be allowed to publish notifications to the topic. You can configure a vault to publish a notification for the following vault events:</p> <ul> <li> <p> <b>ArchiveRetrievalCompleted</b> This event occurs when a job that was initiated for an archive retrieval is completed (<a>InitiateJob</a>). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from <a>DescribeJob</a>. </p> </li> <li> <p> <b>InventoryRetrievalCompleted</b> This event occurs when a job that was initiated for an inventory retrieval is completed (<a>InitiateJob</a>). The status of the completed job can be "Succeeded" or "Failed". The notification sent to the SNS topic is the same output as returned from <a>DescribeJob</a>. </p> </li> </ul> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-put.html">Set Vault Notification Configuration </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   body: JObject (required)
  var path_603365 = newJObject()
  var body_603366 = newJObject()
  add(path_603365, "accountId", newJString(accountId))
  add(path_603365, "vaultName", newJString(vaultName))
  if body != nil:
    body_603366 = body
  result = call_603364.call(path_603365, nil, nil, nil, body_603366)

var setVaultNotifications* = Call_SetVaultNotifications_603350(
    name: "setVaultNotifications", meth: HttpMethod.HttpPut,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/notification-configuration",
    validator: validate_SetVaultNotifications_603351, base: "/",
    url: url_SetVaultNotifications_603352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVaultNotifications_603335 = ref object of OpenApiRestCall_602466
proc url_GetVaultNotifications_603337(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetVaultNotifications_603336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation retrieves the <code>notification-configuration</code> subresource of the specified vault.</p> <p>For information about setting a notification configuration on a vault, see <a>SetVaultNotifications</a>. If a notification configuration for a vault is not set, the operation returns a <code>404 Not Found</code> error. For more information about vault notifications, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a>. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-get.html">Get Vault Notification Configuration </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603338 = path.getOrDefault("accountId")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = nil)
  if valid_603338 != nil:
    section.add "accountId", valid_603338
  var valid_603339 = path.getOrDefault("vaultName")
  valid_603339 = validateParameter(valid_603339, JString, required = true,
                                 default = nil)
  if valid_603339 != nil:
    section.add "vaultName", valid_603339
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603340 = header.getOrDefault("X-Amz-Date")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Date", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Security-Token")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Security-Token", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Content-Sha256", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Algorithm")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Algorithm", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Signature")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Signature", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-SignedHeaders", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Credential")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Credential", valid_603346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603347: Call_GetVaultNotifications_603335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation retrieves the <code>notification-configuration</code> subresource of the specified vault.</p> <p>For information about setting a notification configuration on a vault, see <a>SetVaultNotifications</a>. If a notification configuration for a vault is not set, the operation returns a <code>404 Not Found</code> error. For more information about vault notifications, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a>. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-get.html">Get Vault Notification Configuration </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603347.validator(path, query, header, formData, body)
  let scheme = call_603347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603347.url(scheme.get, call_603347.host, call_603347.base,
                         call_603347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603347, url, valid)

proc call*(call_603348: Call_GetVaultNotifications_603335; accountId: string;
          vaultName: string): Recallable =
  ## getVaultNotifications
  ## <p>This operation retrieves the <code>notification-configuration</code> subresource of the specified vault.</p> <p>For information about setting a notification configuration on a vault, see <a>SetVaultNotifications</a>. If a notification configuration for a vault is not set, the operation returns a <code>404 Not Found</code> error. For more information about vault notifications, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a>. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-get.html">Get Vault Notification Configuration </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603349 = newJObject()
  add(path_603349, "accountId", newJString(accountId))
  add(path_603349, "vaultName", newJString(vaultName))
  result = call_603348.call(path_603349, nil, nil, nil, nil)

var getVaultNotifications* = Call_GetVaultNotifications_603335(
    name: "getVaultNotifications", meth: HttpMethod.HttpGet,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/notification-configuration",
    validator: validate_GetVaultNotifications_603336, base: "/",
    url: url_GetVaultNotifications_603337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVaultNotifications_603367 = ref object of OpenApiRestCall_602466
proc url_DeleteVaultNotifications_603369(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVaultNotifications_603368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation deletes the notification configuration set for a vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely disable the notifications and you might still receive some notifications for a short time after you send the delete request.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-delete.html">Delete Vault Notification Configuration </a> in the Amazon S3 Glacier Developer Guide. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603370 = path.getOrDefault("accountId")
  valid_603370 = validateParameter(valid_603370, JString, required = true,
                                 default = nil)
  if valid_603370 != nil:
    section.add "accountId", valid_603370
  var valid_603371 = path.getOrDefault("vaultName")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "vaultName", valid_603371
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603372 = header.getOrDefault("X-Amz-Date")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Date", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Security-Token")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Security-Token", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Content-Sha256", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Algorithm")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Algorithm", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Signature")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Signature", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-SignedHeaders", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Credential")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Credential", valid_603378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603379: Call_DeleteVaultNotifications_603367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation deletes the notification configuration set for a vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely disable the notifications and you might still receive some notifications for a short time after you send the delete request.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-delete.html">Delete Vault Notification Configuration </a> in the Amazon S3 Glacier Developer Guide. </p>
  ## 
  let valid = call_603379.validator(path, query, header, formData, body)
  let scheme = call_603379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603379.url(scheme.get, call_603379.host, call_603379.base,
                         call_603379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603379, url, valid)

proc call*(call_603380: Call_DeleteVaultNotifications_603367; accountId: string;
          vaultName: string): Recallable =
  ## deleteVaultNotifications
  ## <p>This operation deletes the notification configuration set for a vault. The operation is eventually consistent; that is, it might take some time for Amazon S3 Glacier to completely disable the notifications and you might still receive some notifications for a short time after you send the delete request.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/configuring-notifications.html">Configuring Vault Notifications in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-delete.html">Delete Vault Notification Configuration </a> in the Amazon S3 Glacier Developer Guide. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603381 = newJObject()
  add(path_603381, "accountId", newJString(accountId))
  add(path_603381, "vaultName", newJString(vaultName))
  result = call_603380.call(path_603381, nil, nil, nil, nil)

var deleteVaultNotifications* = Call_DeleteVaultNotifications_603367(
    name: "deleteVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/notification-configuration",
    validator: validate_DeleteVaultNotifications_603368, base: "/",
    url: url_DeleteVaultNotifications_603369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_603382 = ref object of OpenApiRestCall_602466
proc url_DescribeJob_603384(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeJob_603383(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation returns information about a job you previously initiated, including the job initiation date, the user who initiated the job, the job status code/message and the Amazon SNS topic to notify after Amazon S3 Glacier (Glacier) completes the job. For more information about initiating a job, see <a>InitiateJob</a>. </p> <note> <p>This operation enables you to check the status of your job. However, it is strongly recommended that you set up an Amazon SNS topic and specify it in your initiate job request so that Glacier can notify the topic after it completes the job.</p> </note> <p>A job ID will not expire for at least 24 hours after Glacier completes the job.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-describe-job-get.html">Describe Job</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        : The ID of the job to describe.
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_603385 = path.getOrDefault("jobId")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = nil)
  if valid_603385 != nil:
    section.add "jobId", valid_603385
  var valid_603386 = path.getOrDefault("accountId")
  valid_603386 = validateParameter(valid_603386, JString, required = true,
                                 default = nil)
  if valid_603386 != nil:
    section.add "accountId", valid_603386
  var valid_603387 = path.getOrDefault("vaultName")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = nil)
  if valid_603387 != nil:
    section.add "vaultName", valid_603387
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603388 = header.getOrDefault("X-Amz-Date")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Date", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Security-Token")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Security-Token", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Content-Sha256", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Algorithm")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Algorithm", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Signature")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Signature", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-SignedHeaders", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Credential")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Credential", valid_603394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603395: Call_DescribeJob_603382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns information about a job you previously initiated, including the job initiation date, the user who initiated the job, the job status code/message and the Amazon SNS topic to notify after Amazon S3 Glacier (Glacier) completes the job. For more information about initiating a job, see <a>InitiateJob</a>. </p> <note> <p>This operation enables you to check the status of your job. However, it is strongly recommended that you set up an Amazon SNS topic and specify it in your initiate job request so that Glacier can notify the topic after it completes the job.</p> </note> <p>A job ID will not expire for at least 24 hours after Glacier completes the job.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-describe-job-get.html">Describe Job</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603395.validator(path, query, header, formData, body)
  let scheme = call_603395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603395.url(scheme.get, call_603395.host, call_603395.base,
                         call_603395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603395, url, valid)

proc call*(call_603396: Call_DescribeJob_603382; jobId: string; accountId: string;
          vaultName: string): Recallable =
  ## describeJob
  ## <p>This operation returns information about a job you previously initiated, including the job initiation date, the user who initiated the job, the job status code/message and the Amazon SNS topic to notify after Amazon S3 Glacier (Glacier) completes the job. For more information about initiating a job, see <a>InitiateJob</a>. </p> <note> <p>This operation enables you to check the status of your job. However, it is strongly recommended that you set up an Amazon SNS topic and specify it in your initiate job request so that Glacier can notify the topic after it completes the job.</p> </note> <p>A job ID will not expire for at least 24 hours after Glacier completes the job.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-describe-job-get.html">Describe Job</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   jobId: string (required)
  ##        : The ID of the job to describe.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603397 = newJObject()
  add(path_603397, "jobId", newJString(jobId))
  add(path_603397, "accountId", newJString(accountId))
  add(path_603397, "vaultName", newJString(vaultName))
  result = call_603396.call(path_603397, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_603382(name: "describeJob",
                                        meth: HttpMethod.HttpGet,
                                        host: "glacier.amazonaws.com", route: "/{accountId}/vaults/{vaultName}/jobs/{jobId}",
                                        validator: validate_DescribeJob_603383,
                                        base: "/", url: url_DescribeJob_603384,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetDataRetrievalPolicy_603412 = ref object of OpenApiRestCall_602466
proc url_SetDataRetrievalPolicy_603414(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/policies/data-retrieval")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_SetDataRetrievalPolicy_603413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation sets and then enacts a data retrieval policy in the region specified in the PUT request. You can set one policy per region for an AWS account. The policy is enacted within a few minutes of a successful PUT operation.</p> <p>The set policy operation does not affect retrieval jobs that were in progress before the policy was enacted. For more information about data retrieval policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html">Amazon Glacier Data Retrieval Policies</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603415 = path.getOrDefault("accountId")
  valid_603415 = validateParameter(valid_603415, JString, required = true,
                                 default = nil)
  if valid_603415 != nil:
    section.add "accountId", valid_603415
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603416 = header.getOrDefault("X-Amz-Date")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Date", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Security-Token")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Security-Token", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Content-Sha256", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Algorithm")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Algorithm", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Signature")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Signature", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-SignedHeaders", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Credential")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Credential", valid_603422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603424: Call_SetDataRetrievalPolicy_603412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation sets and then enacts a data retrieval policy in the region specified in the PUT request. You can set one policy per region for an AWS account. The policy is enacted within a few minutes of a successful PUT operation.</p> <p>The set policy operation does not affect retrieval jobs that were in progress before the policy was enacted. For more information about data retrieval policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html">Amazon Glacier Data Retrieval Policies</a>. </p>
  ## 
  let valid = call_603424.validator(path, query, header, formData, body)
  let scheme = call_603424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603424.url(scheme.get, call_603424.host, call_603424.base,
                         call_603424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603424, url, valid)

proc call*(call_603425: Call_SetDataRetrievalPolicy_603412; accountId: string;
          body: JsonNode): Recallable =
  ## setDataRetrievalPolicy
  ## <p>This operation sets and then enacts a data retrieval policy in the region specified in the PUT request. You can set one policy per region for an AWS account. The policy is enacted within a few minutes of a successful PUT operation.</p> <p>The set policy operation does not affect retrieval jobs that were in progress before the policy was enacted. For more information about data retrieval policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html">Amazon Glacier Data Retrieval Policies</a>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   body: JObject (required)
  var path_603426 = newJObject()
  var body_603427 = newJObject()
  add(path_603426, "accountId", newJString(accountId))
  if body != nil:
    body_603427 = body
  result = call_603425.call(path_603426, nil, nil, nil, body_603427)

var setDataRetrievalPolicy* = Call_SetDataRetrievalPolicy_603412(
    name: "setDataRetrievalPolicy", meth: HttpMethod.HttpPut,
    host: "glacier.amazonaws.com", route: "/{accountId}/policies/data-retrieval",
    validator: validate_SetDataRetrievalPolicy_603413, base: "/",
    url: url_SetDataRetrievalPolicy_603414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataRetrievalPolicy_603398 = ref object of OpenApiRestCall_602466
proc url_GetDataRetrievalPolicy_603400(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/policies/data-retrieval")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDataRetrievalPolicy_603399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns the current data retrieval policy for the account and region specified in the GET request. For more information about data retrieval policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html">Amazon Glacier Data Retrieval Policies</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603401 = path.getOrDefault("accountId")
  valid_603401 = validateParameter(valid_603401, JString, required = true,
                                 default = nil)
  if valid_603401 != nil:
    section.add "accountId", valid_603401
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603402 = header.getOrDefault("X-Amz-Date")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Date", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Security-Token")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Security-Token", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Content-Sha256", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Algorithm")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Algorithm", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Signature")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Signature", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-SignedHeaders", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Credential")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Credential", valid_603408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603409: Call_GetDataRetrievalPolicy_603398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the current data retrieval policy for the account and region specified in the GET request. For more information about data retrieval policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html">Amazon Glacier Data Retrieval Policies</a>.
  ## 
  let valid = call_603409.validator(path, query, header, formData, body)
  let scheme = call_603409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603409.url(scheme.get, call_603409.host, call_603409.base,
                         call_603409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603409, url, valid)

proc call*(call_603410: Call_GetDataRetrievalPolicy_603398; accountId: string): Recallable =
  ## getDataRetrievalPolicy
  ## This operation returns the current data retrieval policy for the account and region specified in the GET request. For more information about data retrieval policies, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/data-retrieval-policy.html">Amazon Glacier Data Retrieval Policies</a>.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID. 
  var path_603411 = newJObject()
  add(path_603411, "accountId", newJString(accountId))
  result = call_603410.call(path_603411, nil, nil, nil, nil)

var getDataRetrievalPolicy* = Call_GetDataRetrievalPolicy_603398(
    name: "getDataRetrievalPolicy", meth: HttpMethod.HttpGet,
    host: "glacier.amazonaws.com", route: "/{accountId}/policies/data-retrieval",
    validator: validate_GetDataRetrievalPolicy_603399, base: "/",
    url: url_GetDataRetrievalPolicy_603400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobOutput_603428 = ref object of OpenApiRestCall_602466
proc url_GetJobOutput_603430(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId"),
               (kind: ConstantSegment, value: "/output")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetJobOutput_603429(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation downloads the output of the job you initiated using <a>InitiateJob</a>. Depending on the job type you specified when you initiated the job, the output will be either the content of an archive or a vault inventory.</p> <p>You can download all the job output or download a portion of the output by specifying a byte range. In the case of an archive retrieval job, depending on the byte range you specify, Amazon S3 Glacier (Glacier) returns the checksum for the portion of the data. You can compute the checksum on the client and verify that the values match to ensure the portion you downloaded is the correct data.</p> <p>A job ID will not expire for at least 24 hours after Glacier completes the job. That a byte range. For both archive and inventory retrieval jobs, you should verify the downloaded size against the size returned in the headers from the <b>Get Job Output</b> response.</p> <p>For archive retrieval jobs, you should also verify that the size is what you expected. If you download a portion of the output, the expected size is based on the range of bytes you specified. For example, if you specify a range of <code>bytes=0-1048575</code>, you should verify your download size is 1,048,576 bytes. If you download an entire archive, the expected size is the size of the archive when you uploaded it to Amazon S3 Glacier The expected size is also returned in the headers from the <b>Get Job Output</b> response.</p> <p>In the case of an archive retrieval job, depending on the byte range you specify, Glacier returns the checksum for the portion of the data. To ensure the portion you downloaded is the correct data, compute the checksum on the client, verify that the values match, and verify that the size is what you expected.</p> <p>A job ID does not expire for at least 24 hours after Glacier completes the job. That is, you can download the job output within the 24 hours period after Amazon Glacier completes the job.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html">Downloading a Vault Inventory</a>, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/downloading-an-archive.html">Downloading an Archive</a>, and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-job-output-get.html">Get Job Output </a> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        : The job ID whose data is downloaded.
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_603431 = path.getOrDefault("jobId")
  valid_603431 = validateParameter(valid_603431, JString, required = true,
                                 default = nil)
  if valid_603431 != nil:
    section.add "jobId", valid_603431
  var valid_603432 = path.getOrDefault("accountId")
  valid_603432 = validateParameter(valid_603432, JString, required = true,
                                 default = nil)
  if valid_603432 != nil:
    section.add "accountId", valid_603432
  var valid_603433 = path.getOrDefault("vaultName")
  valid_603433 = validateParameter(valid_603433, JString, required = true,
                                 default = nil)
  if valid_603433 != nil:
    section.add "vaultName", valid_603433
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
  ##   X-Amz-Credential: JString
  ##   Range: JString
  ##        : <p>The range of bytes to retrieve from the output. For example, if you want to download the first 1,048,576 bytes, specify the range as <code>bytes=0-1048575</code>. By default, this operation downloads the entire output.</p> <p>If the job output is large, then you can use a range to retrieve a portion of the output. This allows you to download the entire output in smaller chunks of bytes. For example, suppose you have 1 GB of job output you want to download and you decide to download 128 MB chunks of data at a time, which is a total of eight Get Job Output requests. You use the following process to download the job output:</p> <ol> <li> <p>Download a 128 MB chunk of output by specifying the appropriate byte range. Verify that all 128 MB of data was received.</p> </li> <li> <p>Along with the data, the response includes a SHA256 tree hash of the payload. You compute the checksum of the payload on the client and compare it with the checksum you received in the response to ensure you received all the expected data.</p> </li> <li> <p>Repeat steps 1 and 2 for all the eight 128 MB chunks of output data, each time specifying the appropriate byte range.</p> </li> <li> <p>After downloading all the parts of the job output, you have a list of eight checksum values. Compute the tree hash of these values to find the checksum of the entire output. Using the <a>DescribeJob</a> API, obtain job information of the job that provided you the output. The response includes the checksum of the entire archive stored in Amazon S3 Glacier. You compare this value with the checksum you computed to ensure you have downloaded the entire archive content with no errors.</p> <p/> </li> </ol>
  section = newJObject()
  var valid_603434 = header.getOrDefault("X-Amz-Date")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Date", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Security-Token")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Security-Token", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Content-Sha256", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Algorithm")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Algorithm", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-SignedHeaders", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Credential")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Credential", valid_603440
  var valid_603441 = header.getOrDefault("Range")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "Range", valid_603441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603442: Call_GetJobOutput_603428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation downloads the output of the job you initiated using <a>InitiateJob</a>. Depending on the job type you specified when you initiated the job, the output will be either the content of an archive or a vault inventory.</p> <p>You can download all the job output or download a portion of the output by specifying a byte range. In the case of an archive retrieval job, depending on the byte range you specify, Amazon S3 Glacier (Glacier) returns the checksum for the portion of the data. You can compute the checksum on the client and verify that the values match to ensure the portion you downloaded is the correct data.</p> <p>A job ID will not expire for at least 24 hours after Glacier completes the job. That a byte range. For both archive and inventory retrieval jobs, you should verify the downloaded size against the size returned in the headers from the <b>Get Job Output</b> response.</p> <p>For archive retrieval jobs, you should also verify that the size is what you expected. If you download a portion of the output, the expected size is based on the range of bytes you specified. For example, if you specify a range of <code>bytes=0-1048575</code>, you should verify your download size is 1,048,576 bytes. If you download an entire archive, the expected size is the size of the archive when you uploaded it to Amazon S3 Glacier The expected size is also returned in the headers from the <b>Get Job Output</b> response.</p> <p>In the case of an archive retrieval job, depending on the byte range you specify, Glacier returns the checksum for the portion of the data. To ensure the portion you downloaded is the correct data, compute the checksum on the client, verify that the values match, and verify that the size is what you expected.</p> <p>A job ID does not expire for at least 24 hours after Glacier completes the job. That is, you can download the job output within the 24 hours period after Amazon Glacier completes the job.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html">Downloading a Vault Inventory</a>, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/downloading-an-archive.html">Downloading an Archive</a>, and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-job-output-get.html">Get Job Output </a> </p>
  ## 
  let valid = call_603442.validator(path, query, header, formData, body)
  let scheme = call_603442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603442.url(scheme.get, call_603442.host, call_603442.base,
                         call_603442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603442, url, valid)

proc call*(call_603443: Call_GetJobOutput_603428; jobId: string; accountId: string;
          vaultName: string): Recallable =
  ## getJobOutput
  ## <p>This operation downloads the output of the job you initiated using <a>InitiateJob</a>. Depending on the job type you specified when you initiated the job, the output will be either the content of an archive or a vault inventory.</p> <p>You can download all the job output or download a portion of the output by specifying a byte range. In the case of an archive retrieval job, depending on the byte range you specify, Amazon S3 Glacier (Glacier) returns the checksum for the portion of the data. You can compute the checksum on the client and verify that the values match to ensure the portion you downloaded is the correct data.</p> <p>A job ID will not expire for at least 24 hours after Glacier completes the job. That a byte range. For both archive and inventory retrieval jobs, you should verify the downloaded size against the size returned in the headers from the <b>Get Job Output</b> response.</p> <p>For archive retrieval jobs, you should also verify that the size is what you expected. If you download a portion of the output, the expected size is based on the range of bytes you specified. For example, if you specify a range of <code>bytes=0-1048575</code>, you should verify your download size is 1,048,576 bytes. If you download an entire archive, the expected size is the size of the archive when you uploaded it to Amazon S3 Glacier The expected size is also returned in the headers from the <b>Get Job Output</b> response.</p> <p>In the case of an archive retrieval job, depending on the byte range you specify, Glacier returns the checksum for the portion of the data. To ensure the portion you downloaded is the correct data, compute the checksum on the client, verify that the values match, and verify that the size is what you expected.</p> <p>A job ID does not expire for at least 24 hours after Glacier completes the job. That is, you can download the job output within the 24 hours period after Amazon Glacier completes the job.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-inventory.html">Downloading a Vault Inventory</a>, <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/downloading-an-archive.html">Downloading an Archive</a>, and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-job-output-get.html">Get Job Output </a> </p>
  ##   jobId: string (required)
  ##        : The job ID whose data is downloaded.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603444 = newJObject()
  add(path_603444, "jobId", newJString(jobId))
  add(path_603444, "accountId", newJString(accountId))
  add(path_603444, "vaultName", newJString(vaultName))
  result = call_603443.call(path_603444, nil, nil, nil, nil)

var getJobOutput* = Call_GetJobOutput_603428(name: "getJobOutput",
    meth: HttpMethod.HttpGet, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/jobs/{jobId}/output",
    validator: validate_GetJobOutput_603429, base: "/", url: url_GetJobOutput_603430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateJob_603465 = ref object of OpenApiRestCall_602466
proc url_InitiateJob_603467(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_InitiateJob_603466(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation initiates a job of the specified type, which can be a select, an archival retrieval, or a vault retrieval. For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html">Initiate a Job</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603468 = path.getOrDefault("accountId")
  valid_603468 = validateParameter(valid_603468, JString, required = true,
                                 default = nil)
  if valid_603468 != nil:
    section.add "accountId", valid_603468
  var valid_603469 = path.getOrDefault("vaultName")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = nil)
  if valid_603469 != nil:
    section.add "vaultName", valid_603469
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603470 = header.getOrDefault("X-Amz-Date")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Date", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Security-Token")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Security-Token", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_InitiateJob_603465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates a job of the specified type, which can be a select, an archival retrieval, or a vault retrieval. For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html">Initiate a Job</a>. 
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_InitiateJob_603465; accountId: string;
          vaultName: string; body: JsonNode): Recallable =
  ## initiateJob
  ## This operation initiates a job of the specified type, which can be a select, an archival retrieval, or a vault retrieval. For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html">Initiate a Job</a>. 
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   body: JObject (required)
  var path_603480 = newJObject()
  var body_603481 = newJObject()
  add(path_603480, "accountId", newJString(accountId))
  add(path_603480, "vaultName", newJString(vaultName))
  if body != nil:
    body_603481 = body
  result = call_603479.call(path_603480, nil, nil, nil, body_603481)

var initiateJob* = Call_InitiateJob_603465(name: "initiateJob",
                                        meth: HttpMethod.HttpPost,
                                        host: "glacier.amazonaws.com", route: "/{accountId}/vaults/{vaultName}/jobs",
                                        validator: validate_InitiateJob_603466,
                                        base: "/", url: url_InitiateJob_603467,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_603445 = ref object of OpenApiRestCall_602466
proc url_ListJobs_603447(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListJobs_603446(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation lists jobs for a vault, including jobs that are in-progress and jobs that have recently finished. The List Job operation returns a list of these jobs sorted by job initiation time.</p> <note> <p>Amazon Glacier retains recently completed jobs for a period before deleting them; however, it eventually removes completed jobs. The output of completed jobs can be retrieved. Retaining completed jobs for a period of time after they have completed enables you to get a job output in the event you miss the job completion notification or your first attempt to download it fails. For example, suppose you start an archive retrieval job to download an archive. After the job completes, you start to download the archive but encounter a network error. In this scenario, you can retry and download the archive while the job exists.</p> </note> <p>The List Jobs operation supports pagination. You should always check the response <code>Marker</code> field. If there are no more jobs to list, the <code>Marker</code> field is set to <code>null</code>. If there are more jobs to list, the <code>Marker</code> field is set to a non-null value, which you can use to continue the pagination of the list. To return a list of jobs that begins at a specific job, set the marker request parameter to the <code>Marker</code> value for that job that you obtained from a previous List Jobs request.</p> <p>You can set a maximum limit for the number of jobs returned in the response by specifying the <code>limit</code> parameter in the request. The default limit is 50. The number of jobs returned might be fewer than the limit, but the number of returned jobs never exceeds the limit.</p> <p>Additionally, you can filter the jobs list returned by specifying the optional <code>statuscode</code> parameter or <code>completed</code> parameter, or both. Using the <code>statuscode</code> parameter, you can specify to return only jobs that match either the <code>InProgress</code>, <code>Succeeded</code>, or <code>Failed</code> status. Using the <code>completed</code> parameter, you can specify to return only jobs that were completed (<code>true</code>) or jobs that were not completed (<code>false</code>).</p> <p>For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-jobs-get.html">List Jobs</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603448 = path.getOrDefault("accountId")
  valid_603448 = validateParameter(valid_603448, JString, required = true,
                                 default = nil)
  if valid_603448 != nil:
    section.add "accountId", valid_603448
  var valid_603449 = path.getOrDefault("vaultName")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = nil)
  if valid_603449 != nil:
    section.add "vaultName", valid_603449
  result.add "path", section
  ## parameters in `query` object:
  ##   statuscode: JString
  ##             : The type of job status to return. You can specify the following values: <code>InProgress</code>, <code>Succeeded</code>, or <code>Failed</code>.
  ##   marker: JString
  ##         : An opaque string used for pagination. This value specifies the job at which the listing of jobs should begin. Get the marker value from a previous List Jobs response. You only need to include the marker if you are continuing the pagination of results started in a previous List Jobs request.
  ##   completed: JString
  ##            : The state of the jobs to return. You can specify <code>true</code> or <code>false</code>.
  ##   limit: JString
  ##        : The maximum number of jobs to be returned. The default limit is 50. The number of jobs returned might be fewer than the specified limit, but the number of returned jobs never exceeds the limit.
  section = newJObject()
  var valid_603450 = query.getOrDefault("statuscode")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "statuscode", valid_603450
  var valid_603451 = query.getOrDefault("marker")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "marker", valid_603451
  var valid_603452 = query.getOrDefault("completed")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "completed", valid_603452
  var valid_603453 = query.getOrDefault("limit")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "limit", valid_603453
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
  var valid_603454 = header.getOrDefault("X-Amz-Date")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Date", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Security-Token")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Security-Token", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Content-Sha256", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Algorithm")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Algorithm", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Signature")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Signature", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-SignedHeaders", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Credential")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Credential", valid_603460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603461: Call_ListJobs_603445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation lists jobs for a vault, including jobs that are in-progress and jobs that have recently finished. The List Job operation returns a list of these jobs sorted by job initiation time.</p> <note> <p>Amazon Glacier retains recently completed jobs for a period before deleting them; however, it eventually removes completed jobs. The output of completed jobs can be retrieved. Retaining completed jobs for a period of time after they have completed enables you to get a job output in the event you miss the job completion notification or your first attempt to download it fails. For example, suppose you start an archive retrieval job to download an archive. After the job completes, you start to download the archive but encounter a network error. In this scenario, you can retry and download the archive while the job exists.</p> </note> <p>The List Jobs operation supports pagination. You should always check the response <code>Marker</code> field. If there are no more jobs to list, the <code>Marker</code> field is set to <code>null</code>. If there are more jobs to list, the <code>Marker</code> field is set to a non-null value, which you can use to continue the pagination of the list. To return a list of jobs that begins at a specific job, set the marker request parameter to the <code>Marker</code> value for that job that you obtained from a previous List Jobs request.</p> <p>You can set a maximum limit for the number of jobs returned in the response by specifying the <code>limit</code> parameter in the request. The default limit is 50. The number of jobs returned might be fewer than the limit, but the number of returned jobs never exceeds the limit.</p> <p>Additionally, you can filter the jobs list returned by specifying the optional <code>statuscode</code> parameter or <code>completed</code> parameter, or both. Using the <code>statuscode</code> parameter, you can specify to return only jobs that match either the <code>InProgress</code>, <code>Succeeded</code>, or <code>Failed</code> status. Using the <code>completed</code> parameter, you can specify to return only jobs that were completed (<code>true</code>) or jobs that were not completed (<code>false</code>).</p> <p>For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-jobs-get.html">List Jobs</a>. </p>
  ## 
  let valid = call_603461.validator(path, query, header, formData, body)
  let scheme = call_603461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603461.url(scheme.get, call_603461.host, call_603461.base,
                         call_603461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603461, url, valid)

proc call*(call_603462: Call_ListJobs_603445; accountId: string; vaultName: string;
          statuscode: string = ""; marker: string = ""; completed: string = "";
          limit: string = ""): Recallable =
  ## listJobs
  ## <p>This operation lists jobs for a vault, including jobs that are in-progress and jobs that have recently finished. The List Job operation returns a list of these jobs sorted by job initiation time.</p> <note> <p>Amazon Glacier retains recently completed jobs for a period before deleting them; however, it eventually removes completed jobs. The output of completed jobs can be retrieved. Retaining completed jobs for a period of time after they have completed enables you to get a job output in the event you miss the job completion notification or your first attempt to download it fails. For example, suppose you start an archive retrieval job to download an archive. After the job completes, you start to download the archive but encounter a network error. In this scenario, you can retry and download the archive while the job exists.</p> </note> <p>The List Jobs operation supports pagination. You should always check the response <code>Marker</code> field. If there are no more jobs to list, the <code>Marker</code> field is set to <code>null</code>. If there are more jobs to list, the <code>Marker</code> field is set to a non-null value, which you can use to continue the pagination of the list. To return a list of jobs that begins at a specific job, set the marker request parameter to the <code>Marker</code> value for that job that you obtained from a previous List Jobs request.</p> <p>You can set a maximum limit for the number of jobs returned in the response by specifying the <code>limit</code> parameter in the request. The default limit is 50. The number of jobs returned might be fewer than the limit, but the number of returned jobs never exceeds the limit.</p> <p>Additionally, you can filter the jobs list returned by specifying the optional <code>statuscode</code> parameter or <code>completed</code> parameter, or both. Using the <code>statuscode</code> parameter, you can specify to return only jobs that match either the <code>InProgress</code>, <code>Succeeded</code>, or <code>Failed</code> status. Using the <code>completed</code> parameter, you can specify to return only jobs that were completed (<code>true</code>) or jobs that were not completed (<code>false</code>).</p> <p>For more information about using this operation, see the documentation for the underlying REST API <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-jobs-get.html">List Jobs</a>. </p>
  ##   statuscode: string
  ##             : The type of job status to return. You can specify the following values: <code>InProgress</code>, <code>Succeeded</code>, or <code>Failed</code>.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   marker: string
  ##         : An opaque string used for pagination. This value specifies the job at which the listing of jobs should begin. Get the marker value from a previous List Jobs response. You only need to include the marker if you are continuing the pagination of results started in a previous List Jobs request.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   completed: string
  ##            : The state of the jobs to return. You can specify <code>true</code> or <code>false</code>.
  ##   limit: string
  ##        : The maximum number of jobs to be returned. The default limit is 50. The number of jobs returned might be fewer than the specified limit, but the number of returned jobs never exceeds the limit.
  var path_603463 = newJObject()
  var query_603464 = newJObject()
  add(query_603464, "statuscode", newJString(statuscode))
  add(path_603463, "accountId", newJString(accountId))
  add(query_603464, "marker", newJString(marker))
  add(path_603463, "vaultName", newJString(vaultName))
  add(query_603464, "completed", newJString(completed))
  add(query_603464, "limit", newJString(limit))
  result = call_603462.call(path_603463, query_603464, nil, nil, nil)

var listJobs* = Call_ListJobs_603445(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "glacier.amazonaws.com", route: "/{accountId}/vaults/{vaultName}/jobs",
                                  validator: validate_ListJobs_603446, base: "/",
                                  url: url_ListJobs_603447,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateMultipartUpload_603500 = ref object of OpenApiRestCall_602466
proc url_InitiateMultipartUpload_603502(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/multipart-uploads")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_InitiateMultipartUpload_603501(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation initiates a multipart upload. Amazon S3 Glacier creates a multipart upload resource and returns its ID in the response. The multipart upload ID is used in subsequent requests to upload parts of an archive (see <a>UploadMultipartPart</a>).</p> <p>When you initiate a multipart upload, you specify the part size in number of bytes. The part size must be a megabyte (1024 KB) multiplied by a power of 2-for example, 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1 MB, and the maximum is 4 GB.</p> <p>Every part you upload to this resource (see <a>UploadMultipartPart</a>), except the last one, must have the same size. The last one can be the same size or smaller. For example, suppose you want to upload a 16.2 MB file. If you initiate the multipart upload with a part size of 4 MB, you will upload four parts of 4 MB each and one part of 0.2 MB. </p> <note> <p>You don't need to know the size of the archive when you start a multipart upload because Amazon S3 Glacier does not require you to specify the overall archive size.</p> </note> <p>After you complete the multipart upload, Amazon S3 Glacier (Glacier) removes the multipart upload resource referenced by the ID. Glacier also removes the multipart upload resource if you cancel the multipart upload or it may be removed if there is no activity for a period of 24 hours.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-initiate-upload.html">Initiate Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603503 = path.getOrDefault("accountId")
  valid_603503 = validateParameter(valid_603503, JString, required = true,
                                 default = nil)
  if valid_603503 != nil:
    section.add "accountId", valid_603503
  var valid_603504 = path.getOrDefault("vaultName")
  valid_603504 = validateParameter(valid_603504, JString, required = true,
                                 default = nil)
  if valid_603504 != nil:
    section.add "vaultName", valid_603504
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   x-amz-part-size: JString
  ##                  : The size of each part except the last, in bytes. The last part can be smaller than this part size.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-archive-description: JString
  ##                            : <p>The archive description that you are uploading in parts.</p> <p>The part size must be a megabyte (1024 KB) multiplied by a power of 2, for example 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1 MB, and the maximum is 4 GB (4096 MB).</p>
  section = newJObject()
  var valid_603505 = header.getOrDefault("X-Amz-Date")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Date", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Security-Token")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Security-Token", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Content-Sha256", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Algorithm")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Algorithm", valid_603508
  var valid_603509 = header.getOrDefault("x-amz-part-size")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "x-amz-part-size", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Signature")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Signature", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-SignedHeaders", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Credential")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Credential", valid_603512
  var valid_603513 = header.getOrDefault("x-amz-archive-description")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "x-amz-archive-description", valid_603513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603514: Call_InitiateMultipartUpload_603500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation initiates a multipart upload. Amazon S3 Glacier creates a multipart upload resource and returns its ID in the response. The multipart upload ID is used in subsequent requests to upload parts of an archive (see <a>UploadMultipartPart</a>).</p> <p>When you initiate a multipart upload, you specify the part size in number of bytes. The part size must be a megabyte (1024 KB) multiplied by a power of 2-for example, 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1 MB, and the maximum is 4 GB.</p> <p>Every part you upload to this resource (see <a>UploadMultipartPart</a>), except the last one, must have the same size. The last one can be the same size or smaller. For example, suppose you want to upload a 16.2 MB file. If you initiate the multipart upload with a part size of 4 MB, you will upload four parts of 4 MB each and one part of 0.2 MB. </p> <note> <p>You don't need to know the size of the archive when you start a multipart upload because Amazon S3 Glacier does not require you to specify the overall archive size.</p> </note> <p>After you complete the multipart upload, Amazon S3 Glacier (Glacier) removes the multipart upload resource referenced by the ID. Glacier also removes the multipart upload resource if you cancel the multipart upload or it may be removed if there is no activity for a period of 24 hours.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-initiate-upload.html">Initiate Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  let valid = call_603514.validator(path, query, header, formData, body)
  let scheme = call_603514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603514.url(scheme.get, call_603514.host, call_603514.base,
                         call_603514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603514, url, valid)

proc call*(call_603515: Call_InitiateMultipartUpload_603500; accountId: string;
          vaultName: string): Recallable =
  ## initiateMultipartUpload
  ## <p>This operation initiates a multipart upload. Amazon S3 Glacier creates a multipart upload resource and returns its ID in the response. The multipart upload ID is used in subsequent requests to upload parts of an archive (see <a>UploadMultipartPart</a>).</p> <p>When you initiate a multipart upload, you specify the part size in number of bytes. The part size must be a megabyte (1024 KB) multiplied by a power of 2-for example, 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1 MB, and the maximum is 4 GB.</p> <p>Every part you upload to this resource (see <a>UploadMultipartPart</a>), except the last one, must have the same size. The last one can be the same size or smaller. For example, suppose you want to upload a 16.2 MB file. If you initiate the multipart upload with a part size of 4 MB, you will upload four parts of 4 MB each and one part of 0.2 MB. </p> <note> <p>You don't need to know the size of the archive when you start a multipart upload because Amazon S3 Glacier does not require you to specify the overall archive size.</p> </note> <p>After you complete the multipart upload, Amazon S3 Glacier (Glacier) removes the multipart upload resource referenced by the ID. Glacier also removes the multipart upload resource if you cancel the multipart upload or it may be removed if there is no activity for a period of 24 hours.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html">Uploading Large Archives in Parts (Multipart Upload)</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-initiate-upload.html">Initiate Multipart Upload</a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603516 = newJObject()
  add(path_603516, "accountId", newJString(accountId))
  add(path_603516, "vaultName", newJString(vaultName))
  result = call_603515.call(path_603516, nil, nil, nil, nil)

var initiateMultipartUpload* = Call_InitiateMultipartUpload_603500(
    name: "initiateMultipartUpload", meth: HttpMethod.HttpPost,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/multipart-uploads",
    validator: validate_InitiateMultipartUpload_603501, base: "/",
    url: url_InitiateMultipartUpload_603502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultipartUploads_603482 = ref object of OpenApiRestCall_602466
proc url_ListMultipartUploads_603484(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/multipart-uploads")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListMultipartUploads_603483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation lists in-progress multipart uploads for the specified vault. An in-progress multipart upload is a multipart upload that has been initiated by an <a>InitiateMultipartUpload</a> request, but has not yet been completed or aborted. The list returned in the List Multipart Upload response has no guaranteed order. </p> <p>The List Multipart Uploads operation supports pagination. By default, this operation returns up to 50 multipart uploads in the response. You should always check the response for a <code>marker</code> at which to continue the list; if there are no more items the <code>marker</code> is <code>null</code>. To return a list of multipart uploads that begins at a specific upload, set the <code>marker</code> request parameter to the value you obtained from a previous List Multipart Upload request. You can also limit the number of uploads returned in the response by specifying the <code>limit</code> parameter in the request.</p> <p>Note the difference between this operation and listing parts (<a>ListParts</a>). The List Multipart Uploads operation lists all multipart uploads for a vault and does not require a multipart upload ID. The List Parts operation requires a multipart upload ID since parts are associated with a single upload.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-uploads.html">List Multipart Uploads </a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603485 = path.getOrDefault("accountId")
  valid_603485 = validateParameter(valid_603485, JString, required = true,
                                 default = nil)
  if valid_603485 != nil:
    section.add "accountId", valid_603485
  var valid_603486 = path.getOrDefault("vaultName")
  valid_603486 = validateParameter(valid_603486, JString, required = true,
                                 default = nil)
  if valid_603486 != nil:
    section.add "vaultName", valid_603486
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : An opaque string used for pagination. This value specifies the upload at which the listing of uploads should begin. Get the marker value from a previous List Uploads response. You need only include the marker if you are continuing the pagination of results started in a previous List Uploads request.
  ##   limit: JString
  ##        : Specifies the maximum number of uploads returned in the response body. If this value is not specified, the List Uploads operation returns up to 50 uploads.
  section = newJObject()
  var valid_603487 = query.getOrDefault("marker")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "marker", valid_603487
  var valid_603488 = query.getOrDefault("limit")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "limit", valid_603488
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
  var valid_603489 = header.getOrDefault("X-Amz-Date")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Date", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Security-Token")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Security-Token", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Content-Sha256", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Algorithm")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Algorithm", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Signature")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Signature", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-SignedHeaders", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Credential")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Credential", valid_603495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603496: Call_ListMultipartUploads_603482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation lists in-progress multipart uploads for the specified vault. An in-progress multipart upload is a multipart upload that has been initiated by an <a>InitiateMultipartUpload</a> request, but has not yet been completed or aborted. The list returned in the List Multipart Upload response has no guaranteed order. </p> <p>The List Multipart Uploads operation supports pagination. By default, this operation returns up to 50 multipart uploads in the response. You should always check the response for a <code>marker</code> at which to continue the list; if there are no more items the <code>marker</code> is <code>null</code>. To return a list of multipart uploads that begins at a specific upload, set the <code>marker</code> request parameter to the value you obtained from a previous List Multipart Upload request. You can also limit the number of uploads returned in the response by specifying the <code>limit</code> parameter in the request.</p> <p>Note the difference between this operation and listing parts (<a>ListParts</a>). The List Multipart Uploads operation lists all multipart uploads for a vault and does not require a multipart upload ID. The List Parts operation requires a multipart upload ID since parts are associated with a single upload.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-uploads.html">List Multipart Uploads </a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ## 
  let valid = call_603496.validator(path, query, header, formData, body)
  let scheme = call_603496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603496.url(scheme.get, call_603496.host, call_603496.base,
                         call_603496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603496, url, valid)

proc call*(call_603497: Call_ListMultipartUploads_603482; accountId: string;
          vaultName: string; marker: string = ""; limit: string = ""): Recallable =
  ## listMultipartUploads
  ## <p>This operation lists in-progress multipart uploads for the specified vault. An in-progress multipart upload is a multipart upload that has been initiated by an <a>InitiateMultipartUpload</a> request, but has not yet been completed or aborted. The list returned in the List Multipart Upload response has no guaranteed order. </p> <p>The List Multipart Uploads operation supports pagination. By default, this operation returns up to 50 multipart uploads in the response. You should always check the response for a <code>marker</code> at which to continue the list; if there are no more items the <code>marker</code> is <code>null</code>. To return a list of multipart uploads that begins at a specific upload, set the <code>marker</code> request parameter to the value you obtained from a previous List Multipart Upload request. You can also limit the number of uploads returned in the response by specifying the <code>limit</code> parameter in the request.</p> <p>Note the difference between this operation and listing parts (<a>ListParts</a>). The List Multipart Uploads operation lists all multipart uploads for a vault and does not require a multipart upload ID. The List Parts operation requires a multipart upload ID since parts are associated with a single upload.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and the underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/working-with-archives.html">Working with Archives in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-uploads.html">List Multipart Uploads </a> in the <i>Amazon Glacier Developer Guide</i>.</p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   marker: string
  ##         : An opaque string used for pagination. This value specifies the upload at which the listing of uploads should begin. Get the marker value from a previous List Uploads response. You need only include the marker if you are continuing the pagination of results started in a previous List Uploads request.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   limit: string
  ##        : Specifies the maximum number of uploads returned in the response body. If this value is not specified, the List Uploads operation returns up to 50 uploads.
  var path_603498 = newJObject()
  var query_603499 = newJObject()
  add(path_603498, "accountId", newJString(accountId))
  add(query_603499, "marker", newJString(marker))
  add(path_603498, "vaultName", newJString(vaultName))
  add(query_603499, "limit", newJString(limit))
  result = call_603497.call(path_603498, query_603499, nil, nil, nil)

var listMultipartUploads* = Call_ListMultipartUploads_603482(
    name: "listMultipartUploads", meth: HttpMethod.HttpGet,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/multipart-uploads",
    validator: validate_ListMultipartUploads_603483, base: "/",
    url: url_ListMultipartUploads_603484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseProvisionedCapacity_603531 = ref object of OpenApiRestCall_602466
proc url_PurchaseProvisionedCapacity_603533(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/provisioned-capacity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PurchaseProvisionedCapacity_603532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation purchases a provisioned capacity unit for an AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '-' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, don't include any hyphens ('-') in the ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603534 = path.getOrDefault("accountId")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = nil)
  if valid_603534 != nil:
    section.add "accountId", valid_603534
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603535 = header.getOrDefault("X-Amz-Date")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Date", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Security-Token")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Security-Token", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Content-Sha256", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Algorithm")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Algorithm", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Signature")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Signature", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-SignedHeaders", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Credential")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Credential", valid_603541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603542: Call_PurchaseProvisionedCapacity_603531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation purchases a provisioned capacity unit for an AWS account. 
  ## 
  let valid = call_603542.validator(path, query, header, formData, body)
  let scheme = call_603542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603542.url(scheme.get, call_603542.host, call_603542.base,
                         call_603542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603542, url, valid)

proc call*(call_603543: Call_PurchaseProvisionedCapacity_603531; accountId: string): Recallable =
  ## purchaseProvisionedCapacity
  ## This operation purchases a provisioned capacity unit for an AWS account. 
  ##   accountId: string (required)
  ##            : The AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '-' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, don't include any hyphens ('-') in the ID. 
  var path_603544 = newJObject()
  add(path_603544, "accountId", newJString(accountId))
  result = call_603543.call(path_603544, nil, nil, nil, nil)

var purchaseProvisionedCapacity* = Call_PurchaseProvisionedCapacity_603531(
    name: "purchaseProvisionedCapacity", meth: HttpMethod.HttpPost,
    host: "glacier.amazonaws.com", route: "/{accountId}/provisioned-capacity",
    validator: validate_PurchaseProvisionedCapacity_603532, base: "/",
    url: url_PurchaseProvisionedCapacity_603533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedCapacity_603517 = ref object of OpenApiRestCall_602466
proc url_ListProvisionedCapacity_603519(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/provisioned-capacity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListProvisionedCapacity_603518(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists the provisioned capacity units for the specified AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '-' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, don't include any hyphens ('-') in the ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603520 = path.getOrDefault("accountId")
  valid_603520 = validateParameter(valid_603520, JString, required = true,
                                 default = nil)
  if valid_603520 != nil:
    section.add "accountId", valid_603520
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603521 = header.getOrDefault("X-Amz-Date")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Date", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Security-Token")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Security-Token", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Content-Sha256", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Algorithm")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Algorithm", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Signature")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Signature", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-SignedHeaders", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Credential")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Credential", valid_603527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603528: Call_ListProvisionedCapacity_603517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists the provisioned capacity units for the specified AWS account.
  ## 
  let valid = call_603528.validator(path, query, header, formData, body)
  let scheme = call_603528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603528.url(scheme.get, call_603528.host, call_603528.base,
                         call_603528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603528, url, valid)

proc call*(call_603529: Call_ListProvisionedCapacity_603517; accountId: string): Recallable =
  ## listProvisionedCapacity
  ## This operation lists the provisioned capacity units for the specified AWS account.
  ##   accountId: string (required)
  ##            : The AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '-' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, don't include any hyphens ('-') in the ID. 
  var path_603530 = newJObject()
  add(path_603530, "accountId", newJString(accountId))
  result = call_603529.call(path_603530, nil, nil, nil, nil)

var listProvisionedCapacity* = Call_ListProvisionedCapacity_603517(
    name: "listProvisionedCapacity", meth: HttpMethod.HttpGet,
    host: "glacier.amazonaws.com", route: "/{accountId}/provisioned-capacity",
    validator: validate_ListProvisionedCapacity_603518, base: "/",
    url: url_ListProvisionedCapacity_603519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForVault_603545 = ref object of OpenApiRestCall_602466
proc url_ListTagsForVault_603547(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTagsForVault_603546(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## This operation lists all the tags attached to a vault. The operation returns an empty map if there are no tags. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603548 = path.getOrDefault("accountId")
  valid_603548 = validateParameter(valid_603548, JString, required = true,
                                 default = nil)
  if valid_603548 != nil:
    section.add "accountId", valid_603548
  var valid_603549 = path.getOrDefault("vaultName")
  valid_603549 = validateParameter(valid_603549, JString, required = true,
                                 default = nil)
  if valid_603549 != nil:
    section.add "vaultName", valid_603549
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603550 = header.getOrDefault("X-Amz-Date")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Date", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Security-Token")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Security-Token", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Content-Sha256", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Algorithm")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Algorithm", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Signature")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Signature", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-SignedHeaders", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Credential")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Credential", valid_603556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603557: Call_ListTagsForVault_603545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists all the tags attached to a vault. The operation returns an empty map if there are no tags. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>.
  ## 
  let valid = call_603557.validator(path, query, header, formData, body)
  let scheme = call_603557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603557.url(scheme.get, call_603557.host, call_603557.base,
                         call_603557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603557, url, valid)

proc call*(call_603558: Call_ListTagsForVault_603545; accountId: string;
          vaultName: string): Recallable =
  ## listTagsForVault
  ## This operation lists all the tags attached to a vault. The operation returns an empty map if there are no tags. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>.
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  var path_603559 = newJObject()
  add(path_603559, "accountId", newJString(accountId))
  add(path_603559, "vaultName", newJString(vaultName))
  result = call_603558.call(path_603559, nil, nil, nil, nil)

var listTagsForVault* = Call_ListTagsForVault_603545(name: "listTagsForVault",
    meth: HttpMethod.HttpGet, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/tags",
    validator: validate_ListTagsForVault_603546, base: "/",
    url: url_ListTagsForVault_603547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVaults_603560 = ref object of OpenApiRestCall_602466
proc url_ListVaults_603562(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVaults_603561(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation lists all vaults owned by the calling user's account. The list returned in the response is ASCII-sorted by vault name.</p> <p>By default, this operation returns up to 10 items. If there are more vaults to list, the response <code>marker</code> field contains the vault Amazon Resource Name (ARN) at which to continue the list with a new List Vaults request; otherwise, the <code>marker</code> field is <code>null</code>. To return a list of vaults that begins at a specific vault, set the <code>marker</code> request parameter to the vault ARN you obtained from a previous List Vaults request. You can also limit the number of vaults returned in the response by specifying the <code>limit</code> parameter in the request. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html">Retrieving Vault Metadata in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vaults-get.html">List Vaults </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603563 = path.getOrDefault("accountId")
  valid_603563 = validateParameter(valid_603563, JString, required = true,
                                 default = nil)
  if valid_603563 != nil:
    section.add "accountId", valid_603563
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : A string used for pagination. The marker specifies the vault ARN after which the listing of vaults should begin.
  ##   limit: JString
  ##        : The maximum number of vaults to be returned. The default limit is 10. The number of vaults returned might be fewer than the specified limit, but the number of returned vaults never exceeds the limit.
  section = newJObject()
  var valid_603564 = query.getOrDefault("marker")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "marker", valid_603564
  var valid_603565 = query.getOrDefault("limit")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "limit", valid_603565
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
  var valid_603566 = header.getOrDefault("X-Amz-Date")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Date", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Security-Token")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Security-Token", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Content-Sha256", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Algorithm")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Algorithm", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Signature")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Signature", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-SignedHeaders", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Credential")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Credential", valid_603572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603573: Call_ListVaults_603560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation lists all vaults owned by the calling user's account. The list returned in the response is ASCII-sorted by vault name.</p> <p>By default, this operation returns up to 10 items. If there are more vaults to list, the response <code>marker</code> field contains the vault Amazon Resource Name (ARN) at which to continue the list with a new List Vaults request; otherwise, the <code>marker</code> field is <code>null</code>. To return a list of vaults that begins at a specific vault, set the <code>marker</code> request parameter to the vault ARN you obtained from a previous List Vaults request. You can also limit the number of vaults returned in the response by specifying the <code>limit</code> parameter in the request. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html">Retrieving Vault Metadata in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vaults-get.html">List Vaults </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603573.validator(path, query, header, formData, body)
  let scheme = call_603573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603573.url(scheme.get, call_603573.host, call_603573.base,
                         call_603573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603573, url, valid)

proc call*(call_603574: Call_ListVaults_603560; accountId: string;
          marker: string = ""; limit: string = ""): Recallable =
  ## listVaults
  ## <p>This operation lists all vaults owned by the calling user's account. The list returned in the response is ASCII-sorted by vault name.</p> <p>By default, this operation returns up to 10 items. If there are more vaults to list, the response <code>marker</code> field contains the vault Amazon Resource Name (ARN) at which to continue the list with a new List Vaults request; otherwise, the <code>marker</code> field is <code>null</code>. To return a list of vaults that begins at a specific vault, set the <code>marker</code> request parameter to the vault ARN you obtained from a previous List Vaults request. You can also limit the number of vaults returned in the response by specifying the <code>limit</code> parameter in the request. </p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p>For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/retrieving-vault-info.html">Retrieving Vault Metadata in Amazon S3 Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vaults-get.html">List Vaults </a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID. This value must match the AWS account ID associated with the credentials used to sign the request. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon Glacier uses the AWS account ID associated with the credentials used to sign the request. If you specify your account ID, do not include any hyphens ('-') in the ID.
  ##   marker: string
  ##         : A string used for pagination. The marker specifies the vault ARN after which the listing of vaults should begin.
  ##   limit: string
  ##        : The maximum number of vaults to be returned. The default limit is 10. The number of vaults returned might be fewer than the specified limit, but the number of returned vaults never exceeds the limit.
  var path_603575 = newJObject()
  var query_603576 = newJObject()
  add(path_603575, "accountId", newJString(accountId))
  add(query_603576, "marker", newJString(marker))
  add(query_603576, "limit", newJString(limit))
  result = call_603574.call(path_603575, query_603576, nil, nil, nil)

var listVaults* = Call_ListVaults_603560(name: "listVaults",
                                      meth: HttpMethod.HttpGet,
                                      host: "glacier.amazonaws.com",
                                      route: "/{accountId}/vaults",
                                      validator: validate_ListVaults_603561,
                                      base: "/", url: url_ListVaults_603562,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromVault_603577 = ref object of OpenApiRestCall_602466
proc url_RemoveTagsFromVault_603579(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/tags#operation=remove")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_RemoveTagsFromVault_603578(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation removes one or more tags from the set of tags attached to a vault. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>. This operation is idempotent. The operation will be successful, even if there are no tags attached to the vault. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603580 = path.getOrDefault("accountId")
  valid_603580 = validateParameter(valid_603580, JString, required = true,
                                 default = nil)
  if valid_603580 != nil:
    section.add "accountId", valid_603580
  var valid_603581 = path.getOrDefault("vaultName")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = nil)
  if valid_603581 != nil:
    section.add "vaultName", valid_603581
  result.add "path", section
  ## parameters in `query` object:
  ##   operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `operation` field"
  var valid_603582 = query.getOrDefault("operation")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = newJString("remove"))
  if valid_603582 != nil:
    section.add "operation", valid_603582
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
  var valid_603585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Content-Sha256", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Algorithm")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Algorithm", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Signature")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Signature", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-SignedHeaders", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Credential")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Credential", valid_603589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603591: Call_RemoveTagsFromVault_603577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes one or more tags from the set of tags attached to a vault. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>. This operation is idempotent. The operation will be successful, even if there are no tags attached to the vault. 
  ## 
  let valid = call_603591.validator(path, query, header, formData, body)
  let scheme = call_603591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603591.url(scheme.get, call_603591.host, call_603591.base,
                         call_603591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603591, url, valid)

proc call*(call_603592: Call_RemoveTagsFromVault_603577; accountId: string;
          vaultName: string; body: JsonNode; operation: string = "remove"): Recallable =
  ## removeTagsFromVault
  ## This operation removes one or more tags from the set of tags attached to a vault. For more information about tags, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/tagging.html">Tagging Amazon S3 Glacier Resources</a>. This operation is idempotent. The operation will be successful, even if there are no tags attached to the vault. 
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID.
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   operation: string (required)
  ##   body: JObject (required)
  var path_603593 = newJObject()
  var query_603594 = newJObject()
  var body_603595 = newJObject()
  add(path_603593, "accountId", newJString(accountId))
  add(path_603593, "vaultName", newJString(vaultName))
  add(query_603594, "operation", newJString(operation))
  if body != nil:
    body_603595 = body
  result = call_603592.call(path_603593, query_603594, nil, nil, body_603595)

var removeTagsFromVault* = Call_RemoveTagsFromVault_603577(
    name: "removeTagsFromVault", meth: HttpMethod.HttpPost,
    host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/tags#operation=remove",
    validator: validate_RemoveTagsFromVault_603578, base: "/",
    url: url_RemoveTagsFromVault_603579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadArchive_603596 = ref object of OpenApiRestCall_602466
proc url_UploadArchive_603598(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "accountId" in path, "`accountId` is a required path parameter"
  assert "vaultName" in path, "`vaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "accountId"),
               (kind: ConstantSegment, value: "/vaults/"),
               (kind: VariableSegment, value: "vaultName"),
               (kind: ConstantSegment, value: "/archives")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UploadArchive_603597(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation adds an archive to a vault. This is a synchronous operation, and for a successful upload, your data is durably persisted. Amazon S3 Glacier returns the archive ID in the <code>x-amz-archive-id</code> header of the response. </p> <p>You must use the archive ID to access your data in Amazon S3 Glacier. After you upload an archive, you should save the archive ID returned so that you can retrieve or delete the archive later. Besides saving the archive ID, you can also index it and give it a friendly name to allow for better searching. You can also use the optional archive description field to specify how the archive is referred to in an external index of archives, such as you might create in Amazon DynamoDB. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see <a>InitiateJob</a>. </p> <p>You must provide a SHA256 tree hash of the data you are uploading. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>. </p> <p>You can optionally specify an archive description of up to 1,024 printable ASCII characters. You can get the archive description when you either retrieve the archive or get the vault inventory. For more information, see <a>InitiateJob</a>. Amazon Glacier does not interpret the description in any way. An archive description does not need to be unique. You cannot use the description to retrieve or sort the archive list. </p> <p>Archives are immutable. After you upload an archive, you cannot edit the archive or its description.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-an-archive.html">Uploading an Archive in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-post.html">Upload Archive</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   accountId: JString (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: JString (required)
  ##            : The name of the vault.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `accountId` field"
  var valid_603599 = path.getOrDefault("accountId")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = nil)
  if valid_603599 != nil:
    section.add "accountId", valid_603599
  var valid_603600 = path.getOrDefault("vaultName")
  valid_603600 = validateParameter(valid_603600, JString, required = true,
                                 default = nil)
  if valid_603600 != nil:
    section.add "vaultName", valid_603600
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
  ##   X-Amz-Credential: JString
  ##   x-amz-sha256-tree-hash: JString
  ##                         : The SHA256 tree hash of the data being uploaded.
  ##   x-amz-archive-description: JString
  ##                            : The optional description of the archive you are uploading.
  section = newJObject()
  var valid_603601 = header.getOrDefault("X-Amz-Date")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Date", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Security-Token")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Security-Token", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Content-Sha256", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Algorithm")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Algorithm", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Signature")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Signature", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-SignedHeaders", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Credential")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Credential", valid_603607
  var valid_603608 = header.getOrDefault("x-amz-sha256-tree-hash")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "x-amz-sha256-tree-hash", valid_603608
  var valid_603609 = header.getOrDefault("x-amz-archive-description")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "x-amz-archive-description", valid_603609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603611: Call_UploadArchive_603596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation adds an archive to a vault. This is a synchronous operation, and for a successful upload, your data is durably persisted. Amazon S3 Glacier returns the archive ID in the <code>x-amz-archive-id</code> header of the response. </p> <p>You must use the archive ID to access your data in Amazon S3 Glacier. After you upload an archive, you should save the archive ID returned so that you can retrieve or delete the archive later. Besides saving the archive ID, you can also index it and give it a friendly name to allow for better searching. You can also use the optional archive description field to specify how the archive is referred to in an external index of archives, such as you might create in Amazon DynamoDB. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see <a>InitiateJob</a>. </p> <p>You must provide a SHA256 tree hash of the data you are uploading. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>. </p> <p>You can optionally specify an archive description of up to 1,024 printable ASCII characters. You can get the archive description when you either retrieve the archive or get the vault inventory. For more information, see <a>InitiateJob</a>. Amazon Glacier does not interpret the description in any way. An archive description does not need to be unique. You cannot use the description to retrieve or sort the archive list. </p> <p>Archives are immutable. After you upload an archive, you cannot edit the archive or its description.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-an-archive.html">Uploading an Archive in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-post.html">Upload Archive</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ## 
  let valid = call_603611.validator(path, query, header, formData, body)
  let scheme = call_603611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603611.url(scheme.get, call_603611.host, call_603611.base,
                         call_603611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603611, url, valid)

proc call*(call_603612: Call_UploadArchive_603596; accountId: string;
          vaultName: string; body: JsonNode): Recallable =
  ## uploadArchive
  ## <p>This operation adds an archive to a vault. This is a synchronous operation, and for a successful upload, your data is durably persisted. Amazon S3 Glacier returns the archive ID in the <code>x-amz-archive-id</code> header of the response. </p> <p>You must use the archive ID to access your data in Amazon S3 Glacier. After you upload an archive, you should save the archive ID returned so that you can retrieve or delete the archive later. Besides saving the archive ID, you can also index it and give it a friendly name to allow for better searching. You can also use the optional archive description field to specify how the archive is referred to in an external index of archives, such as you might create in Amazon DynamoDB. You can also get the vault inventory to obtain a list of archive IDs in a vault. For more information, see <a>InitiateJob</a>. </p> <p>You must provide a SHA256 tree hash of the data you are uploading. For information about computing a SHA256 tree hash, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations.html">Computing Checksums</a>. </p> <p>You can optionally specify an archive description of up to 1,024 printable ASCII characters. You can get the archive description when you either retrieve the archive or get the vault inventory. For more information, see <a>InitiateJob</a>. Amazon Glacier does not interpret the description in any way. An archive description does not need to be unique. You cannot use the description to retrieve or sort the archive list. </p> <p>Archives are immutable. After you upload an archive, you cannot edit the archive or its description.</p> <p>An AWS account has full permission to perform all operations (actions). However, AWS Identity and Access Management (IAM) users don't have any permissions by default. You must grant them explicit permission to perform specific actions. For more information, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/using-iam-with-amazon-glacier.html">Access Control Using AWS Identity and Access Management (IAM)</a>.</p> <p> For conceptual information and underlying REST API, see <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-an-archive.html">Uploading an Archive in Amazon Glacier</a> and <a href="https://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-post.html">Upload Archive</a> in the <i>Amazon Glacier Developer Guide</i>. </p>
  ##   accountId: string (required)
  ##            : The <code>AccountId</code> value is the AWS account ID of the account that owns the vault. You can either specify an AWS account ID or optionally a single '<code>-</code>' (hyphen), in which case Amazon S3 Glacier uses the AWS account ID associated with the credentials used to sign the request. If you use an account ID, do not include any hyphens ('-') in the ID. 
  ##   vaultName: string (required)
  ##            : The name of the vault.
  ##   body: JObject (required)
  var path_603613 = newJObject()
  var body_603614 = newJObject()
  add(path_603613, "accountId", newJString(accountId))
  add(path_603613, "vaultName", newJString(vaultName))
  if body != nil:
    body_603614 = body
  result = call_603612.call(path_603613, nil, nil, nil, body_603614)

var uploadArchive* = Call_UploadArchive_603596(name: "uploadArchive",
    meth: HttpMethod.HttpPost, host: "glacier.amazonaws.com",
    route: "/{accountId}/vaults/{vaultName}/archives",
    validator: validate_UploadArchive_603597, base: "/", url: url_UploadArchive_603598,
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
