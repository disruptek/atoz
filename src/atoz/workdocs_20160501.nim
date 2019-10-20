
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetDocumentVersion_592703 = ref object of OpenApiRestCall_592364
proc url_GetDocumentVersion_592705(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDocumentVersion_592704(path: JsonNode; query: JsonNode;
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
  var valid_592831 = path.getOrDefault("VersionId")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "VersionId", valid_592831
  var valid_592832 = path.getOrDefault("DocumentId")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = nil)
  if valid_592832 != nil:
    section.add "DocumentId", valid_592832
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  section = newJObject()
  var valid_592833 = query.getOrDefault("includeCustomMetadata")
  valid_592833 = validateParameter(valid_592833, JBool, required = false, default = nil)
  if valid_592833 != nil:
    section.add "includeCustomMetadata", valid_592833
  var valid_592834 = query.getOrDefault("fields")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "fields", valid_592834
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
  var valid_592835 = header.getOrDefault("X-Amz-Signature")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Signature", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Content-Sha256", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Date")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Date", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Credential")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Credential", valid_592838
  var valid_592839 = header.getOrDefault("Authentication")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "Authentication", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-Security-Token")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-Security-Token", valid_592840
  var valid_592841 = header.getOrDefault("X-Amz-Algorithm")
  valid_592841 = validateParameter(valid_592841, JString, required = false,
                                 default = nil)
  if valid_592841 != nil:
    section.add "X-Amz-Algorithm", valid_592841
  var valid_592842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592842 = validateParameter(valid_592842, JString, required = false,
                                 default = nil)
  if valid_592842 != nil:
    section.add "X-Amz-SignedHeaders", valid_592842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592865: Call_GetDocumentVersion_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_592865.validator(path, query, header, formData, body)
  let scheme = call_592865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592865.url(scheme.get, call_592865.host, call_592865.base,
                         call_592865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592865, url, valid)

proc call*(call_592936: Call_GetDocumentVersion_592703; VersionId: string;
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
  var path_592937 = newJObject()
  var query_592939 = newJObject()
  add(path_592937, "VersionId", newJString(VersionId))
  add(path_592937, "DocumentId", newJString(DocumentId))
  add(query_592939, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(query_592939, "fields", newJString(fields))
  result = call_592936.call(path_592937, query_592939, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_592703(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_592704, base: "/",
    url: url_GetDocumentVersion_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_592994 = ref object of OpenApiRestCall_592364
proc url_UpdateDocumentVersion_592996(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDocumentVersion_592995(path: JsonNode; query: JsonNode;
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
  var valid_592997 = path.getOrDefault("VersionId")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "VersionId", valid_592997
  var valid_592998 = path.getOrDefault("DocumentId")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = nil)
  if valid_592998 != nil:
    section.add "DocumentId", valid_592998
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
  var valid_592999 = header.getOrDefault("X-Amz-Signature")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Signature", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Content-Sha256", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Date")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Date", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Credential")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Credential", valid_593002
  var valid_593003 = header.getOrDefault("Authentication")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "Authentication", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Security-Token")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Security-Token", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Algorithm")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Algorithm", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-SignedHeaders", valid_593006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593008: Call_UpdateDocumentVersion_592994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_593008.validator(path, query, header, formData, body)
  let scheme = call_593008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593008.url(scheme.get, call_593008.host, call_593008.base,
                         call_593008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593008, url, valid)

proc call*(call_593009: Call_UpdateDocumentVersion_592994; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_593010 = newJObject()
  var body_593011 = newJObject()
  add(path_593010, "VersionId", newJString(VersionId))
  add(path_593010, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_593011 = body
  result = call_593009.call(path_593010, nil, nil, nil, body_593011)

var updateDocumentVersion* = Call_UpdateDocumentVersion_592994(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_592995, base: "/",
    url: url_UpdateDocumentVersion_592996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_592978 = ref object of OpenApiRestCall_592364
proc url_AbortDocumentVersionUpload_592980(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_AbortDocumentVersionUpload_592979(path: JsonNode; query: JsonNode;
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
  var valid_592981 = path.getOrDefault("VersionId")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "VersionId", valid_592981
  var valid_592982 = path.getOrDefault("DocumentId")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = nil)
  if valid_592982 != nil:
    section.add "DocumentId", valid_592982
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
  var valid_592983 = header.getOrDefault("X-Amz-Signature")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Signature", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Content-Sha256", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Date")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Date", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Credential")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Credential", valid_592986
  var valid_592987 = header.getOrDefault("Authentication")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "Authentication", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Security-Token")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Security-Token", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Algorithm")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Algorithm", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-SignedHeaders", valid_592990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592991: Call_AbortDocumentVersionUpload_592978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_592991.validator(path, query, header, formData, body)
  let scheme = call_592991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592991.url(scheme.get, call_592991.host, call_592991.base,
                         call_592991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592991, url, valid)

proc call*(call_592992: Call_AbortDocumentVersionUpload_592978; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_592993 = newJObject()
  add(path_592993, "VersionId", newJString(VersionId))
  add(path_592993, "DocumentId", newJString(DocumentId))
  result = call_592992.call(path_592993, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_592978(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_592979, base: "/",
    url: url_AbortDocumentVersionUpload_592980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_593012 = ref object of OpenApiRestCall_592364
proc url_ActivateUser_593014(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ActivateUser_593013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593015 = path.getOrDefault("UserId")
  valid_593015 = validateParameter(valid_593015, JString, required = true,
                                 default = nil)
  if valid_593015 != nil:
    section.add "UserId", valid_593015
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
  var valid_593016 = header.getOrDefault("X-Amz-Signature")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Signature", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Content-Sha256", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Date")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Date", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Credential")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Credential", valid_593019
  var valid_593020 = header.getOrDefault("Authentication")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "Authentication", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Security-Token")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Security-Token", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Algorithm")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Algorithm", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-SignedHeaders", valid_593023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593024: Call_ActivateUser_593012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_593024.validator(path, query, header, formData, body)
  let scheme = call_593024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593024.url(scheme.get, call_593024.host, call_593024.base,
                         call_593024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593024, url, valid)

proc call*(call_593025: Call_ActivateUser_593012; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_593026 = newJObject()
  add(path_593026, "UserId", newJString(UserId))
  result = call_593025.call(path_593026, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_593012(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_593013,
    base: "/", url: url_ActivateUser_593014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_593027 = ref object of OpenApiRestCall_592364
proc url_DeactivateUser_593029(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeactivateUser_593028(path: JsonNode; query: JsonNode;
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
  var valid_593030 = path.getOrDefault("UserId")
  valid_593030 = validateParameter(valid_593030, JString, required = true,
                                 default = nil)
  if valid_593030 != nil:
    section.add "UserId", valid_593030
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
  var valid_593031 = header.getOrDefault("X-Amz-Signature")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Signature", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Content-Sha256", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Date")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Date", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Credential")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Credential", valid_593034
  var valid_593035 = header.getOrDefault("Authentication")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "Authentication", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Security-Token")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Security-Token", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Algorithm")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Algorithm", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-SignedHeaders", valid_593038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593039: Call_DeactivateUser_593027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_593039.validator(path, query, header, formData, body)
  let scheme = call_593039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593039.url(scheme.get, call_593039.host, call_593039.base,
                         call_593039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593039, url, valid)

proc call*(call_593040: Call_DeactivateUser_593027; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_593041 = newJObject()
  add(path_593041, "UserId", newJString(UserId))
  result = call_593040.call(path_593041, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_593027(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_593028, base: "/", url: url_DeactivateUser_593029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_593061 = ref object of OpenApiRestCall_592364
proc url_AddResourcePermissions_593063(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_AddResourcePermissions_593062(path: JsonNode; query: JsonNode;
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
  var valid_593064 = path.getOrDefault("ResourceId")
  valid_593064 = validateParameter(valid_593064, JString, required = true,
                                 default = nil)
  if valid_593064 != nil:
    section.add "ResourceId", valid_593064
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
  var valid_593065 = header.getOrDefault("X-Amz-Signature")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Signature", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Content-Sha256", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Date")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Date", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Credential")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Credential", valid_593068
  var valid_593069 = header.getOrDefault("Authentication")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "Authentication", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_AddResourcePermissions_593061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_AddResourcePermissions_593061; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_593076 = newJObject()
  var body_593077 = newJObject()
  add(path_593076, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_593077 = body
  result = call_593075.call(path_593076, nil, nil, nil, body_593077)

var addResourcePermissions* = Call_AddResourcePermissions_593061(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_593062, base: "/",
    url: url_AddResourcePermissions_593063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_593042 = ref object of OpenApiRestCall_592364
proc url_DescribeResourcePermissions_593044(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeResourcePermissions_593043(path: JsonNode; query: JsonNode;
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
  var valid_593045 = path.getOrDefault("ResourceId")
  valid_593045 = validateParameter(valid_593045, JString, required = true,
                                 default = nil)
  if valid_593045 != nil:
    section.add "ResourceId", valid_593045
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  section = newJObject()
  var valid_593046 = query.getOrDefault("limit")
  valid_593046 = validateParameter(valid_593046, JInt, required = false, default = nil)
  if valid_593046 != nil:
    section.add "limit", valid_593046
  var valid_593047 = query.getOrDefault("principalId")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "principalId", valid_593047
  var valid_593048 = query.getOrDefault("marker")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "marker", valid_593048
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
  var valid_593049 = header.getOrDefault("X-Amz-Signature")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Signature", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Content-Sha256", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Date")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Date", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Credential")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Credential", valid_593052
  var valid_593053 = header.getOrDefault("Authentication")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "Authentication", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Security-Token")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Security-Token", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Algorithm")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Algorithm", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-SignedHeaders", valid_593056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593057: Call_DescribeResourcePermissions_593042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_593057.validator(path, query, header, formData, body)
  let scheme = call_593057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593057.url(scheme.get, call_593057.host, call_593057.base,
                         call_593057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593057, url, valid)

proc call*(call_593058: Call_DescribeResourcePermissions_593042;
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
  var path_593059 = newJObject()
  var query_593060 = newJObject()
  add(query_593060, "limit", newJInt(limit))
  add(path_593059, "ResourceId", newJString(ResourceId))
  add(query_593060, "principalId", newJString(principalId))
  add(query_593060, "marker", newJString(marker))
  result = call_593058.call(path_593059, query_593060, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_593042(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_593043, base: "/",
    url: url_DescribeResourcePermissions_593044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_593078 = ref object of OpenApiRestCall_592364
proc url_RemoveAllResourcePermissions_593080(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_RemoveAllResourcePermissions_593079(path: JsonNode; query: JsonNode;
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
  var valid_593081 = path.getOrDefault("ResourceId")
  valid_593081 = validateParameter(valid_593081, JString, required = true,
                                 default = nil)
  if valid_593081 != nil:
    section.add "ResourceId", valid_593081
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
  var valid_593082 = header.getOrDefault("X-Amz-Signature")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Signature", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Content-Sha256", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Date")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Date", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Credential")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Credential", valid_593085
  var valid_593086 = header.getOrDefault("Authentication")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "Authentication", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Security-Token")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Security-Token", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Algorithm")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Algorithm", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-SignedHeaders", valid_593089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593090: Call_RemoveAllResourcePermissions_593078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_593090.validator(path, query, header, formData, body)
  let scheme = call_593090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593090.url(scheme.get, call_593090.host, call_593090.base,
                         call_593090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593090, url, valid)

proc call*(call_593091: Call_RemoveAllResourcePermissions_593078;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_593092 = newJObject()
  add(path_593092, "ResourceId", newJString(ResourceId))
  result = call_593091.call(path_593092, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_593078(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_593079, base: "/",
    url: url_RemoveAllResourcePermissions_593080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_593093 = ref object of OpenApiRestCall_592364
proc url_CreateComment_593095(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateComment_593094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593096 = path.getOrDefault("VersionId")
  valid_593096 = validateParameter(valid_593096, JString, required = true,
                                 default = nil)
  if valid_593096 != nil:
    section.add "VersionId", valid_593096
  var valid_593097 = path.getOrDefault("DocumentId")
  valid_593097 = validateParameter(valid_593097, JString, required = true,
                                 default = nil)
  if valid_593097 != nil:
    section.add "DocumentId", valid_593097
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
  var valid_593098 = header.getOrDefault("X-Amz-Signature")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Signature", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Content-Sha256", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Date")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Date", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Credential")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Credential", valid_593101
  var valid_593102 = header.getOrDefault("Authentication")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "Authentication", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Security-Token")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Security-Token", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Algorithm")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Algorithm", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-SignedHeaders", valid_593105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593107: Call_CreateComment_593093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_593107.validator(path, query, header, formData, body)
  let scheme = call_593107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593107.url(scheme.get, call_593107.host, call_593107.base,
                         call_593107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593107, url, valid)

proc call*(call_593108: Call_CreateComment_593093; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_593109 = newJObject()
  var body_593110 = newJObject()
  add(path_593109, "VersionId", newJString(VersionId))
  add(path_593109, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_593110 = body
  result = call_593108.call(path_593109, nil, nil, nil, body_593110)

var createComment* = Call_CreateComment_593093(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_593094, base: "/", url: url_CreateComment_593095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_593111 = ref object of OpenApiRestCall_592364
proc url_CreateCustomMetadata_593113(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateCustomMetadata_593112(path: JsonNode; query: JsonNode;
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
  var valid_593114 = path.getOrDefault("ResourceId")
  valid_593114 = validateParameter(valid_593114, JString, required = true,
                                 default = nil)
  if valid_593114 != nil:
    section.add "ResourceId", valid_593114
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_593115 = query.getOrDefault("versionid")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "versionid", valid_593115
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
  var valid_593116 = header.getOrDefault("X-Amz-Signature")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Signature", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Content-Sha256", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Date")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Date", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Credential")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Credential", valid_593119
  var valid_593120 = header.getOrDefault("Authentication")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "Authentication", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593125: Call_CreateCustomMetadata_593111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_593125.validator(path, query, header, formData, body)
  let scheme = call_593125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593125.url(scheme.get, call_593125.host, call_593125.base,
                         call_593125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593125, url, valid)

proc call*(call_593126: Call_CreateCustomMetadata_593111; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_593127 = newJObject()
  var query_593128 = newJObject()
  var body_593129 = newJObject()
  add(query_593128, "versionid", newJString(versionid))
  add(path_593127, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_593129 = body
  result = call_593126.call(path_593127, query_593128, nil, nil, body_593129)

var createCustomMetadata* = Call_CreateCustomMetadata_593111(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_593112, base: "/",
    url: url_CreateCustomMetadata_593113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_593130 = ref object of OpenApiRestCall_592364
proc url_DeleteCustomMetadata_593132(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteCustomMetadata_593131(path: JsonNode; query: JsonNode;
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
  var valid_593133 = path.getOrDefault("ResourceId")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = nil)
  if valid_593133 != nil:
    section.add "ResourceId", valid_593133
  result.add "path", section
  ## parameters in `query` object:
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  section = newJObject()
  var valid_593134 = query.getOrDefault("deleteAll")
  valid_593134 = validateParameter(valid_593134, JBool, required = false, default = nil)
  if valid_593134 != nil:
    section.add "deleteAll", valid_593134
  var valid_593135 = query.getOrDefault("keys")
  valid_593135 = validateParameter(valid_593135, JArray, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "keys", valid_593135
  var valid_593136 = query.getOrDefault("versionId")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "versionId", valid_593136
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
  var valid_593137 = header.getOrDefault("X-Amz-Signature")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Signature", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Content-Sha256", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Date")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Date", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Credential")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Credential", valid_593140
  var valid_593141 = header.getOrDefault("Authentication")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "Authentication", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Security-Token")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Security-Token", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Algorithm")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Algorithm", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-SignedHeaders", valid_593144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593145: Call_DeleteCustomMetadata_593130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_593145.validator(path, query, header, formData, body)
  let scheme = call_593145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593145.url(scheme.get, call_593145.host, call_593145.base,
                         call_593145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593145, url, valid)

proc call*(call_593146: Call_DeleteCustomMetadata_593130; ResourceId: string;
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
  var path_593147 = newJObject()
  var query_593148 = newJObject()
  add(query_593148, "deleteAll", newJBool(deleteAll))
  add(path_593147, "ResourceId", newJString(ResourceId))
  if keys != nil:
    query_593148.add "keys", keys
  add(query_593148, "versionId", newJString(versionId))
  result = call_593146.call(path_593147, query_593148, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_593130(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_593131, base: "/",
    url: url_DeleteCustomMetadata_593132, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_593149 = ref object of OpenApiRestCall_592364
proc url_CreateFolder_593151(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFolder_593150(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593152 = header.getOrDefault("X-Amz-Signature")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Signature", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Content-Sha256", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Date")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Date", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Credential")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Credential", valid_593155
  var valid_593156 = header.getOrDefault("Authentication")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "Authentication", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Security-Token")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Security-Token", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Algorithm")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Algorithm", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-SignedHeaders", valid_593159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593161: Call_CreateFolder_593149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_593161.validator(path, query, header, formData, body)
  let scheme = call_593161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593161.url(scheme.get, call_593161.host, call_593161.base,
                         call_593161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593161, url, valid)

proc call*(call_593162: Call_CreateFolder_593149; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_593163 = newJObject()
  if body != nil:
    body_593163 = body
  result = call_593162.call(nil, nil, nil, nil, body_593163)

var createFolder* = Call_CreateFolder_593149(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_593150, base: "/",
    url: url_CreateFolder_593151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_593164 = ref object of OpenApiRestCall_592364
proc url_CreateLabels_593166(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateLabels_593165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593167 = path.getOrDefault("ResourceId")
  valid_593167 = validateParameter(valid_593167, JString, required = true,
                                 default = nil)
  if valid_593167 != nil:
    section.add "ResourceId", valid_593167
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
  var valid_593168 = header.getOrDefault("X-Amz-Signature")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Signature", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Content-Sha256", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Date")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Date", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Credential")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Credential", valid_593171
  var valid_593172 = header.getOrDefault("Authentication")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "Authentication", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Security-Token")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Security-Token", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Algorithm")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Algorithm", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-SignedHeaders", valid_593175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593177: Call_CreateLabels_593164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_593177.validator(path, query, header, formData, body)
  let scheme = call_593177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593177.url(scheme.get, call_593177.host, call_593177.base,
                         call_593177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593177, url, valid)

proc call*(call_593178: Call_CreateLabels_593164; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_593179 = newJObject()
  var body_593180 = newJObject()
  add(path_593179, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_593180 = body
  result = call_593178.call(path_593179, nil, nil, nil, body_593180)

var createLabels* = Call_CreateLabels_593164(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_593165, base: "/", url: url_CreateLabels_593166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_593181 = ref object of OpenApiRestCall_592364
proc url_DeleteLabels_593183(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteLabels_593182(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593184 = path.getOrDefault("ResourceId")
  valid_593184 = validateParameter(valid_593184, JString, required = true,
                                 default = nil)
  if valid_593184 != nil:
    section.add "ResourceId", valid_593184
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_593185 = query.getOrDefault("labels")
  valid_593185 = validateParameter(valid_593185, JArray, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "labels", valid_593185
  var valid_593186 = query.getOrDefault("deleteAll")
  valid_593186 = validateParameter(valid_593186, JBool, required = false, default = nil)
  if valid_593186 != nil:
    section.add "deleteAll", valid_593186
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
  var valid_593187 = header.getOrDefault("X-Amz-Signature")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Signature", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Content-Sha256", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Date")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Date", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Credential")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Credential", valid_593190
  var valid_593191 = header.getOrDefault("Authentication")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "Authentication", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Security-Token")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Security-Token", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Algorithm")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Algorithm", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-SignedHeaders", valid_593194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593195: Call_DeleteLabels_593181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_593195.validator(path, query, header, formData, body)
  let scheme = call_593195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593195.url(scheme.get, call_593195.host, call_593195.base,
                         call_593195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593195, url, valid)

proc call*(call_593196: Call_DeleteLabels_593181; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_593197 = newJObject()
  var query_593198 = newJObject()
  if labels != nil:
    query_593198.add "labels", labels
  add(query_593198, "deleteAll", newJBool(deleteAll))
  add(path_593197, "ResourceId", newJString(ResourceId))
  result = call_593196.call(path_593197, query_593198, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_593181(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_593182, base: "/", url: url_DeleteLabels_593183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_593216 = ref object of OpenApiRestCall_592364
proc url_CreateNotificationSubscription_593218(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_CreateNotificationSubscription_593217(path: JsonNode;
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
  var valid_593219 = path.getOrDefault("OrganizationId")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "OrganizationId", valid_593219
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
  var valid_593220 = header.getOrDefault("X-Amz-Signature")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Signature", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Content-Sha256", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Date")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Date", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Credential")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Credential", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Security-Token")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Security-Token", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Algorithm")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Algorithm", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-SignedHeaders", valid_593226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593228: Call_CreateNotificationSubscription_593216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_593228.validator(path, query, header, formData, body)
  let scheme = call_593228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593228.url(scheme.get, call_593228.host, call_593228.base,
                         call_593228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593228, url, valid)

proc call*(call_593229: Call_CreateNotificationSubscription_593216;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_593230 = newJObject()
  var body_593231 = newJObject()
  add(path_593230, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_593231 = body
  result = call_593229.call(path_593230, nil, nil, nil, body_593231)

var createNotificationSubscription* = Call_CreateNotificationSubscription_593216(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_593217, base: "/",
    url: url_CreateNotificationSubscription_593218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_593199 = ref object of OpenApiRestCall_592364
proc url_DescribeNotificationSubscriptions_593201(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeNotificationSubscriptions_593200(path: JsonNode;
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
  var valid_593202 = path.getOrDefault("OrganizationId")
  valid_593202 = validateParameter(valid_593202, JString, required = true,
                                 default = nil)
  if valid_593202 != nil:
    section.add "OrganizationId", valid_593202
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_593203 = query.getOrDefault("limit")
  valid_593203 = validateParameter(valid_593203, JInt, required = false, default = nil)
  if valid_593203 != nil:
    section.add "limit", valid_593203
  var valid_593204 = query.getOrDefault("marker")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "marker", valid_593204
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
  var valid_593205 = header.getOrDefault("X-Amz-Signature")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Signature", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Content-Sha256", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Date")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Date", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Credential")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Credential", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Security-Token")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Security-Token", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Algorithm")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Algorithm", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-SignedHeaders", valid_593211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593212: Call_DescribeNotificationSubscriptions_593199;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_593212.validator(path, query, header, formData, body)
  let scheme = call_593212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593212.url(scheme.get, call_593212.host, call_593212.base,
                         call_593212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593212, url, valid)

proc call*(call_593213: Call_DescribeNotificationSubscriptions_593199;
          OrganizationId: string; limit: int = 0; marker: string = ""): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var path_593214 = newJObject()
  var query_593215 = newJObject()
  add(path_593214, "OrganizationId", newJString(OrganizationId))
  add(query_593215, "limit", newJInt(limit))
  add(query_593215, "marker", newJString(marker))
  result = call_593213.call(path_593214, query_593215, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_593199(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_593200, base: "/",
    url: url_DescribeNotificationSubscriptions_593201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_593270 = ref object of OpenApiRestCall_592364
proc url_CreateUser_593272(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUser_593271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593273 = header.getOrDefault("X-Amz-Signature")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Signature", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Content-Sha256", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Date")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Date", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Credential")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Credential", valid_593276
  var valid_593277 = header.getOrDefault("Authentication")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "Authentication", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Security-Token")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Security-Token", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Algorithm")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Algorithm", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-SignedHeaders", valid_593280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593282: Call_CreateUser_593270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_593282.validator(path, query, header, formData, body)
  let scheme = call_593282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593282.url(scheme.get, call_593282.host, call_593282.base,
                         call_593282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593282, url, valid)

proc call*(call_593283: Call_CreateUser_593270; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_593284 = newJObject()
  if body != nil:
    body_593284 = body
  result = call_593283.call(nil, nil, nil, nil, body_593284)

var createUser* = Call_CreateUser_593270(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_593271,
                                      base: "/", url: url_CreateUser_593272,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_593232 = ref object of OpenApiRestCall_592364
proc url_DescribeUsers_593234(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUsers_593233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593248 = query.getOrDefault("sort")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_593248 != nil:
    section.add "sort", valid_593248
  var valid_593249 = query.getOrDefault("Marker")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "Marker", valid_593249
  var valid_593250 = query.getOrDefault("order")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_593250 != nil:
    section.add "order", valid_593250
  var valid_593251 = query.getOrDefault("limit")
  valid_593251 = validateParameter(valid_593251, JInt, required = false, default = nil)
  if valid_593251 != nil:
    section.add "limit", valid_593251
  var valid_593252 = query.getOrDefault("Limit")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "Limit", valid_593252
  var valid_593253 = query.getOrDefault("userIds")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "userIds", valid_593253
  var valid_593254 = query.getOrDefault("include")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = newJString("ALL"))
  if valid_593254 != nil:
    section.add "include", valid_593254
  var valid_593255 = query.getOrDefault("query")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "query", valid_593255
  var valid_593256 = query.getOrDefault("organizationId")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "organizationId", valid_593256
  var valid_593257 = query.getOrDefault("fields")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "fields", valid_593257
  var valid_593258 = query.getOrDefault("marker")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "marker", valid_593258
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
  var valid_593259 = header.getOrDefault("X-Amz-Signature")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Signature", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Content-Sha256", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Date")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Date", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Credential")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Credential", valid_593262
  var valid_593263 = header.getOrDefault("Authentication")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "Authentication", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Security-Token")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Security-Token", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Algorithm")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Algorithm", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-SignedHeaders", valid_593266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593267: Call_DescribeUsers_593232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_593267.validator(path, query, header, formData, body)
  let scheme = call_593267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593267.url(scheme.get, call_593267.host, call_593267.base,
                         call_593267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593267, url, valid)

proc call*(call_593268: Call_DescribeUsers_593232; sort: string = "USER_NAME";
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
  var query_593269 = newJObject()
  add(query_593269, "sort", newJString(sort))
  add(query_593269, "Marker", newJString(Marker))
  add(query_593269, "order", newJString(order))
  add(query_593269, "limit", newJInt(limit))
  add(query_593269, "Limit", newJString(Limit))
  add(query_593269, "userIds", newJString(userIds))
  add(query_593269, "include", newJString(`include`))
  add(query_593269, "query", newJString(query))
  add(query_593269, "organizationId", newJString(organizationId))
  add(query_593269, "fields", newJString(fields))
  add(query_593269, "marker", newJString(marker))
  result = call_593268.call(nil, query_593269, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_593232(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_593233, base: "/",
    url: url_DescribeUsers_593234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_593285 = ref object of OpenApiRestCall_592364
proc url_DeleteComment_593287(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteComment_593286(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593288 = path.getOrDefault("VersionId")
  valid_593288 = validateParameter(valid_593288, JString, required = true,
                                 default = nil)
  if valid_593288 != nil:
    section.add "VersionId", valid_593288
  var valid_593289 = path.getOrDefault("DocumentId")
  valid_593289 = validateParameter(valid_593289, JString, required = true,
                                 default = nil)
  if valid_593289 != nil:
    section.add "DocumentId", valid_593289
  var valid_593290 = path.getOrDefault("CommentId")
  valid_593290 = validateParameter(valid_593290, JString, required = true,
                                 default = nil)
  if valid_593290 != nil:
    section.add "CommentId", valid_593290
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
  var valid_593291 = header.getOrDefault("X-Amz-Signature")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Signature", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Content-Sha256", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Date")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Date", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Credential")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Credential", valid_593294
  var valid_593295 = header.getOrDefault("Authentication")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "Authentication", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Security-Token")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Security-Token", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Algorithm")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Algorithm", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-SignedHeaders", valid_593298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593299: Call_DeleteComment_593285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_593299.validator(path, query, header, formData, body)
  let scheme = call_593299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593299.url(scheme.get, call_593299.host, call_593299.base,
                         call_593299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593299, url, valid)

proc call*(call_593300: Call_DeleteComment_593285; VersionId: string;
          DocumentId: string; CommentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  var path_593301 = newJObject()
  add(path_593301, "VersionId", newJString(VersionId))
  add(path_593301, "DocumentId", newJString(DocumentId))
  add(path_593301, "CommentId", newJString(CommentId))
  result = call_593300.call(path_593301, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_593285(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_593286, base: "/", url: url_DeleteComment_593287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_593302 = ref object of OpenApiRestCall_592364
proc url_GetDocument_593304(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDocument_593303(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593305 = path.getOrDefault("DocumentId")
  valid_593305 = validateParameter(valid_593305, JString, required = true,
                                 default = nil)
  if valid_593305 != nil:
    section.add "DocumentId", valid_593305
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_593306 = query.getOrDefault("includeCustomMetadata")
  valid_593306 = validateParameter(valid_593306, JBool, required = false, default = nil)
  if valid_593306 != nil:
    section.add "includeCustomMetadata", valid_593306
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
  var valid_593307 = header.getOrDefault("X-Amz-Signature")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Signature", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Content-Sha256", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Date")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Date", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Credential")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Credential", valid_593310
  var valid_593311 = header.getOrDefault("Authentication")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "Authentication", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Security-Token")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Security-Token", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Algorithm")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Algorithm", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-SignedHeaders", valid_593314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593315: Call_GetDocument_593302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_593315.validator(path, query, header, formData, body)
  let scheme = call_593315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593315.url(scheme.get, call_593315.host, call_593315.base,
                         call_593315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593315, url, valid)

proc call*(call_593316: Call_GetDocument_593302; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  var path_593317 = newJObject()
  var query_593318 = newJObject()
  add(path_593317, "DocumentId", newJString(DocumentId))
  add(query_593318, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_593316.call(path_593317, query_593318, nil, nil, nil)

var getDocument* = Call_GetDocument_593302(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_593303,
                                        base: "/", url: url_GetDocument_593304,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_593334 = ref object of OpenApiRestCall_592364
proc url_UpdateDocument_593336(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDocument_593335(path: JsonNode; query: JsonNode;
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
  var valid_593337 = path.getOrDefault("DocumentId")
  valid_593337 = validateParameter(valid_593337, JString, required = true,
                                 default = nil)
  if valid_593337 != nil:
    section.add "DocumentId", valid_593337
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
  var valid_593338 = header.getOrDefault("X-Amz-Signature")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Signature", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Content-Sha256", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Date")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Date", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Credential")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Credential", valid_593341
  var valid_593342 = header.getOrDefault("Authentication")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "Authentication", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Security-Token")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Security-Token", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Algorithm")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Algorithm", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-SignedHeaders", valid_593345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593347: Call_UpdateDocument_593334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_593347.validator(path, query, header, formData, body)
  let scheme = call_593347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593347.url(scheme.get, call_593347.host, call_593347.base,
                         call_593347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593347, url, valid)

proc call*(call_593348: Call_UpdateDocument_593334; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_593349 = newJObject()
  var body_593350 = newJObject()
  add(path_593349, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_593350 = body
  result = call_593348.call(path_593349, nil, nil, nil, body_593350)

var updateDocument* = Call_UpdateDocument_593334(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_593335,
    base: "/", url: url_UpdateDocument_593336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_593319 = ref object of OpenApiRestCall_592364
proc url_DeleteDocument_593321(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDocument_593320(path: JsonNode; query: JsonNode;
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
  var valid_593322 = path.getOrDefault("DocumentId")
  valid_593322 = validateParameter(valid_593322, JString, required = true,
                                 default = nil)
  if valid_593322 != nil:
    section.add "DocumentId", valid_593322
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
  var valid_593323 = header.getOrDefault("X-Amz-Signature")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Signature", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Content-Sha256", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Date")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Date", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Credential")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Credential", valid_593326
  var valid_593327 = header.getOrDefault("Authentication")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "Authentication", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Security-Token")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Security-Token", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-Algorithm")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Algorithm", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-SignedHeaders", valid_593330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593331: Call_DeleteDocument_593319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_593331.validator(path, query, header, formData, body)
  let scheme = call_593331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593331.url(scheme.get, call_593331.host, call_593331.base,
                         call_593331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593331, url, valid)

proc call*(call_593332: Call_DeleteDocument_593319; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_593333 = newJObject()
  add(path_593333, "DocumentId", newJString(DocumentId))
  result = call_593332.call(path_593333, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_593319(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_593320,
    base: "/", url: url_DeleteDocument_593321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_593351 = ref object of OpenApiRestCall_592364
proc url_GetFolder_593353(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetFolder_593352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593354 = path.getOrDefault("FolderId")
  valid_593354 = validateParameter(valid_593354, JString, required = true,
                                 default = nil)
  if valid_593354 != nil:
    section.add "FolderId", valid_593354
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_593355 = query.getOrDefault("includeCustomMetadata")
  valid_593355 = validateParameter(valid_593355, JBool, required = false, default = nil)
  if valid_593355 != nil:
    section.add "includeCustomMetadata", valid_593355
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
  var valid_593356 = header.getOrDefault("X-Amz-Signature")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Signature", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Content-Sha256", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Date")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Date", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Credential")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Credential", valid_593359
  var valid_593360 = header.getOrDefault("Authentication")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "Authentication", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-Security-Token")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-Security-Token", valid_593361
  var valid_593362 = header.getOrDefault("X-Amz-Algorithm")
  valid_593362 = validateParameter(valid_593362, JString, required = false,
                                 default = nil)
  if valid_593362 != nil:
    section.add "X-Amz-Algorithm", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-SignedHeaders", valid_593363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593364: Call_GetFolder_593351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_593364.validator(path, query, header, formData, body)
  let scheme = call_593364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593364.url(scheme.get, call_593364.host, call_593364.base,
                         call_593364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593364, url, valid)

proc call*(call_593365: Call_GetFolder_593351; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_593366 = newJObject()
  var query_593367 = newJObject()
  add(query_593367, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_593366, "FolderId", newJString(FolderId))
  result = call_593365.call(path_593366, query_593367, nil, nil, nil)

var getFolder* = Call_GetFolder_593351(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_593352,
                                    base: "/", url: url_GetFolder_593353,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_593383 = ref object of OpenApiRestCall_592364
proc url_UpdateFolder_593385(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateFolder_593384(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593386 = path.getOrDefault("FolderId")
  valid_593386 = validateParameter(valid_593386, JString, required = true,
                                 default = nil)
  if valid_593386 != nil:
    section.add "FolderId", valid_593386
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
  var valid_593387 = header.getOrDefault("X-Amz-Signature")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Signature", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Content-Sha256", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Date")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Date", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Credential")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Credential", valid_593390
  var valid_593391 = header.getOrDefault("Authentication")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "Authentication", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Security-Token")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Security-Token", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Algorithm")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Algorithm", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-SignedHeaders", valid_593394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593396: Call_UpdateFolder_593383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_593396.validator(path, query, header, formData, body)
  let scheme = call_593396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593396.url(scheme.get, call_593396.host, call_593396.base,
                         call_593396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593396, url, valid)

proc call*(call_593397: Call_UpdateFolder_593383; body: JsonNode; FolderId: string): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   body: JObject (required)
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_593398 = newJObject()
  var body_593399 = newJObject()
  if body != nil:
    body_593399 = body
  add(path_593398, "FolderId", newJString(FolderId))
  result = call_593397.call(path_593398, nil, nil, nil, body_593399)

var updateFolder* = Call_UpdateFolder_593383(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_593384,
    base: "/", url: url_UpdateFolder_593385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_593368 = ref object of OpenApiRestCall_592364
proc url_DeleteFolder_593370(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteFolder_593369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593371 = path.getOrDefault("FolderId")
  valid_593371 = validateParameter(valid_593371, JString, required = true,
                                 default = nil)
  if valid_593371 != nil:
    section.add "FolderId", valid_593371
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
  var valid_593372 = header.getOrDefault("X-Amz-Signature")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Signature", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Content-Sha256", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Date")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Date", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Credential")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Credential", valid_593375
  var valid_593376 = header.getOrDefault("Authentication")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "Authentication", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Security-Token")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Security-Token", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Algorithm")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Algorithm", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-SignedHeaders", valid_593379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593380: Call_DeleteFolder_593368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_593380.validator(path, query, header, formData, body)
  let scheme = call_593380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593380.url(scheme.get, call_593380.host, call_593380.base,
                         call_593380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593380, url, valid)

proc call*(call_593381: Call_DeleteFolder_593368; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_593382 = newJObject()
  add(path_593382, "FolderId", newJString(FolderId))
  result = call_593381.call(path_593382, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_593368(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_593369,
    base: "/", url: url_DeleteFolder_593370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_593400 = ref object of OpenApiRestCall_592364
proc url_DescribeFolderContents_593402(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeFolderContents_593401(path: JsonNode; query: JsonNode;
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
  var valid_593403 = path.getOrDefault("FolderId")
  valid_593403 = validateParameter(valid_593403, JString, required = true,
                                 default = nil)
  if valid_593403 != nil:
    section.add "FolderId", valid_593403
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
  var valid_593404 = query.getOrDefault("sort")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = newJString("DATE"))
  if valid_593404 != nil:
    section.add "sort", valid_593404
  var valid_593405 = query.getOrDefault("Marker")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "Marker", valid_593405
  var valid_593406 = query.getOrDefault("order")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_593406 != nil:
    section.add "order", valid_593406
  var valid_593407 = query.getOrDefault("limit")
  valid_593407 = validateParameter(valid_593407, JInt, required = false, default = nil)
  if valid_593407 != nil:
    section.add "limit", valid_593407
  var valid_593408 = query.getOrDefault("Limit")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "Limit", valid_593408
  var valid_593409 = query.getOrDefault("type")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = newJString("ALL"))
  if valid_593409 != nil:
    section.add "type", valid_593409
  var valid_593410 = query.getOrDefault("include")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "include", valid_593410
  var valid_593411 = query.getOrDefault("marker")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "marker", valid_593411
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
  var valid_593412 = header.getOrDefault("X-Amz-Signature")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Signature", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Content-Sha256", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Date")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Date", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Credential")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Credential", valid_593415
  var valid_593416 = header.getOrDefault("Authentication")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "Authentication", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Security-Token")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Security-Token", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Algorithm")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Algorithm", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-SignedHeaders", valid_593419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593420: Call_DescribeFolderContents_593400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_593420.validator(path, query, header, formData, body)
  let scheme = call_593420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593420.url(scheme.get, call_593420.host, call_593420.base,
                         call_593420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593420, url, valid)

proc call*(call_593421: Call_DescribeFolderContents_593400; FolderId: string;
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
  var path_593422 = newJObject()
  var query_593423 = newJObject()
  add(query_593423, "sort", newJString(sort))
  add(query_593423, "Marker", newJString(Marker))
  add(query_593423, "order", newJString(order))
  add(query_593423, "limit", newJInt(limit))
  add(query_593423, "Limit", newJString(Limit))
  add(query_593423, "type", newJString(`type`))
  add(query_593423, "include", newJString(`include`))
  add(path_593422, "FolderId", newJString(FolderId))
  add(query_593423, "marker", newJString(marker))
  result = call_593421.call(path_593422, query_593423, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_593400(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_593401, base: "/",
    url: url_DescribeFolderContents_593402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_593424 = ref object of OpenApiRestCall_592364
proc url_DeleteFolderContents_593426(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteFolderContents_593425(path: JsonNode; query: JsonNode;
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
  var valid_593427 = path.getOrDefault("FolderId")
  valid_593427 = validateParameter(valid_593427, JString, required = true,
                                 default = nil)
  if valid_593427 != nil:
    section.add "FolderId", valid_593427
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
  var valid_593428 = header.getOrDefault("X-Amz-Signature")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Signature", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Content-Sha256", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Date")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Date", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Credential")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Credential", valid_593431
  var valid_593432 = header.getOrDefault("Authentication")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "Authentication", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Security-Token")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Security-Token", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Algorithm")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Algorithm", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-SignedHeaders", valid_593435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593436: Call_DeleteFolderContents_593424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_593436.validator(path, query, header, formData, body)
  let scheme = call_593436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593436.url(scheme.get, call_593436.host, call_593436.base,
                         call_593436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593436, url, valid)

proc call*(call_593437: Call_DeleteFolderContents_593424; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_593438 = newJObject()
  add(path_593438, "FolderId", newJString(FolderId))
  result = call_593437.call(path_593438, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_593424(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_593425, base: "/",
    url: url_DeleteFolderContents_593426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_593439 = ref object of OpenApiRestCall_592364
proc url_DeleteNotificationSubscription_593441(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteNotificationSubscription_593440(path: JsonNode;
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
  var valid_593442 = path.getOrDefault("SubscriptionId")
  valid_593442 = validateParameter(valid_593442, JString, required = true,
                                 default = nil)
  if valid_593442 != nil:
    section.add "SubscriptionId", valid_593442
  var valid_593443 = path.getOrDefault("OrganizationId")
  valid_593443 = validateParameter(valid_593443, JString, required = true,
                                 default = nil)
  if valid_593443 != nil:
    section.add "OrganizationId", valid_593443
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
  var valid_593444 = header.getOrDefault("X-Amz-Signature")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Signature", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Content-Sha256", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Date")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Date", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Credential")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Credential", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Security-Token")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Security-Token", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Algorithm")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Algorithm", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-SignedHeaders", valid_593450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593451: Call_DeleteNotificationSubscription_593439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_593451.validator(path, query, header, formData, body)
  let scheme = call_593451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593451.url(scheme.get, call_593451.host, call_593451.base,
                         call_593451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593451, url, valid)

proc call*(call_593452: Call_DeleteNotificationSubscription_593439;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_593453 = newJObject()
  add(path_593453, "SubscriptionId", newJString(SubscriptionId))
  add(path_593453, "OrganizationId", newJString(OrganizationId))
  result = call_593452.call(path_593453, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_593439(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_593440, base: "/",
    url: url_DeleteNotificationSubscription_593441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_593469 = ref object of OpenApiRestCall_592364
proc url_UpdateUser_593471(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_UpdateUser_593470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593472 = path.getOrDefault("UserId")
  valid_593472 = validateParameter(valid_593472, JString, required = true,
                                 default = nil)
  if valid_593472 != nil:
    section.add "UserId", valid_593472
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
  var valid_593473 = header.getOrDefault("X-Amz-Signature")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Signature", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Content-Sha256", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Date")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Date", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Credential")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Credential", valid_593476
  var valid_593477 = header.getOrDefault("Authentication")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "Authentication", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Security-Token")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Security-Token", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Algorithm")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Algorithm", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-SignedHeaders", valid_593480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593482: Call_UpdateUser_593469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_593482.validator(path, query, header, formData, body)
  let scheme = call_593482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593482.url(scheme.get, call_593482.host, call_593482.base,
                         call_593482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593482, url, valid)

proc call*(call_593483: Call_UpdateUser_593469; UserId: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   UserId: string (required)
  ##         : The ID of the user.
  ##   body: JObject (required)
  var path_593484 = newJObject()
  var body_593485 = newJObject()
  add(path_593484, "UserId", newJString(UserId))
  if body != nil:
    body_593485 = body
  result = call_593483.call(path_593484, nil, nil, nil, body_593485)

var updateUser* = Call_UpdateUser_593469(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_593470,
                                      base: "/", url: url_UpdateUser_593471,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_593454 = ref object of OpenApiRestCall_592364
proc url_DeleteUser_593456(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_DeleteUser_593455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593457 = path.getOrDefault("UserId")
  valid_593457 = validateParameter(valid_593457, JString, required = true,
                                 default = nil)
  if valid_593457 != nil:
    section.add "UserId", valid_593457
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
  var valid_593458 = header.getOrDefault("X-Amz-Signature")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Signature", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Content-Sha256", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Date")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Date", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Credential")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Credential", valid_593461
  var valid_593462 = header.getOrDefault("Authentication")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "Authentication", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Security-Token")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Security-Token", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Algorithm")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Algorithm", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-SignedHeaders", valid_593465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593466: Call_DeleteUser_593454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_593466.validator(path, query, header, formData, body)
  let scheme = call_593466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593466.url(scheme.get, call_593466.host, call_593466.base,
                         call_593466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593466, url, valid)

proc call*(call_593467: Call_DeleteUser_593454; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_593468 = newJObject()
  add(path_593468, "UserId", newJString(UserId))
  result = call_593467.call(path_593468, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_593454(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_593455,
                                      base: "/", url: url_DeleteUser_593456,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_593486 = ref object of OpenApiRestCall_592364
proc url_DescribeActivities_593488(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeActivities_593487(path: JsonNode; query: JsonNode;
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
  var valid_593489 = query.getOrDefault("endTime")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "endTime", valid_593489
  var valid_593490 = query.getOrDefault("userId")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "userId", valid_593490
  var valid_593491 = query.getOrDefault("resourceId")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "resourceId", valid_593491
  var valid_593492 = query.getOrDefault("limit")
  valid_593492 = validateParameter(valid_593492, JInt, required = false, default = nil)
  if valid_593492 != nil:
    section.add "limit", valid_593492
  var valid_593493 = query.getOrDefault("startTime")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "startTime", valid_593493
  var valid_593494 = query.getOrDefault("activityTypes")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "activityTypes", valid_593494
  var valid_593495 = query.getOrDefault("organizationId")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "organizationId", valid_593495
  var valid_593496 = query.getOrDefault("includeIndirectActivities")
  valid_593496 = validateParameter(valid_593496, JBool, required = false, default = nil)
  if valid_593496 != nil:
    section.add "includeIndirectActivities", valid_593496
  var valid_593497 = query.getOrDefault("marker")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "marker", valid_593497
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
  var valid_593498 = header.getOrDefault("X-Amz-Signature")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Signature", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Content-Sha256", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Date")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Date", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Credential")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Credential", valid_593501
  var valid_593502 = header.getOrDefault("Authentication")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "Authentication", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Security-Token")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Security-Token", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Algorithm")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Algorithm", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-SignedHeaders", valid_593505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593506: Call_DescribeActivities_593486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_593506.validator(path, query, header, formData, body)
  let scheme = call_593506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593506.url(scheme.get, call_593506.host, call_593506.base,
                         call_593506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593506, url, valid)

proc call*(call_593507: Call_DescribeActivities_593486; endTime: string = "";
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
  var query_593508 = newJObject()
  add(query_593508, "endTime", newJString(endTime))
  add(query_593508, "userId", newJString(userId))
  add(query_593508, "resourceId", newJString(resourceId))
  add(query_593508, "limit", newJInt(limit))
  add(query_593508, "startTime", newJString(startTime))
  add(query_593508, "activityTypes", newJString(activityTypes))
  add(query_593508, "organizationId", newJString(organizationId))
  add(query_593508, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_593508, "marker", newJString(marker))
  result = call_593507.call(nil, query_593508, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_593486(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_593487, base: "/",
    url: url_DescribeActivities_593488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_593509 = ref object of OpenApiRestCall_592364
proc url_DescribeComments_593511(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeComments_593510(path: JsonNode; query: JsonNode;
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
  var valid_593512 = path.getOrDefault("VersionId")
  valid_593512 = validateParameter(valid_593512, JString, required = true,
                                 default = nil)
  if valid_593512 != nil:
    section.add "VersionId", valid_593512
  var valid_593513 = path.getOrDefault("DocumentId")
  valid_593513 = validateParameter(valid_593513, JString, required = true,
                                 default = nil)
  if valid_593513 != nil:
    section.add "DocumentId", valid_593513
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  section = newJObject()
  var valid_593514 = query.getOrDefault("limit")
  valid_593514 = validateParameter(valid_593514, JInt, required = false, default = nil)
  if valid_593514 != nil:
    section.add "limit", valid_593514
  var valid_593515 = query.getOrDefault("marker")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "marker", valid_593515
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
  var valid_593516 = header.getOrDefault("X-Amz-Signature")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Signature", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Content-Sha256", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Date")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Date", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Credential")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Credential", valid_593519
  var valid_593520 = header.getOrDefault("Authentication")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "Authentication", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Security-Token")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Security-Token", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Algorithm")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Algorithm", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-SignedHeaders", valid_593523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593524: Call_DescribeComments_593509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_593524.validator(path, query, header, formData, body)
  let scheme = call_593524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593524.url(scheme.get, call_593524.host, call_593524.base,
                         call_593524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593524, url, valid)

proc call*(call_593525: Call_DescribeComments_593509; VersionId: string;
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
  var path_593526 = newJObject()
  var query_593527 = newJObject()
  add(path_593526, "VersionId", newJString(VersionId))
  add(path_593526, "DocumentId", newJString(DocumentId))
  add(query_593527, "limit", newJInt(limit))
  add(query_593527, "marker", newJString(marker))
  result = call_593525.call(path_593526, query_593527, nil, nil, nil)

var describeComments* = Call_DescribeComments_593509(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_593510, base: "/",
    url: url_DescribeComments_593511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_593528 = ref object of OpenApiRestCall_592364
proc url_DescribeDocumentVersions_593530(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeDocumentVersions_593529(path: JsonNode; query: JsonNode;
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
  var valid_593531 = path.getOrDefault("DocumentId")
  valid_593531 = validateParameter(valid_593531, JString, required = true,
                                 default = nil)
  if valid_593531 != nil:
    section.add "DocumentId", valid_593531
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
  var valid_593532 = query.getOrDefault("Marker")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "Marker", valid_593532
  var valid_593533 = query.getOrDefault("limit")
  valid_593533 = validateParameter(valid_593533, JInt, required = false, default = nil)
  if valid_593533 != nil:
    section.add "limit", valid_593533
  var valid_593534 = query.getOrDefault("Limit")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "Limit", valid_593534
  var valid_593535 = query.getOrDefault("include")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "include", valid_593535
  var valid_593536 = query.getOrDefault("fields")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "fields", valid_593536
  var valid_593537 = query.getOrDefault("marker")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "marker", valid_593537
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
  var valid_593538 = header.getOrDefault("X-Amz-Signature")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Signature", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-Content-Sha256", valid_593539
  var valid_593540 = header.getOrDefault("X-Amz-Date")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Date", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Credential")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Credential", valid_593541
  var valid_593542 = header.getOrDefault("Authentication")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "Authentication", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Security-Token")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Security-Token", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Algorithm")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Algorithm", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-SignedHeaders", valid_593545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593546: Call_DescribeDocumentVersions_593528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_593546.validator(path, query, header, formData, body)
  let scheme = call_593546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593546.url(scheme.get, call_593546.host, call_593546.base,
                         call_593546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593546, url, valid)

proc call*(call_593547: Call_DescribeDocumentVersions_593528; DocumentId: string;
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
  var path_593548 = newJObject()
  var query_593549 = newJObject()
  add(query_593549, "Marker", newJString(Marker))
  add(path_593548, "DocumentId", newJString(DocumentId))
  add(query_593549, "limit", newJInt(limit))
  add(query_593549, "Limit", newJString(Limit))
  add(query_593549, "include", newJString(`include`))
  add(query_593549, "fields", newJString(fields))
  add(query_593549, "marker", newJString(marker))
  result = call_593547.call(path_593548, query_593549, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_593528(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_593529, base: "/",
    url: url_DescribeDocumentVersions_593530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_593550 = ref object of OpenApiRestCall_592364
proc url_DescribeGroups_593552(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGroups_593551(path: JsonNode; query: JsonNode;
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
  var valid_593553 = query.getOrDefault("searchQuery")
  valid_593553 = validateParameter(valid_593553, JString, required = true,
                                 default = nil)
  if valid_593553 != nil:
    section.add "searchQuery", valid_593553
  var valid_593554 = query.getOrDefault("limit")
  valid_593554 = validateParameter(valid_593554, JInt, required = false, default = nil)
  if valid_593554 != nil:
    section.add "limit", valid_593554
  var valid_593555 = query.getOrDefault("organizationId")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "organizationId", valid_593555
  var valid_593556 = query.getOrDefault("marker")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "marker", valid_593556
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
  var valid_593557 = header.getOrDefault("X-Amz-Signature")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Signature", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Content-Sha256", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Date")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Date", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Credential")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Credential", valid_593560
  var valid_593561 = header.getOrDefault("Authentication")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "Authentication", valid_593561
  var valid_593562 = header.getOrDefault("X-Amz-Security-Token")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Security-Token", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Algorithm")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Algorithm", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-SignedHeaders", valid_593564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593565: Call_DescribeGroups_593550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_593565.validator(path, query, header, formData, body)
  let scheme = call_593565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593565.url(scheme.get, call_593565.host, call_593565.base,
                         call_593565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593565, url, valid)

proc call*(call_593566: Call_DescribeGroups_593550; searchQuery: string;
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
  var query_593567 = newJObject()
  add(query_593567, "searchQuery", newJString(searchQuery))
  add(query_593567, "limit", newJInt(limit))
  add(query_593567, "organizationId", newJString(organizationId))
  add(query_593567, "marker", newJString(marker))
  result = call_593566.call(nil, query_593567, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_593550(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_593551,
    base: "/", url: url_DescribeGroups_593552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_593568 = ref object of OpenApiRestCall_592364
proc url_DescribeRootFolders_593570(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRootFolders_593569(path: JsonNode; query: JsonNode;
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
  var valid_593571 = query.getOrDefault("limit")
  valid_593571 = validateParameter(valid_593571, JInt, required = false, default = nil)
  if valid_593571 != nil:
    section.add "limit", valid_593571
  var valid_593572 = query.getOrDefault("marker")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "marker", valid_593572
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
  var valid_593573 = header.getOrDefault("X-Amz-Signature")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amz-Signature", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Content-Sha256", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-Date")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Date", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Credential")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Credential", valid_593576
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_593577 = header.getOrDefault("Authentication")
  valid_593577 = validateParameter(valid_593577, JString, required = true,
                                 default = nil)
  if valid_593577 != nil:
    section.add "Authentication", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-Security-Token")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-Security-Token", valid_593578
  var valid_593579 = header.getOrDefault("X-Amz-Algorithm")
  valid_593579 = validateParameter(valid_593579, JString, required = false,
                                 default = nil)
  if valid_593579 != nil:
    section.add "X-Amz-Algorithm", valid_593579
  var valid_593580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593580 = validateParameter(valid_593580, JString, required = false,
                                 default = nil)
  if valid_593580 != nil:
    section.add "X-Amz-SignedHeaders", valid_593580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593581: Call_DescribeRootFolders_593568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_593581.validator(path, query, header, formData, body)
  let scheme = call_593581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593581.url(scheme.get, call_593581.host, call_593581.base,
                         call_593581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593581, url, valid)

proc call*(call_593582: Call_DescribeRootFolders_593568; limit: int = 0;
          marker: string = ""): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var query_593583 = newJObject()
  add(query_593583, "limit", newJInt(limit))
  add(query_593583, "marker", newJString(marker))
  result = call_593582.call(nil, query_593583, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_593568(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_593569, base: "/",
    url: url_DescribeRootFolders_593570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_593584 = ref object of OpenApiRestCall_592364
proc url_GetCurrentUser_593586(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCurrentUser_593585(path: JsonNode; query: JsonNode;
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
  var valid_593587 = header.getOrDefault("X-Amz-Signature")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Signature", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Content-Sha256", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Date")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Date", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Credential")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Credential", valid_593590
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_593591 = header.getOrDefault("Authentication")
  valid_593591 = validateParameter(valid_593591, JString, required = true,
                                 default = nil)
  if valid_593591 != nil:
    section.add "Authentication", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Security-Token")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Security-Token", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-Algorithm")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-Algorithm", valid_593593
  var valid_593594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593594 = validateParameter(valid_593594, JString, required = false,
                                 default = nil)
  if valid_593594 != nil:
    section.add "X-Amz-SignedHeaders", valid_593594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593595: Call_GetCurrentUser_593584; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_593595.validator(path, query, header, formData, body)
  let scheme = call_593595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593595.url(scheme.get, call_593595.host, call_593595.base,
                         call_593595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593595, url, valid)

proc call*(call_593596: Call_GetCurrentUser_593584): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_593596.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_593584(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_593585,
    base: "/", url: url_GetCurrentUser_593586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_593597 = ref object of OpenApiRestCall_592364
proc url_GetDocumentPath_593599(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDocumentPath_593598(path: JsonNode; query: JsonNode;
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
  var valid_593600 = path.getOrDefault("DocumentId")
  valid_593600 = validateParameter(valid_593600, JString, required = true,
                                 default = nil)
  if valid_593600 != nil:
    section.add "DocumentId", valid_593600
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_593601 = query.getOrDefault("limit")
  valid_593601 = validateParameter(valid_593601, JInt, required = false, default = nil)
  if valid_593601 != nil:
    section.add "limit", valid_593601
  var valid_593602 = query.getOrDefault("fields")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "fields", valid_593602
  var valid_593603 = query.getOrDefault("marker")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "marker", valid_593603
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
  var valid_593604 = header.getOrDefault("X-Amz-Signature")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Signature", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Content-Sha256", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Date")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Date", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Credential")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Credential", valid_593607
  var valid_593608 = header.getOrDefault("Authentication")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "Authentication", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Security-Token")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Security-Token", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-Algorithm")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-Algorithm", valid_593610
  var valid_593611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-SignedHeaders", valid_593611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593612: Call_GetDocumentPath_593597; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_593612.validator(path, query, header, formData, body)
  let scheme = call_593612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593612.url(scheme.get, call_593612.host, call_593612.base,
                         call_593612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593612, url, valid)

proc call*(call_593613: Call_GetDocumentPath_593597; DocumentId: string;
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
  var path_593614 = newJObject()
  var query_593615 = newJObject()
  add(path_593614, "DocumentId", newJString(DocumentId))
  add(query_593615, "limit", newJInt(limit))
  add(query_593615, "fields", newJString(fields))
  add(query_593615, "marker", newJString(marker))
  result = call_593613.call(path_593614, query_593615, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_593597(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_593598, base: "/", url: url_GetDocumentPath_593599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_593616 = ref object of OpenApiRestCall_592364
proc url_GetFolderPath_593618(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetFolderPath_593617(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593619 = path.getOrDefault("FolderId")
  valid_593619 = validateParameter(valid_593619, JString, required = true,
                                 default = nil)
  if valid_593619 != nil:
    section.add "FolderId", valid_593619
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_593620 = query.getOrDefault("limit")
  valid_593620 = validateParameter(valid_593620, JInt, required = false, default = nil)
  if valid_593620 != nil:
    section.add "limit", valid_593620
  var valid_593621 = query.getOrDefault("fields")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "fields", valid_593621
  var valid_593622 = query.getOrDefault("marker")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "marker", valid_593622
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
  var valid_593623 = header.getOrDefault("X-Amz-Signature")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Signature", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Content-Sha256", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Date")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Date", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Credential")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Credential", valid_593626
  var valid_593627 = header.getOrDefault("Authentication")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "Authentication", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-Security-Token")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-Security-Token", valid_593628
  var valid_593629 = header.getOrDefault("X-Amz-Algorithm")
  valid_593629 = validateParameter(valid_593629, JString, required = false,
                                 default = nil)
  if valid_593629 != nil:
    section.add "X-Amz-Algorithm", valid_593629
  var valid_593630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-SignedHeaders", valid_593630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593631: Call_GetFolderPath_593616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_593631.validator(path, query, header, formData, body)
  let scheme = call_593631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593631.url(scheme.get, call_593631.host, call_593631.base,
                         call_593631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593631, url, valid)

proc call*(call_593632: Call_GetFolderPath_593616; FolderId: string; limit: int = 0;
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
  var path_593633 = newJObject()
  var query_593634 = newJObject()
  add(query_593634, "limit", newJInt(limit))
  add(path_593633, "FolderId", newJString(FolderId))
  add(query_593634, "fields", newJString(fields))
  add(query_593634, "marker", newJString(marker))
  result = call_593632.call(path_593633, query_593634, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_593616(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_593617,
    base: "/", url: url_GetFolderPath_593618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_593635 = ref object of OpenApiRestCall_592364
proc url_GetResources_593637(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResources_593636(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593638 = query.getOrDefault("userId")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "userId", valid_593638
  var valid_593639 = query.getOrDefault("limit")
  valid_593639 = validateParameter(valid_593639, JInt, required = false, default = nil)
  if valid_593639 != nil:
    section.add "limit", valid_593639
  var valid_593640 = query.getOrDefault("collectionType")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_593640 != nil:
    section.add "collectionType", valid_593640
  var valid_593641 = query.getOrDefault("marker")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "marker", valid_593641
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
  var valid_593642 = header.getOrDefault("X-Amz-Signature")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Signature", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Content-Sha256", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Date")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Date", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-Credential")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-Credential", valid_593645
  var valid_593646 = header.getOrDefault("Authentication")
  valid_593646 = validateParameter(valid_593646, JString, required = false,
                                 default = nil)
  if valid_593646 != nil:
    section.add "Authentication", valid_593646
  var valid_593647 = header.getOrDefault("X-Amz-Security-Token")
  valid_593647 = validateParameter(valid_593647, JString, required = false,
                                 default = nil)
  if valid_593647 != nil:
    section.add "X-Amz-Security-Token", valid_593647
  var valid_593648 = header.getOrDefault("X-Amz-Algorithm")
  valid_593648 = validateParameter(valid_593648, JString, required = false,
                                 default = nil)
  if valid_593648 != nil:
    section.add "X-Amz-Algorithm", valid_593648
  var valid_593649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-SignedHeaders", valid_593649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593650: Call_GetResources_593635; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_593650.validator(path, query, header, formData, body)
  let scheme = call_593650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593650.url(scheme.get, call_593650.host, call_593650.base,
                         call_593650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593650, url, valid)

proc call*(call_593651: Call_GetResources_593635; userId: string = ""; limit: int = 0;
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
  var query_593652 = newJObject()
  add(query_593652, "userId", newJString(userId))
  add(query_593652, "limit", newJInt(limit))
  add(query_593652, "collectionType", newJString(collectionType))
  add(query_593652, "marker", newJString(marker))
  result = call_593651.call(nil, query_593652, nil, nil, nil)

var getResources* = Call_GetResources_593635(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_593636, base: "/",
    url: url_GetResources_593637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_593653 = ref object of OpenApiRestCall_592364
proc url_InitiateDocumentVersionUpload_593655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_InitiateDocumentVersionUpload_593654(path: JsonNode; query: JsonNode;
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
  var valid_593656 = header.getOrDefault("X-Amz-Signature")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-Signature", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Content-Sha256", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Date")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Date", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Credential")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Credential", valid_593659
  var valid_593660 = header.getOrDefault("Authentication")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "Authentication", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Security-Token")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Security-Token", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Algorithm")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Algorithm", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-SignedHeaders", valid_593663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593665: Call_InitiateDocumentVersionUpload_593653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_593665.validator(path, query, header, formData, body)
  let scheme = call_593665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593665.url(scheme.get, call_593665.host, call_593665.base,
                         call_593665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593665, url, valid)

proc call*(call_593666: Call_InitiateDocumentVersionUpload_593653; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_593667 = newJObject()
  if body != nil:
    body_593667 = body
  result = call_593666.call(nil, nil, nil, nil, body_593667)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_593653(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_593654, base: "/",
    url: url_InitiateDocumentVersionUpload_593655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_593668 = ref object of OpenApiRestCall_592364
proc url_RemoveResourcePermission_593670(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_RemoveResourcePermission_593669(path: JsonNode; query: JsonNode;
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
  var valid_593671 = path.getOrDefault("ResourceId")
  valid_593671 = validateParameter(valid_593671, JString, required = true,
                                 default = nil)
  if valid_593671 != nil:
    section.add "ResourceId", valid_593671
  var valid_593672 = path.getOrDefault("PrincipalId")
  valid_593672 = validateParameter(valid_593672, JString, required = true,
                                 default = nil)
  if valid_593672 != nil:
    section.add "PrincipalId", valid_593672
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_593673 = query.getOrDefault("type")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = newJString("USER"))
  if valid_593673 != nil:
    section.add "type", valid_593673
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
  var valid_593674 = header.getOrDefault("X-Amz-Signature")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Signature", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Content-Sha256", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Date")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Date", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Credential")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Credential", valid_593677
  var valid_593678 = header.getOrDefault("Authentication")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "Authentication", valid_593678
  var valid_593679 = header.getOrDefault("X-Amz-Security-Token")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-Security-Token", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-Algorithm")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-Algorithm", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-SignedHeaders", valid_593681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593682: Call_RemoveResourcePermission_593668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_593682.validator(path, query, header, formData, body)
  let scheme = call_593682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593682.url(scheme.get, call_593682.host, call_593682.base,
                         call_593682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593682, url, valid)

proc call*(call_593683: Call_RemoveResourcePermission_593668; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_593684 = newJObject()
  var query_593685 = newJObject()
  add(path_593684, "ResourceId", newJString(ResourceId))
  add(query_593685, "type", newJString(`type`))
  add(path_593684, "PrincipalId", newJString(PrincipalId))
  result = call_593683.call(path_593684, query_593685, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_593668(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_593669, base: "/",
    url: url_RemoveResourcePermission_593670, schemes: {Scheme.Https, Scheme.Http})
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
