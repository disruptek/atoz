
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon WorkDocs
## version: 2016-05-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The WorkDocs API is designed for the following use cases:</p> <ul> <li> <p>File Migration: File migration applications are supported for users who want to migrate their files from an on-premises or off-premises file system or service. Users can insert files into a user directory structure, as well as allow for basic metadata changes, such as modifications to the permissions of files.</p> </li> <li> <p>Security: Support security applications are supported for users who have additional security needs, such as antivirus or data loss prevention. The API actions, along with AWS CloudTrail, allow these applications to detect when changes occur in Amazon WorkDocs. Then, the application can take the necessary actions and replace the target file. If the target file violates the policy, the application can also choose to email the user.</p> </li> <li> <p>eDiscovery/Analytics: General administrative applications are supported, such as eDiscovery and analytics. These applications can choose to mimic or record the actions in an Amazon WorkDocs site, along with AWS CloudTrail, to replicate data for eDiscovery, backup, or analytical applications.</p> </li> </ul> <p>All Amazon WorkDocs API actions are Amazon authenticated and certificate-signed. They not only require the use of the AWS SDK, but also allow for the exclusive use of IAM users and roles to help facilitate access, trust, and permission policies. By creating a role and allowing an IAM user to access the Amazon WorkDocs site, the IAM user gains full administrative visibility into the entire Amazon WorkDocs site (or as set in the IAM policy). This includes, but is not limited to, the ability to modify file permissions and upload any file to any user. This allows developers to perform the three use cases above, as well as give users the ability to grant access on a selective basis using the IAM model.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/workdocs/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "workdocs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "workdocs.ap-southeast-1.amazonaws.com",
                           "us-west-2": "workdocs.us-west-2.amazonaws.com",
                           "eu-west-2": "workdocs.eu-west-2.amazonaws.com", "ap-northeast-3": "workdocs.ap-northeast-3.amazonaws.com", "eu-central-1": "workdocs.eu-central-1.amazonaws.com",
                           "us-east-2": "workdocs.us-east-2.amazonaws.com",
                           "us-east-1": "workdocs.us-east-1.amazonaws.com", "cn-northwest-1": "workdocs.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "workdocs.ap-south-1.amazonaws.com",
                           "eu-north-1": "workdocs.eu-north-1.amazonaws.com", "ap-northeast-2": "workdocs.ap-northeast-2.amazonaws.com",
                           "us-west-1": "workdocs.us-west-1.amazonaws.com", "us-gov-east-1": "workdocs.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "workdocs.eu-west-3.amazonaws.com", "cn-north-1": "workdocs.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "workdocs.sa-east-1.amazonaws.com",
                           "eu-west-1": "workdocs.eu-west-1.amazonaws.com", "us-gov-west-1": "workdocs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "workdocs.ap-southeast-2.amazonaws.com", "ca-central-1": "workdocs.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "workdocs.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "workdocs.ap-southeast-1.amazonaws.com",
      "us-west-2": "workdocs.us-west-2.amazonaws.com",
      "eu-west-2": "workdocs.eu-west-2.amazonaws.com",
      "ap-northeast-3": "workdocs.ap-northeast-3.amazonaws.com",
      "eu-central-1": "workdocs.eu-central-1.amazonaws.com",
      "us-east-2": "workdocs.us-east-2.amazonaws.com",
      "us-east-1": "workdocs.us-east-1.amazonaws.com",
      "cn-northwest-1": "workdocs.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "workdocs.ap-south-1.amazonaws.com",
      "eu-north-1": "workdocs.eu-north-1.amazonaws.com",
      "ap-northeast-2": "workdocs.ap-northeast-2.amazonaws.com",
      "us-west-1": "workdocs.us-west-1.amazonaws.com",
      "us-gov-east-1": "workdocs.us-gov-east-1.amazonaws.com",
      "eu-west-3": "workdocs.eu-west-3.amazonaws.com",
      "cn-north-1": "workdocs.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "workdocs.sa-east-1.amazonaws.com",
      "eu-west-1": "workdocs.eu-west-1.amazonaws.com",
      "us-gov-west-1": "workdocs.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "workdocs.ap-southeast-2.amazonaws.com",
      "ca-central-1": "workdocs.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "workdocs"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetDocumentVersion_610996 = ref object of OpenApiRestCall_610658
