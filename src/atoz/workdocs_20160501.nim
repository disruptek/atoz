
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_GetDocumentVersion_612996 = ref object of OpenApiRestCall_612658
proc url_GetDocumentVersion_612998(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentVersion_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("VersionId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "VersionId", valid_613124
  var valid_613125 = path.getOrDefault("DocumentId")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = nil)
  if valid_613125 != nil:
    section.add "DocumentId", valid_613125
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  section = newJObject()
  var valid_613126 = query.getOrDefault("includeCustomMetadata")
  valid_613126 = validateParameter(valid_613126, JBool, required = false, default = nil)
  if valid_613126 != nil:
    section.add "includeCustomMetadata", valid_613126
  var valid_613127 = query.getOrDefault("fields")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "fields", valid_613127
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
  var valid_613128 = header.getOrDefault("X-Amz-Signature")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Signature", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Content-Sha256", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Date")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Date", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Credential")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Credential", valid_613131
  var valid_613132 = header.getOrDefault("Authentication")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "Authentication", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-Security-Token")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-Security-Token", valid_613133
  var valid_613134 = header.getOrDefault("X-Amz-Algorithm")
  valid_613134 = validateParameter(valid_613134, JString, required = false,
                                 default = nil)
  if valid_613134 != nil:
    section.add "X-Amz-Algorithm", valid_613134
  var valid_613135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613135 = validateParameter(valid_613135, JString, required = false,
                                 default = nil)
  if valid_613135 != nil:
    section.add "X-Amz-SignedHeaders", valid_613135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613158: Call_GetDocumentVersion_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_613158.validator(path, query, header, formData, body)
  let scheme = call_613158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613158.url(scheme.get, call_613158.host, call_613158.base,
                         call_613158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613158, url, valid)

proc call*(call_613229: Call_GetDocumentVersion_612996; VersionId: string;
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
  var path_613230 = newJObject()
  var query_613232 = newJObject()
  add(path_613230, "VersionId", newJString(VersionId))
  add(path_613230, "DocumentId", newJString(DocumentId))
  add(query_613232, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(query_613232, "fields", newJString(fields))
  result = call_613229.call(path_613230, query_613232, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_612996(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_612997, base: "/",
    url: url_GetDocumentVersion_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_613287 = ref object of OpenApiRestCall_612658
proc url_UpdateDocumentVersion_613289(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocumentVersion_613288(path: JsonNode; query: JsonNode;
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
  var valid_613290 = path.getOrDefault("VersionId")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "VersionId", valid_613290
  var valid_613291 = path.getOrDefault("DocumentId")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = nil)
  if valid_613291 != nil:
    section.add "DocumentId", valid_613291
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
  var valid_613292 = header.getOrDefault("X-Amz-Signature")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Signature", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Content-Sha256", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Date")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Date", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Credential")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Credential", valid_613295
  var valid_613296 = header.getOrDefault("Authentication")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "Authentication", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Security-Token")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Security-Token", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Algorithm")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Algorithm", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-SignedHeaders", valid_613299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613301: Call_UpdateDocumentVersion_613287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_613301.validator(path, query, header, formData, body)
  let scheme = call_613301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613301.url(scheme.get, call_613301.host, call_613301.base,
                         call_613301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613301, url, valid)

proc call*(call_613302: Call_UpdateDocumentVersion_613287; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_613303 = newJObject()
  var body_613304 = newJObject()
  add(path_613303, "VersionId", newJString(VersionId))
  add(path_613303, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_613304 = body
  result = call_613302.call(path_613303, nil, nil, nil, body_613304)

var updateDocumentVersion* = Call_UpdateDocumentVersion_613287(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_613288, base: "/",
    url: url_UpdateDocumentVersion_613289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_613271 = ref object of OpenApiRestCall_612658
proc url_AbortDocumentVersionUpload_613273(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AbortDocumentVersionUpload_613272(path: JsonNode; query: JsonNode;
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
  var valid_613274 = path.getOrDefault("VersionId")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = nil)
  if valid_613274 != nil:
    section.add "VersionId", valid_613274
  var valid_613275 = path.getOrDefault("DocumentId")
  valid_613275 = validateParameter(valid_613275, JString, required = true,
                                 default = nil)
  if valid_613275 != nil:
    section.add "DocumentId", valid_613275
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
  var valid_613276 = header.getOrDefault("X-Amz-Signature")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Signature", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Content-Sha256", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Date")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Date", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Credential")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Credential", valid_613279
  var valid_613280 = header.getOrDefault("Authentication")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "Authentication", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Security-Token")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Security-Token", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Algorithm")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Algorithm", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-SignedHeaders", valid_613283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613284: Call_AbortDocumentVersionUpload_613271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_613284.validator(path, query, header, formData, body)
  let scheme = call_613284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613284.url(scheme.get, call_613284.host, call_613284.base,
                         call_613284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613284, url, valid)

proc call*(call_613285: Call_AbortDocumentVersionUpload_613271; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_613286 = newJObject()
  add(path_613286, "VersionId", newJString(VersionId))
  add(path_613286, "DocumentId", newJString(DocumentId))
  result = call_613285.call(path_613286, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_613271(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_613272, base: "/",
    url: url_AbortDocumentVersionUpload_613273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_613305 = ref object of OpenApiRestCall_612658
proc url_ActivateUser_613307(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ActivateUser_613306(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613308 = path.getOrDefault("UserId")
  valid_613308 = validateParameter(valid_613308, JString, required = true,
                                 default = nil)
  if valid_613308 != nil:
    section.add "UserId", valid_613308
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
  var valid_613309 = header.getOrDefault("X-Amz-Signature")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Signature", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Content-Sha256", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Date")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Date", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Credential")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Credential", valid_613312
  var valid_613313 = header.getOrDefault("Authentication")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "Authentication", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Security-Token")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Security-Token", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Algorithm")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Algorithm", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-SignedHeaders", valid_613316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613317: Call_ActivateUser_613305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_613317.validator(path, query, header, formData, body)
  let scheme = call_613317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613317.url(scheme.get, call_613317.host, call_613317.base,
                         call_613317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613317, url, valid)

proc call*(call_613318: Call_ActivateUser_613305; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_613319 = newJObject()
  add(path_613319, "UserId", newJString(UserId))
  result = call_613318.call(path_613319, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_613305(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_613306,
    base: "/", url: url_ActivateUser_613307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_613320 = ref object of OpenApiRestCall_612658
proc url_DeactivateUser_613322(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeactivateUser_613321(path: JsonNode; query: JsonNode;
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
  var valid_613323 = path.getOrDefault("UserId")
  valid_613323 = validateParameter(valid_613323, JString, required = true,
                                 default = nil)
  if valid_613323 != nil:
    section.add "UserId", valid_613323
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
  var valid_613324 = header.getOrDefault("X-Amz-Signature")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Signature", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Content-Sha256", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Date")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Date", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Credential")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Credential", valid_613327
  var valid_613328 = header.getOrDefault("Authentication")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "Authentication", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Security-Token")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Security-Token", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Algorithm")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Algorithm", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-SignedHeaders", valid_613331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613332: Call_DeactivateUser_613320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_613332.validator(path, query, header, formData, body)
  let scheme = call_613332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613332.url(scheme.get, call_613332.host, call_613332.base,
                         call_613332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613332, url, valid)

proc call*(call_613333: Call_DeactivateUser_613320; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_613334 = newJObject()
  add(path_613334, "UserId", newJString(UserId))
  result = call_613333.call(path_613334, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_613320(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_613321, base: "/", url: url_DeactivateUser_613322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_613354 = ref object of OpenApiRestCall_612658
proc url_AddResourcePermissions_613356(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddResourcePermissions_613355(path: JsonNode; query: JsonNode;
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
  var valid_613357 = path.getOrDefault("ResourceId")
  valid_613357 = validateParameter(valid_613357, JString, required = true,
                                 default = nil)
  if valid_613357 != nil:
    section.add "ResourceId", valid_613357
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
  var valid_613358 = header.getOrDefault("X-Amz-Signature")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Signature", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Content-Sha256", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Date")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Date", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Credential")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Credential", valid_613361
  var valid_613362 = header.getOrDefault("Authentication")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "Authentication", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_AddResourcePermissions_613354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_AddResourcePermissions_613354; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_613369 = newJObject()
  var body_613370 = newJObject()
  add(path_613369, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_613370 = body
  result = call_613368.call(path_613369, nil, nil, nil, body_613370)

var addResourcePermissions* = Call_AddResourcePermissions_613354(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_613355, base: "/",
    url: url_AddResourcePermissions_613356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_613335 = ref object of OpenApiRestCall_612658
proc url_DescribeResourcePermissions_613337(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeResourcePermissions_613336(path: JsonNode; query: JsonNode;
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
  var valid_613338 = path.getOrDefault("ResourceId")
  valid_613338 = validateParameter(valid_613338, JString, required = true,
                                 default = nil)
  if valid_613338 != nil:
    section.add "ResourceId", valid_613338
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  section = newJObject()
  var valid_613339 = query.getOrDefault("limit")
  valid_613339 = validateParameter(valid_613339, JInt, required = false, default = nil)
  if valid_613339 != nil:
    section.add "limit", valid_613339
  var valid_613340 = query.getOrDefault("principalId")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "principalId", valid_613340
  var valid_613341 = query.getOrDefault("marker")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "marker", valid_613341
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
  var valid_613342 = header.getOrDefault("X-Amz-Signature")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Signature", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Content-Sha256", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Date")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Date", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Credential")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Credential", valid_613345
  var valid_613346 = header.getOrDefault("Authentication")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "Authentication", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613350: Call_DescribeResourcePermissions_613335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_613350.validator(path, query, header, formData, body)
  let scheme = call_613350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613350.url(scheme.get, call_613350.host, call_613350.base,
                         call_613350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613350, url, valid)

proc call*(call_613351: Call_DescribeResourcePermissions_613335;
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
  var path_613352 = newJObject()
  var query_613353 = newJObject()
  add(query_613353, "limit", newJInt(limit))
  add(path_613352, "ResourceId", newJString(ResourceId))
  add(query_613353, "principalId", newJString(principalId))
  add(query_613353, "marker", newJString(marker))
  result = call_613351.call(path_613352, query_613353, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_613335(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_613336, base: "/",
    url: url_DescribeResourcePermissions_613337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_613371 = ref object of OpenApiRestCall_612658
proc url_RemoveAllResourcePermissions_613373(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveAllResourcePermissions_613372(path: JsonNode; query: JsonNode;
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
  var valid_613374 = path.getOrDefault("ResourceId")
  valid_613374 = validateParameter(valid_613374, JString, required = true,
                                 default = nil)
  if valid_613374 != nil:
    section.add "ResourceId", valid_613374
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
  var valid_613375 = header.getOrDefault("X-Amz-Signature")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Signature", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Content-Sha256", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Date")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Date", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Credential")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Credential", valid_613378
  var valid_613379 = header.getOrDefault("Authentication")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "Authentication", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Security-Token")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Security-Token", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Algorithm")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Algorithm", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-SignedHeaders", valid_613382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613383: Call_RemoveAllResourcePermissions_613371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_613383.validator(path, query, header, formData, body)
  let scheme = call_613383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613383.url(scheme.get, call_613383.host, call_613383.base,
                         call_613383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613383, url, valid)

proc call*(call_613384: Call_RemoveAllResourcePermissions_613371;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_613385 = newJObject()
  add(path_613385, "ResourceId", newJString(ResourceId))
  result = call_613384.call(path_613385, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_613371(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_613372, base: "/",
    url: url_RemoveAllResourcePermissions_613373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_613386 = ref object of OpenApiRestCall_612658
proc url_CreateComment_613388(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateComment_613387(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613389 = path.getOrDefault("VersionId")
  valid_613389 = validateParameter(valid_613389, JString, required = true,
                                 default = nil)
  if valid_613389 != nil:
    section.add "VersionId", valid_613389
  var valid_613390 = path.getOrDefault("DocumentId")
  valid_613390 = validateParameter(valid_613390, JString, required = true,
                                 default = nil)
  if valid_613390 != nil:
    section.add "DocumentId", valid_613390
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
  var valid_613391 = header.getOrDefault("X-Amz-Signature")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Signature", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Content-Sha256", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Date")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Date", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Credential")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Credential", valid_613394
  var valid_613395 = header.getOrDefault("Authentication")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "Authentication", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Security-Token")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Security-Token", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Algorithm")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Algorithm", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-SignedHeaders", valid_613398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613400: Call_CreateComment_613386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_613400.validator(path, query, header, formData, body)
  let scheme = call_613400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613400.url(scheme.get, call_613400.host, call_613400.base,
                         call_613400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613400, url, valid)

proc call*(call_613401: Call_CreateComment_613386; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_613402 = newJObject()
  var body_613403 = newJObject()
  add(path_613402, "VersionId", newJString(VersionId))
  add(path_613402, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_613403 = body
  result = call_613401.call(path_613402, nil, nil, nil, body_613403)

var createComment* = Call_CreateComment_613386(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_613387, base: "/", url: url_CreateComment_613388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_613404 = ref object of OpenApiRestCall_612658
proc url_CreateCustomMetadata_613406(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateCustomMetadata_613405(path: JsonNode; query: JsonNode;
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
  var valid_613407 = path.getOrDefault("ResourceId")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = nil)
  if valid_613407 != nil:
    section.add "ResourceId", valid_613407
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_613408 = query.getOrDefault("versionid")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "versionid", valid_613408
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
  var valid_613409 = header.getOrDefault("X-Amz-Signature")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Signature", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Content-Sha256", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Date")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Date", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Credential")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Credential", valid_613412
  var valid_613413 = header.getOrDefault("Authentication")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "Authentication", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Security-Token")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Security-Token", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Algorithm")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Algorithm", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-SignedHeaders", valid_613416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613418: Call_CreateCustomMetadata_613404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_613418.validator(path, query, header, formData, body)
  let scheme = call_613418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613418.url(scheme.get, call_613418.host, call_613418.base,
                         call_613418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613418, url, valid)

proc call*(call_613419: Call_CreateCustomMetadata_613404; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_613420 = newJObject()
  var query_613421 = newJObject()
  var body_613422 = newJObject()
  add(query_613421, "versionid", newJString(versionid))
  add(path_613420, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_613422 = body
  result = call_613419.call(path_613420, query_613421, nil, nil, body_613422)

var createCustomMetadata* = Call_CreateCustomMetadata_613404(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_613405, base: "/",
    url: url_CreateCustomMetadata_613406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_613423 = ref object of OpenApiRestCall_612658
proc url_DeleteCustomMetadata_613425(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCustomMetadata_613424(path: JsonNode; query: JsonNode;
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
  var valid_613426 = path.getOrDefault("ResourceId")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = nil)
  if valid_613426 != nil:
    section.add "ResourceId", valid_613426
  result.add "path", section
  ## parameters in `query` object:
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  section = newJObject()
  var valid_613427 = query.getOrDefault("deleteAll")
  valid_613427 = validateParameter(valid_613427, JBool, required = false, default = nil)
  if valid_613427 != nil:
    section.add "deleteAll", valid_613427
  var valid_613428 = query.getOrDefault("keys")
  valid_613428 = validateParameter(valid_613428, JArray, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "keys", valid_613428
  var valid_613429 = query.getOrDefault("versionId")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "versionId", valid_613429
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
  var valid_613430 = header.getOrDefault("X-Amz-Signature")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Signature", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Content-Sha256", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Date")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Date", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Credential")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Credential", valid_613433
  var valid_613434 = header.getOrDefault("Authentication")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "Authentication", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Security-Token")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Security-Token", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Algorithm")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Algorithm", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-SignedHeaders", valid_613437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613438: Call_DeleteCustomMetadata_613423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_613438.validator(path, query, header, formData, body)
  let scheme = call_613438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613438.url(scheme.get, call_613438.host, call_613438.base,
                         call_613438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613438, url, valid)

proc call*(call_613439: Call_DeleteCustomMetadata_613423; ResourceId: string;
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
  var path_613440 = newJObject()
  var query_613441 = newJObject()
  add(query_613441, "deleteAll", newJBool(deleteAll))
  add(path_613440, "ResourceId", newJString(ResourceId))
  if keys != nil:
    query_613441.add "keys", keys
  add(query_613441, "versionId", newJString(versionId))
  result = call_613439.call(path_613440, query_613441, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_613423(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_613424, base: "/",
    url: url_DeleteCustomMetadata_613425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_613442 = ref object of OpenApiRestCall_612658
proc url_CreateFolder_613444(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFolder_613443(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613445 = header.getOrDefault("X-Amz-Signature")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Signature", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Content-Sha256", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Date")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Date", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Credential")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Credential", valid_613448
  var valid_613449 = header.getOrDefault("Authentication")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "Authentication", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Security-Token")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Security-Token", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Algorithm")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Algorithm", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-SignedHeaders", valid_613452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613454: Call_CreateFolder_613442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_613454.validator(path, query, header, formData, body)
  let scheme = call_613454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613454.url(scheme.get, call_613454.host, call_613454.base,
                         call_613454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613454, url, valid)

proc call*(call_613455: Call_CreateFolder_613442; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_613456 = newJObject()
  if body != nil:
    body_613456 = body
  result = call_613455.call(nil, nil, nil, nil, body_613456)

var createFolder* = Call_CreateFolder_613442(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_613443, base: "/",
    url: url_CreateFolder_613444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_613457 = ref object of OpenApiRestCall_612658
proc url_CreateLabels_613459(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateLabels_613458(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613460 = path.getOrDefault("ResourceId")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "ResourceId", valid_613460
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
  var valid_613461 = header.getOrDefault("X-Amz-Signature")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Signature", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Content-Sha256", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Date")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Date", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Credential")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Credential", valid_613464
  var valid_613465 = header.getOrDefault("Authentication")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "Authentication", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Security-Token")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Security-Token", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Algorithm")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Algorithm", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-SignedHeaders", valid_613468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613470: Call_CreateLabels_613457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_613470.validator(path, query, header, formData, body)
  let scheme = call_613470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613470.url(scheme.get, call_613470.host, call_613470.base,
                         call_613470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613470, url, valid)

proc call*(call_613471: Call_CreateLabels_613457; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_613472 = newJObject()
  var body_613473 = newJObject()
  add(path_613472, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_613473 = body
  result = call_613471.call(path_613472, nil, nil, nil, body_613473)

var createLabels* = Call_CreateLabels_613457(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_613458, base: "/", url: url_CreateLabels_613459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_613474 = ref object of OpenApiRestCall_612658
proc url_DeleteLabels_613476(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLabels_613475(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613477 = path.getOrDefault("ResourceId")
  valid_613477 = validateParameter(valid_613477, JString, required = true,
                                 default = nil)
  if valid_613477 != nil:
    section.add "ResourceId", valid_613477
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_613478 = query.getOrDefault("labels")
  valid_613478 = validateParameter(valid_613478, JArray, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "labels", valid_613478
  var valid_613479 = query.getOrDefault("deleteAll")
  valid_613479 = validateParameter(valid_613479, JBool, required = false, default = nil)
  if valid_613479 != nil:
    section.add "deleteAll", valid_613479
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
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("Authentication")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "Authentication", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Security-Token")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Security-Token", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Algorithm")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Algorithm", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-SignedHeaders", valid_613487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613488: Call_DeleteLabels_613474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_613488.validator(path, query, header, formData, body)
  let scheme = call_613488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613488.url(scheme.get, call_613488.host, call_613488.base,
                         call_613488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613488, url, valid)

proc call*(call_613489: Call_DeleteLabels_613474; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_613490 = newJObject()
  var query_613491 = newJObject()
  if labels != nil:
    query_613491.add "labels", labels
  add(query_613491, "deleteAll", newJBool(deleteAll))
  add(path_613490, "ResourceId", newJString(ResourceId))
  result = call_613489.call(path_613490, query_613491, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_613474(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_613475, base: "/", url: url_DeleteLabels_613476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_613509 = ref object of OpenApiRestCall_612658
proc url_CreateNotificationSubscription_613511(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateNotificationSubscription_613510(path: JsonNode;
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
  var valid_613512 = path.getOrDefault("OrganizationId")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "OrganizationId", valid_613512
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
  var valid_613513 = header.getOrDefault("X-Amz-Signature")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Signature", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Content-Sha256", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Date")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Date", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Credential")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Credential", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Security-Token")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Security-Token", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Algorithm")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Algorithm", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-SignedHeaders", valid_613519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613521: Call_CreateNotificationSubscription_613509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_613521.validator(path, query, header, formData, body)
  let scheme = call_613521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613521.url(scheme.get, call_613521.host, call_613521.base,
                         call_613521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613521, url, valid)

proc call*(call_613522: Call_CreateNotificationSubscription_613509;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_613523 = newJObject()
  var body_613524 = newJObject()
  add(path_613523, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_613524 = body
  result = call_613522.call(path_613523, nil, nil, nil, body_613524)

var createNotificationSubscription* = Call_CreateNotificationSubscription_613509(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_613510, base: "/",
    url: url_CreateNotificationSubscription_613511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_613492 = ref object of OpenApiRestCall_612658
proc url_DescribeNotificationSubscriptions_613494(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeNotificationSubscriptions_613493(path: JsonNode;
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
  var valid_613495 = path.getOrDefault("OrganizationId")
  valid_613495 = validateParameter(valid_613495, JString, required = true,
                                 default = nil)
  if valid_613495 != nil:
    section.add "OrganizationId", valid_613495
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_613496 = query.getOrDefault("limit")
  valid_613496 = validateParameter(valid_613496, JInt, required = false, default = nil)
  if valid_613496 != nil:
    section.add "limit", valid_613496
  var valid_613497 = query.getOrDefault("marker")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "marker", valid_613497
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
  var valid_613498 = header.getOrDefault("X-Amz-Signature")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Signature", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Content-Sha256", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Date")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Date", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Credential")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Credential", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Security-Token")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Security-Token", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Algorithm")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Algorithm", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-SignedHeaders", valid_613504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613505: Call_DescribeNotificationSubscriptions_613492;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_613505.validator(path, query, header, formData, body)
  let scheme = call_613505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613505.url(scheme.get, call_613505.host, call_613505.base,
                         call_613505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613505, url, valid)

proc call*(call_613506: Call_DescribeNotificationSubscriptions_613492;
          OrganizationId: string; limit: int = 0; marker: string = ""): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var path_613507 = newJObject()
  var query_613508 = newJObject()
  add(path_613507, "OrganizationId", newJString(OrganizationId))
  add(query_613508, "limit", newJInt(limit))
  add(query_613508, "marker", newJString(marker))
  result = call_613506.call(path_613507, query_613508, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_613492(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_613493, base: "/",
    url: url_DescribeNotificationSubscriptions_613494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_613563 = ref object of OpenApiRestCall_612658
proc url_CreateUser_613565(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_613564(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613566 = header.getOrDefault("X-Amz-Signature")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Signature", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Content-Sha256", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Date")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Date", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Credential")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Credential", valid_613569
  var valid_613570 = header.getOrDefault("Authentication")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "Authentication", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Security-Token")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Security-Token", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Algorithm")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Algorithm", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-SignedHeaders", valid_613573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613575: Call_CreateUser_613563; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_613575.validator(path, query, header, formData, body)
  let scheme = call_613575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613575.url(scheme.get, call_613575.host, call_613575.base,
                         call_613575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613575, url, valid)

proc call*(call_613576: Call_CreateUser_613563; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_613577 = newJObject()
  if body != nil:
    body_613577 = body
  result = call_613576.call(nil, nil, nil, nil, body_613577)

var createUser* = Call_CreateUser_613563(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_613564,
                                      base: "/", url: url_CreateUser_613565,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_613525 = ref object of OpenApiRestCall_612658
proc url_DescribeUsers_613527(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUsers_613526(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613541 = query.getOrDefault("sort")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_613541 != nil:
    section.add "sort", valid_613541
  var valid_613542 = query.getOrDefault("Marker")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "Marker", valid_613542
  var valid_613543 = query.getOrDefault("order")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_613543 != nil:
    section.add "order", valid_613543
  var valid_613544 = query.getOrDefault("limit")
  valid_613544 = validateParameter(valid_613544, JInt, required = false, default = nil)
  if valid_613544 != nil:
    section.add "limit", valid_613544
  var valid_613545 = query.getOrDefault("Limit")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "Limit", valid_613545
  var valid_613546 = query.getOrDefault("userIds")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "userIds", valid_613546
  var valid_613547 = query.getOrDefault("include")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = newJString("ALL"))
  if valid_613547 != nil:
    section.add "include", valid_613547
  var valid_613548 = query.getOrDefault("query")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "query", valid_613548
  var valid_613549 = query.getOrDefault("organizationId")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "organizationId", valid_613549
  var valid_613550 = query.getOrDefault("fields")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "fields", valid_613550
  var valid_613551 = query.getOrDefault("marker")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "marker", valid_613551
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
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("Authentication")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "Authentication", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Security-Token")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Security-Token", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Algorithm")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Algorithm", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-SignedHeaders", valid_613559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_DescribeUsers_613525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_DescribeUsers_613525; sort: string = "USER_NAME";
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
  var query_613562 = newJObject()
  add(query_613562, "sort", newJString(sort))
  add(query_613562, "Marker", newJString(Marker))
  add(query_613562, "order", newJString(order))
  add(query_613562, "limit", newJInt(limit))
  add(query_613562, "Limit", newJString(Limit))
  add(query_613562, "userIds", newJString(userIds))
  add(query_613562, "include", newJString(`include`))
  add(query_613562, "query", newJString(query))
  add(query_613562, "organizationId", newJString(organizationId))
  add(query_613562, "fields", newJString(fields))
  add(query_613562, "marker", newJString(marker))
  result = call_613561.call(nil, query_613562, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_613525(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_613526, base: "/",
    url: url_DescribeUsers_613527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_613578 = ref object of OpenApiRestCall_612658
proc url_DeleteComment_613580(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteComment_613579(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613581 = path.getOrDefault("VersionId")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = nil)
  if valid_613581 != nil:
    section.add "VersionId", valid_613581
  var valid_613582 = path.getOrDefault("DocumentId")
  valid_613582 = validateParameter(valid_613582, JString, required = true,
                                 default = nil)
  if valid_613582 != nil:
    section.add "DocumentId", valid_613582
  var valid_613583 = path.getOrDefault("CommentId")
  valid_613583 = validateParameter(valid_613583, JString, required = true,
                                 default = nil)
  if valid_613583 != nil:
    section.add "CommentId", valid_613583
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
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("Authentication")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "Authentication", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Security-Token")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Security-Token", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Algorithm")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Algorithm", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-SignedHeaders", valid_613591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_DeleteComment_613578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_DeleteComment_613578; VersionId: string;
          DocumentId: string; CommentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  var path_613594 = newJObject()
  add(path_613594, "VersionId", newJString(VersionId))
  add(path_613594, "DocumentId", newJString(DocumentId))
  add(path_613594, "CommentId", newJString(CommentId))
  result = call_613593.call(path_613594, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_613578(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_613579, base: "/", url: url_DeleteComment_613580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_613595 = ref object of OpenApiRestCall_612658
proc url_GetDocument_613597(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocument_613596(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613598 = path.getOrDefault("DocumentId")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "DocumentId", valid_613598
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_613599 = query.getOrDefault("includeCustomMetadata")
  valid_613599 = validateParameter(valid_613599, JBool, required = false, default = nil)
  if valid_613599 != nil:
    section.add "includeCustomMetadata", valid_613599
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
  var valid_613600 = header.getOrDefault("X-Amz-Signature")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Signature", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Content-Sha256", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Date")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Date", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Credential")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Credential", valid_613603
  var valid_613604 = header.getOrDefault("Authentication")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "Authentication", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Security-Token")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Security-Token", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Algorithm")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Algorithm", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-SignedHeaders", valid_613607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613608: Call_GetDocument_613595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_613608.validator(path, query, header, formData, body)
  let scheme = call_613608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613608.url(scheme.get, call_613608.host, call_613608.base,
                         call_613608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613608, url, valid)

proc call*(call_613609: Call_GetDocument_613595; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  var path_613610 = newJObject()
  var query_613611 = newJObject()
  add(path_613610, "DocumentId", newJString(DocumentId))
  add(query_613611, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_613609.call(path_613610, query_613611, nil, nil, nil)

var getDocument* = Call_GetDocument_613595(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_613596,
                                        base: "/", url: url_GetDocument_613597,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_613627 = ref object of OpenApiRestCall_612658
proc url_UpdateDocument_613629(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDocument_613628(path: JsonNode; query: JsonNode;
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
  var valid_613630 = path.getOrDefault("DocumentId")
  valid_613630 = validateParameter(valid_613630, JString, required = true,
                                 default = nil)
  if valid_613630 != nil:
    section.add "DocumentId", valid_613630
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
  var valid_613631 = header.getOrDefault("X-Amz-Signature")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Signature", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Content-Sha256", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Date")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Date", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Credential")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Credential", valid_613634
  var valid_613635 = header.getOrDefault("Authentication")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "Authentication", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Security-Token")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Security-Token", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Algorithm")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Algorithm", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-SignedHeaders", valid_613638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613640: Call_UpdateDocument_613627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_613640.validator(path, query, header, formData, body)
  let scheme = call_613640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613640.url(scheme.get, call_613640.host, call_613640.base,
                         call_613640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613640, url, valid)

proc call*(call_613641: Call_UpdateDocument_613627; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_613642 = newJObject()
  var body_613643 = newJObject()
  add(path_613642, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_613643 = body
  result = call_613641.call(path_613642, nil, nil, nil, body_613643)

var updateDocument* = Call_UpdateDocument_613627(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_613628,
    base: "/", url: url_UpdateDocument_613629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_613612 = ref object of OpenApiRestCall_612658
proc url_DeleteDocument_613614(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDocument_613613(path: JsonNode; query: JsonNode;
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
  var valid_613615 = path.getOrDefault("DocumentId")
  valid_613615 = validateParameter(valid_613615, JString, required = true,
                                 default = nil)
  if valid_613615 != nil:
    section.add "DocumentId", valid_613615
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
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("Authentication")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "Authentication", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Security-Token")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Security-Token", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Algorithm")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Algorithm", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-SignedHeaders", valid_613623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613624: Call_DeleteDocument_613612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_613624.validator(path, query, header, formData, body)
  let scheme = call_613624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613624.url(scheme.get, call_613624.host, call_613624.base,
                         call_613624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613624, url, valid)

proc call*(call_613625: Call_DeleteDocument_613612; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_613626 = newJObject()
  add(path_613626, "DocumentId", newJString(DocumentId))
  result = call_613625.call(path_613626, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_613612(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_613613,
    base: "/", url: url_DeleteDocument_613614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_613644 = ref object of OpenApiRestCall_612658
proc url_GetFolder_613646(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFolder_613645(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613647 = path.getOrDefault("FolderId")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = nil)
  if valid_613647 != nil:
    section.add "FolderId", valid_613647
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_613648 = query.getOrDefault("includeCustomMetadata")
  valid_613648 = validateParameter(valid_613648, JBool, required = false, default = nil)
  if valid_613648 != nil:
    section.add "includeCustomMetadata", valid_613648
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
  var valid_613649 = header.getOrDefault("X-Amz-Signature")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Signature", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Content-Sha256", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Date")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Date", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Credential")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Credential", valid_613652
  var valid_613653 = header.getOrDefault("Authentication")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "Authentication", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Security-Token")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Security-Token", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Algorithm")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Algorithm", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-SignedHeaders", valid_613656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613657: Call_GetFolder_613644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_613657.validator(path, query, header, formData, body)
  let scheme = call_613657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613657.url(scheme.get, call_613657.host, call_613657.base,
                         call_613657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613657, url, valid)

proc call*(call_613658: Call_GetFolder_613644; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_613659 = newJObject()
  var query_613660 = newJObject()
  add(query_613660, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_613659, "FolderId", newJString(FolderId))
  result = call_613658.call(path_613659, query_613660, nil, nil, nil)

var getFolder* = Call_GetFolder_613644(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_613645,
                                    base: "/", url: url_GetFolder_613646,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_613676 = ref object of OpenApiRestCall_612658
proc url_UpdateFolder_613678(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFolder_613677(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613679 = path.getOrDefault("FolderId")
  valid_613679 = validateParameter(valid_613679, JString, required = true,
                                 default = nil)
  if valid_613679 != nil:
    section.add "FolderId", valid_613679
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
  var valid_613680 = header.getOrDefault("X-Amz-Signature")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Signature", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Content-Sha256", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Date")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Date", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Credential")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Credential", valid_613683
  var valid_613684 = header.getOrDefault("Authentication")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "Authentication", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Security-Token")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Security-Token", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Algorithm")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Algorithm", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-SignedHeaders", valid_613687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613689: Call_UpdateFolder_613676; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_613689.validator(path, query, header, formData, body)
  let scheme = call_613689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613689.url(scheme.get, call_613689.host, call_613689.base,
                         call_613689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613689, url, valid)

proc call*(call_613690: Call_UpdateFolder_613676; body: JsonNode; FolderId: string): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   body: JObject (required)
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_613691 = newJObject()
  var body_613692 = newJObject()
  if body != nil:
    body_613692 = body
  add(path_613691, "FolderId", newJString(FolderId))
  result = call_613690.call(path_613691, nil, nil, nil, body_613692)

var updateFolder* = Call_UpdateFolder_613676(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_613677,
    base: "/", url: url_UpdateFolder_613678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_613661 = ref object of OpenApiRestCall_612658
proc url_DeleteFolder_613663(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFolder_613662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613664 = path.getOrDefault("FolderId")
  valid_613664 = validateParameter(valid_613664, JString, required = true,
                                 default = nil)
  if valid_613664 != nil:
    section.add "FolderId", valid_613664
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
  var valid_613665 = header.getOrDefault("X-Amz-Signature")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Signature", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Content-Sha256", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Date")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Date", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Credential")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Credential", valid_613668
  var valid_613669 = header.getOrDefault("Authentication")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "Authentication", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Security-Token")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Security-Token", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Algorithm")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Algorithm", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-SignedHeaders", valid_613672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613673: Call_DeleteFolder_613661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_613673.validator(path, query, header, formData, body)
  let scheme = call_613673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613673.url(scheme.get, call_613673.host, call_613673.base,
                         call_613673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613673, url, valid)

proc call*(call_613674: Call_DeleteFolder_613661; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_613675 = newJObject()
  add(path_613675, "FolderId", newJString(FolderId))
  result = call_613674.call(path_613675, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_613661(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_613662,
    base: "/", url: url_DeleteFolder_613663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_613693 = ref object of OpenApiRestCall_612658
proc url_DescribeFolderContents_613695(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFolderContents_613694(path: JsonNode; query: JsonNode;
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
  var valid_613696 = path.getOrDefault("FolderId")
  valid_613696 = validateParameter(valid_613696, JString, required = true,
                                 default = nil)
  if valid_613696 != nil:
    section.add "FolderId", valid_613696
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
  var valid_613697 = query.getOrDefault("sort")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = newJString("DATE"))
  if valid_613697 != nil:
    section.add "sort", valid_613697
  var valid_613698 = query.getOrDefault("Marker")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "Marker", valid_613698
  var valid_613699 = query.getOrDefault("order")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_613699 != nil:
    section.add "order", valid_613699
  var valid_613700 = query.getOrDefault("limit")
  valid_613700 = validateParameter(valid_613700, JInt, required = false, default = nil)
  if valid_613700 != nil:
    section.add "limit", valid_613700
  var valid_613701 = query.getOrDefault("Limit")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "Limit", valid_613701
  var valid_613702 = query.getOrDefault("type")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = newJString("ALL"))
  if valid_613702 != nil:
    section.add "type", valid_613702
  var valid_613703 = query.getOrDefault("include")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "include", valid_613703
  var valid_613704 = query.getOrDefault("marker")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "marker", valid_613704
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
  var valid_613705 = header.getOrDefault("X-Amz-Signature")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Signature", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Content-Sha256", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Date")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Date", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Credential")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Credential", valid_613708
  var valid_613709 = header.getOrDefault("Authentication")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "Authentication", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Security-Token")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Security-Token", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Algorithm")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Algorithm", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-SignedHeaders", valid_613712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613713: Call_DescribeFolderContents_613693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_613713.validator(path, query, header, formData, body)
  let scheme = call_613713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613713.url(scheme.get, call_613713.host, call_613713.base,
                         call_613713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613713, url, valid)

proc call*(call_613714: Call_DescribeFolderContents_613693; FolderId: string;
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
  var path_613715 = newJObject()
  var query_613716 = newJObject()
  add(query_613716, "sort", newJString(sort))
  add(query_613716, "Marker", newJString(Marker))
  add(query_613716, "order", newJString(order))
  add(query_613716, "limit", newJInt(limit))
  add(query_613716, "Limit", newJString(Limit))
  add(query_613716, "type", newJString(`type`))
  add(query_613716, "include", newJString(`include`))
  add(path_613715, "FolderId", newJString(FolderId))
  add(query_613716, "marker", newJString(marker))
  result = call_613714.call(path_613715, query_613716, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_613693(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_613694, base: "/",
    url: url_DescribeFolderContents_613695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_613717 = ref object of OpenApiRestCall_612658
proc url_DeleteFolderContents_613719(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFolderContents_613718(path: JsonNode; query: JsonNode;
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
  var valid_613720 = path.getOrDefault("FolderId")
  valid_613720 = validateParameter(valid_613720, JString, required = true,
                                 default = nil)
  if valid_613720 != nil:
    section.add "FolderId", valid_613720
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
  var valid_613721 = header.getOrDefault("X-Amz-Signature")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Signature", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Content-Sha256", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Date")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Date", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Credential")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Credential", valid_613724
  var valid_613725 = header.getOrDefault("Authentication")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "Authentication", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Security-Token")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Security-Token", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Algorithm")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Algorithm", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-SignedHeaders", valid_613728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613729: Call_DeleteFolderContents_613717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_613729.validator(path, query, header, formData, body)
  let scheme = call_613729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613729.url(scheme.get, call_613729.host, call_613729.base,
                         call_613729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613729, url, valid)

proc call*(call_613730: Call_DeleteFolderContents_613717; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_613731 = newJObject()
  add(path_613731, "FolderId", newJString(FolderId))
  result = call_613730.call(path_613731, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_613717(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_613718, base: "/",
    url: url_DeleteFolderContents_613719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_613732 = ref object of OpenApiRestCall_612658
proc url_DeleteNotificationSubscription_613734(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteNotificationSubscription_613733(path: JsonNode;
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
  var valid_613735 = path.getOrDefault("SubscriptionId")
  valid_613735 = validateParameter(valid_613735, JString, required = true,
                                 default = nil)
  if valid_613735 != nil:
    section.add "SubscriptionId", valid_613735
  var valid_613736 = path.getOrDefault("OrganizationId")
  valid_613736 = validateParameter(valid_613736, JString, required = true,
                                 default = nil)
  if valid_613736 != nil:
    section.add "OrganizationId", valid_613736
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
  var valid_613737 = header.getOrDefault("X-Amz-Signature")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Signature", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Content-Sha256", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Date")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Date", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Credential")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Credential", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Security-Token")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Security-Token", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Algorithm")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Algorithm", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-SignedHeaders", valid_613743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613744: Call_DeleteNotificationSubscription_613732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_613744.validator(path, query, header, formData, body)
  let scheme = call_613744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613744.url(scheme.get, call_613744.host, call_613744.base,
                         call_613744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613744, url, valid)

proc call*(call_613745: Call_DeleteNotificationSubscription_613732;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_613746 = newJObject()
  add(path_613746, "SubscriptionId", newJString(SubscriptionId))
  add(path_613746, "OrganizationId", newJString(OrganizationId))
  result = call_613745.call(path_613746, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_613732(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_613733, base: "/",
    url: url_DeleteNotificationSubscription_613734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_613762 = ref object of OpenApiRestCall_612658
proc url_UpdateUser_613764(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_613763(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613765 = path.getOrDefault("UserId")
  valid_613765 = validateParameter(valid_613765, JString, required = true,
                                 default = nil)
  if valid_613765 != nil:
    section.add "UserId", valid_613765
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
  var valid_613766 = header.getOrDefault("X-Amz-Signature")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Signature", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Content-Sha256", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Date")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Date", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Credential")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Credential", valid_613769
  var valid_613770 = header.getOrDefault("Authentication")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "Authentication", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Security-Token")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Security-Token", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Algorithm")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Algorithm", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-SignedHeaders", valid_613773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613775: Call_UpdateUser_613762; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_613775.validator(path, query, header, formData, body)
  let scheme = call_613775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613775.url(scheme.get, call_613775.host, call_613775.base,
                         call_613775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613775, url, valid)

proc call*(call_613776: Call_UpdateUser_613762; UserId: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   UserId: string (required)
  ##         : The ID of the user.
  ##   body: JObject (required)
  var path_613777 = newJObject()
  var body_613778 = newJObject()
  add(path_613777, "UserId", newJString(UserId))
  if body != nil:
    body_613778 = body
  result = call_613776.call(path_613777, nil, nil, nil, body_613778)

var updateUser* = Call_UpdateUser_613762(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_613763,
                                      base: "/", url: url_UpdateUser_613764,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_613747 = ref object of OpenApiRestCall_612658
proc url_DeleteUser_613749(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_613748(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613750 = path.getOrDefault("UserId")
  valid_613750 = validateParameter(valid_613750, JString, required = true,
                                 default = nil)
  if valid_613750 != nil:
    section.add "UserId", valid_613750
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
  var valid_613751 = header.getOrDefault("X-Amz-Signature")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Signature", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Content-Sha256", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Date")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Date", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Credential")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Credential", valid_613754
  var valid_613755 = header.getOrDefault("Authentication")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "Authentication", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Security-Token")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Security-Token", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Algorithm")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Algorithm", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-SignedHeaders", valid_613758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613759: Call_DeleteUser_613747; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_613759.validator(path, query, header, formData, body)
  let scheme = call_613759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613759.url(scheme.get, call_613759.host, call_613759.base,
                         call_613759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613759, url, valid)

proc call*(call_613760: Call_DeleteUser_613747; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_613761 = newJObject()
  add(path_613761, "UserId", newJString(UserId))
  result = call_613760.call(path_613761, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_613747(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_613748,
                                      base: "/", url: url_DeleteUser_613749,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_613779 = ref object of OpenApiRestCall_612658
proc url_DescribeActivities_613781(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActivities_613780(path: JsonNode; query: JsonNode;
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
  var valid_613782 = query.getOrDefault("endTime")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "endTime", valid_613782
  var valid_613783 = query.getOrDefault("userId")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "userId", valid_613783
  var valid_613784 = query.getOrDefault("resourceId")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "resourceId", valid_613784
  var valid_613785 = query.getOrDefault("limit")
  valid_613785 = validateParameter(valid_613785, JInt, required = false, default = nil)
  if valid_613785 != nil:
    section.add "limit", valid_613785
  var valid_613786 = query.getOrDefault("startTime")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "startTime", valid_613786
  var valid_613787 = query.getOrDefault("activityTypes")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "activityTypes", valid_613787
  var valid_613788 = query.getOrDefault("organizationId")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "organizationId", valid_613788
  var valid_613789 = query.getOrDefault("includeIndirectActivities")
  valid_613789 = validateParameter(valid_613789, JBool, required = false, default = nil)
  if valid_613789 != nil:
    section.add "includeIndirectActivities", valid_613789
  var valid_613790 = query.getOrDefault("marker")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "marker", valid_613790
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
  var valid_613791 = header.getOrDefault("X-Amz-Signature")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Signature", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Content-Sha256", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Date")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Date", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Credential")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Credential", valid_613794
  var valid_613795 = header.getOrDefault("Authentication")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "Authentication", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Security-Token")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Security-Token", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Algorithm")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Algorithm", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-SignedHeaders", valid_613798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613799: Call_DescribeActivities_613779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_613799.validator(path, query, header, formData, body)
  let scheme = call_613799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613799.url(scheme.get, call_613799.host, call_613799.base,
                         call_613799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613799, url, valid)

proc call*(call_613800: Call_DescribeActivities_613779; endTime: string = "";
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
  var query_613801 = newJObject()
  add(query_613801, "endTime", newJString(endTime))
  add(query_613801, "userId", newJString(userId))
  add(query_613801, "resourceId", newJString(resourceId))
  add(query_613801, "limit", newJInt(limit))
  add(query_613801, "startTime", newJString(startTime))
  add(query_613801, "activityTypes", newJString(activityTypes))
  add(query_613801, "organizationId", newJString(organizationId))
  add(query_613801, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_613801, "marker", newJString(marker))
  result = call_613800.call(nil, query_613801, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_613779(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_613780, base: "/",
    url: url_DescribeActivities_613781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_613802 = ref object of OpenApiRestCall_612658
proc url_DescribeComments_613804(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeComments_613803(path: JsonNode; query: JsonNode;
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
  var valid_613805 = path.getOrDefault("VersionId")
  valid_613805 = validateParameter(valid_613805, JString, required = true,
                                 default = nil)
  if valid_613805 != nil:
    section.add "VersionId", valid_613805
  var valid_613806 = path.getOrDefault("DocumentId")
  valid_613806 = validateParameter(valid_613806, JString, required = true,
                                 default = nil)
  if valid_613806 != nil:
    section.add "DocumentId", valid_613806
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  section = newJObject()
  var valid_613807 = query.getOrDefault("limit")
  valid_613807 = validateParameter(valid_613807, JInt, required = false, default = nil)
  if valid_613807 != nil:
    section.add "limit", valid_613807
  var valid_613808 = query.getOrDefault("marker")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "marker", valid_613808
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
  var valid_613809 = header.getOrDefault("X-Amz-Signature")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Signature", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Content-Sha256", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Date")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Date", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Credential")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Credential", valid_613812
  var valid_613813 = header.getOrDefault("Authentication")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "Authentication", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Security-Token")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Security-Token", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Algorithm")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Algorithm", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-SignedHeaders", valid_613816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_DescribeComments_613802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_DescribeComments_613802; VersionId: string;
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
  var path_613819 = newJObject()
  var query_613820 = newJObject()
  add(path_613819, "VersionId", newJString(VersionId))
  add(path_613819, "DocumentId", newJString(DocumentId))
  add(query_613820, "limit", newJInt(limit))
  add(query_613820, "marker", newJString(marker))
  result = call_613818.call(path_613819, query_613820, nil, nil, nil)

var describeComments* = Call_DescribeComments_613802(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_613803, base: "/",
    url: url_DescribeComments_613804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_613821 = ref object of OpenApiRestCall_612658
proc url_DescribeDocumentVersions_613823(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDocumentVersions_613822(path: JsonNode; query: JsonNode;
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
  var valid_613824 = path.getOrDefault("DocumentId")
  valid_613824 = validateParameter(valid_613824, JString, required = true,
                                 default = nil)
  if valid_613824 != nil:
    section.add "DocumentId", valid_613824
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
  var valid_613825 = query.getOrDefault("Marker")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "Marker", valid_613825
  var valid_613826 = query.getOrDefault("limit")
  valid_613826 = validateParameter(valid_613826, JInt, required = false, default = nil)
  if valid_613826 != nil:
    section.add "limit", valid_613826
  var valid_613827 = query.getOrDefault("Limit")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "Limit", valid_613827
  var valid_613828 = query.getOrDefault("include")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "include", valid_613828
  var valid_613829 = query.getOrDefault("fields")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "fields", valid_613829
  var valid_613830 = query.getOrDefault("marker")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "marker", valid_613830
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
  var valid_613831 = header.getOrDefault("X-Amz-Signature")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Signature", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Content-Sha256", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Date")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Date", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Credential")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Credential", valid_613834
  var valid_613835 = header.getOrDefault("Authentication")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "Authentication", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Security-Token")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Security-Token", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Algorithm")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Algorithm", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-SignedHeaders", valid_613838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613839: Call_DescribeDocumentVersions_613821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_613839.validator(path, query, header, formData, body)
  let scheme = call_613839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613839.url(scheme.get, call_613839.host, call_613839.base,
                         call_613839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613839, url, valid)

proc call*(call_613840: Call_DescribeDocumentVersions_613821; DocumentId: string;
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
  var path_613841 = newJObject()
  var query_613842 = newJObject()
  add(query_613842, "Marker", newJString(Marker))
  add(path_613841, "DocumentId", newJString(DocumentId))
  add(query_613842, "limit", newJInt(limit))
  add(query_613842, "Limit", newJString(Limit))
  add(query_613842, "include", newJString(`include`))
  add(query_613842, "fields", newJString(fields))
  add(query_613842, "marker", newJString(marker))
  result = call_613840.call(path_613841, query_613842, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_613821(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_613822, base: "/",
    url: url_DescribeDocumentVersions_613823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_613843 = ref object of OpenApiRestCall_612658
proc url_DescribeGroups_613845(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGroups_613844(path: JsonNode; query: JsonNode;
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
  var valid_613846 = query.getOrDefault("searchQuery")
  valid_613846 = validateParameter(valid_613846, JString, required = true,
                                 default = nil)
  if valid_613846 != nil:
    section.add "searchQuery", valid_613846
  var valid_613847 = query.getOrDefault("limit")
  valid_613847 = validateParameter(valid_613847, JInt, required = false, default = nil)
  if valid_613847 != nil:
    section.add "limit", valid_613847
  var valid_613848 = query.getOrDefault("organizationId")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "organizationId", valid_613848
  var valid_613849 = query.getOrDefault("marker")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "marker", valid_613849
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
  var valid_613850 = header.getOrDefault("X-Amz-Signature")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Signature", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Content-Sha256", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Date")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Date", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Credential")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Credential", valid_613853
  var valid_613854 = header.getOrDefault("Authentication")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "Authentication", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Security-Token")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Security-Token", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Algorithm")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Algorithm", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-SignedHeaders", valid_613857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613858: Call_DescribeGroups_613843; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_613858.validator(path, query, header, formData, body)
  let scheme = call_613858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613858.url(scheme.get, call_613858.host, call_613858.base,
                         call_613858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613858, url, valid)

proc call*(call_613859: Call_DescribeGroups_613843; searchQuery: string;
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
  var query_613860 = newJObject()
  add(query_613860, "searchQuery", newJString(searchQuery))
  add(query_613860, "limit", newJInt(limit))
  add(query_613860, "organizationId", newJString(organizationId))
  add(query_613860, "marker", newJString(marker))
  result = call_613859.call(nil, query_613860, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_613843(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_613844,
    base: "/", url: url_DescribeGroups_613845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_613861 = ref object of OpenApiRestCall_612658
proc url_DescribeRootFolders_613863(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRootFolders_613862(path: JsonNode; query: JsonNode;
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
  var valid_613864 = query.getOrDefault("limit")
  valid_613864 = validateParameter(valid_613864, JInt, required = false, default = nil)
  if valid_613864 != nil:
    section.add "limit", valid_613864
  var valid_613865 = query.getOrDefault("marker")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "marker", valid_613865
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
  var valid_613866 = header.getOrDefault("X-Amz-Signature")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Signature", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Content-Sha256", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Date")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Date", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Credential")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Credential", valid_613869
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_613870 = header.getOrDefault("Authentication")
  valid_613870 = validateParameter(valid_613870, JString, required = true,
                                 default = nil)
  if valid_613870 != nil:
    section.add "Authentication", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Security-Token")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Security-Token", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Algorithm")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Algorithm", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-SignedHeaders", valid_613873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613874: Call_DescribeRootFolders_613861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_613874.validator(path, query, header, formData, body)
  let scheme = call_613874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613874.url(scheme.get, call_613874.host, call_613874.base,
                         call_613874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613874, url, valid)

proc call*(call_613875: Call_DescribeRootFolders_613861; limit: int = 0;
          marker: string = ""): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var query_613876 = newJObject()
  add(query_613876, "limit", newJInt(limit))
  add(query_613876, "marker", newJString(marker))
  result = call_613875.call(nil, query_613876, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_613861(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_613862, base: "/",
    url: url_DescribeRootFolders_613863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_613877 = ref object of OpenApiRestCall_612658
proc url_GetCurrentUser_613879(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentUser_613878(path: JsonNode; query: JsonNode;
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
  var valid_613880 = header.getOrDefault("X-Amz-Signature")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Signature", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Content-Sha256", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Date")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Date", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Credential")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Credential", valid_613883
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_613884 = header.getOrDefault("Authentication")
  valid_613884 = validateParameter(valid_613884, JString, required = true,
                                 default = nil)
  if valid_613884 != nil:
    section.add "Authentication", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Security-Token")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Security-Token", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Algorithm")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Algorithm", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-SignedHeaders", valid_613887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613888: Call_GetCurrentUser_613877; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_613888.validator(path, query, header, formData, body)
  let scheme = call_613888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613888.url(scheme.get, call_613888.host, call_613888.base,
                         call_613888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613888, url, valid)

proc call*(call_613889: Call_GetCurrentUser_613877): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_613889.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_613877(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_613878,
    base: "/", url: url_GetCurrentUser_613879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_613890 = ref object of OpenApiRestCall_612658
proc url_GetDocumentPath_613892(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDocumentPath_613891(path: JsonNode; query: JsonNode;
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
  var valid_613893 = path.getOrDefault("DocumentId")
  valid_613893 = validateParameter(valid_613893, JString, required = true,
                                 default = nil)
  if valid_613893 != nil:
    section.add "DocumentId", valid_613893
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_613894 = query.getOrDefault("limit")
  valid_613894 = validateParameter(valid_613894, JInt, required = false, default = nil)
  if valid_613894 != nil:
    section.add "limit", valid_613894
  var valid_613895 = query.getOrDefault("fields")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "fields", valid_613895
  var valid_613896 = query.getOrDefault("marker")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "marker", valid_613896
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
  var valid_613897 = header.getOrDefault("X-Amz-Signature")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Signature", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Content-Sha256", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Date")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Date", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Credential")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Credential", valid_613900
  var valid_613901 = header.getOrDefault("Authentication")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "Authentication", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Security-Token")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Security-Token", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Algorithm")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Algorithm", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-SignedHeaders", valid_613904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613905: Call_GetDocumentPath_613890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_613905.validator(path, query, header, formData, body)
  let scheme = call_613905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613905.url(scheme.get, call_613905.host, call_613905.base,
                         call_613905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613905, url, valid)

proc call*(call_613906: Call_GetDocumentPath_613890; DocumentId: string;
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
  var path_613907 = newJObject()
  var query_613908 = newJObject()
  add(path_613907, "DocumentId", newJString(DocumentId))
  add(query_613908, "limit", newJInt(limit))
  add(query_613908, "fields", newJString(fields))
  add(query_613908, "marker", newJString(marker))
  result = call_613906.call(path_613907, query_613908, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_613890(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_613891, base: "/", url: url_GetDocumentPath_613892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_613909 = ref object of OpenApiRestCall_612658
proc url_GetFolderPath_613911(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFolderPath_613910(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613912 = path.getOrDefault("FolderId")
  valid_613912 = validateParameter(valid_613912, JString, required = true,
                                 default = nil)
  if valid_613912 != nil:
    section.add "FolderId", valid_613912
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_613913 = query.getOrDefault("limit")
  valid_613913 = validateParameter(valid_613913, JInt, required = false, default = nil)
  if valid_613913 != nil:
    section.add "limit", valid_613913
  var valid_613914 = query.getOrDefault("fields")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "fields", valid_613914
  var valid_613915 = query.getOrDefault("marker")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "marker", valid_613915
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
  var valid_613916 = header.getOrDefault("X-Amz-Signature")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Signature", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Content-Sha256", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Date")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Date", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Credential")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Credential", valid_613919
  var valid_613920 = header.getOrDefault("Authentication")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "Authentication", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-Security-Token")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Security-Token", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-Algorithm")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-Algorithm", valid_613922
  var valid_613923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-SignedHeaders", valid_613923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613924: Call_GetFolderPath_613909; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_613924.validator(path, query, header, formData, body)
  let scheme = call_613924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613924.url(scheme.get, call_613924.host, call_613924.base,
                         call_613924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613924, url, valid)

proc call*(call_613925: Call_GetFolderPath_613909; FolderId: string; limit: int = 0;
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
  var path_613926 = newJObject()
  var query_613927 = newJObject()
  add(query_613927, "limit", newJInt(limit))
  add(path_613926, "FolderId", newJString(FolderId))
  add(query_613927, "fields", newJString(fields))
  add(query_613927, "marker", newJString(marker))
  result = call_613925.call(path_613926, query_613927, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_613909(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_613910,
    base: "/", url: url_GetFolderPath_613911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_613928 = ref object of OpenApiRestCall_612658
proc url_GetResources_613930(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_613929(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613931 = query.getOrDefault("userId")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "userId", valid_613931
  var valid_613932 = query.getOrDefault("limit")
  valid_613932 = validateParameter(valid_613932, JInt, required = false, default = nil)
  if valid_613932 != nil:
    section.add "limit", valid_613932
  var valid_613933 = query.getOrDefault("collectionType")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_613933 != nil:
    section.add "collectionType", valid_613933
  var valid_613934 = query.getOrDefault("marker")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "marker", valid_613934
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
  var valid_613935 = header.getOrDefault("X-Amz-Signature")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Signature", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Content-Sha256", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Date")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Date", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Credential")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Credential", valid_613938
  var valid_613939 = header.getOrDefault("Authentication")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "Authentication", valid_613939
  var valid_613940 = header.getOrDefault("X-Amz-Security-Token")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Security-Token", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Algorithm")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Algorithm", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-SignedHeaders", valid_613942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613943: Call_GetResources_613928; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_613943.validator(path, query, header, formData, body)
  let scheme = call_613943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613943.url(scheme.get, call_613943.host, call_613943.base,
                         call_613943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613943, url, valid)

proc call*(call_613944: Call_GetResources_613928; userId: string = ""; limit: int = 0;
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
  var query_613945 = newJObject()
  add(query_613945, "userId", newJString(userId))
  add(query_613945, "limit", newJInt(limit))
  add(query_613945, "collectionType", newJString(collectionType))
  add(query_613945, "marker", newJString(marker))
  result = call_613944.call(nil, query_613945, nil, nil, nil)

var getResources* = Call_GetResources_613928(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_613929, base: "/",
    url: url_GetResources_613930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_613946 = ref object of OpenApiRestCall_612658
proc url_InitiateDocumentVersionUpload_613948(protocol: Scheme; host: string;
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

proc validate_InitiateDocumentVersionUpload_613947(path: JsonNode; query: JsonNode;
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
  var valid_613949 = header.getOrDefault("X-Amz-Signature")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Signature", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Content-Sha256", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Date")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Date", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Credential")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Credential", valid_613952
  var valid_613953 = header.getOrDefault("Authentication")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "Authentication", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Security-Token")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Security-Token", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Algorithm")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Algorithm", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-SignedHeaders", valid_613956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613958: Call_InitiateDocumentVersionUpload_613946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_613958.validator(path, query, header, formData, body)
  let scheme = call_613958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613958.url(scheme.get, call_613958.host, call_613958.base,
                         call_613958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613958, url, valid)

proc call*(call_613959: Call_InitiateDocumentVersionUpload_613946; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_613960 = newJObject()
  if body != nil:
    body_613960 = body
  result = call_613959.call(nil, nil, nil, nil, body_613960)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_613946(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_613947, base: "/",
    url: url_InitiateDocumentVersionUpload_613948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_613961 = ref object of OpenApiRestCall_612658
proc url_RemoveResourcePermission_613963(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveResourcePermission_613962(path: JsonNode; query: JsonNode;
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
  var valid_613964 = path.getOrDefault("ResourceId")
  valid_613964 = validateParameter(valid_613964, JString, required = true,
                                 default = nil)
  if valid_613964 != nil:
    section.add "ResourceId", valid_613964
  var valid_613965 = path.getOrDefault("PrincipalId")
  valid_613965 = validateParameter(valid_613965, JString, required = true,
                                 default = nil)
  if valid_613965 != nil:
    section.add "PrincipalId", valid_613965
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_613966 = query.getOrDefault("type")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = newJString("USER"))
  if valid_613966 != nil:
    section.add "type", valid_613966
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
  var valid_613967 = header.getOrDefault("X-Amz-Signature")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Signature", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Content-Sha256", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Date")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Date", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Credential")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Credential", valid_613970
  var valid_613971 = header.getOrDefault("Authentication")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "Authentication", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-Security-Token")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-Security-Token", valid_613972
  var valid_613973 = header.getOrDefault("X-Amz-Algorithm")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Algorithm", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-SignedHeaders", valid_613974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613975: Call_RemoveResourcePermission_613961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_613975.validator(path, query, header, formData, body)
  let scheme = call_613975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613975.url(scheme.get, call_613975.host, call_613975.base,
                         call_613975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613975, url, valid)

proc call*(call_613976: Call_RemoveResourcePermission_613961; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_613977 = newJObject()
  var query_613978 = newJObject()
  add(path_613977, "ResourceId", newJString(ResourceId))
  add(query_613978, "type", newJString(`type`))
  add(path_613977, "PrincipalId", newJString(PrincipalId))
  result = call_613976.call(path_613977, query_613978, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_613961(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_613962, base: "/",
    url: url_RemoveResourcePermission_613963, schemes: {Scheme.Https, Scheme.Http})
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
