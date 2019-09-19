
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetDocumentVersion_600768 = ref object of OpenApiRestCall_600426
proc url_GetDocumentVersion_600770(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDocumentVersion_600769(path: JsonNode; query: JsonNode;
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
  var valid_600896 = path.getOrDefault("VersionId")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "VersionId", valid_600896
  var valid_600897 = path.getOrDefault("DocumentId")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = nil)
  if valid_600897 != nil:
    section.add "DocumentId", valid_600897
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_600898 = query.getOrDefault("fields")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "fields", valid_600898
  var valid_600899 = query.getOrDefault("includeCustomMetadata")
  valid_600899 = validateParameter(valid_600899, JBool, required = false, default = nil)
  if valid_600899 != nil:
    section.add "includeCustomMetadata", valid_600899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600900 = header.getOrDefault("X-Amz-Date")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Date", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Security-Token")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Security-Token", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Content-Sha256", valid_600902
  var valid_600903 = header.getOrDefault("Authentication")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "Authentication", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Algorithm")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Algorithm", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Signature")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Signature", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-SignedHeaders", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Credential")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Credential", valid_600907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600930: Call_GetDocumentVersion_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_600930.validator(path, query, header, formData, body)
  let scheme = call_600930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600930.url(scheme.get, call_600930.host, call_600930.base,
                         call_600930.route, valid.getOrDefault("path"))
  result = hook(call_600930, url, valid)