proc url_GetDocumentVersion_610998(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  assert "VersionId" in path, "`VersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentVersion_610997(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves version metadata for the specified document.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
  ##            : The version ID of the document.
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `VersionId` field"
  var valid_611124 = path.getOrDefault("VersionId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "VersionId", valid_611124
  var valid_611125 = path.getOrDefault("DocumentId")
  valid_611125 = validateParameter(valid_611125, JString, required = true,
                                 default = nil)
  if valid_611125 != nil:
    section.add "DocumentId", valid_611125
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  section = newJObject()
  var valid_611126 = query.getOrDefault("includeCustomMetadata")
  valid_611126 = validateParameter(valid_611126, JBool, required = false, default = nil)
  if valid_611126 != nil:
    section.add "includeCustomMetadata", valid_611126
  var valid_611127 = query.getOrDefault("fields")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "fields", valid_611127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611128 = header.getOrDefault("X-Amz-Signature")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Signature", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Content-Sha256", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Date")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Date", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Credential")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Credential", valid_611131
  var valid_611132 = header.getOrDefault("Authentication")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "Authentication", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-Security-Token")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-Security-Token", valid_611133
  var valid_611134 = header.getOrDefault("X-Amz-Algorithm")
  valid_611134 = validateParameter(valid_611134, JString, required = false,
                                 default = nil)
  if valid_611134 != nil:
    section.add "X-Amz-Algorithm", valid_611134
  var valid_611135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611135 = validateParameter(valid_611135, JString, required = false,
                                 default = nil)
  if valid_611135 != nil:
    section.add "X-Amz-SignedHeaders", valid_611135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611158: Call_GetDocumentVersion_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_611158.validator(path, query, header, formData, body)
  let scheme = call_611158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611158.url(scheme.get, call_611158.host, call_611158.base,
                         call_611158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611158, url, valid)

proc call*(call_611229: Call_GetDocumentVersion_610996; VersionId: string;
          DocumentId: string; includeCustomMetadata: bool = false; fields: string = ""): Recallable =
  ## getDocumentVersion
  ## Retrieves version metadata for the specified document.
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to TRUE to include custom metadata in the response.
  ##   fields: string
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  var path_611230 = newJObject()
  var query_611232 = newJObject()
  add(path_611230, "VersionId", newJString(VersionId))
  add(path_611230, "DocumentId", newJString(DocumentId))
  add(query_611232, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(query_611232, "fields", newJString(fields))
  result = call_611229.call(path_611230, query_611232, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_610996(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_610997, base: "/",
    url: url_GetDocumentVersion_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_611287 = ref object of OpenApiRestCall_610658
proc url_UpdateDocumentVersion_611289(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  assert "VersionId" in path, "`VersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocumentVersion_611288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
  ##            : The version ID of the document.
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `VersionId` field"
  var valid_611290 = path.getOrDefault("VersionId")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "VersionId", valid_611290
  var valid_611291 = path.getOrDefault("DocumentId")
  valid_611291 = validateParameter(valid_611291, JString, required = true,
                                 default = nil)
  if valid_611291 != nil:
    section.add "DocumentId", valid_611291
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611292 = header.getOrDefault("X-Amz-Signature")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Signature", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Content-Sha256", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Date")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Date", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Credential")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Credential", valid_611295
  var valid_611296 = header.getOrDefault("Authentication")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "Authentication", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Security-Token")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Security-Token", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Algorithm")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Algorithm", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-SignedHeaders", valid_611299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611301: Call_UpdateDocumentVersion_611287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_611301.validator(path, query, header, formData, body)
  let scheme = call_611301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611301.url(scheme.get, call_611301.host, call_611301.base,
                         call_611301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611301, url, valid)

proc call*(call_611302: Call_UpdateDocumentVersion_611287; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_611303 = newJObject()
  var body_611304 = newJObject()
  add(path_611303, "VersionId", newJString(VersionId))
  add(path_611303, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_611304 = body
  result = call_611302.call(path_611303, nil, nil, nil, body_611304)

var updateDocumentVersion* = Call_UpdateDocumentVersion_611287(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_611288, base: "/",
    url: url_UpdateDocumentVersion_611289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_611271 = ref object of OpenApiRestCall_610658
proc url_AbortDocumentVersionUpload_611273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  assert "VersionId" in path, "`VersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AbortDocumentVersionUpload_611272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
  ##            : The ID of the version.
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `VersionId` field"
  var valid_611274 = path.getOrDefault("VersionId")
  valid_611274 = validateParameter(valid_611274, JString, required = true,
                                 default = nil)
  if valid_611274 != nil:
    section.add "VersionId", valid_611274
  var valid_611275 = path.getOrDefault("DocumentId")
  valid_611275 = validateParameter(valid_611275, JString, required = true,
                                 default = nil)
  if valid_611275 != nil:
    section.add "DocumentId", valid_611275
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611276 = header.getOrDefault("X-Amz-Signature")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Signature", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Content-Sha256", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Date")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Date", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Credential")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Credential", valid_611279
  var valid_611280 = header.getOrDefault("Authentication")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "Authentication", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Security-Token")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Security-Token", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-Algorithm")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Algorithm", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-SignedHeaders", valid_611283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611284: Call_AbortDocumentVersionUpload_611271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_611284.validator(path, query, header, formData, body)
  let scheme = call_611284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611284.url(scheme.get, call_611284.host, call_611284.base,
                         call_611284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611284, url, valid)

proc call*(call_611285: Call_AbortDocumentVersionUpload_611271; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_611286 = newJObject()
  add(path_611286, "VersionId", newJString(VersionId))
  add(path_611286, "DocumentId", newJString(DocumentId))
  result = call_611285.call(path_611286, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_611271(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_611272, base: "/",
    url: url_AbortDocumentVersionUpload_611273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_611305 = ref object of OpenApiRestCall_610658
proc url_ActivateUser_611307(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/activation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ActivateUser_611306(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_611308 = path.getOrDefault("UserId")
  valid_611308 = validateParameter(valid_611308, JString, required = true,
                                 default = nil)
  if valid_611308 != nil:
    section.add "UserId", valid_611308
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611309 = header.getOrDefault("X-Amz-Signature")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Signature", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Content-Sha256", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Date")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Date", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Credential")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Credential", valid_611312
  var valid_611313 = header.getOrDefault("Authentication")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "Authentication", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Security-Token")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Security-Token", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Algorithm")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Algorithm", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-SignedHeaders", valid_611316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611317: Call_ActivateUser_611305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_611317.validator(path, query, header, formData, body)
  let scheme = call_611317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611317.url(scheme.get, call_611317.host, call_611317.base,
                         call_611317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611317, url, valid)

proc call*(call_611318: Call_ActivateUser_611305; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_611319 = newJObject()
  add(path_611319, "UserId", newJString(UserId))
  result = call_611318.call(path_611319, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_611305(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_611306,
    base: "/", url: url_ActivateUser_611307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_611320 = ref object of OpenApiRestCall_610658
proc url_DeactivateUser_611322(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/activation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeactivateUser_611321(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_611323 = path.getOrDefault("UserId")
  valid_611323 = validateParameter(valid_611323, JString, required = true,
                                 default = nil)
  if valid_611323 != nil:
    section.add "UserId", valid_611323
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611324 = header.getOrDefault("X-Amz-Signature")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Signature", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Content-Sha256", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Date")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Date", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Credential")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Credential", valid_611327
  var valid_611328 = header.getOrDefault("Authentication")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "Authentication", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Security-Token")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Security-Token", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Algorithm")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Algorithm", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-SignedHeaders", valid_611331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611332: Call_DeactivateUser_611320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_611332.validator(path, query, header, formData, body)
  let scheme = call_611332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611332.url(scheme.get, call_611332.host, call_611332.base,
                         call_611332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611332, url, valid)

proc call*(call_611333: Call_DeactivateUser_611320; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_611334 = newJObject()
  add(path_611334, "UserId", newJString(UserId))
  result = call_611333.call(path_611334, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_611320(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_611321, base: "/", url: url_DeactivateUser_611322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_611354 = ref object of OpenApiRestCall_610658
proc url_AddResourcePermissions_611356(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddResourcePermissions_611355(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611357 = path.getOrDefault("ResourceId")
  valid_611357 = validateParameter(valid_611357, JString, required = true,
                                 default = nil)
  if valid_611357 != nil:
    section.add "ResourceId", valid_611357
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611358 = header.getOrDefault("X-Amz-Signature")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Signature", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Content-Sha256", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Date")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Date", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Credential")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Credential", valid_611361
  var valid_611362 = header.getOrDefault("Authentication")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "Authentication", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_AddResourcePermissions_611354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_AddResourcePermissions_611354; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_611369 = newJObject()
  var body_611370 = newJObject()
  add(path_611369, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_611370 = body
  result = call_611368.call(path_611369, nil, nil, nil, body_611370)

var addResourcePermissions* = Call_AddResourcePermissions_611354(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_611355, base: "/",
    url: url_AddResourcePermissions_611356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_611335 = ref object of OpenApiRestCall_610658
proc url_DescribeResourcePermissions_611337(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeResourcePermissions_611336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the permissions of a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611338 = path.getOrDefault("ResourceId")
  valid_611338 = validateParameter(valid_611338, JString, required = true,
                                 default = nil)
  if valid_611338 != nil:
    section.add "ResourceId", valid_611338
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  section = newJObject()
  var valid_611339 = query.getOrDefault("limit")
  valid_611339 = validateParameter(valid_611339, JInt, required = false, default = nil)
  if valid_611339 != nil:
    section.add "limit", valid_611339
  var valid_611340 = query.getOrDefault("principalId")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "principalId", valid_611340
  var valid_611341 = query.getOrDefault("marker")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "marker", valid_611341
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611342 = header.getOrDefault("X-Amz-Signature")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Signature", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Content-Sha256", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Date")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Date", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Credential")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Credential", valid_611345
  var valid_611346 = header.getOrDefault("Authentication")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "Authentication", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Security-Token")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Security-Token", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Algorithm")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Algorithm", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-SignedHeaders", valid_611349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611350: Call_DescribeResourcePermissions_611335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_611350.validator(path, query, header, formData, body)
  let scheme = call_611350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611350.url(scheme.get, call_611350.host, call_611350.base,
                         call_611350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611350, url, valid)

proc call*(call_611351: Call_DescribeResourcePermissions_611335;
          ResourceId: string; limit: int = 0; principalId: string = "";
          marker: string = ""): Recallable =
  ## describeResourcePermissions
  ## Describes the permissions of a specified resource.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   principalId: string
  ##              : The ID of the principal to filter permissions by.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  var path_611352 = newJObject()
  var query_611353 = newJObject()
  add(query_611353, "limit", newJInt(limit))
  add(path_611352, "ResourceId", newJString(ResourceId))
  add(query_611353, "principalId", newJString(principalId))
  add(query_611353, "marker", newJString(marker))
  result = call_611351.call(path_611352, query_611353, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_611335(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_611336, base: "/",
    url: url_DescribeResourcePermissions_611337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_611371 = ref object of OpenApiRestCall_610658
proc url_RemoveAllResourcePermissions_611373(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveAllResourcePermissions_611372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes all the permissions from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611374 = path.getOrDefault("ResourceId")
  valid_611374 = validateParameter(valid_611374, JString, required = true,
                                 default = nil)
  if valid_611374 != nil:
    section.add "ResourceId", valid_611374
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611375 = header.getOrDefault("X-Amz-Signature")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Signature", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Content-Sha256", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Date")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Date", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Credential")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Credential", valid_611378
  var valid_611379 = header.getOrDefault("Authentication")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "Authentication", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Security-Token")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Security-Token", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Algorithm")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Algorithm", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-SignedHeaders", valid_611382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611383: Call_RemoveAllResourcePermissions_611371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_611383.validator(path, query, header, formData, body)
  let scheme = call_611383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611383.url(scheme.get, call_611383.host, call_611383.base,
                         call_611383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611383, url, valid)

proc call*(call_611384: Call_RemoveAllResourcePermissions_611371;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_611385 = newJObject()
  add(path_611385, "ResourceId", newJString(ResourceId))
  result = call_611384.call(path_611385, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_611371(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_611372, base: "/",
    url: url_RemoveAllResourcePermissions_611373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_611386 = ref object of OpenApiRestCall_610658
proc url_CreateComment_611388(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  assert "VersionId" in path, "`VersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionId"),
               (kind: ConstantSegment, value: "/comment")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateComment_611387(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a new comment to the specified document version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
  ##            : The ID of the document version.
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `VersionId` field"
  var valid_611389 = path.getOrDefault("VersionId")
  valid_611389 = validateParameter(valid_611389, JString, required = true,
                                 default = nil)
  if valid_611389 != nil:
    section.add "VersionId", valid_611389
  var valid_611390 = path.getOrDefault("DocumentId")
  valid_611390 = validateParameter(valid_611390, JString, required = true,
                                 default = nil)
  if valid_611390 != nil:
    section.add "DocumentId", valid_611390
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611391 = header.getOrDefault("X-Amz-Signature")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Signature", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Content-Sha256", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Date")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Date", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Credential")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Credential", valid_611394
  var valid_611395 = header.getOrDefault("Authentication")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "Authentication", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Security-Token")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Security-Token", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Algorithm")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Algorithm", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-SignedHeaders", valid_611398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611400: Call_CreateComment_611386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_611400.validator(path, query, header, formData, body)
  let scheme = call_611400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611400.url(scheme.get, call_611400.host, call_611400.base,
                         call_611400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611400, url, valid)

proc call*(call_611401: Call_CreateComment_611386; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_611402 = newJObject()
  var body_611403 = newJObject()
  add(path_611402, "VersionId", newJString(VersionId))
  add(path_611402, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_611403 = body
  result = call_611401.call(path_611402, nil, nil, nil, body_611403)

var createComment* = Call_CreateComment_611386(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_611387, base: "/", url: url_CreateComment_611388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_611404 = ref object of OpenApiRestCall_610658
proc url_CreateCustomMetadata_611406(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/customMetadata")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCustomMetadata_611405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611407 = path.getOrDefault("ResourceId")
  valid_611407 = validateParameter(valid_611407, JString, required = true,
                                 default = nil)
  if valid_611407 != nil:
    section.add "ResourceId", valid_611407
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_611408 = query.getOrDefault("versionid")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "versionid", valid_611408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611409 = header.getOrDefault("X-Amz-Signature")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Signature", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Content-Sha256", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Date")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Date", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Credential")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Credential", valid_611412
  var valid_611413 = header.getOrDefault("Authentication")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "Authentication", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Security-Token")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Security-Token", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Algorithm")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Algorithm", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-SignedHeaders", valid_611416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611418: Call_CreateCustomMetadata_611404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_611418.validator(path, query, header, formData, body)
  let scheme = call_611418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611418.url(scheme.get, call_611418.host, call_611418.base,
                         call_611418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611418, url, valid)

proc call*(call_611419: Call_CreateCustomMetadata_611404; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_611420 = newJObject()
  var query_611421 = newJObject()
  var body_611422 = newJObject()
  add(query_611421, "versionid", newJString(versionid))
  add(path_611420, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_611422 = body
  result = call_611419.call(path_611420, query_611421, nil, nil, body_611422)

var createCustomMetadata* = Call_CreateCustomMetadata_611404(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_611405, base: "/",
    url: url_CreateCustomMetadata_611406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_611423 = ref object of OpenApiRestCall_610658
proc url_DeleteCustomMetadata_611425(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/customMetadata")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCustomMetadata_611424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes custom metadata from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource, either a document or folder.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611426 = path.getOrDefault("ResourceId")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = nil)
  if valid_611426 != nil:
    section.add "ResourceId", valid_611426
  result.add "path", section
  ## parameters in `query` object:
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  section = newJObject()
  var valid_611427 = query.getOrDefault("deleteAll")
  valid_611427 = validateParameter(valid_611427, JBool, required = false, default = nil)
  if valid_611427 != nil:
    section.add "deleteAll", valid_611427
  var valid_611428 = query.getOrDefault("keys")
  valid_611428 = validateParameter(valid_611428, JArray, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "keys", valid_611428
  var valid_611429 = query.getOrDefault("versionId")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "versionId", valid_611429
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611430 = header.getOrDefault("X-Amz-Signature")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Signature", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Content-Sha256", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Date")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Date", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Credential")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Credential", valid_611433
  var valid_611434 = header.getOrDefault("Authentication")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "Authentication", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Security-Token")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Security-Token", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Algorithm")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Algorithm", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-SignedHeaders", valid_611437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611438: Call_DeleteCustomMetadata_611423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_611438.validator(path, query, header, formData, body)
  let scheme = call_611438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611438.url(scheme.get, call_611438.host, call_611438.base,
                         call_611438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611438, url, valid)

proc call*(call_611439: Call_DeleteCustomMetadata_611423; ResourceId: string;
          deleteAll: bool = false; keys: JsonNode = nil; versionId: string = ""): Recallable =
  ## deleteCustomMetadata
  ## Deletes custom metadata from the specified resource.
  ##   deleteAll: bool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource, either a document or folder.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   versionId: string
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  var path_611440 = newJObject()
  var query_611441 = newJObject()
  add(query_611441, "deleteAll", newJBool(deleteAll))
  add(path_611440, "ResourceId", newJString(ResourceId))
  if keys != nil:
    query_611441.add "keys", keys
  add(query_611441, "versionId", newJString(versionId))
  result = call_611439.call(path_611440, query_611441, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_611423(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_611424, base: "/",
    url: url_DeleteCustomMetadata_611425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_611442 = ref object of OpenApiRestCall_610658
proc url_CreateFolder_611444(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFolder_611443(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a folder with the specified name and parent folder.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611445 = header.getOrDefault("X-Amz-Signature")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Signature", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Content-Sha256", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Date")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Date", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Credential")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Credential", valid_611448
  var valid_611449 = header.getOrDefault("Authentication")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "Authentication", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Security-Token")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Security-Token", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Algorithm")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Algorithm", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-SignedHeaders", valid_611452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611454: Call_CreateFolder_611442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_611454.validator(path, query, header, formData, body)
  let scheme = call_611454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611454.url(scheme.get, call_611454.host, call_611454.base,
                         call_611454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611454, url, valid)

proc call*(call_611455: Call_CreateFolder_611442; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_611456 = newJObject()
  if body != nil:
    body_611456 = body
  result = call_611455.call(nil, nil, nil, nil, body_611456)

var createFolder* = Call_CreateFolder_611442(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_611443, base: "/",
    url: url_CreateFolder_611444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_611457 = ref object of OpenApiRestCall_610658
proc url_CreateLabels_611459(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/labels")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateLabels_611458(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611460 = path.getOrDefault("ResourceId")
  valid_611460 = validateParameter(valid_611460, JString, required = true,
                                 default = nil)
  if valid_611460 != nil:
    section.add "ResourceId", valid_611460
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611461 = header.getOrDefault("X-Amz-Signature")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Signature", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Content-Sha256", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Date")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Date", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Credential")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Credential", valid_611464
  var valid_611465 = header.getOrDefault("Authentication")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "Authentication", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Security-Token")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Security-Token", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Algorithm")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Algorithm", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-SignedHeaders", valid_611468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611470: Call_CreateLabels_611457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_611470.validator(path, query, header, formData, body)
  let scheme = call_611470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611470.url(scheme.get, call_611470.host, call_611470.base,
                         call_611470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611470, url, valid)

proc call*(call_611471: Call_CreateLabels_611457; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_611472 = newJObject()
  var body_611473 = newJObject()
  add(path_611472, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_611473 = body
  result = call_611471.call(path_611472, nil, nil, nil, body_611473)

var createLabels* = Call_CreateLabels_611457(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_611458, base: "/", url: url_CreateLabels_611459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_611474 = ref object of OpenApiRestCall_610658
proc url_DeleteLabels_611476(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/labels")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLabels_611475(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified list of labels from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611477 = path.getOrDefault("ResourceId")
  valid_611477 = validateParameter(valid_611477, JString, required = true,
                                 default = nil)
  if valid_611477 != nil:
    section.add "ResourceId", valid_611477
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_611478 = query.getOrDefault("labels")
  valid_611478 = validateParameter(valid_611478, JArray, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "labels", valid_611478
  var valid_611479 = query.getOrDefault("deleteAll")
  valid_611479 = validateParameter(valid_611479, JBool, required = false, default = nil)
  if valid_611479 != nil:
    section.add "deleteAll", valid_611479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611480 = header.getOrDefault("X-Amz-Signature")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Signature", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Content-Sha256", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Date")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Date", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Credential")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Credential", valid_611483
  var valid_611484 = header.getOrDefault("Authentication")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "Authentication", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Security-Token")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Security-Token", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Algorithm")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Algorithm", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-SignedHeaders", valid_611487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611488: Call_DeleteLabels_611474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_611488.validator(path, query, header, formData, body)
  let scheme = call_611488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611488.url(scheme.get, call_611488.host, call_611488.base,
                         call_611488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611488, url, valid)

proc call*(call_611489: Call_DeleteLabels_611474; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_611490 = newJObject()
  var query_611491 = newJObject()
  if labels != nil:
    query_611491.add "labels", labels
  add(query_611491, "deleteAll", newJBool(deleteAll))
  add(path_611490, "ResourceId", newJString(ResourceId))
  result = call_611489.call(path_611490, query_611491, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_611474(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_611475, base: "/", url: url_DeleteLabels_611476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_611509 = ref object of OpenApiRestCall_610658
proc url_CreateNotificationSubscription_611511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path, "`OrganizationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/organizations/"),
               (kind: VariableSegment, value: "OrganizationId"),
               (kind: ConstantSegment, value: "/subscriptions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateNotificationSubscription_611510(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OrganizationId: JString (required)
  ##                 : The ID of the organization.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `OrganizationId` field"
  var valid_611512 = path.getOrDefault("OrganizationId")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "OrganizationId", valid_611512
  result.add "path", section
  section = newJObject()
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
  var valid_611513 = header.getOrDefault("X-Amz-Signature")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Signature", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Content-Sha256", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Date")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Date", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Credential")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Credential", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Security-Token")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Security-Token", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Algorithm")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Algorithm", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-SignedHeaders", valid_611519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611521: Call_CreateNotificationSubscription_611509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_611521.validator(path, query, header, formData, body)
  let scheme = call_611521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611521.url(scheme.get, call_611521.host, call_611521.base,
                         call_611521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611521, url, valid)

proc call*(call_611522: Call_CreateNotificationSubscription_611509;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_611523 = newJObject()
  var body_611524 = newJObject()
  add(path_611523, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_611524 = body
  result = call_611522.call(path_611523, nil, nil, nil, body_611524)

var createNotificationSubscription* = Call_CreateNotificationSubscription_611509(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_611510, base: "/",
    url: url_CreateNotificationSubscription_611511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_611492 = ref object of OpenApiRestCall_610658
proc url_DescribeNotificationSubscriptions_611494(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path, "`OrganizationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/organizations/"),
               (kind: VariableSegment, value: "OrganizationId"),
               (kind: ConstantSegment, value: "/subscriptions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeNotificationSubscriptions_611493(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the specified notification subscriptions.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OrganizationId: JString (required)
  ##                 : The ID of the organization.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `OrganizationId` field"
  var valid_611495 = path.getOrDefault("OrganizationId")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = nil)
  if valid_611495 != nil:
    section.add "OrganizationId", valid_611495
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_611496 = query.getOrDefault("limit")
  valid_611496 = validateParameter(valid_611496, JInt, required = false, default = nil)
  if valid_611496 != nil:
    section.add "limit", valid_611496
  var valid_611497 = query.getOrDefault("marker")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "marker", valid_611497
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
  var valid_611498 = header.getOrDefault("X-Amz-Signature")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Signature", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Content-Sha256", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Date")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Date", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Credential")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Credential", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Security-Token")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Security-Token", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Algorithm")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Algorithm", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-SignedHeaders", valid_611504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611505: Call_DescribeNotificationSubscriptions_611492;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_611505.validator(path, query, header, formData, body)
  let scheme = call_611505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611505.url(scheme.get, call_611505.host, call_611505.base,
                         call_611505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611505, url, valid)

proc call*(call_611506: Call_DescribeNotificationSubscriptions_611492;
          OrganizationId: string; limit: int = 0; marker: string = ""): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var path_611507 = newJObject()
  var query_611508 = newJObject()
  add(path_611507, "OrganizationId", newJString(OrganizationId))
  add(query_611508, "limit", newJInt(limit))
  add(query_611508, "marker", newJString(marker))
  result = call_611506.call(path_611507, query_611508, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_611492(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_611493, base: "/",
    url: url_DescribeNotificationSubscriptions_611494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_611563 = ref object of OpenApiRestCall_610658
proc url_CreateUser_611565(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_611564(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611566 = header.getOrDefault("X-Amz-Signature")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Signature", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Content-Sha256", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Date")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Date", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Credential")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Credential", valid_611569
  var valid_611570 = header.getOrDefault("Authentication")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "Authentication", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Security-Token")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Security-Token", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Algorithm")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Algorithm", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-SignedHeaders", valid_611573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611575: Call_CreateUser_611563; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_611575.validator(path, query, header, formData, body)
  let scheme = call_611575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611575.url(scheme.get, call_611575.host, call_611575.base,
                         call_611575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611575, url, valid)

proc call*(call_611576: Call_CreateUser_611563; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_611577 = newJObject()
  if body != nil:
    body_611577 = body
  result = call_611576.call(nil, nil, nil, nil, body_611577)

var createUser* = Call_CreateUser_611563(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_611564,
                                      base: "/", url: url_CreateUser_611565,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_611525 = ref object of OpenApiRestCall_610658
proc url_DescribeUsers_611527(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUsers_611526(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   sort: JString
  ##       : The sorting criteria.
  ##   Marker: JString
  ##         : Pagination token
  ##   order: JString
  ##        : The order for the results.
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   Limit: JString
  ##        : Pagination limit
  ##   userIds: JString
  ##          : The IDs of the users.
  ##   include: JString
  ##          : The state of the users. Specify "ALL" to include inactive users.
  ##   query: JString
  ##        : A query to filter users by user name.
  ##   organizationId: JString
  ##                 : The ID of the organization.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_611541 = query.getOrDefault("sort")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_611541 != nil:
    section.add "sort", valid_611541
  var valid_611542 = query.getOrDefault("Marker")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "Marker", valid_611542
  var valid_611543 = query.getOrDefault("order")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_611543 != nil:
    section.add "order", valid_611543
  var valid_611544 = query.getOrDefault("limit")
  valid_611544 = validateParameter(valid_611544, JInt, required = false, default = nil)
  if valid_611544 != nil:
    section.add "limit", valid_611544
  var valid_611545 = query.getOrDefault("Limit")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "Limit", valid_611545
  var valid_611546 = query.getOrDefault("userIds")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "userIds", valid_611546
  var valid_611547 = query.getOrDefault("include")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = newJString("ALL"))
  if valid_611547 != nil:
    section.add "include", valid_611547
  var valid_611548 = query.getOrDefault("query")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "query", valid_611548
  var valid_611549 = query.getOrDefault("organizationId")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "organizationId", valid_611549
  var valid_611550 = query.getOrDefault("fields")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "fields", valid_611550
  var valid_611551 = query.getOrDefault("marker")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "marker", valid_611551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611552 = header.getOrDefault("X-Amz-Signature")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Signature", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Content-Sha256", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Date")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Date", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Credential")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Credential", valid_611555
  var valid_611556 = header.getOrDefault("Authentication")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "Authentication", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Security-Token")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Security-Token", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Algorithm")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Algorithm", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-SignedHeaders", valid_611559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611560: Call_DescribeUsers_611525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_611560.validator(path, query, header, formData, body)
  let scheme = call_611560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611560.url(scheme.get, call_611560.host, call_611560.base,
                         call_611560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611560, url, valid)

proc call*(call_611561: Call_DescribeUsers_611525; sort: string = "USER_NAME";
          Marker: string = ""; order: string = "ASCENDING"; limit: int = 0;
          Limit: string = ""; userIds: string = ""; `include`: string = "ALL";
          query: string = ""; organizationId: string = ""; fields: string = "";
          marker: string = ""): Recallable =
  ## describeUsers
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ##   sort: string
  ##       : The sorting criteria.
  ##   Marker: string
  ##         : Pagination token
  ##   order: string
  ##        : The order for the results.
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   Limit: string
  ##        : Pagination limit
  ##   userIds: string
  ##          : The IDs of the users.
  ##   include: string
  ##          : The state of the users. Specify "ALL" to include inactive users.
  ##   query: string
  ##        : A query to filter users by user name.
  ##   organizationId: string
  ##                 : The ID of the organization.
  ##   fields: string
  ##         : A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var query_611562 = newJObject()
  add(query_611562, "sort", newJString(sort))
  add(query_611562, "Marker", newJString(Marker))
  add(query_611562, "order", newJString(order))
  add(query_611562, "limit", newJInt(limit))
  add(query_611562, "Limit", newJString(Limit))
  add(query_611562, "userIds", newJString(userIds))
  add(query_611562, "include", newJString(`include`))
  add(query_611562, "query", newJString(query))
  add(query_611562, "organizationId", newJString(organizationId))
  add(query_611562, "fields", newJString(fields))
  add(query_611562, "marker", newJString(marker))
  result = call_611561.call(nil, query_611562, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_611525(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_611526, base: "/",
    url: url_DescribeUsers_611527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_611578 = ref object of OpenApiRestCall_610658
proc url_DeleteComment_611580(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  assert "VersionId" in path, "`VersionId` is a required path parameter"
  assert "CommentId" in path, "`CommentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionId"),
               (kind: ConstantSegment, value: "/comment/"),
               (kind: VariableSegment, value: "CommentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteComment_611579(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified comment from the document version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
  ##            : The ID of the document version.
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  ##   CommentId: JString (required)
  ##            : The ID of the comment.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `VersionId` field"
  var valid_611581 = path.getOrDefault("VersionId")
  valid_611581 = validateParameter(valid_611581, JString, required = true,
                                 default = nil)
  if valid_611581 != nil:
    section.add "VersionId", valid_611581
  var valid_611582 = path.getOrDefault("DocumentId")
  valid_611582 = validateParameter(valid_611582, JString, required = true,
                                 default = nil)
  if valid_611582 != nil:
    section.add "DocumentId", valid_611582
  var valid_611583 = path.getOrDefault("CommentId")
  valid_611583 = validateParameter(valid_611583, JString, required = true,
                                 default = nil)
  if valid_611583 != nil:
    section.add "CommentId", valid_611583
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("Authentication")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "Authentication", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Security-Token")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Security-Token", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Algorithm")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Algorithm", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-SignedHeaders", valid_611591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611592: Call_DeleteComment_611578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_611592.validator(path, query, header, formData, body)
  let scheme = call_611592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611592.url(scheme.get, call_611592.host, call_611592.base,
                         call_611592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611592, url, valid)

proc call*(call_611593: Call_DeleteComment_611578; VersionId: string;
          DocumentId: string; CommentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  var path_611594 = newJObject()
  add(path_611594, "VersionId", newJString(VersionId))
  add(path_611594, "DocumentId", newJString(DocumentId))
  add(path_611594, "CommentId", newJString(CommentId))
  result = call_611593.call(path_611594, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_611578(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_611579, base: "/", url: url_DeleteComment_611580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_611595 = ref object of OpenApiRestCall_610658
proc url_GetDocument_611597(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocument_611596(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves details of a document.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DocumentId` field"
  var valid_611598 = path.getOrDefault("DocumentId")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = nil)
  if valid_611598 != nil:
    section.add "DocumentId", valid_611598
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_611599 = query.getOrDefault("includeCustomMetadata")
  valid_611599 = validateParameter(valid_611599, JBool, required = false, default = nil)
  if valid_611599 != nil:
    section.add "includeCustomMetadata", valid_611599
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611600 = header.getOrDefault("X-Amz-Signature")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Signature", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Content-Sha256", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Date")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Date", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Credential")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Credential", valid_611603
  var valid_611604 = header.getOrDefault("Authentication")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "Authentication", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Security-Token")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Security-Token", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Algorithm")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Algorithm", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-SignedHeaders", valid_611607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611608: Call_GetDocument_611595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_611608.validator(path, query, header, formData, body)
  let scheme = call_611608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611608.url(scheme.get, call_611608.host, call_611608.base,
                         call_611608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611608, url, valid)

proc call*(call_611609: Call_GetDocument_611595; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  var path_611610 = newJObject()
  var query_611611 = newJObject()
  add(path_611610, "DocumentId", newJString(DocumentId))
  add(query_611611, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_611609.call(path_611610, query_611611, nil, nil, nil)

var getDocument* = Call_GetDocument_611595(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_611596,
                                        base: "/", url: url_GetDocument_611597,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_611627 = ref object of OpenApiRestCall_610658
proc url_UpdateDocument_611629(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocument_611628(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DocumentId` field"
  var valid_611630 = path.getOrDefault("DocumentId")
  valid_611630 = validateParameter(valid_611630, JString, required = true,
                                 default = nil)
  if valid_611630 != nil:
    section.add "DocumentId", valid_611630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611631 = header.getOrDefault("X-Amz-Signature")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Signature", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Content-Sha256", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Date")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Date", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Credential")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Credential", valid_611634
  var valid_611635 = header.getOrDefault("Authentication")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "Authentication", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Security-Token")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Security-Token", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Algorithm")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Algorithm", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-SignedHeaders", valid_611638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611640: Call_UpdateDocument_611627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_611640.validator(path, query, header, formData, body)
  let scheme = call_611640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611640.url(scheme.get, call_611640.host, call_611640.base,
                         call_611640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611640, url, valid)

proc call*(call_611641: Call_UpdateDocument_611627; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_611642 = newJObject()
  var body_611643 = newJObject()
  add(path_611642, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_611643 = body
  result = call_611641.call(path_611642, nil, nil, nil, body_611643)

var updateDocument* = Call_UpdateDocument_611627(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_611628,
    base: "/", url: url_UpdateDocument_611629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_611612 = ref object of OpenApiRestCall_610658
proc url_DeleteDocument_611614(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDocument_611613(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DocumentId` field"
  var valid_611615 = path.getOrDefault("DocumentId")
  valid_611615 = validateParameter(valid_611615, JString, required = true,
                                 default = nil)
  if valid_611615 != nil:
    section.add "DocumentId", valid_611615
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611616 = header.getOrDefault("X-Amz-Signature")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Signature", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Content-Sha256", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Date")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Date", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Credential")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Credential", valid_611619
  var valid_611620 = header.getOrDefault("Authentication")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "Authentication", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Security-Token")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Security-Token", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Algorithm")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Algorithm", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-SignedHeaders", valid_611623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611624: Call_DeleteDocument_611612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_611624.validator(path, query, header, formData, body)
  let scheme = call_611624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611624.url(scheme.get, call_611624.host, call_611624.base,
                         call_611624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611624, url, valid)

proc call*(call_611625: Call_DeleteDocument_611612; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_611626 = newJObject()
  add(path_611626, "DocumentId", newJString(DocumentId))
  result = call_611625.call(path_611626, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_611612(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_611613,
    base: "/", url: url_DeleteDocument_611614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_611644 = ref object of OpenApiRestCall_610658
proc url_GetFolder_611646(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFolder_611645(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the metadata of the specified folder.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_611647 = path.getOrDefault("FolderId")
  valid_611647 = validateParameter(valid_611647, JString, required = true,
                                 default = nil)
  if valid_611647 != nil:
    section.add "FolderId", valid_611647
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_611648 = query.getOrDefault("includeCustomMetadata")
  valid_611648 = validateParameter(valid_611648, JBool, required = false, default = nil)
  if valid_611648 != nil:
    section.add "includeCustomMetadata", valid_611648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611649 = header.getOrDefault("X-Amz-Signature")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Signature", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Content-Sha256", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Date")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Date", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Credential")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Credential", valid_611652
  var valid_611653 = header.getOrDefault("Authentication")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "Authentication", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Security-Token")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Security-Token", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Algorithm")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Algorithm", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-SignedHeaders", valid_611656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611657: Call_GetFolder_611644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_611657.validator(path, query, header, formData, body)
  let scheme = call_611657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611657.url(scheme.get, call_611657.host, call_611657.base,
                         call_611657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611657, url, valid)

proc call*(call_611658: Call_GetFolder_611644; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_611659 = newJObject()
  var query_611660 = newJObject()
  add(query_611660, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_611659, "FolderId", newJString(FolderId))
  result = call_611658.call(path_611659, query_611660, nil, nil, nil)

var getFolder* = Call_GetFolder_611644(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_611645,
                                    base: "/", url: url_GetFolder_611646,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_611676 = ref object of OpenApiRestCall_610658
proc url_UpdateFolder_611678(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFolder_611677(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_611679 = path.getOrDefault("FolderId")
  valid_611679 = validateParameter(valid_611679, JString, required = true,
                                 default = nil)
  if valid_611679 != nil:
    section.add "FolderId", valid_611679
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611680 = header.getOrDefault("X-Amz-Signature")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Signature", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Content-Sha256", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Date")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Date", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Credential")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Credential", valid_611683
  var valid_611684 = header.getOrDefault("Authentication")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "Authentication", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Security-Token")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Security-Token", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Algorithm")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Algorithm", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-SignedHeaders", valid_611687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611689: Call_UpdateFolder_611676; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_611689.validator(path, query, header, formData, body)
  let scheme = call_611689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611689.url(scheme.get, call_611689.host, call_611689.base,
                         call_611689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611689, url, valid)

proc call*(call_611690: Call_UpdateFolder_611676; body: JsonNode; FolderId: string): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   body: JObject (required)
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_611691 = newJObject()
  var body_611692 = newJObject()
  if body != nil:
    body_611692 = body
  add(path_611691, "FolderId", newJString(FolderId))
  result = call_611690.call(path_611691, nil, nil, nil, body_611692)

var updateFolder* = Call_UpdateFolder_611676(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_611677,
    base: "/", url: url_UpdateFolder_611678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_611661 = ref object of OpenApiRestCall_610658
proc url_DeleteFolder_611663(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFolder_611662(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently deletes the specified folder and its contents.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_611664 = path.getOrDefault("FolderId")
  valid_611664 = validateParameter(valid_611664, JString, required = true,
                                 default = nil)
  if valid_611664 != nil:
    section.add "FolderId", valid_611664
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611665 = header.getOrDefault("X-Amz-Signature")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Signature", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Content-Sha256", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Date")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Date", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Credential")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Credential", valid_611668
  var valid_611669 = header.getOrDefault("Authentication")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "Authentication", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Security-Token")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Security-Token", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Algorithm")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Algorithm", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-SignedHeaders", valid_611672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611673: Call_DeleteFolder_611661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_611673.validator(path, query, header, formData, body)
  let scheme = call_611673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611673.url(scheme.get, call_611673.host, call_611673.base,
                         call_611673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611673, url, valid)

proc call*(call_611674: Call_DeleteFolder_611661; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_611675 = newJObject()
  add(path_611675, "FolderId", newJString(FolderId))
  result = call_611674.call(path_611675, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_611661(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_611662,
    base: "/", url: url_DeleteFolder_611663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_611693 = ref object of OpenApiRestCall_610658
proc url_DescribeFolderContents_611695(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId"),
               (kind: ConstantSegment, value: "/contents")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFolderContents_611694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_611696 = path.getOrDefault("FolderId")
  valid_611696 = validateParameter(valid_611696, JString, required = true,
                                 default = nil)
  if valid_611696 != nil:
    section.add "FolderId", valid_611696
  result.add "path", section
  ## parameters in `query` object:
  ##   sort: JString
  ##       : The sorting criteria.
  ##   Marker: JString
  ##         : Pagination token
  ##   order: JString
  ##        : The order for the contents of the folder.
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   Limit: JString
  ##        : Pagination limit
  ##   type: JString
  ##       : The type of items.
  ##   include: JString
  ##          : The contents to include. Specify "INITIALIZED" to include initialized documents.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  section = newJObject()
  var valid_611697 = query.getOrDefault("sort")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = newJString("DATE"))
  if valid_611697 != nil:
    section.add "sort", valid_611697
  var valid_611698 = query.getOrDefault("Marker")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "Marker", valid_611698
  var valid_611699 = query.getOrDefault("order")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_611699 != nil:
    section.add "order", valid_611699
  var valid_611700 = query.getOrDefault("limit")
  valid_611700 = validateParameter(valid_611700, JInt, required = false, default = nil)
  if valid_611700 != nil:
    section.add "limit", valid_611700
  var valid_611701 = query.getOrDefault("Limit")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "Limit", valid_611701
  var valid_611702 = query.getOrDefault("type")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = newJString("ALL"))
  if valid_611702 != nil:
    section.add "type", valid_611702
  var valid_611703 = query.getOrDefault("include")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "include", valid_611703
  var valid_611704 = query.getOrDefault("marker")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "marker", valid_611704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611705 = header.getOrDefault("X-Amz-Signature")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Signature", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Content-Sha256", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Date")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Date", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Credential")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Credential", valid_611708
  var valid_611709 = header.getOrDefault("Authentication")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "Authentication", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Security-Token")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Security-Token", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Algorithm")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Algorithm", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-SignedHeaders", valid_611712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611713: Call_DescribeFolderContents_611693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_611713.validator(path, query, header, formData, body)
  let scheme = call_611713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611713.url(scheme.get, call_611713.host, call_611713.base,
                         call_611713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611713, url, valid)

proc call*(call_611714: Call_DescribeFolderContents_611693; FolderId: string;
          sort: string = "DATE"; Marker: string = ""; order: string = "ASCENDING";
          limit: int = 0; Limit: string = ""; `type`: string = "ALL";
          `include`: string = ""; marker: string = ""): Recallable =
  ## describeFolderContents
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ##   sort: string
  ##       : The sorting criteria.
  ##   Marker: string
  ##         : Pagination token
  ##   order: string
  ##        : The order for the contents of the folder.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   Limit: string
  ##        : Pagination limit
  ##   type: string
  ##       : The type of items.
  ##   include: string
  ##          : The contents to include. Specify "INITIALIZED" to include initialized documents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   marker: string
  ##         : The marker for the next set of results. This marker was received from a previous call.
  var path_611715 = newJObject()
  var query_611716 = newJObject()
  add(query_611716, "sort", newJString(sort))
  add(query_611716, "Marker", newJString(Marker))
  add(query_611716, "order", newJString(order))
  add(query_611716, "limit", newJInt(limit))
  add(query_611716, "Limit", newJString(Limit))
  add(query_611716, "type", newJString(`type`))
  add(query_611716, "include", newJString(`include`))
  add(path_611715, "FolderId", newJString(FolderId))
  add(query_611716, "marker", newJString(marker))
  result = call_611714.call(path_611715, query_611716, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_611693(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_611694, base: "/",
    url: url_DescribeFolderContents_611695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_611717 = ref object of OpenApiRestCall_610658
proc url_DeleteFolderContents_611719(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId"),
               (kind: ConstantSegment, value: "/contents")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFolderContents_611718(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the contents of the specified folder.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_611720 = path.getOrDefault("FolderId")
  valid_611720 = validateParameter(valid_611720, JString, required = true,
                                 default = nil)
  if valid_611720 != nil:
    section.add "FolderId", valid_611720
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611721 = header.getOrDefault("X-Amz-Signature")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Signature", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Content-Sha256", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Date")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Date", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Credential")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Credential", valid_611724
  var valid_611725 = header.getOrDefault("Authentication")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "Authentication", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Security-Token")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Security-Token", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Algorithm")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Algorithm", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-SignedHeaders", valid_611728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611729: Call_DeleteFolderContents_611717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_611729.validator(path, query, header, formData, body)
  let scheme = call_611729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611729.url(scheme.get, call_611729.host, call_611729.base,
                         call_611729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611729, url, valid)

proc call*(call_611730: Call_DeleteFolderContents_611717; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_611731 = newJObject()
  add(path_611731, "FolderId", newJString(FolderId))
  result = call_611730.call(path_611731, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_611717(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_611718, base: "/",
    url: url_DeleteFolderContents_611719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_611732 = ref object of OpenApiRestCall_610658
proc url_DeleteNotificationSubscription_611734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path, "`OrganizationId` is a required path parameter"
  assert "SubscriptionId" in path, "`SubscriptionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/organizations/"),
               (kind: VariableSegment, value: "OrganizationId"),
               (kind: ConstantSegment, value: "/subscriptions/"),
               (kind: VariableSegment, value: "SubscriptionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteNotificationSubscription_611733(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified subscription from the specified organization.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscriptionId: JString (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: JString (required)
  ##                 : The ID of the organization.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `SubscriptionId` field"
  var valid_611735 = path.getOrDefault("SubscriptionId")
  valid_611735 = validateParameter(valid_611735, JString, required = true,
                                 default = nil)
  if valid_611735 != nil:
    section.add "SubscriptionId", valid_611735
  var valid_611736 = path.getOrDefault("OrganizationId")
  valid_611736 = validateParameter(valid_611736, JString, required = true,
                                 default = nil)
  if valid_611736 != nil:
    section.add "OrganizationId", valid_611736
  result.add "path", section
  section = newJObject()
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
  var valid_611737 = header.getOrDefault("X-Amz-Signature")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Signature", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Content-Sha256", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Date")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Date", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Credential")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Credential", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Security-Token")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Security-Token", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Algorithm")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Algorithm", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-SignedHeaders", valid_611743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611744: Call_DeleteNotificationSubscription_611732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_611744.validator(path, query, header, formData, body)
  let scheme = call_611744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611744.url(scheme.get, call_611744.host, call_611744.base,
                         call_611744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611744, url, valid)

proc call*(call_611745: Call_DeleteNotificationSubscription_611732;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_611746 = newJObject()
  add(path_611746, "SubscriptionId", newJString(SubscriptionId))
  add(path_611746, "OrganizationId", newJString(OrganizationId))
  result = call_611745.call(path_611746, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_611732(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_611733, base: "/",
    url: url_DeleteNotificationSubscription_611734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_611762 = ref object of OpenApiRestCall_610658
proc url_UpdateUser_611764(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_611763(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_611765 = path.getOrDefault("UserId")
  valid_611765 = validateParameter(valid_611765, JString, required = true,
                                 default = nil)
  if valid_611765 != nil:
    section.add "UserId", valid_611765
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611766 = header.getOrDefault("X-Amz-Signature")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Signature", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Content-Sha256", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Date")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Date", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Credential")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Credential", valid_611769
  var valid_611770 = header.getOrDefault("Authentication")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "Authentication", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Security-Token")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Security-Token", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Algorithm")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Algorithm", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-SignedHeaders", valid_611773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611775: Call_UpdateUser_611762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_611775.validator(path, query, header, formData, body)
  let scheme = call_611775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611775.url(scheme.get, call_611775.host, call_611775.base,
                         call_611775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611775, url, valid)

proc call*(call_611776: Call_UpdateUser_611762; UserId: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   UserId: string (required)
  ##         : The ID of the user.
  ##   body: JObject (required)
  var path_611777 = newJObject()
  var body_611778 = newJObject()
  add(path_611777, "UserId", newJString(UserId))
  if body != nil:
    body_611778 = body
  result = call_611776.call(path_611777, nil, nil, nil, body_611778)

var updateUser* = Call_UpdateUser_611762(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_611763,
                                      base: "/", url: url_UpdateUser_611764,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_611747 = ref object of OpenApiRestCall_610658
proc url_DeleteUser_611749(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_611748(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_611750 = path.getOrDefault("UserId")
  valid_611750 = validateParameter(valid_611750, JString, required = true,
                                 default = nil)
  if valid_611750 != nil:
    section.add "UserId", valid_611750
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611751 = header.getOrDefault("X-Amz-Signature")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Signature", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Content-Sha256", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Date")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Date", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Credential")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Credential", valid_611754
  var valid_611755 = header.getOrDefault("Authentication")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "Authentication", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Security-Token")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Security-Token", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Algorithm")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Algorithm", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-SignedHeaders", valid_611758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611759: Call_DeleteUser_611747; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_611759.validator(path, query, header, formData, body)
  let scheme = call_611759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611759.url(scheme.get, call_611759.host, call_611759.base,
                         call_611759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611759, url, valid)

proc call*(call_611760: Call_DeleteUser_611747; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_611761 = newJObject()
  add(path_611761, "UserId", newJString(UserId))
  result = call_611760.call(path_611761, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_611747(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_611748,
                                      base: "/", url: url_DeleteUser_611749,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_611779 = ref object of OpenApiRestCall_610658
proc url_DescribeActivities_611781(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivities_611780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes the user activities in a specified time period.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   endTime: JString
  ##          : The timestamp that determines the end time of the activities. The response includes the activities performed before the specified timestamp.
  ##   userId: JString
  ##         : The ID of the user who performed the action. The response includes activities pertaining to this user. This is an optional parameter and is only applicable for administrative API (SigV4) requests.
  ##   resourceId: JString
  ##             : The document or folder ID for which to describe activity types.
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   startTime: JString
  ##            : The timestamp that determines the starting time of the activities. The response includes the activities performed after the specified timestamp.
  ##   activityTypes: JString
  ##                : Specifies which activity types to include in the response. If this field is left empty, all activity types are returned.
  ##   organizationId: JString
  ##                 : The ID of the organization. This is a mandatory parameter when using administrative API (SigV4) requests.
  ##   includeIndirectActivities: JBool
  ##                            : Includes indirect activities. An indirect activity results from a direct activity performed on a parent resource. For example, sharing a parent folder (the direct activity) shares all of the subfolders and documents within the parent folder (the indirect activity).
  ##   marker: JString
  ##         : The marker for the next set of results.
  section = newJObject()
  var valid_611782 = query.getOrDefault("endTime")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "endTime", valid_611782
  var valid_611783 = query.getOrDefault("userId")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "userId", valid_611783
  var valid_611784 = query.getOrDefault("resourceId")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "resourceId", valid_611784
  var valid_611785 = query.getOrDefault("limit")
  valid_611785 = validateParameter(valid_611785, JInt, required = false, default = nil)
  if valid_611785 != nil:
    section.add "limit", valid_611785
  var valid_611786 = query.getOrDefault("startTime")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "startTime", valid_611786
  var valid_611787 = query.getOrDefault("activityTypes")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "activityTypes", valid_611787
  var valid_611788 = query.getOrDefault("organizationId")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "organizationId", valid_611788
  var valid_611789 = query.getOrDefault("includeIndirectActivities")
  valid_611789 = validateParameter(valid_611789, JBool, required = false, default = nil)
  if valid_611789 != nil:
    section.add "includeIndirectActivities", valid_611789
  var valid_611790 = query.getOrDefault("marker")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "marker", valid_611790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611791 = header.getOrDefault("X-Amz-Signature")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Signature", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Content-Sha256", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Date")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Date", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Credential")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Credential", valid_611794
  var valid_611795 = header.getOrDefault("Authentication")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "Authentication", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Security-Token")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Security-Token", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Algorithm")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Algorithm", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-SignedHeaders", valid_611798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611799: Call_DescribeActivities_611779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_611799.validator(path, query, header, formData, body)
  let scheme = call_611799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611799.url(scheme.get, call_611799.host, call_611799.base,
                         call_611799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611799, url, valid)

proc call*(call_611800: Call_DescribeActivities_611779; endTime: string = "";
          userId: string = ""; resourceId: string = ""; limit: int = 0;
          startTime: string = ""; activityTypes: string = "";
          organizationId: string = ""; includeIndirectActivities: bool = false;
          marker: string = ""): Recallable =
  ## describeActivities
  ## Describes the user activities in a specified time period.
  ##   endTime: string
  ##          : The timestamp that determines the end time of the activities. The response includes the activities performed before the specified timestamp.
  ##   userId: string
  ##         : The ID of the user who performed the action. The response includes activities pertaining to this user. This is an optional parameter and is only applicable for administrative API (SigV4) requests.
  ##   resourceId: string
  ##             : The document or folder ID for which to describe activity types.
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   startTime: string
  ##            : The timestamp that determines the starting time of the activities. The response includes the activities performed after the specified timestamp.
  ##   activityTypes: string
  ##                : Specifies which activity types to include in the response. If this field is left empty, all activity types are returned.
  ##   organizationId: string
  ##                 : The ID of the organization. This is a mandatory parameter when using administrative API (SigV4) requests.
  ##   includeIndirectActivities: bool
  ##                            : Includes indirect activities. An indirect activity results from a direct activity performed on a parent resource. For example, sharing a parent folder (the direct activity) shares all of the subfolders and documents within the parent folder (the indirect activity).
  ##   marker: string
  ##         : The marker for the next set of results.
  var query_611801 = newJObject()
  add(query_611801, "endTime", newJString(endTime))
  add(query_611801, "userId", newJString(userId))
  add(query_611801, "resourceId", newJString(resourceId))
  add(query_611801, "limit", newJInt(limit))
  add(query_611801, "startTime", newJString(startTime))
  add(query_611801, "activityTypes", newJString(activityTypes))
  add(query_611801, "organizationId", newJString(organizationId))
  add(query_611801, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_611801, "marker", newJString(marker))
  result = call_611800.call(nil, query_611801, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_611779(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_611780, base: "/",
    url: url_DescribeActivities_611781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_611802 = ref object of OpenApiRestCall_610658
proc url_DescribeComments_611804(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  assert "VersionId" in path, "`VersionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionId"),
               (kind: ConstantSegment, value: "/comments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeComments_611803(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## List all the comments for the specified document version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
  ##            : The ID of the document version.
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `VersionId` field"
  var valid_611805 = path.getOrDefault("VersionId")
  valid_611805 = validateParameter(valid_611805, JString, required = true,
                                 default = nil)
  if valid_611805 != nil:
    section.add "VersionId", valid_611805
  var valid_611806 = path.getOrDefault("DocumentId")
  valid_611806 = validateParameter(valid_611806, JString, required = true,
                                 default = nil)
  if valid_611806 != nil:
    section.add "DocumentId", valid_611806
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  section = newJObject()
  var valid_611807 = query.getOrDefault("limit")
  valid_611807 = validateParameter(valid_611807, JInt, required = false, default = nil)
  if valid_611807 != nil:
    section.add "limit", valid_611807
  var valid_611808 = query.getOrDefault("marker")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "marker", valid_611808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611809 = header.getOrDefault("X-Amz-Signature")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Signature", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Content-Sha256", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Date")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Date", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Credential")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Credential", valid_611812
  var valid_611813 = header.getOrDefault("Authentication")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "Authentication", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Security-Token")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Security-Token", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Algorithm")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Algorithm", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-SignedHeaders", valid_611816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_DescribeComments_611802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_DescribeComments_611802; VersionId: string;
          DocumentId: string; limit: int = 0; marker: string = ""): Recallable =
  ## describeComments
  ## List all the comments for the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   marker: string
  ##         : The marker for the next set of results. This marker was received from a previous call.
  var path_611819 = newJObject()
  var query_611820 = newJObject()
  add(path_611819, "VersionId", newJString(VersionId))
  add(path_611819, "DocumentId", newJString(DocumentId))
  add(query_611820, "limit", newJInt(limit))
  add(query_611820, "marker", newJString(marker))
  result = call_611818.call(path_611819, query_611820, nil, nil, nil)

var describeComments* = Call_DescribeComments_611802(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_611803, base: "/",
    url: url_DescribeComments_611804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_611821 = ref object of OpenApiRestCall_610658
proc url_DescribeDocumentVersions_611823(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDocumentVersions_611822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DocumentId` field"
  var valid_611824 = path.getOrDefault("DocumentId")
  valid_611824 = validateParameter(valid_611824, JString, required = true,
                                 default = nil)
  if valid_611824 != nil:
    section.add "DocumentId", valid_611824
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   limit: JInt
  ##        : The maximum number of versions to return with this call.
  ##   Limit: JString
  ##        : Pagination limit
  ##   include: JString
  ##          : A comma-separated list of values. Specify "INITIALIZED" to include incomplete versions.
  ##   fields: JString
  ##         : Specify "SOURCE" to include initialized versions and a URL for the source document.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_611825 = query.getOrDefault("Marker")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "Marker", valid_611825
  var valid_611826 = query.getOrDefault("limit")
  valid_611826 = validateParameter(valid_611826, JInt, required = false, default = nil)
  if valid_611826 != nil:
    section.add "limit", valid_611826
  var valid_611827 = query.getOrDefault("Limit")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "Limit", valid_611827
  var valid_611828 = query.getOrDefault("include")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "include", valid_611828
  var valid_611829 = query.getOrDefault("fields")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "fields", valid_611829
  var valid_611830 = query.getOrDefault("marker")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "marker", valid_611830
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611831 = header.getOrDefault("X-Amz-Signature")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Signature", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Content-Sha256", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Date")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Date", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Credential")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Credential", valid_611834
  var valid_611835 = header.getOrDefault("Authentication")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "Authentication", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Security-Token")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Security-Token", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-Algorithm")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Algorithm", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-SignedHeaders", valid_611838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611839: Call_DescribeDocumentVersions_611821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_611839.validator(path, query, header, formData, body)
  let scheme = call_611839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611839.url(scheme.get, call_611839.host, call_611839.base,
                         call_611839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611839, url, valid)

proc call*(call_611840: Call_DescribeDocumentVersions_611821; DocumentId: string;
          Marker: string = ""; limit: int = 0; Limit: string = ""; `include`: string = "";
          fields: string = ""; marker: string = ""): Recallable =
  ## describeDocumentVersions
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   limit: int
  ##        : The maximum number of versions to return with this call.
  ##   Limit: string
  ##        : Pagination limit
  ##   include: string
  ##          : A comma-separated list of values. Specify "INITIALIZED" to include incomplete versions.
  ##   fields: string
  ##         : Specify "SOURCE" to include initialized versions and a URL for the source document.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var path_611841 = newJObject()
  var query_611842 = newJObject()
  add(query_611842, "Marker", newJString(Marker))
  add(path_611841, "DocumentId", newJString(DocumentId))
  add(query_611842, "limit", newJInt(limit))
  add(query_611842, "Limit", newJString(Limit))
  add(query_611842, "include", newJString(`include`))
  add(query_611842, "fields", newJString(fields))
  add(query_611842, "marker", newJString(marker))
  result = call_611840.call(path_611841, query_611842, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_611821(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_611822, base: "/",
    url: url_DescribeDocumentVersions_611823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_611843 = ref object of OpenApiRestCall_610658
proc url_DescribeGroups_611845(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGroups_611844(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   searchQuery: JString (required)
  ##              : A query to describe groups by group name.
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   organizationId: JString
  ##                 : The ID of the organization.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `searchQuery` field"
  var valid_611846 = query.getOrDefault("searchQuery")
  valid_611846 = validateParameter(valid_611846, JString, required = true,
                                 default = nil)
  if valid_611846 != nil:
    section.add "searchQuery", valid_611846
  var valid_611847 = query.getOrDefault("limit")
  valid_611847 = validateParameter(valid_611847, JInt, required = false, default = nil)
  if valid_611847 != nil:
    section.add "limit", valid_611847
  var valid_611848 = query.getOrDefault("organizationId")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "organizationId", valid_611848
  var valid_611849 = query.getOrDefault("marker")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "marker", valid_611849
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611850 = header.getOrDefault("X-Amz-Signature")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Signature", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Content-Sha256", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Date")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Date", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-Credential")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Credential", valid_611853
  var valid_611854 = header.getOrDefault("Authentication")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "Authentication", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Security-Token")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Security-Token", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Algorithm")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Algorithm", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-SignedHeaders", valid_611857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611858: Call_DescribeGroups_611843; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_611858.validator(path, query, header, formData, body)
  let scheme = call_611858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611858.url(scheme.get, call_611858.host, call_611858.base,
                         call_611858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611858, url, valid)

proc call*(call_611859: Call_DescribeGroups_611843; searchQuery: string;
          limit: int = 0; organizationId: string = ""; marker: string = ""): Recallable =
  ## describeGroups
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ##   searchQuery: string (required)
  ##              : A query to describe groups by group name.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   organizationId: string
  ##                 : The ID of the organization.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var query_611860 = newJObject()
  add(query_611860, "searchQuery", newJString(searchQuery))
  add(query_611860, "limit", newJInt(limit))
  add(query_611860, "organizationId", newJString(organizationId))
  add(query_611860, "marker", newJString(marker))
  result = call_611859.call(nil, query_611860, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_611843(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_611844,
    base: "/", url: url_DescribeGroups_611845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_611861 = ref object of OpenApiRestCall_610658
proc url_DescribeRootFolders_611863(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRootFolders_611862(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_611864 = query.getOrDefault("limit")
  valid_611864 = validateParameter(valid_611864, JInt, required = false, default = nil)
  if valid_611864 != nil:
    section.add "limit", valid_611864
  var valid_611865 = query.getOrDefault("marker")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "marker", valid_611865
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString (required)
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611866 = header.getOrDefault("X-Amz-Signature")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Signature", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Content-Sha256", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Date")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Date", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Credential")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Credential", valid_611869
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_611870 = header.getOrDefault("Authentication")
  valid_611870 = validateParameter(valid_611870, JString, required = true,
                                 default = nil)
  if valid_611870 != nil:
    section.add "Authentication", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-Security-Token")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-Security-Token", valid_611871
  var valid_611872 = header.getOrDefault("X-Amz-Algorithm")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Algorithm", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-SignedHeaders", valid_611873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611874: Call_DescribeRootFolders_611861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_611874.validator(path, query, header, formData, body)
  let scheme = call_611874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611874.url(scheme.get, call_611874.host, call_611874.base,
                         call_611874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611874, url, valid)

proc call*(call_611875: Call_DescribeRootFolders_611861; limit: int = 0;
          marker: string = ""): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var query_611876 = newJObject()
  add(query_611876, "limit", newJInt(limit))
  add(query_611876, "marker", newJString(marker))
  result = call_611875.call(nil, query_611876, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_611861(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_611862, base: "/",
    url: url_DescribeRootFolders_611863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_611877 = ref object of OpenApiRestCall_610658
proc url_GetCurrentUser_611879(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCurrentUser_611878(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString (required)
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611880 = header.getOrDefault("X-Amz-Signature")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Signature", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Content-Sha256", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Date")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Date", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Credential")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Credential", valid_611883
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_611884 = header.getOrDefault("Authentication")
  valid_611884 = validateParameter(valid_611884, JString, required = true,
                                 default = nil)
  if valid_611884 != nil:
    section.add "Authentication", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Security-Token")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Security-Token", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Algorithm")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Algorithm", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-SignedHeaders", valid_611887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611888: Call_GetCurrentUser_611877; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_611888.validator(path, query, header, formData, body)
  let scheme = call_611888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611888.url(scheme.get, call_611888.host, call_611888.base,
                         call_611888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611888, url, valid)

proc call*(call_611889: Call_GetCurrentUser_611877): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_611889.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_611877(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_611878,
    base: "/", url: url_GetCurrentUser_611879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_611890 = ref object of OpenApiRestCall_610658
proc url_GetDocumentPath_611892(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentPath_611891(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DocumentId` field"
  var valid_611893 = path.getOrDefault("DocumentId")
  valid_611893 = validateParameter(valid_611893, JString, required = true,
                                 default = nil)
  if valid_611893 != nil:
    section.add "DocumentId", valid_611893
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_611894 = query.getOrDefault("limit")
  valid_611894 = validateParameter(valid_611894, JInt, required = false, default = nil)
  if valid_611894 != nil:
    section.add "limit", valid_611894
  var valid_611895 = query.getOrDefault("fields")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "fields", valid_611895
  var valid_611896 = query.getOrDefault("marker")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "marker", valid_611896
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611897 = header.getOrDefault("X-Amz-Signature")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Signature", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Content-Sha256", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Date")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Date", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Credential")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Credential", valid_611900
  var valid_611901 = header.getOrDefault("Authentication")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "Authentication", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Security-Token")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Security-Token", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Algorithm")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Algorithm", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-SignedHeaders", valid_611904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611905: Call_GetDocumentPath_611890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_611905.validator(path, query, header, formData, body)
  let scheme = call_611905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611905.url(scheme.get, call_611905.host, call_611905.base,
                         call_611905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611905, url, valid)

proc call*(call_611906: Call_GetDocumentPath_611890; DocumentId: string;
          limit: int = 0; fields: string = ""; marker: string = ""): Recallable =
  ## getDocumentPath
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   limit: int
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: string
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: string
  ##         : This value is not supported.
  var path_611907 = newJObject()
  var query_611908 = newJObject()
  add(path_611907, "DocumentId", newJString(DocumentId))
  add(query_611908, "limit", newJInt(limit))
  add(query_611908, "fields", newJString(fields))
  add(query_611908, "marker", newJString(marker))
  result = call_611906.call(path_611907, query_611908, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_611890(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_611891, base: "/", url: url_GetDocumentPath_611892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_611909 = ref object of OpenApiRestCall_610658
proc url_GetFolderPath_611911(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId"),
               (kind: ConstantSegment, value: "/path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFolderPath_611910(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_611912 = path.getOrDefault("FolderId")
  valid_611912 = validateParameter(valid_611912, JString, required = true,
                                 default = nil)
  if valid_611912 != nil:
    section.add "FolderId", valid_611912
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_611913 = query.getOrDefault("limit")
  valid_611913 = validateParameter(valid_611913, JInt, required = false, default = nil)
  if valid_611913 != nil:
    section.add "limit", valid_611913
  var valid_611914 = query.getOrDefault("fields")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "fields", valid_611914
  var valid_611915 = query.getOrDefault("marker")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "marker", valid_611915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611916 = header.getOrDefault("X-Amz-Signature")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Signature", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Content-Sha256", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Date")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Date", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Credential")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Credential", valid_611919
  var valid_611920 = header.getOrDefault("Authentication")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "Authentication", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-Security-Token")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Security-Token", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-Algorithm")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-Algorithm", valid_611922
  var valid_611923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-SignedHeaders", valid_611923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611924: Call_GetFolderPath_611909; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_611924.validator(path, query, header, formData, body)
  let scheme = call_611924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611924.url(scheme.get, call_611924.host, call_611924.base,
                         call_611924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611924, url, valid)

proc call*(call_611925: Call_GetFolderPath_611909; FolderId: string; limit: int = 0;
          fields: string = ""; marker: string = ""): Recallable =
  ## getFolderPath
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ##   limit: int
  ##        : The maximum number of levels in the hierarchy to return.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   fields: string
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: string
  ##         : This value is not supported.
  var path_611926 = newJObject()
  var query_611927 = newJObject()
  add(query_611927, "limit", newJInt(limit))
  add(path_611926, "FolderId", newJString(FolderId))
  add(query_611927, "fields", newJString(fields))
  add(query_611927, "marker", newJString(marker))
  result = call_611925.call(path_611926, query_611927, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_611909(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_611910,
    base: "/", url: url_GetFolderPath_611911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_611928 = ref object of OpenApiRestCall_610658
proc url_GetResources_611930(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResources_611929(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   userId: JString
  ##         : The user ID for the resource collection. This is a required field for accessing the API operation using IAM credentials.
  ##   limit: JInt
  ##        : The maximum number of resources to return.
  ##   collectionType: JString
  ##                 : The collection type.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  section = newJObject()
  var valid_611931 = query.getOrDefault("userId")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "userId", valid_611931
  var valid_611932 = query.getOrDefault("limit")
  valid_611932 = validateParameter(valid_611932, JInt, required = false, default = nil)
  if valid_611932 != nil:
    section.add "limit", valid_611932
  var valid_611933 = query.getOrDefault("collectionType")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_611933 != nil:
    section.add "collectionType", valid_611933
  var valid_611934 = query.getOrDefault("marker")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "marker", valid_611934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : The Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API operation using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611935 = header.getOrDefault("X-Amz-Signature")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Signature", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Content-Sha256", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Date")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Date", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Credential")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Credential", valid_611938
  var valid_611939 = header.getOrDefault("Authentication")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "Authentication", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Security-Token")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Security-Token", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Algorithm")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Algorithm", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-SignedHeaders", valid_611942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611943: Call_GetResources_611928; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_611943.validator(path, query, header, formData, body)
  let scheme = call_611943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611943.url(scheme.get, call_611943.host, call_611943.base,
                         call_611943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611943, url, valid)

proc call*(call_611944: Call_GetResources_611928; userId: string = ""; limit: int = 0;
          collectionType: string = "SHARED_WITH_ME"; marker: string = ""): Recallable =
  ## getResources
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ##   userId: string
  ##         : The user ID for the resource collection. This is a required field for accessing the API operation using IAM credentials.
  ##   limit: int
  ##        : The maximum number of resources to return.
  ##   collectionType: string
  ##                 : The collection type.
  ##   marker: string
  ##         : The marker for the next set of results. This marker was received from a previous call.
  var query_611945 = newJObject()
  add(query_611945, "userId", newJString(userId))
  add(query_611945, "limit", newJInt(limit))
  add(query_611945, "collectionType", newJString(collectionType))
  add(query_611945, "marker", newJString(marker))
  result = call_611944.call(nil, query_611945, nil, nil, nil)

var getResources* = Call_GetResources_611928(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_611929, base: "/",
    url: url_GetResources_611930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_611946 = ref object of OpenApiRestCall_610658
proc url_InitiateDocumentVersionUpload_611948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateDocumentVersionUpload_611947(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611949 = header.getOrDefault("X-Amz-Signature")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-Signature", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Content-Sha256", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Date")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Date", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Credential")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Credential", valid_611952
  var valid_611953 = header.getOrDefault("Authentication")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "Authentication", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Security-Token")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Security-Token", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Algorithm")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Algorithm", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-SignedHeaders", valid_611956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611958: Call_InitiateDocumentVersionUpload_611946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_611958.validator(path, query, header, formData, body)
  let scheme = call_611958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611958.url(scheme.get, call_611958.host, call_611958.base,
                         call_611958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611958, url, valid)

proc call*(call_611959: Call_InitiateDocumentVersionUpload_611946; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_611960 = newJObject()
  if body != nil:
    body_611960 = body
  result = call_611959.call(nil, nil, nil, nil, body_611960)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_611946(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_611947, base: "/",
    url: url_InitiateDocumentVersionUpload_611948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_611961 = ref object of OpenApiRestCall_610658
proc url_RemoveResourcePermission_611963(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  assert "PrincipalId" in path, "`PrincipalId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/permissions/"),
               (kind: VariableSegment, value: "PrincipalId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveResourcePermission_611962(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource.
  ##   PrincipalId: JString (required)
  ##              : The principal ID of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_611964 = path.getOrDefault("ResourceId")
  valid_611964 = validateParameter(valid_611964, JString, required = true,
                                 default = nil)
  if valid_611964 != nil:
    section.add "ResourceId", valid_611964
  var valid_611965 = path.getOrDefault("PrincipalId")
  valid_611965 = validateParameter(valid_611965, JString, required = true,
                                 default = nil)
  if valid_611965 != nil:
    section.add "PrincipalId", valid_611965
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_611966 = query.getOrDefault("type")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = newJString("USER"))
  if valid_611966 != nil:
    section.add "type", valid_611966
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611967 = header.getOrDefault("X-Amz-Signature")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Signature", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Content-Sha256", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Date")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Date", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Credential")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Credential", valid_611970
  var valid_611971 = header.getOrDefault("Authentication")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "Authentication", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-Security-Token")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-Security-Token", valid_611972
  var valid_611973 = header.getOrDefault("X-Amz-Algorithm")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Algorithm", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-SignedHeaders", valid_611974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611975: Call_RemoveResourcePermission_611961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_611975.validator(path, query, header, formData, body)
  let scheme = call_611975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611975.url(scheme.get, call_611975.host, call_611975.base,
                         call_611975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611975, url, valid)

proc call*(call_611976: Call_RemoveResourcePermission_611961; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_611977 = newJObject()
  var query_611978 = newJObject()
  add(path_611977, "ResourceId", newJString(ResourceId))
  add(query_611978, "type", newJString(`type`))
  add(path_611977, "PrincipalId", newJString(PrincipalId))
  result = call_611976.call(path_611977, query_611978, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_611961(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_611962, base: "/",
    url: url_RemoveResourcePermission_611963, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