proc call*(call_601001: Call_GetDocumentVersion_600768; VersionId: string;
          DocumentId: string; fields: string = ""; includeCustomMetadata: bool = false): Recallable =
  ## getDocumentVersion
  ## Retrieves version metadata for the specified document.
  ##   fields: string
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to TRUE to include custom metadata in the response.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_601002 = newJObject()
  var query_601004 = newJObject()
  add(query_601004, "fields", newJString(fields))
  add(path_601002, "VersionId", newJString(VersionId))
  add(query_601004, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_601002, "DocumentId", newJString(DocumentId))
  result = call_601001.call(path_601002, query_601004, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_600768(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_600769, base: "/",
    url: url_GetDocumentVersion_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_601059 = ref object of OpenApiRestCall_600426
proc url_UpdateDocumentVersion_601061(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDocumentVersion_601060(path: JsonNode; query: JsonNode;
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
  var valid_601062 = path.getOrDefault("VersionId")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = nil)
  if valid_601062 != nil:
    section.add "VersionId", valid_601062
  var valid_601063 = path.getOrDefault("DocumentId")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "DocumentId", valid_601063
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601064 = header.getOrDefault("X-Amz-Date")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Date", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Security-Token")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Security-Token", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Content-Sha256", valid_601066
  var valid_601067 = header.getOrDefault("Authentication")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "Authentication", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Algorithm")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Algorithm", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Signature")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Signature", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-SignedHeaders", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Credential")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Credential", valid_601071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601073: Call_UpdateDocumentVersion_601059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_601073.validator(path, query, header, formData, body)
  let scheme = call_601073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601073.url(scheme.get, call_601073.host, call_601073.base,
                         call_601073.route, valid.getOrDefault("path"))
  result = hook(call_601073, url, valid)

proc call*(call_601074: Call_UpdateDocumentVersion_601059; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_601075 = newJObject()
  var body_601076 = newJObject()
  add(path_601075, "VersionId", newJString(VersionId))
  add(path_601075, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_601076 = body
  result = call_601074.call(path_601075, nil, nil, nil, body_601076)

var updateDocumentVersion* = Call_UpdateDocumentVersion_601059(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_601060, base: "/",
    url: url_UpdateDocumentVersion_601061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_601043 = ref object of OpenApiRestCall_600426
proc url_AbortDocumentVersionUpload_601045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AbortDocumentVersionUpload_601044(path: JsonNode; query: JsonNode;
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
  var valid_601046 = path.getOrDefault("VersionId")
  valid_601046 = validateParameter(valid_601046, JString, required = true,
                                 default = nil)
  if valid_601046 != nil:
    section.add "VersionId", valid_601046
  var valid_601047 = path.getOrDefault("DocumentId")
  valid_601047 = validateParameter(valid_601047, JString, required = true,
                                 default = nil)
  if valid_601047 != nil:
    section.add "DocumentId", valid_601047
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601048 = header.getOrDefault("X-Amz-Date")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Date", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Security-Token")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Security-Token", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Content-Sha256", valid_601050
  var valid_601051 = header.getOrDefault("Authentication")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "Authentication", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Algorithm")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Algorithm", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Signature")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Signature", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-SignedHeaders", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Credential")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Credential", valid_601055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601056: Call_AbortDocumentVersionUpload_601043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_601056.validator(path, query, header, formData, body)
  let scheme = call_601056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601056.url(scheme.get, call_601056.host, call_601056.base,
                         call_601056.route, valid.getOrDefault("path"))
  result = hook(call_601056, url, valid)

proc call*(call_601057: Call_AbortDocumentVersionUpload_601043; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_601058 = newJObject()
  add(path_601058, "VersionId", newJString(VersionId))
  add(path_601058, "DocumentId", newJString(DocumentId))
  result = call_601057.call(path_601058, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_601043(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_601044, base: "/",
    url: url_AbortDocumentVersionUpload_601045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_601077 = ref object of OpenApiRestCall_600426
proc url_ActivateUser_601079(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/activation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ActivateUser_601078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601080 = path.getOrDefault("UserId")
  valid_601080 = validateParameter(valid_601080, JString, required = true,
                                 default = nil)
  if valid_601080 != nil:
    section.add "UserId", valid_601080
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601081 = header.getOrDefault("X-Amz-Date")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Date", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Security-Token")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Security-Token", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Content-Sha256", valid_601083
  var valid_601084 = header.getOrDefault("Authentication")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "Authentication", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Algorithm")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Algorithm", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Signature")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Signature", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-SignedHeaders", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Credential")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Credential", valid_601088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601089: Call_ActivateUser_601077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_601089.validator(path, query, header, formData, body)
  let scheme = call_601089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601089.url(scheme.get, call_601089.host, call_601089.base,
                         call_601089.route, valid.getOrDefault("path"))
  result = hook(call_601089, url, valid)

proc call*(call_601090: Call_ActivateUser_601077; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_601091 = newJObject()
  add(path_601091, "UserId", newJString(UserId))
  result = call_601090.call(path_601091, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_601077(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_601078,
    base: "/", url: url_ActivateUser_601079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_601092 = ref object of OpenApiRestCall_600426
proc url_DeactivateUser_601094(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/activation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeactivateUser_601093(path: JsonNode; query: JsonNode;
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
  var valid_601095 = path.getOrDefault("UserId")
  valid_601095 = validateParameter(valid_601095, JString, required = true,
                                 default = nil)
  if valid_601095 != nil:
    section.add "UserId", valid_601095
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601096 = header.getOrDefault("X-Amz-Date")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Date", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Security-Token")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Security-Token", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Content-Sha256", valid_601098
  var valid_601099 = header.getOrDefault("Authentication")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "Authentication", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Algorithm")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Algorithm", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Signature")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Signature", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-SignedHeaders", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Credential")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Credential", valid_601103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601104: Call_DeactivateUser_601092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_601104.validator(path, query, header, formData, body)
  let scheme = call_601104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601104.url(scheme.get, call_601104.host, call_601104.base,
                         call_601104.route, valid.getOrDefault("path"))
  result = hook(call_601104, url, valid)

proc call*(call_601105: Call_DeactivateUser_601092; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_601106 = newJObject()
  add(path_601106, "UserId", newJString(UserId))
  result = call_601105.call(path_601106, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_601092(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_601093, base: "/", url: url_DeactivateUser_601094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_601126 = ref object of OpenApiRestCall_600426
proc url_AddResourcePermissions_601128(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AddResourcePermissions_601127(path: JsonNode; query: JsonNode;
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
  var valid_601129 = path.getOrDefault("ResourceId")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = nil)
  if valid_601129 != nil:
    section.add "ResourceId", valid_601129
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
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
  var valid_601132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Content-Sha256", valid_601132
  var valid_601133 = header.getOrDefault("Authentication")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "Authentication", valid_601133
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

proc call*(call_601139: Call_AddResourcePermissions_601126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_AddResourcePermissions_601126; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_601141 = newJObject()
  var body_601142 = newJObject()
  add(path_601141, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_601142 = body
  result = call_601140.call(path_601141, nil, nil, nil, body_601142)

var addResourcePermissions* = Call_AddResourcePermissions_601126(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_601127, base: "/",
    url: url_AddResourcePermissions_601128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_601107 = ref object of OpenApiRestCall_600426
proc url_DescribeResourcePermissions_601109(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeResourcePermissions_601108(path: JsonNode; query: JsonNode;
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
  var valid_601110 = path.getOrDefault("ResourceId")
  valid_601110 = validateParameter(valid_601110, JString, required = true,
                                 default = nil)
  if valid_601110 != nil:
    section.add "ResourceId", valid_601110
  result.add "path", section
  ## parameters in `query` object:
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_601111 = query.getOrDefault("principalId")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "principalId", valid_601111
  var valid_601112 = query.getOrDefault("marker")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "marker", valid_601112
  var valid_601113 = query.getOrDefault("limit")
  valid_601113 = validateParameter(valid_601113, JInt, required = false, default = nil)
  if valid_601113 != nil:
    section.add "limit", valid_601113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601114 = header.getOrDefault("X-Amz-Date")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Date", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Security-Token")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Security-Token", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Content-Sha256", valid_601116
  var valid_601117 = header.getOrDefault("Authentication")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "Authentication", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Algorithm")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Algorithm", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Signature")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Signature", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-SignedHeaders", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Credential")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Credential", valid_601121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601122: Call_DescribeResourcePermissions_601107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_601122.validator(path, query, header, formData, body)
  let scheme = call_601122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601122.url(scheme.get, call_601122.host, call_601122.base,
                         call_601122.route, valid.getOrDefault("path"))
  result = hook(call_601122, url, valid)

proc call*(call_601123: Call_DescribeResourcePermissions_601107;
          ResourceId: string; principalId: string = ""; marker: string = "";
          limit: int = 0): Recallable =
  ## describeResourcePermissions
  ## Describes the permissions of a specified resource.
  ##   principalId: string
  ##              : The ID of the principal to filter permissions by.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  var path_601124 = newJObject()
  var query_601125 = newJObject()
  add(query_601125, "principalId", newJString(principalId))
  add(query_601125, "marker", newJString(marker))
  add(path_601124, "ResourceId", newJString(ResourceId))
  add(query_601125, "limit", newJInt(limit))
  result = call_601123.call(path_601124, query_601125, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_601107(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_601108, base: "/",
    url: url_DescribeResourcePermissions_601109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_601143 = ref object of OpenApiRestCall_600426
proc url_RemoveAllResourcePermissions_601145(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RemoveAllResourcePermissions_601144(path: JsonNode; query: JsonNode;
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
  var valid_601146 = path.getOrDefault("ResourceId")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = nil)
  if valid_601146 != nil:
    section.add "ResourceId", valid_601146
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Content-Sha256", valid_601149
  var valid_601150 = header.getOrDefault("Authentication")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "Authentication", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601155: Call_RemoveAllResourcePermissions_601143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_601155.validator(path, query, header, formData, body)
  let scheme = call_601155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601155.url(scheme.get, call_601155.host, call_601155.base,
                         call_601155.route, valid.getOrDefault("path"))
  result = hook(call_601155, url, valid)

proc call*(call_601156: Call_RemoveAllResourcePermissions_601143;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_601157 = newJObject()
  add(path_601157, "ResourceId", newJString(ResourceId))
  result = call_601156.call(path_601157, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_601143(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_601144, base: "/",
    url: url_RemoveAllResourcePermissions_601145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_601158 = ref object of OpenApiRestCall_600426
proc url_CreateComment_601160(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateComment_601159(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601161 = path.getOrDefault("VersionId")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "VersionId", valid_601161
  var valid_601162 = path.getOrDefault("DocumentId")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = nil)
  if valid_601162 != nil:
    section.add "DocumentId", valid_601162
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601163 = header.getOrDefault("X-Amz-Date")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Date", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Security-Token")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Security-Token", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Content-Sha256", valid_601165
  var valid_601166 = header.getOrDefault("Authentication")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "Authentication", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Algorithm")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Algorithm", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Signature")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Signature", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-SignedHeaders", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Credential")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Credential", valid_601170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601172: Call_CreateComment_601158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_601172.validator(path, query, header, formData, body)
  let scheme = call_601172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601172.url(scheme.get, call_601172.host, call_601172.base,
                         call_601172.route, valid.getOrDefault("path"))
  result = hook(call_601172, url, valid)

proc call*(call_601173: Call_CreateComment_601158; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_601174 = newJObject()
  var body_601175 = newJObject()
  add(path_601174, "VersionId", newJString(VersionId))
  add(path_601174, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_601175 = body
  result = call_601173.call(path_601174, nil, nil, nil, body_601175)

var createComment* = Call_CreateComment_601158(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_601159, base: "/", url: url_CreateComment_601160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_601176 = ref object of OpenApiRestCall_600426
proc url_CreateCustomMetadata_601178(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/customMetadata")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateCustomMetadata_601177(path: JsonNode; query: JsonNode;
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
  var valid_601179 = path.getOrDefault("ResourceId")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "ResourceId", valid_601179
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_601180 = query.getOrDefault("versionid")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "versionid", valid_601180
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601181 = header.getOrDefault("X-Amz-Date")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Date", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Security-Token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Security-Token", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Content-Sha256", valid_601183
  var valid_601184 = header.getOrDefault("Authentication")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "Authentication", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_CreateCustomMetadata_601176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"))
  result = hook(call_601190, url, valid)

proc call*(call_601191: Call_CreateCustomMetadata_601176; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_601192 = newJObject()
  var query_601193 = newJObject()
  var body_601194 = newJObject()
  add(query_601193, "versionid", newJString(versionid))
  add(path_601192, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_601194 = body
  result = call_601191.call(path_601192, query_601193, nil, nil, body_601194)

var createCustomMetadata* = Call_CreateCustomMetadata_601176(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_601177, base: "/",
    url: url_CreateCustomMetadata_601178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_601195 = ref object of OpenApiRestCall_600426
proc url_DeleteCustomMetadata_601197(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/customMetadata")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteCustomMetadata_601196(path: JsonNode; query: JsonNode;
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
  var valid_601198 = path.getOrDefault("ResourceId")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = nil)
  if valid_601198 != nil:
    section.add "ResourceId", valid_601198
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  section = newJObject()
  var valid_601199 = query.getOrDefault("versionId")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "versionId", valid_601199
  var valid_601200 = query.getOrDefault("keys")
  valid_601200 = validateParameter(valid_601200, JArray, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "keys", valid_601200
  var valid_601201 = query.getOrDefault("deleteAll")
  valid_601201 = validateParameter(valid_601201, JBool, required = false, default = nil)
  if valid_601201 != nil:
    section.add "deleteAll", valid_601201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601202 = header.getOrDefault("X-Amz-Date")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Date", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Security-Token")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Security-Token", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Content-Sha256", valid_601204
  var valid_601205 = header.getOrDefault("Authentication")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "Authentication", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Algorithm")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Algorithm", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Signature", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-SignedHeaders", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Credential")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Credential", valid_601209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601210: Call_DeleteCustomMetadata_601195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_601210.validator(path, query, header, formData, body)
  let scheme = call_601210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601210.url(scheme.get, call_601210.host, call_601210.base,
                         call_601210.route, valid.getOrDefault("path"))
  result = hook(call_601210, url, valid)

proc call*(call_601211: Call_DeleteCustomMetadata_601195; ResourceId: string;
          versionId: string = ""; keys: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteCustomMetadata
  ## Deletes custom metadata from the specified resource.
  ##   versionId: string
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   ResourceId: string (required)
  ##             : The ID of the resource, either a document or folder.
  ##   deleteAll: bool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  var path_601212 = newJObject()
  var query_601213 = newJObject()
  add(query_601213, "versionId", newJString(versionId))
  if keys != nil:
    query_601213.add "keys", keys
  add(path_601212, "ResourceId", newJString(ResourceId))
  add(query_601213, "deleteAll", newJBool(deleteAll))
  result = call_601211.call(path_601212, query_601213, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_601195(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_601196, base: "/",
    url: url_DeleteCustomMetadata_601197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_601214 = ref object of OpenApiRestCall_600426
proc url_CreateFolder_601216(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFolder_601215(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601217 = header.getOrDefault("X-Amz-Date")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Date", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Security-Token")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Security-Token", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Content-Sha256", valid_601219
  var valid_601220 = header.getOrDefault("Authentication")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "Authentication", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Algorithm")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Algorithm", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Signature")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Signature", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-SignedHeaders", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Credential")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Credential", valid_601224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601226: Call_CreateFolder_601214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_601226.validator(path, query, header, formData, body)
  let scheme = call_601226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601226.url(scheme.get, call_601226.host, call_601226.base,
                         call_601226.route, valid.getOrDefault("path"))
  result = hook(call_601226, url, valid)

proc call*(call_601227: Call_CreateFolder_601214; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_601228 = newJObject()
  if body != nil:
    body_601228 = body
  result = call_601227.call(nil, nil, nil, nil, body_601228)

var createFolder* = Call_CreateFolder_601214(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_601215, base: "/",
    url: url_CreateFolder_601216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_601229 = ref object of OpenApiRestCall_600426
proc url_CreateLabels_601231(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/labels")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateLabels_601230(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601232 = path.getOrDefault("ResourceId")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "ResourceId", valid_601232
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601233 = header.getOrDefault("X-Amz-Date")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Date", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Security-Token")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Security-Token", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Content-Sha256", valid_601235
  var valid_601236 = header.getOrDefault("Authentication")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "Authentication", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Algorithm")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Algorithm", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Signature")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Signature", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-SignedHeaders", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Credential")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Credential", valid_601240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601242: Call_CreateLabels_601229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_601242.validator(path, query, header, formData, body)
  let scheme = call_601242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601242.url(scheme.get, call_601242.host, call_601242.base,
                         call_601242.route, valid.getOrDefault("path"))
  result = hook(call_601242, url, valid)

proc call*(call_601243: Call_CreateLabels_601229; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_601244 = newJObject()
  var body_601245 = newJObject()
  add(path_601244, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_601245 = body
  result = call_601243.call(path_601244, nil, nil, nil, body_601245)

var createLabels* = Call_CreateLabels_601229(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_601230, base: "/", url: url_CreateLabels_601231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_601246 = ref object of OpenApiRestCall_600426
proc url_DeleteLabels_601248(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/resources/"),
               (kind: VariableSegment, value: "ResourceId"),
               (kind: ConstantSegment, value: "/labels")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteLabels_601247(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601249 = path.getOrDefault("ResourceId")
  valid_601249 = validateParameter(valid_601249, JString, required = true,
                                 default = nil)
  if valid_601249 != nil:
    section.add "ResourceId", valid_601249
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_601250 = query.getOrDefault("labels")
  valid_601250 = validateParameter(valid_601250, JArray, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "labels", valid_601250
  var valid_601251 = query.getOrDefault("deleteAll")
  valid_601251 = validateParameter(valid_601251, JBool, required = false, default = nil)
  if valid_601251 != nil:
    section.add "deleteAll", valid_601251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601252 = header.getOrDefault("X-Amz-Date")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Date", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Security-Token")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Security-Token", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Content-Sha256", valid_601254
  var valid_601255 = header.getOrDefault("Authentication")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "Authentication", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Algorithm")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Algorithm", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Signature")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Signature", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-SignedHeaders", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Credential")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Credential", valid_601259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601260: Call_DeleteLabels_601246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_601260.validator(path, query, header, formData, body)
  let scheme = call_601260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601260.url(scheme.get, call_601260.host, call_601260.base,
                         call_601260.route, valid.getOrDefault("path"))
  result = hook(call_601260, url, valid)

proc call*(call_601261: Call_DeleteLabels_601246; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  var path_601262 = newJObject()
  var query_601263 = newJObject()
  if labels != nil:
    query_601263.add "labels", labels
  add(path_601262, "ResourceId", newJString(ResourceId))
  add(query_601263, "deleteAll", newJBool(deleteAll))
  result = call_601261.call(path_601262, query_601263, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_601246(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_601247, base: "/", url: url_DeleteLabels_601248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_601281 = ref object of OpenApiRestCall_600426
proc url_CreateNotificationSubscription_601283(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path, "`OrganizationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/organizations/"),
               (kind: VariableSegment, value: "OrganizationId"),
               (kind: ConstantSegment, value: "/subscriptions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateNotificationSubscription_601282(path: JsonNode;
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
  var valid_601284 = path.getOrDefault("OrganizationId")
  valid_601284 = validateParameter(valid_601284, JString, required = true,
                                 default = nil)
  if valid_601284 != nil:
    section.add "OrganizationId", valid_601284
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
  var valid_601285 = header.getOrDefault("X-Amz-Date")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Date", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Security-Token")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Security-Token", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Content-Sha256", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Algorithm")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Algorithm", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Signature")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Signature", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-SignedHeaders", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Credential")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Credential", valid_601291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601293: Call_CreateNotificationSubscription_601281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_601293.validator(path, query, header, formData, body)
  let scheme = call_601293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601293.url(scheme.get, call_601293.host, call_601293.base,
                         call_601293.route, valid.getOrDefault("path"))
  result = hook(call_601293, url, valid)

proc call*(call_601294: Call_CreateNotificationSubscription_601281;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_601295 = newJObject()
  var body_601296 = newJObject()
  add(path_601295, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_601296 = body
  result = call_601294.call(path_601295, nil, nil, nil, body_601296)

var createNotificationSubscription* = Call_CreateNotificationSubscription_601281(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_601282, base: "/",
    url: url_CreateNotificationSubscription_601283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_601264 = ref object of OpenApiRestCall_600426
proc url_DescribeNotificationSubscriptions_601266(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path, "`OrganizationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/organizations/"),
               (kind: VariableSegment, value: "OrganizationId"),
               (kind: ConstantSegment, value: "/subscriptions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeNotificationSubscriptions_601265(path: JsonNode;
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
  var valid_601267 = path.getOrDefault("OrganizationId")
  valid_601267 = validateParameter(valid_601267, JString, required = true,
                                 default = nil)
  if valid_601267 != nil:
    section.add "OrganizationId", valid_601267
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_601268 = query.getOrDefault("marker")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "marker", valid_601268
  var valid_601269 = query.getOrDefault("limit")
  valid_601269 = validateParameter(valid_601269, JInt, required = false, default = nil)
  if valid_601269 != nil:
    section.add "limit", valid_601269
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
  var valid_601270 = header.getOrDefault("X-Amz-Date")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Date", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Security-Token")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Security-Token", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Content-Sha256", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Algorithm")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Algorithm", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Signature")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Signature", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-SignedHeaders", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Credential")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Credential", valid_601276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601277: Call_DescribeNotificationSubscriptions_601264;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_601277.validator(path, query, header, formData, body)
  let scheme = call_601277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601277.url(scheme.get, call_601277.host, call_601277.base,
                         call_601277.route, valid.getOrDefault("path"))
  result = hook(call_601277, url, valid)

proc call*(call_601278: Call_DescribeNotificationSubscriptions_601264;
          OrganizationId: string; marker: string = ""; limit: int = 0): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  var path_601279 = newJObject()
  var query_601280 = newJObject()
  add(path_601279, "OrganizationId", newJString(OrganizationId))
  add(query_601280, "marker", newJString(marker))
  add(query_601280, "limit", newJInt(limit))
  result = call_601278.call(path_601279, query_601280, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_601264(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_601265, base: "/",
    url: url_DescribeNotificationSubscriptions_601266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_601335 = ref object of OpenApiRestCall_600426
proc url_CreateUser_601337(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUser_601336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601338 = header.getOrDefault("X-Amz-Date")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Date", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Security-Token")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Security-Token", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Content-Sha256", valid_601340
  var valid_601341 = header.getOrDefault("Authentication")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "Authentication", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Algorithm")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Algorithm", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Signature")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Signature", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-SignedHeaders", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Credential")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Credential", valid_601345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601347: Call_CreateUser_601335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_601347.validator(path, query, header, formData, body)
  let scheme = call_601347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601347.url(scheme.get, call_601347.host, call_601347.base,
                         call_601347.route, valid.getOrDefault("path"))
  result = hook(call_601347, url, valid)

proc call*(call_601348: Call_CreateUser_601335; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_601349 = newJObject()
  if body != nil:
    body_601349 = body
  result = call_601348.call(nil, nil, nil, nil, body_601349)

var createUser* = Call_CreateUser_601335(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_601336,
                                      base: "/", url: url_CreateUser_601337,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_601297 = ref object of OpenApiRestCall_600426
proc url_DescribeUsers_601299(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUsers_601298(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  ##   query: JString
  ##        : A query to filter users by user name.
  ##   sort: JString
  ##       : The sorting criteria.
  ##   order: JString
  ##        : The order for the results.
  ##   Limit: JString
  ##        : Pagination limit
  ##   include: JString
  ##          : The state of the users. Specify "ALL" to include inactive users.
  ##   organizationId: JString
  ##                 : The ID of the organization.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Marker: JString
  ##         : Pagination token
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   userIds: JString
  ##          : The IDs of the users.
  section = newJObject()
  var valid_601300 = query.getOrDefault("fields")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "fields", valid_601300
  var valid_601301 = query.getOrDefault("query")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "query", valid_601301
  var valid_601315 = query.getOrDefault("sort")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_601315 != nil:
    section.add "sort", valid_601315
  var valid_601316 = query.getOrDefault("order")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_601316 != nil:
    section.add "order", valid_601316
  var valid_601317 = query.getOrDefault("Limit")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "Limit", valid_601317
  var valid_601318 = query.getOrDefault("include")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = newJString("ALL"))
  if valid_601318 != nil:
    section.add "include", valid_601318
  var valid_601319 = query.getOrDefault("organizationId")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "organizationId", valid_601319
  var valid_601320 = query.getOrDefault("marker")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "marker", valid_601320
  var valid_601321 = query.getOrDefault("Marker")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "Marker", valid_601321
  var valid_601322 = query.getOrDefault("limit")
  valid_601322 = validateParameter(valid_601322, JInt, required = false, default = nil)
  if valid_601322 != nil:
    section.add "limit", valid_601322
  var valid_601323 = query.getOrDefault("userIds")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "userIds", valid_601323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601324 = header.getOrDefault("X-Amz-Date")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Date", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Security-Token")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Security-Token", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Content-Sha256", valid_601326
  var valid_601327 = header.getOrDefault("Authentication")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "Authentication", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Algorithm")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Algorithm", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Signature")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Signature", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-SignedHeaders", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Credential")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Credential", valid_601331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601332: Call_DescribeUsers_601297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_601332.validator(path, query, header, formData, body)
  let scheme = call_601332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601332.url(scheme.get, call_601332.host, call_601332.base,
                         call_601332.route, valid.getOrDefault("path"))
  result = hook(call_601332, url, valid)

proc call*(call_601333: Call_DescribeUsers_601297; fields: string = "";
          query: string = ""; sort: string = "USER_NAME"; order: string = "ASCENDING";
          Limit: string = ""; `include`: string = "ALL"; organizationId: string = "";
          marker: string = ""; Marker: string = ""; limit: int = 0; userIds: string = ""): Recallable =
  ## describeUsers
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ##   fields: string
  ##         : A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  ##   query: string
  ##        : A query to filter users by user name.
  ##   sort: string
  ##       : The sorting criteria.
  ##   order: string
  ##        : The order for the results.
  ##   Limit: string
  ##        : Pagination limit
  ##   include: string
  ##          : The state of the users. Specify "ALL" to include inactive users.
  ##   organizationId: string
  ##                 : The ID of the organization.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Marker: string
  ##         : Pagination token
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   userIds: string
  ##          : The IDs of the users.
  var query_601334 = newJObject()
  add(query_601334, "fields", newJString(fields))
  add(query_601334, "query", newJString(query))
  add(query_601334, "sort", newJString(sort))
  add(query_601334, "order", newJString(order))
  add(query_601334, "Limit", newJString(Limit))
  add(query_601334, "include", newJString(`include`))
  add(query_601334, "organizationId", newJString(organizationId))
  add(query_601334, "marker", newJString(marker))
  add(query_601334, "Marker", newJString(Marker))
  add(query_601334, "limit", newJInt(limit))
  add(query_601334, "userIds", newJString(userIds))
  result = call_601333.call(nil, query_601334, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_601297(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_601298, base: "/",
    url: url_DescribeUsers_601299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_601350 = ref object of OpenApiRestCall_600426
proc url_DeleteComment_601352(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteComment_601351(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified comment from the document version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CommentId: JString (required)
  ##            : The ID of the comment.
  ##   VersionId: JString (required)
  ##            : The ID of the document version.
  ##   DocumentId: JString (required)
  ##             : The ID of the document.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `CommentId` field"
  var valid_601353 = path.getOrDefault("CommentId")
  valid_601353 = validateParameter(valid_601353, JString, required = true,
                                 default = nil)
  if valid_601353 != nil:
    section.add "CommentId", valid_601353
  var valid_601354 = path.getOrDefault("VersionId")
  valid_601354 = validateParameter(valid_601354, JString, required = true,
                                 default = nil)
  if valid_601354 != nil:
    section.add "VersionId", valid_601354
  var valid_601355 = path.getOrDefault("DocumentId")
  valid_601355 = validateParameter(valid_601355, JString, required = true,
                                 default = nil)
  if valid_601355 != nil:
    section.add "DocumentId", valid_601355
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601356 = header.getOrDefault("X-Amz-Date")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Date", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Security-Token")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Security-Token", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("Authentication")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "Authentication", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Algorithm")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Algorithm", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Signature")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Signature", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-SignedHeaders", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Credential")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Credential", valid_601363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601364: Call_DeleteComment_601350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"))
  result = hook(call_601364, url, valid)

proc call*(call_601365: Call_DeleteComment_601350; CommentId: string;
          VersionId: string; DocumentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_601366 = newJObject()
  add(path_601366, "CommentId", newJString(CommentId))
  add(path_601366, "VersionId", newJString(VersionId))
  add(path_601366, "DocumentId", newJString(DocumentId))
  result = call_601365.call(path_601366, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_601350(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_601351, base: "/", url: url_DeleteComment_601352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_601367 = ref object of OpenApiRestCall_600426
proc url_GetDocument_601369(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDocument_601368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601370 = path.getOrDefault("DocumentId")
  valid_601370 = validateParameter(valid_601370, JString, required = true,
                                 default = nil)
  if valid_601370 != nil:
    section.add "DocumentId", valid_601370
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_601371 = query.getOrDefault("includeCustomMetadata")
  valid_601371 = validateParameter(valid_601371, JBool, required = false, default = nil)
  if valid_601371 != nil:
    section.add "includeCustomMetadata", valid_601371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601372 = header.getOrDefault("X-Amz-Date")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Date", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Security-Token")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Security-Token", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Content-Sha256", valid_601374
  var valid_601375 = header.getOrDefault("Authentication")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "Authentication", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Algorithm")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Algorithm", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Signature")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Signature", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-SignedHeaders", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Credential")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Credential", valid_601379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601380: Call_GetDocument_601367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_601380.validator(path, query, header, formData, body)
  let scheme = call_601380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601380.url(scheme.get, call_601380.host, call_601380.base,
                         call_601380.route, valid.getOrDefault("path"))
  result = hook(call_601380, url, valid)

proc call*(call_601381: Call_GetDocument_601367; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_601382 = newJObject()
  var query_601383 = newJObject()
  add(query_601383, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_601382, "DocumentId", newJString(DocumentId))
  result = call_601381.call(path_601382, query_601383, nil, nil, nil)

var getDocument* = Call_GetDocument_601367(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_601368,
                                        base: "/", url: url_GetDocument_601369,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_601399 = ref object of OpenApiRestCall_600426
proc url_UpdateDocument_601401(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDocument_601400(path: JsonNode; query: JsonNode;
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
  var valid_601402 = path.getOrDefault("DocumentId")
  valid_601402 = validateParameter(valid_601402, JString, required = true,
                                 default = nil)
  if valid_601402 != nil:
    section.add "DocumentId", valid_601402
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601403 = header.getOrDefault("X-Amz-Date")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Date", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Security-Token")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Security-Token", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Content-Sha256", valid_601405
  var valid_601406 = header.getOrDefault("Authentication")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "Authentication", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Algorithm")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Algorithm", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Signature")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Signature", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-SignedHeaders", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Credential")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Credential", valid_601410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601412: Call_UpdateDocument_601399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_601412.validator(path, query, header, formData, body)
  let scheme = call_601412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601412.url(scheme.get, call_601412.host, call_601412.base,
                         call_601412.route, valid.getOrDefault("path"))
  result = hook(call_601412, url, valid)

proc call*(call_601413: Call_UpdateDocument_601399; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_601414 = newJObject()
  var body_601415 = newJObject()
  add(path_601414, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_601415 = body
  result = call_601413.call(path_601414, nil, nil, nil, body_601415)

var updateDocument* = Call_UpdateDocument_601399(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_601400,
    base: "/", url: url_UpdateDocument_601401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_601384 = ref object of OpenApiRestCall_600426
proc url_DeleteDocument_601386(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDocument_601385(path: JsonNode; query: JsonNode;
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
  var valid_601387 = path.getOrDefault("DocumentId")
  valid_601387 = validateParameter(valid_601387, JString, required = true,
                                 default = nil)
  if valid_601387 != nil:
    section.add "DocumentId", valid_601387
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601388 = header.getOrDefault("X-Amz-Date")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Date", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Security-Token")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Security-Token", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Content-Sha256", valid_601390
  var valid_601391 = header.getOrDefault("Authentication")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "Authentication", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Algorithm")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Algorithm", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Signature")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Signature", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-SignedHeaders", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Credential")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Credential", valid_601395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601396: Call_DeleteDocument_601384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_601396.validator(path, query, header, formData, body)
  let scheme = call_601396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601396.url(scheme.get, call_601396.host, call_601396.base,
                         call_601396.route, valid.getOrDefault("path"))
  result = hook(call_601396, url, valid)

proc call*(call_601397: Call_DeleteDocument_601384; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_601398 = newJObject()
  add(path_601398, "DocumentId", newJString(DocumentId))
  result = call_601397.call(path_601398, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_601384(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_601385,
    base: "/", url: url_DeleteDocument_601386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_601416 = ref object of OpenApiRestCall_600426
proc url_GetFolder_601418(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFolder_601417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601419 = path.getOrDefault("FolderId")
  valid_601419 = validateParameter(valid_601419, JString, required = true,
                                 default = nil)
  if valid_601419 != nil:
    section.add "FolderId", valid_601419
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_601420 = query.getOrDefault("includeCustomMetadata")
  valid_601420 = validateParameter(valid_601420, JBool, required = false, default = nil)
  if valid_601420 != nil:
    section.add "includeCustomMetadata", valid_601420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
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
  var valid_601423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Content-Sha256", valid_601423
  var valid_601424 = header.getOrDefault("Authentication")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "Authentication", valid_601424
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
  if body != nil:
    result.add "body", body

proc call*(call_601429: Call_GetFolder_601416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_601429.validator(path, query, header, formData, body)
  let scheme = call_601429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601429.url(scheme.get, call_601429.host, call_601429.base,
                         call_601429.route, valid.getOrDefault("path"))
  result = hook(call_601429, url, valid)

proc call*(call_601430: Call_GetFolder_601416; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  var path_601431 = newJObject()
  var query_601432 = newJObject()
  add(path_601431, "FolderId", newJString(FolderId))
  add(query_601432, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_601430.call(path_601431, query_601432, nil, nil, nil)

var getFolder* = Call_GetFolder_601416(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_601417,
                                    base: "/", url: url_GetFolder_601418,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_601448 = ref object of OpenApiRestCall_600426
proc url_UpdateFolder_601450(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFolder_601449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601451 = path.getOrDefault("FolderId")
  valid_601451 = validateParameter(valid_601451, JString, required = true,
                                 default = nil)
  if valid_601451 != nil:
    section.add "FolderId", valid_601451
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601452 = header.getOrDefault("X-Amz-Date")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Date", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Security-Token")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Security-Token", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Content-Sha256", valid_601454
  var valid_601455 = header.getOrDefault("Authentication")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "Authentication", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Algorithm")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Algorithm", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Signature")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Signature", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-SignedHeaders", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Credential")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Credential", valid_601459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601461: Call_UpdateFolder_601448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_601461.validator(path, query, header, formData, body)
  let scheme = call_601461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601461.url(scheme.get, call_601461.host, call_601461.base,
                         call_601461.route, valid.getOrDefault("path"))
  result = hook(call_601461, url, valid)

proc call*(call_601462: Call_UpdateFolder_601448; FolderId: string; body: JsonNode): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   body: JObject (required)
  var path_601463 = newJObject()
  var body_601464 = newJObject()
  add(path_601463, "FolderId", newJString(FolderId))
  if body != nil:
    body_601464 = body
  result = call_601462.call(path_601463, nil, nil, nil, body_601464)

var updateFolder* = Call_UpdateFolder_601448(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_601449,
    base: "/", url: url_UpdateFolder_601450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_601433 = ref object of OpenApiRestCall_600426
proc url_DeleteFolder_601435(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFolder_601434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601436 = path.getOrDefault("FolderId")
  valid_601436 = validateParameter(valid_601436, JString, required = true,
                                 default = nil)
  if valid_601436 != nil:
    section.add "FolderId", valid_601436
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Content-Sha256", valid_601439
  var valid_601440 = header.getOrDefault("Authentication")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "Authentication", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Algorithm")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Algorithm", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Signature")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Signature", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-SignedHeaders", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Credential")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Credential", valid_601444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601445: Call_DeleteFolder_601433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_601445.validator(path, query, header, formData, body)
  let scheme = call_601445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601445.url(scheme.get, call_601445.host, call_601445.base,
                         call_601445.route, valid.getOrDefault("path"))
  result = hook(call_601445, url, valid)

proc call*(call_601446: Call_DeleteFolder_601433; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_601447 = newJObject()
  add(path_601447, "FolderId", newJString(FolderId))
  result = call_601446.call(path_601447, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_601433(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_601434,
    base: "/", url: url_DeleteFolder_601435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_601465 = ref object of OpenApiRestCall_600426
proc url_DescribeFolderContents_601467(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId"),
               (kind: ConstantSegment, value: "/contents")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeFolderContents_601466(path: JsonNode; query: JsonNode;
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
  var valid_601468 = path.getOrDefault("FolderId")
  valid_601468 = validateParameter(valid_601468, JString, required = true,
                                 default = nil)
  if valid_601468 != nil:
    section.add "FolderId", valid_601468
  result.add "path", section
  ## parameters in `query` object:
  ##   sort: JString
  ##       : The sorting criteria.
  ##   type: JString
  ##       : The type of items.
  ##   order: JString
  ##        : The order for the contents of the folder.
  ##   Limit: JString
  ##        : Pagination limit
  ##   include: JString
  ##          : The contents to include. Specify "INITIALIZED" to include initialized documents.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   Marker: JString
  ##         : Pagination token
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_601469 = query.getOrDefault("sort")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = newJString("DATE"))
  if valid_601469 != nil:
    section.add "sort", valid_601469
  var valid_601470 = query.getOrDefault("type")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = newJString("ALL"))
  if valid_601470 != nil:
    section.add "type", valid_601470
  var valid_601471 = query.getOrDefault("order")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_601471 != nil:
    section.add "order", valid_601471
  var valid_601472 = query.getOrDefault("Limit")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "Limit", valid_601472
  var valid_601473 = query.getOrDefault("include")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "include", valid_601473
  var valid_601474 = query.getOrDefault("marker")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "marker", valid_601474
  var valid_601475 = query.getOrDefault("Marker")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "Marker", valid_601475
  var valid_601476 = query.getOrDefault("limit")
  valid_601476 = validateParameter(valid_601476, JInt, required = false, default = nil)
  if valid_601476 != nil:
    section.add "limit", valid_601476
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601477 = header.getOrDefault("X-Amz-Date")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Date", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Security-Token")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Security-Token", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Content-Sha256", valid_601479
  var valid_601480 = header.getOrDefault("Authentication")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "Authentication", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Algorithm")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Algorithm", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Signature")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Signature", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-SignedHeaders", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Credential")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Credential", valid_601484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601485: Call_DescribeFolderContents_601465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_601485.validator(path, query, header, formData, body)
  let scheme = call_601485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601485.url(scheme.get, call_601485.host, call_601485.base,
                         call_601485.route, valid.getOrDefault("path"))
  result = hook(call_601485, url, valid)

proc call*(call_601486: Call_DescribeFolderContents_601465; FolderId: string;
          sort: string = "DATE"; `type`: string = "ALL"; order: string = "ASCENDING";
          Limit: string = ""; `include`: string = ""; marker: string = "";
          Marker: string = ""; limit: int = 0): Recallable =
  ## describeFolderContents
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ##   sort: string
  ##       : The sorting criteria.
  ##   type: string
  ##       : The type of items.
  ##   order: string
  ##        : The order for the contents of the folder.
  ##   Limit: string
  ##        : Pagination limit
  ##   include: string
  ##          : The contents to include. Specify "INITIALIZED" to include initialized documents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   marker: string
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   Marker: string
  ##         : Pagination token
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  var path_601487 = newJObject()
  var query_601488 = newJObject()
  add(query_601488, "sort", newJString(sort))
  add(query_601488, "type", newJString(`type`))
  add(query_601488, "order", newJString(order))
  add(query_601488, "Limit", newJString(Limit))
  add(query_601488, "include", newJString(`include`))
  add(path_601487, "FolderId", newJString(FolderId))
  add(query_601488, "marker", newJString(marker))
  add(query_601488, "Marker", newJString(Marker))
  add(query_601488, "limit", newJInt(limit))
  result = call_601486.call(path_601487, query_601488, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_601465(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_601466, base: "/",
    url: url_DescribeFolderContents_601467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_601489 = ref object of OpenApiRestCall_600426
proc url_DeleteFolderContents_601491(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId"),
               (kind: ConstantSegment, value: "/contents")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFolderContents_601490(path: JsonNode; query: JsonNode;
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
  var valid_601492 = path.getOrDefault("FolderId")
  valid_601492 = validateParameter(valid_601492, JString, required = true,
                                 default = nil)
  if valid_601492 != nil:
    section.add "FolderId", valid_601492
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601493 = header.getOrDefault("X-Amz-Date")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Date", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Security-Token")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Security-Token", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Content-Sha256", valid_601495
  var valid_601496 = header.getOrDefault("Authentication")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "Authentication", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Algorithm")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Algorithm", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Signature")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Signature", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-SignedHeaders", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Credential")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Credential", valid_601500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601501: Call_DeleteFolderContents_601489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_601501.validator(path, query, header, formData, body)
  let scheme = call_601501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601501.url(scheme.get, call_601501.host, call_601501.base,
                         call_601501.route, valid.getOrDefault("path"))
  result = hook(call_601501, url, valid)

proc call*(call_601502: Call_DeleteFolderContents_601489; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_601503 = newJObject()
  add(path_601503, "FolderId", newJString(FolderId))
  result = call_601502.call(path_601503, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_601489(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_601490, base: "/",
    url: url_DeleteFolderContents_601491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_601504 = ref object of OpenApiRestCall_600426
proc url_DeleteNotificationSubscription_601506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteNotificationSubscription_601505(path: JsonNode;
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
  var valid_601507 = path.getOrDefault("SubscriptionId")
  valid_601507 = validateParameter(valid_601507, JString, required = true,
                                 default = nil)
  if valid_601507 != nil:
    section.add "SubscriptionId", valid_601507
  var valid_601508 = path.getOrDefault("OrganizationId")
  valid_601508 = validateParameter(valid_601508, JString, required = true,
                                 default = nil)
  if valid_601508 != nil:
    section.add "OrganizationId", valid_601508
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
  var valid_601509 = header.getOrDefault("X-Amz-Date")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Date", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Security-Token")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Security-Token", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Content-Sha256", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Algorithm")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Algorithm", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Signature")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Signature", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-SignedHeaders", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Credential")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Credential", valid_601515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601516: Call_DeleteNotificationSubscription_601504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_601516.validator(path, query, header, formData, body)
  let scheme = call_601516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601516.url(scheme.get, call_601516.host, call_601516.base,
                         call_601516.route, valid.getOrDefault("path"))
  result = hook(call_601516, url, valid)

proc call*(call_601517: Call_DeleteNotificationSubscription_601504;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_601518 = newJObject()
  add(path_601518, "SubscriptionId", newJString(SubscriptionId))
  add(path_601518, "OrganizationId", newJString(OrganizationId))
  result = call_601517.call(path_601518, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_601504(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_601505, base: "/",
    url: url_DeleteNotificationSubscription_601506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_601534 = ref object of OpenApiRestCall_600426
proc url_UpdateUser_601536(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUser_601535(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601537 = path.getOrDefault("UserId")
  valid_601537 = validateParameter(valid_601537, JString, required = true,
                                 default = nil)
  if valid_601537 != nil:
    section.add "UserId", valid_601537
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601538 = header.getOrDefault("X-Amz-Date")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Date", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Security-Token")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Security-Token", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Content-Sha256", valid_601540
  var valid_601541 = header.getOrDefault("Authentication")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "Authentication", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Algorithm")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Algorithm", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Signature")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Signature", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-SignedHeaders", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Credential")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Credential", valid_601545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601547: Call_UpdateUser_601534; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_601547.validator(path, query, header, formData, body)
  let scheme = call_601547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601547.url(scheme.get, call_601547.host, call_601547.base,
                         call_601547.route, valid.getOrDefault("path"))
  result = hook(call_601547, url, valid)

proc call*(call_601548: Call_UpdateUser_601534; body: JsonNode; UserId: string): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_601549 = newJObject()
  var body_601550 = newJObject()
  if body != nil:
    body_601550 = body
  add(path_601549, "UserId", newJString(UserId))
  result = call_601548.call(path_601549, nil, nil, nil, body_601550)

var updateUser* = Call_UpdateUser_601534(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_601535,
                                      base: "/", url: url_UpdateUser_601536,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_601519 = ref object of OpenApiRestCall_600426
proc url_DeleteUser_601521(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteUser_601520(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601522 = path.getOrDefault("UserId")
  valid_601522 = validateParameter(valid_601522, JString, required = true,
                                 default = nil)
  if valid_601522 != nil:
    section.add "UserId", valid_601522
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601523 = header.getOrDefault("X-Amz-Date")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Date", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Security-Token")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Security-Token", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Content-Sha256", valid_601525
  var valid_601526 = header.getOrDefault("Authentication")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "Authentication", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Algorithm")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Algorithm", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Signature")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Signature", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-SignedHeaders", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Credential")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Credential", valid_601530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601531: Call_DeleteUser_601519; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_601531.validator(path, query, header, formData, body)
  let scheme = call_601531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601531.url(scheme.get, call_601531.host, call_601531.base,
                         call_601531.route, valid.getOrDefault("path"))
  result = hook(call_601531, url, valid)

proc call*(call_601532: Call_DeleteUser_601519; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_601533 = newJObject()
  add(path_601533, "UserId", newJString(UserId))
  result = call_601532.call(path_601533, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_601519(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_601520,
                                      base: "/", url: url_DeleteUser_601521,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_601551 = ref object of OpenApiRestCall_600426
proc url_DescribeActivities_601553(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeActivities_601552(path: JsonNode; query: JsonNode;
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
  ##   organizationId: JString
  ##                 : The ID of the organization. This is a mandatory parameter when using administrative API (SigV4) requests.
  ##   includeIndirectActivities: JBool
  ##                            : Includes indirect activities. An indirect activity results from a direct activity performed on a parent resource. For example, sharing a parent folder (the direct activity) shares all of the subfolders and documents within the parent folder (the indirect activity).
  ##   activityTypes: JString
  ##                : Specifies which activity types to include in the response. If this field is left empty, all activity types are returned.
  ##   marker: JString
  ##         : The marker for the next set of results.
  ##   resourceId: JString
  ##             : The document or folder ID for which to describe activity types.
  ##   startTime: JString
  ##            : The timestamp that determines the starting time of the activities. The response includes the activities performed after the specified timestamp.
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   userId: JString
  ##         : The ID of the user who performed the action. The response includes activities pertaining to this user. This is an optional parameter and is only applicable for administrative API (SigV4) requests.
  section = newJObject()
  var valid_601554 = query.getOrDefault("endTime")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "endTime", valid_601554
  var valid_601555 = query.getOrDefault("organizationId")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "organizationId", valid_601555
  var valid_601556 = query.getOrDefault("includeIndirectActivities")
  valid_601556 = validateParameter(valid_601556, JBool, required = false, default = nil)
  if valid_601556 != nil:
    section.add "includeIndirectActivities", valid_601556
  var valid_601557 = query.getOrDefault("activityTypes")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "activityTypes", valid_601557
  var valid_601558 = query.getOrDefault("marker")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "marker", valid_601558
  var valid_601559 = query.getOrDefault("resourceId")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "resourceId", valid_601559
  var valid_601560 = query.getOrDefault("startTime")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "startTime", valid_601560
  var valid_601561 = query.getOrDefault("limit")
  valid_601561 = validateParameter(valid_601561, JInt, required = false, default = nil)
  if valid_601561 != nil:
    section.add "limit", valid_601561
  var valid_601562 = query.getOrDefault("userId")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "userId", valid_601562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
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
  var valid_601565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Content-Sha256", valid_601565
  var valid_601566 = header.getOrDefault("Authentication")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "Authentication", valid_601566
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
  if body != nil:
    result.add "body", body

proc call*(call_601571: Call_DescribeActivities_601551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_601571.validator(path, query, header, formData, body)
  let scheme = call_601571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601571.url(scheme.get, call_601571.host, call_601571.base,
                         call_601571.route, valid.getOrDefault("path"))
  result = hook(call_601571, url, valid)

proc call*(call_601572: Call_DescribeActivities_601551; endTime: string = "";
          organizationId: string = ""; includeIndirectActivities: bool = false;
          activityTypes: string = ""; marker: string = ""; resourceId: string = "";
          startTime: string = ""; limit: int = 0; userId: string = ""): Recallable =
  ## describeActivities
  ## Describes the user activities in a specified time period.
  ##   endTime: string
  ##          : The timestamp that determines the end time of the activities. The response includes the activities performed before the specified timestamp.
  ##   organizationId: string
  ##                 : The ID of the organization. This is a mandatory parameter when using administrative API (SigV4) requests.
  ##   includeIndirectActivities: bool
  ##                            : Includes indirect activities. An indirect activity results from a direct activity performed on a parent resource. For example, sharing a parent folder (the direct activity) shares all of the subfolders and documents within the parent folder (the indirect activity).
  ##   activityTypes: string
  ##                : Specifies which activity types to include in the response. If this field is left empty, all activity types are returned.
  ##   marker: string
  ##         : The marker for the next set of results.
  ##   resourceId: string
  ##             : The document or folder ID for which to describe activity types.
  ##   startTime: string
  ##            : The timestamp that determines the starting time of the activities. The response includes the activities performed after the specified timestamp.
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   userId: string
  ##         : The ID of the user who performed the action. The response includes activities pertaining to this user. This is an optional parameter and is only applicable for administrative API (SigV4) requests.
  var query_601573 = newJObject()
  add(query_601573, "endTime", newJString(endTime))
  add(query_601573, "organizationId", newJString(organizationId))
  add(query_601573, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_601573, "activityTypes", newJString(activityTypes))
  add(query_601573, "marker", newJString(marker))
  add(query_601573, "resourceId", newJString(resourceId))
  add(query_601573, "startTime", newJString(startTime))
  add(query_601573, "limit", newJInt(limit))
  add(query_601573, "userId", newJString(userId))
  result = call_601572.call(nil, query_601573, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_601551(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_601552, base: "/",
    url: url_DescribeActivities_601553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_601574 = ref object of OpenApiRestCall_600426
proc url_DescribeComments_601576(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeComments_601575(path: JsonNode; query: JsonNode;
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
  var valid_601577 = path.getOrDefault("VersionId")
  valid_601577 = validateParameter(valid_601577, JString, required = true,
                                 default = nil)
  if valid_601577 != nil:
    section.add "VersionId", valid_601577
  var valid_601578 = path.getOrDefault("DocumentId")
  valid_601578 = validateParameter(valid_601578, JString, required = true,
                                 default = nil)
  if valid_601578 != nil:
    section.add "DocumentId", valid_601578
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   limit: JInt
  ##        : The maximum number of items to return.
  section = newJObject()
  var valid_601579 = query.getOrDefault("marker")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "marker", valid_601579
  var valid_601580 = query.getOrDefault("limit")
  valid_601580 = validateParameter(valid_601580, JInt, required = false, default = nil)
  if valid_601580 != nil:
    section.add "limit", valid_601580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601581 = header.getOrDefault("X-Amz-Date")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Date", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Security-Token")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Security-Token", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Content-Sha256", valid_601583
  var valid_601584 = header.getOrDefault("Authentication")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "Authentication", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Algorithm")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Algorithm", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Signature")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Signature", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-SignedHeaders", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Credential")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Credential", valid_601588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601589: Call_DescribeComments_601574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_601589.validator(path, query, header, formData, body)
  let scheme = call_601589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601589.url(scheme.get, call_601589.host, call_601589.base,
                         call_601589.route, valid.getOrDefault("path"))
  result = hook(call_601589, url, valid)

proc call*(call_601590: Call_DescribeComments_601574; VersionId: string;
          DocumentId: string; marker: string = ""; limit: int = 0): Recallable =
  ## describeComments
  ## List all the comments for the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   marker: string
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   limit: int
  ##        : The maximum number of items to return.
  var path_601591 = newJObject()
  var query_601592 = newJObject()
  add(path_601591, "VersionId", newJString(VersionId))
  add(query_601592, "marker", newJString(marker))
  add(path_601591, "DocumentId", newJString(DocumentId))
  add(query_601592, "limit", newJInt(limit))
  result = call_601590.call(path_601591, query_601592, nil, nil, nil)

var describeComments* = Call_DescribeComments_601574(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_601575, base: "/",
    url: url_DescribeComments_601576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_601593 = ref object of OpenApiRestCall_600426
proc url_DescribeDocumentVersions_601595(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeDocumentVersions_601594(path: JsonNode; query: JsonNode;
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
  var valid_601596 = path.getOrDefault("DocumentId")
  valid_601596 = validateParameter(valid_601596, JString, required = true,
                                 default = nil)
  if valid_601596 != nil:
    section.add "DocumentId", valid_601596
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : Specify "SOURCE" to include initialized versions and a URL for the source document.
  ##   Limit: JString
  ##        : Pagination limit
  ##   include: JString
  ##          : A comma-separated list of values. Specify "INITIALIZED" to include incomplete versions.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Marker: JString
  ##         : Pagination token
  ##   limit: JInt
  ##        : The maximum number of versions to return with this call.
  section = newJObject()
  var valid_601597 = query.getOrDefault("fields")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "fields", valid_601597
  var valid_601598 = query.getOrDefault("Limit")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "Limit", valid_601598
  var valid_601599 = query.getOrDefault("include")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "include", valid_601599
  var valid_601600 = query.getOrDefault("marker")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "marker", valid_601600
  var valid_601601 = query.getOrDefault("Marker")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "Marker", valid_601601
  var valid_601602 = query.getOrDefault("limit")
  valid_601602 = validateParameter(valid_601602, JInt, required = false, default = nil)
  if valid_601602 != nil:
    section.add "limit", valid_601602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601603 = header.getOrDefault("X-Amz-Date")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Date", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Security-Token")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Security-Token", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Content-Sha256", valid_601605
  var valid_601606 = header.getOrDefault("Authentication")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "Authentication", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Algorithm")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Algorithm", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Signature")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Signature", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-SignedHeaders", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Credential")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Credential", valid_601610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601611: Call_DescribeDocumentVersions_601593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_601611.validator(path, query, header, formData, body)
  let scheme = call_601611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601611.url(scheme.get, call_601611.host, call_601611.base,
                         call_601611.route, valid.getOrDefault("path"))
  result = hook(call_601611, url, valid)

proc call*(call_601612: Call_DescribeDocumentVersions_601593; DocumentId: string;
          fields: string = ""; Limit: string = ""; `include`: string = "";
          marker: string = ""; Marker: string = ""; limit: int = 0): Recallable =
  ## describeDocumentVersions
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ##   fields: string
  ##         : Specify "SOURCE" to include initialized versions and a URL for the source document.
  ##   Limit: string
  ##        : Pagination limit
  ##   include: string
  ##          : A comma-separated list of values. Specify "INITIALIZED" to include incomplete versions.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Marker: string
  ##         : Pagination token
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   limit: int
  ##        : The maximum number of versions to return with this call.
  var path_601613 = newJObject()
  var query_601614 = newJObject()
  add(query_601614, "fields", newJString(fields))
  add(query_601614, "Limit", newJString(Limit))
  add(query_601614, "include", newJString(`include`))
  add(query_601614, "marker", newJString(marker))
  add(query_601614, "Marker", newJString(Marker))
  add(path_601613, "DocumentId", newJString(DocumentId))
  add(query_601614, "limit", newJInt(limit))
  result = call_601612.call(path_601613, query_601614, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_601593(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_601594, base: "/",
    url: url_DescribeDocumentVersions_601595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_601615 = ref object of OpenApiRestCall_600426
proc url_DescribeGroups_601617(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeGroups_601616(path: JsonNode; query: JsonNode;
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
  ##   organizationId: JString
  ##                 : The ID of the organization.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `searchQuery` field"
  var valid_601618 = query.getOrDefault("searchQuery")
  valid_601618 = validateParameter(valid_601618, JString, required = true,
                                 default = nil)
  if valid_601618 != nil:
    section.add "searchQuery", valid_601618
  var valid_601619 = query.getOrDefault("organizationId")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "organizationId", valid_601619
  var valid_601620 = query.getOrDefault("marker")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "marker", valid_601620
  var valid_601621 = query.getOrDefault("limit")
  valid_601621 = validateParameter(valid_601621, JInt, required = false, default = nil)
  if valid_601621 != nil:
    section.add "limit", valid_601621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601622 = header.getOrDefault("X-Amz-Date")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Date", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Security-Token")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Security-Token", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Content-Sha256", valid_601624
  var valid_601625 = header.getOrDefault("Authentication")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "Authentication", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Algorithm")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Algorithm", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Signature")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Signature", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-SignedHeaders", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Credential")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Credential", valid_601629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601630: Call_DescribeGroups_601615; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_601630.validator(path, query, header, formData, body)
  let scheme = call_601630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601630.url(scheme.get, call_601630.host, call_601630.base,
                         call_601630.route, valid.getOrDefault("path"))
  result = hook(call_601630, url, valid)

proc call*(call_601631: Call_DescribeGroups_601615; searchQuery: string;
          organizationId: string = ""; marker: string = ""; limit: int = 0): Recallable =
  ## describeGroups
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ##   searchQuery: string (required)
  ##              : A query to describe groups by group name.
  ##   organizationId: string
  ##                 : The ID of the organization.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  var query_601632 = newJObject()
  add(query_601632, "searchQuery", newJString(searchQuery))
  add(query_601632, "organizationId", newJString(organizationId))
  add(query_601632, "marker", newJString(marker))
  add(query_601632, "limit", newJInt(limit))
  result = call_601631.call(nil, query_601632, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_601615(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_601616,
    base: "/", url: url_DescribeGroups_601617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_601633 = ref object of OpenApiRestCall_600426
proc url_DescribeRootFolders_601635(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRootFolders_601634(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: JInt
  ##        : The maximum number of items to return.
  section = newJObject()
  var valid_601636 = query.getOrDefault("marker")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "marker", valid_601636
  var valid_601637 = query.getOrDefault("limit")
  valid_601637 = validateParameter(valid_601637, JInt, required = false, default = nil)
  if valid_601637 != nil:
    section.add "limit", valid_601637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString (required)
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
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
  var valid_601640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Content-Sha256", valid_601640
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_601641 = header.getOrDefault("Authentication")
  valid_601641 = validateParameter(valid_601641, JString, required = true,
                                 default = nil)
  if valid_601641 != nil:
    section.add "Authentication", valid_601641
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
  if body != nil:
    result.add "body", body

proc call*(call_601646: Call_DescribeRootFolders_601633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_601646.validator(path, query, header, formData, body)
  let scheme = call_601646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601646.url(scheme.get, call_601646.host, call_601646.base,
                         call_601646.route, valid.getOrDefault("path"))
  result = hook(call_601646, url, valid)

proc call*(call_601647: Call_DescribeRootFolders_601633; marker: string = "";
          limit: int = 0): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return.
  var query_601648 = newJObject()
  add(query_601648, "marker", newJString(marker))
  add(query_601648, "limit", newJInt(limit))
  result = call_601647.call(nil, query_601648, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_601633(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_601634, base: "/",
    url: url_DescribeRootFolders_601635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_601649 = ref object of OpenApiRestCall_600426
proc url_GetCurrentUser_601651(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCurrentUser_601650(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString (required)
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601652 = header.getOrDefault("X-Amz-Date")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Date", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Security-Token")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Security-Token", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Content-Sha256", valid_601654
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_601655 = header.getOrDefault("Authentication")
  valid_601655 = validateParameter(valid_601655, JString, required = true,
                                 default = nil)
  if valid_601655 != nil:
    section.add "Authentication", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Algorithm")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Algorithm", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Signature")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Signature", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-SignedHeaders", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-Credential")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Credential", valid_601659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601660: Call_GetCurrentUser_601649; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_601660.validator(path, query, header, formData, body)
  let scheme = call_601660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601660.url(scheme.get, call_601660.host, call_601660.base,
                         call_601660.route, valid.getOrDefault("path"))
  result = hook(call_601660, url, valid)

proc call*(call_601661: Call_GetCurrentUser_601649): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_601661.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_601649(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_601650,
    base: "/", url: url_GetCurrentUser_601651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_601662 = ref object of OpenApiRestCall_600426
proc url_GetDocumentPath_601664(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId"),
               (kind: ConstantSegment, value: "/path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDocumentPath_601663(path: JsonNode; query: JsonNode;
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
  var valid_601665 = path.getOrDefault("DocumentId")
  valid_601665 = validateParameter(valid_601665, JString, required = true,
                                 default = nil)
  if valid_601665 != nil:
    section.add "DocumentId", valid_601665
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_601666 = query.getOrDefault("fields")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "fields", valid_601666
  var valid_601667 = query.getOrDefault("marker")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "marker", valid_601667
  var valid_601668 = query.getOrDefault("limit")
  valid_601668 = validateParameter(valid_601668, JInt, required = false, default = nil)
  if valid_601668 != nil:
    section.add "limit", valid_601668
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601669 = header.getOrDefault("X-Amz-Date")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Date", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Security-Token")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Security-Token", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Content-Sha256", valid_601671
  var valid_601672 = header.getOrDefault("Authentication")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "Authentication", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Algorithm")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Algorithm", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-Signature")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Signature", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-SignedHeaders", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-Credential")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Credential", valid_601676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601677: Call_GetDocumentPath_601662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_601677.validator(path, query, header, formData, body)
  let scheme = call_601677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601677.url(scheme.get, call_601677.host, call_601677.base,
                         call_601677.route, valid.getOrDefault("path"))
  result = hook(call_601677, url, valid)

proc call*(call_601678: Call_GetDocumentPath_601662; DocumentId: string;
          fields: string = ""; marker: string = ""; limit: int = 0): Recallable =
  ## getDocumentPath
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ##   fields: string
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: string
  ##         : This value is not supported.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   limit: int
  ##        : The maximum number of levels in the hierarchy to return.
  var path_601679 = newJObject()
  var query_601680 = newJObject()
  add(query_601680, "fields", newJString(fields))
  add(query_601680, "marker", newJString(marker))
  add(path_601679, "DocumentId", newJString(DocumentId))
  add(query_601680, "limit", newJInt(limit))
  result = call_601678.call(path_601679, query_601680, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_601662(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_601663, base: "/", url: url_GetDocumentPath_601664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_601681 = ref object of OpenApiRestCall_600426
proc url_GetFolderPath_601683(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId"),
               (kind: ConstantSegment, value: "/path")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFolderPath_601682(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601684 = path.getOrDefault("FolderId")
  valid_601684 = validateParameter(valid_601684, JString, required = true,
                                 default = nil)
  if valid_601684 != nil:
    section.add "FolderId", valid_601684
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_601685 = query.getOrDefault("fields")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "fields", valid_601685
  var valid_601686 = query.getOrDefault("marker")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "marker", valid_601686
  var valid_601687 = query.getOrDefault("limit")
  valid_601687 = validateParameter(valid_601687, JInt, required = false, default = nil)
  if valid_601687 != nil:
    section.add "limit", valid_601687
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601688 = header.getOrDefault("X-Amz-Date")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Date", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Security-Token")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Security-Token", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Content-Sha256", valid_601690
  var valid_601691 = header.getOrDefault("Authentication")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "Authentication", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Algorithm")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Algorithm", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Signature")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Signature", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-SignedHeaders", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Credential")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Credential", valid_601695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601696: Call_GetFolderPath_601681; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_601696.validator(path, query, header, formData, body)
  let scheme = call_601696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601696.url(scheme.get, call_601696.host, call_601696.base,
                         call_601696.route, valid.getOrDefault("path"))
  result = hook(call_601696, url, valid)

proc call*(call_601697: Call_GetFolderPath_601681; FolderId: string;
          fields: string = ""; marker: string = ""; limit: int = 0): Recallable =
  ## getFolderPath
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ##   fields: string
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   marker: string
  ##         : This value is not supported.
  ##   limit: int
  ##        : The maximum number of levels in the hierarchy to return.
  var path_601698 = newJObject()
  var query_601699 = newJObject()
  add(query_601699, "fields", newJString(fields))
  add(path_601698, "FolderId", newJString(FolderId))
  add(query_601699, "marker", newJString(marker))
  add(query_601699, "limit", newJInt(limit))
  result = call_601697.call(path_601698, query_601699, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_601681(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_601682,
    base: "/", url: url_GetFolderPath_601683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_601700 = ref object of OpenApiRestCall_600426
proc url_GetResources_601702(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResources_601701(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   collectionType: JString
  ##                 : The collection type.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   limit: JInt
  ##        : The maximum number of resources to return.
  ##   userId: JString
  ##         : The user ID for the resource collection. This is a required field for accessing the API operation using IAM credentials.
  section = newJObject()
  var valid_601703 = query.getOrDefault("collectionType")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_601703 != nil:
    section.add "collectionType", valid_601703
  var valid_601704 = query.getOrDefault("marker")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "marker", valid_601704
  var valid_601705 = query.getOrDefault("limit")
  valid_601705 = validateParameter(valid_601705, JInt, required = false, default = nil)
  if valid_601705 != nil:
    section.add "limit", valid_601705
  var valid_601706 = query.getOrDefault("userId")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "userId", valid_601706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : The Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API operation using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601707 = header.getOrDefault("X-Amz-Date")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Date", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Security-Token")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Security-Token", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Content-Sha256", valid_601709
  var valid_601710 = header.getOrDefault("Authentication")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "Authentication", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Algorithm")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Algorithm", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Signature")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Signature", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-SignedHeaders", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Credential")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Credential", valid_601714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601715: Call_GetResources_601700; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_601715.validator(path, query, header, formData, body)
  let scheme = call_601715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601715.url(scheme.get, call_601715.host, call_601715.base,
                         call_601715.route, valid.getOrDefault("path"))
  result = hook(call_601715, url, valid)

proc call*(call_601716: Call_GetResources_601700;
          collectionType: string = "SHARED_WITH_ME"; marker: string = "";
          limit: int = 0; userId: string = ""): Recallable =
  ## getResources
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ##   collectionType: string
  ##                 : The collection type.
  ##   marker: string
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   limit: int
  ##        : The maximum number of resources to return.
  ##   userId: string
  ##         : The user ID for the resource collection. This is a required field for accessing the API operation using IAM credentials.
  var query_601717 = newJObject()
  add(query_601717, "collectionType", newJString(collectionType))
  add(query_601717, "marker", newJString(marker))
  add(query_601717, "limit", newJInt(limit))
  add(query_601717, "userId", newJString(userId))
  result = call_601716.call(nil, query_601717, nil, nil, nil)

var getResources* = Call_GetResources_601700(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_601701, base: "/",
    url: url_GetResources_601702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_601718 = ref object of OpenApiRestCall_600426
proc url_InitiateDocumentVersionUpload_601720(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InitiateDocumentVersionUpload_601719(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601721 = header.getOrDefault("X-Amz-Date")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Date", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Security-Token")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Security-Token", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Content-Sha256", valid_601723
  var valid_601724 = header.getOrDefault("Authentication")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "Authentication", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Algorithm")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Algorithm", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Signature")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Signature", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-SignedHeaders", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Credential")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Credential", valid_601728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601730: Call_InitiateDocumentVersionUpload_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_601730.validator(path, query, header, formData, body)
  let scheme = call_601730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601730.url(scheme.get, call_601730.host, call_601730.base,
                         call_601730.route, valid.getOrDefault("path"))
  result = hook(call_601730, url, valid)

proc call*(call_601731: Call_InitiateDocumentVersionUpload_601718; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_601732 = newJObject()
  if body != nil:
    body_601732 = body
  result = call_601731.call(nil, nil, nil, nil, body_601732)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_601718(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_601719, base: "/",
    url: url_InitiateDocumentVersionUpload_601720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_601733 = ref object of OpenApiRestCall_600426
proc url_RemoveResourcePermission_601735(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RemoveResourcePermission_601734(path: JsonNode; query: JsonNode;
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
  var valid_601736 = path.getOrDefault("ResourceId")
  valid_601736 = validateParameter(valid_601736, JString, required = true,
                                 default = nil)
  if valid_601736 != nil:
    section.add "ResourceId", valid_601736
  var valid_601737 = path.getOrDefault("PrincipalId")
  valid_601737 = validateParameter(valid_601737, JString, required = true,
                                 default = nil)
  if valid_601737 != nil:
    section.add "PrincipalId", valid_601737
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_601738 = query.getOrDefault("type")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = newJString("USER"))
  if valid_601738 != nil:
    section.add "type", valid_601738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   Authentication: JString
  ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601739 = header.getOrDefault("X-Amz-Date")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Date", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Security-Token")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Security-Token", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Content-Sha256", valid_601741
  var valid_601742 = header.getOrDefault("Authentication")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "Authentication", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Algorithm")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Algorithm", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Signature")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Signature", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-SignedHeaders", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Credential")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Credential", valid_601746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601747: Call_RemoveResourcePermission_601733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_601747.validator(path, query, header, formData, body)
  let scheme = call_601747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601747.url(scheme.get, call_601747.host, call_601747.base,
                         call_601747.route, valid.getOrDefault("path"))
  result = hook(call_601747, url, valid)

proc call*(call_601748: Call_RemoveResourcePermission_601733; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_601749 = newJObject()
  var query_601750 = newJObject()
  add(query_601750, "type", newJString(`type`))
  add(path_601749, "ResourceId", newJString(ResourceId))
  add(path_601749, "PrincipalId", newJString(PrincipalId))
  result = call_601748.call(path_601749, query_601750, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_601733(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_601734, base: "/",
    url: url_RemoveResourcePermission_601735, schemes: {Scheme.Https, Scheme.Http})
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
