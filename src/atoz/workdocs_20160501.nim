
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_GetDocumentVersion_772933 = ref object of OpenApiRestCall_772597
proc url_GetDocumentVersion_772935(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentVersion_772934(path: JsonNode; query: JsonNode;
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
  var valid_773061 = path.getOrDefault("VersionId")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "VersionId", valid_773061
  var valid_773062 = path.getOrDefault("DocumentId")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = nil)
  if valid_773062 != nil:
    section.add "DocumentId", valid_773062
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_773063 = query.getOrDefault("fields")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "fields", valid_773063
  var valid_773064 = query.getOrDefault("includeCustomMetadata")
  valid_773064 = validateParameter(valid_773064, JBool, required = false, default = nil)
  if valid_773064 != nil:
    section.add "includeCustomMetadata", valid_773064
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
  var valid_773065 = header.getOrDefault("X-Amz-Date")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Date", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Security-Token")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Security-Token", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Content-Sha256", valid_773067
  var valid_773068 = header.getOrDefault("Authentication")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "Authentication", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-Algorithm")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-Algorithm", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-Signature")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-Signature", valid_773070
  var valid_773071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773071 = validateParameter(valid_773071, JString, required = false,
                                 default = nil)
  if valid_773071 != nil:
    section.add "X-Amz-SignedHeaders", valid_773071
  var valid_773072 = header.getOrDefault("X-Amz-Credential")
  valid_773072 = validateParameter(valid_773072, JString, required = false,
                                 default = nil)
  if valid_773072 != nil:
    section.add "X-Amz-Credential", valid_773072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773095: Call_GetDocumentVersion_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_773095.validator(path, query, header, formData, body)
  let scheme = call_773095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773095.url(scheme.get, call_773095.host, call_773095.base,
                         call_773095.route, valid.getOrDefault("path"))
  result = hook(call_773095, url, valid)

proc call*(call_773166: Call_GetDocumentVersion_772933; VersionId: string;
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
  var path_773167 = newJObject()
  var query_773169 = newJObject()
  add(query_773169, "fields", newJString(fields))
  add(path_773167, "VersionId", newJString(VersionId))
  add(query_773169, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_773167, "DocumentId", newJString(DocumentId))
  result = call_773166.call(path_773167, query_773169, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_772933(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_772934, base: "/",
    url: url_GetDocumentVersion_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_773224 = ref object of OpenApiRestCall_772597
proc url_UpdateDocumentVersion_773226(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentVersion_773225(path: JsonNode; query: JsonNode;
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
  var valid_773227 = path.getOrDefault("VersionId")
  valid_773227 = validateParameter(valid_773227, JString, required = true,
                                 default = nil)
  if valid_773227 != nil:
    section.add "VersionId", valid_773227
  var valid_773228 = path.getOrDefault("DocumentId")
  valid_773228 = validateParameter(valid_773228, JString, required = true,
                                 default = nil)
  if valid_773228 != nil:
    section.add "DocumentId", valid_773228
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
  var valid_773229 = header.getOrDefault("X-Amz-Date")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Date", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Security-Token")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Security-Token", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Content-Sha256", valid_773231
  var valid_773232 = header.getOrDefault("Authentication")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "Authentication", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Algorithm")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Algorithm", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Signature")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Signature", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-SignedHeaders", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Credential")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Credential", valid_773236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773238: Call_UpdateDocumentVersion_773224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_773238.validator(path, query, header, formData, body)
  let scheme = call_773238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773238.url(scheme.get, call_773238.host, call_773238.base,
                         call_773238.route, valid.getOrDefault("path"))
  result = hook(call_773238, url, valid)

proc call*(call_773239: Call_UpdateDocumentVersion_773224; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_773240 = newJObject()
  var body_773241 = newJObject()
  add(path_773240, "VersionId", newJString(VersionId))
  add(path_773240, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_773241 = body
  result = call_773239.call(path_773240, nil, nil, nil, body_773241)

var updateDocumentVersion* = Call_UpdateDocumentVersion_773224(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_773225, base: "/",
    url: url_UpdateDocumentVersion_773226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_773208 = ref object of OpenApiRestCall_772597
proc url_AbortDocumentVersionUpload_773210(protocol: Scheme; host: string;
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

proc validate_AbortDocumentVersionUpload_773209(path: JsonNode; query: JsonNode;
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
  var valid_773211 = path.getOrDefault("VersionId")
  valid_773211 = validateParameter(valid_773211, JString, required = true,
                                 default = nil)
  if valid_773211 != nil:
    section.add "VersionId", valid_773211
  var valid_773212 = path.getOrDefault("DocumentId")
  valid_773212 = validateParameter(valid_773212, JString, required = true,
                                 default = nil)
  if valid_773212 != nil:
    section.add "DocumentId", valid_773212
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
  var valid_773213 = header.getOrDefault("X-Amz-Date")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Date", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Security-Token")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Security-Token", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Content-Sha256", valid_773215
  var valid_773216 = header.getOrDefault("Authentication")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "Authentication", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-Algorithm")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Algorithm", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Signature")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Signature", valid_773218
  var valid_773219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-SignedHeaders", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Credential")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Credential", valid_773220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773221: Call_AbortDocumentVersionUpload_773208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_773221.validator(path, query, header, formData, body)
  let scheme = call_773221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773221.url(scheme.get, call_773221.host, call_773221.base,
                         call_773221.route, valid.getOrDefault("path"))
  result = hook(call_773221, url, valid)

proc call*(call_773222: Call_AbortDocumentVersionUpload_773208; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_773223 = newJObject()
  add(path_773223, "VersionId", newJString(VersionId))
  add(path_773223, "DocumentId", newJString(DocumentId))
  result = call_773222.call(path_773223, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_773208(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_773209, base: "/",
    url: url_AbortDocumentVersionUpload_773210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_773242 = ref object of OpenApiRestCall_772597
proc url_ActivateUser_773244(protocol: Scheme; host: string; base: string;
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

proc validate_ActivateUser_773243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773245 = path.getOrDefault("UserId")
  valid_773245 = validateParameter(valid_773245, JString, required = true,
                                 default = nil)
  if valid_773245 != nil:
    section.add "UserId", valid_773245
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
  var valid_773246 = header.getOrDefault("X-Amz-Date")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Date", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Security-Token")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Security-Token", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Content-Sha256", valid_773248
  var valid_773249 = header.getOrDefault("Authentication")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "Authentication", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Algorithm")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Algorithm", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Signature")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Signature", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-SignedHeaders", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Credential")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Credential", valid_773253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773254: Call_ActivateUser_773242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_773254.validator(path, query, header, formData, body)
  let scheme = call_773254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773254.url(scheme.get, call_773254.host, call_773254.base,
                         call_773254.route, valid.getOrDefault("path"))
  result = hook(call_773254, url, valid)

proc call*(call_773255: Call_ActivateUser_773242; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_773256 = newJObject()
  add(path_773256, "UserId", newJString(UserId))
  result = call_773255.call(path_773256, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_773242(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_773243,
    base: "/", url: url_ActivateUser_773244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_773257 = ref object of OpenApiRestCall_772597
proc url_DeactivateUser_773259(protocol: Scheme; host: string; base: string;
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

proc validate_DeactivateUser_773258(path: JsonNode; query: JsonNode;
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
  var valid_773260 = path.getOrDefault("UserId")
  valid_773260 = validateParameter(valid_773260, JString, required = true,
                                 default = nil)
  if valid_773260 != nil:
    section.add "UserId", valid_773260
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
  var valid_773261 = header.getOrDefault("X-Amz-Date")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Date", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Security-Token")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Security-Token", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Content-Sha256", valid_773263
  var valid_773264 = header.getOrDefault("Authentication")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "Authentication", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Algorithm")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Algorithm", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Signature")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Signature", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-SignedHeaders", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Credential")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Credential", valid_773268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773269: Call_DeactivateUser_773257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_773269.validator(path, query, header, formData, body)
  let scheme = call_773269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773269.url(scheme.get, call_773269.host, call_773269.base,
                         call_773269.route, valid.getOrDefault("path"))
  result = hook(call_773269, url, valid)

proc call*(call_773270: Call_DeactivateUser_773257; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_773271 = newJObject()
  add(path_773271, "UserId", newJString(UserId))
  result = call_773270.call(path_773271, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_773257(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_773258, base: "/", url: url_DeactivateUser_773259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_773291 = ref object of OpenApiRestCall_772597
proc url_AddResourcePermissions_773293(protocol: Scheme; host: string; base: string;
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

proc validate_AddResourcePermissions_773292(path: JsonNode; query: JsonNode;
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
  var valid_773294 = path.getOrDefault("ResourceId")
  valid_773294 = validateParameter(valid_773294, JString, required = true,
                                 default = nil)
  if valid_773294 != nil:
    section.add "ResourceId", valid_773294
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Content-Sha256", valid_773297
  var valid_773298 = header.getOrDefault("Authentication")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "Authentication", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_AddResourcePermissions_773291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_AddResourcePermissions_773291; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_773306 = newJObject()
  var body_773307 = newJObject()
  add(path_773306, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_773307 = body
  result = call_773305.call(path_773306, nil, nil, nil, body_773307)

var addResourcePermissions* = Call_AddResourcePermissions_773291(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_773292, base: "/",
    url: url_AddResourcePermissions_773293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_773272 = ref object of OpenApiRestCall_772597
proc url_DescribeResourcePermissions_773274(protocol: Scheme; host: string;
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

proc validate_DescribeResourcePermissions_773273(path: JsonNode; query: JsonNode;
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
  var valid_773275 = path.getOrDefault("ResourceId")
  valid_773275 = validateParameter(valid_773275, JString, required = true,
                                 default = nil)
  if valid_773275 != nil:
    section.add "ResourceId", valid_773275
  result.add "path", section
  ## parameters in `query` object:
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_773276 = query.getOrDefault("principalId")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "principalId", valid_773276
  var valid_773277 = query.getOrDefault("marker")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "marker", valid_773277
  var valid_773278 = query.getOrDefault("limit")
  valid_773278 = validateParameter(valid_773278, JInt, required = false, default = nil)
  if valid_773278 != nil:
    section.add "limit", valid_773278
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
  var valid_773279 = header.getOrDefault("X-Amz-Date")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Date", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Security-Token")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Security-Token", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Content-Sha256", valid_773281
  var valid_773282 = header.getOrDefault("Authentication")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "Authentication", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Algorithm")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Algorithm", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Signature")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Signature", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-SignedHeaders", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Credential")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Credential", valid_773286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773287: Call_DescribeResourcePermissions_773272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_773287.validator(path, query, header, formData, body)
  let scheme = call_773287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773287.url(scheme.get, call_773287.host, call_773287.base,
                         call_773287.route, valid.getOrDefault("path"))
  result = hook(call_773287, url, valid)

proc call*(call_773288: Call_DescribeResourcePermissions_773272;
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
  var path_773289 = newJObject()
  var query_773290 = newJObject()
  add(query_773290, "principalId", newJString(principalId))
  add(query_773290, "marker", newJString(marker))
  add(path_773289, "ResourceId", newJString(ResourceId))
  add(query_773290, "limit", newJInt(limit))
  result = call_773288.call(path_773289, query_773290, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_773272(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_773273, base: "/",
    url: url_DescribeResourcePermissions_773274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_773308 = ref object of OpenApiRestCall_772597
proc url_RemoveAllResourcePermissions_773310(protocol: Scheme; host: string;
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

proc validate_RemoveAllResourcePermissions_773309(path: JsonNode; query: JsonNode;
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
  var valid_773311 = path.getOrDefault("ResourceId")
  valid_773311 = validateParameter(valid_773311, JString, required = true,
                                 default = nil)
  if valid_773311 != nil:
    section.add "ResourceId", valid_773311
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
  var valid_773312 = header.getOrDefault("X-Amz-Date")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Date", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Security-Token")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Security-Token", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Content-Sha256", valid_773314
  var valid_773315 = header.getOrDefault("Authentication")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "Authentication", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Algorithm")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Algorithm", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Signature")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Signature", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-SignedHeaders", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-Credential")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Credential", valid_773319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773320: Call_RemoveAllResourcePermissions_773308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_773320.validator(path, query, header, formData, body)
  let scheme = call_773320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773320.url(scheme.get, call_773320.host, call_773320.base,
                         call_773320.route, valid.getOrDefault("path"))
  result = hook(call_773320, url, valid)

proc call*(call_773321: Call_RemoveAllResourcePermissions_773308;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_773322 = newJObject()
  add(path_773322, "ResourceId", newJString(ResourceId))
  result = call_773321.call(path_773322, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_773308(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_773309, base: "/",
    url: url_RemoveAllResourcePermissions_773310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_773323 = ref object of OpenApiRestCall_772597
proc url_CreateComment_773325(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComment_773324(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773326 = path.getOrDefault("VersionId")
  valid_773326 = validateParameter(valid_773326, JString, required = true,
                                 default = nil)
  if valid_773326 != nil:
    section.add "VersionId", valid_773326
  var valid_773327 = path.getOrDefault("DocumentId")
  valid_773327 = validateParameter(valid_773327, JString, required = true,
                                 default = nil)
  if valid_773327 != nil:
    section.add "DocumentId", valid_773327
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
  var valid_773328 = header.getOrDefault("X-Amz-Date")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Date", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Security-Token")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Security-Token", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Content-Sha256", valid_773330
  var valid_773331 = header.getOrDefault("Authentication")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "Authentication", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Algorithm")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Algorithm", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Signature")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Signature", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-SignedHeaders", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Credential")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Credential", valid_773335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773337: Call_CreateComment_773323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_773337.validator(path, query, header, formData, body)
  let scheme = call_773337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773337.url(scheme.get, call_773337.host, call_773337.base,
                         call_773337.route, valid.getOrDefault("path"))
  result = hook(call_773337, url, valid)

proc call*(call_773338: Call_CreateComment_773323; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_773339 = newJObject()
  var body_773340 = newJObject()
  add(path_773339, "VersionId", newJString(VersionId))
  add(path_773339, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_773340 = body
  result = call_773338.call(path_773339, nil, nil, nil, body_773340)

var createComment* = Call_CreateComment_773323(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_773324, base: "/", url: url_CreateComment_773325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_773341 = ref object of OpenApiRestCall_772597
proc url_CreateCustomMetadata_773343(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCustomMetadata_773342(path: JsonNode; query: JsonNode;
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
  var valid_773344 = path.getOrDefault("ResourceId")
  valid_773344 = validateParameter(valid_773344, JString, required = true,
                                 default = nil)
  if valid_773344 != nil:
    section.add "ResourceId", valid_773344
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_773345 = query.getOrDefault("versionid")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "versionid", valid_773345
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
  var valid_773346 = header.getOrDefault("X-Amz-Date")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Date", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Security-Token")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Security-Token", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Content-Sha256", valid_773348
  var valid_773349 = header.getOrDefault("Authentication")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "Authentication", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Algorithm")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Algorithm", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Signature")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Signature", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-SignedHeaders", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Credential")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Credential", valid_773353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773355: Call_CreateCustomMetadata_773341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_773355.validator(path, query, header, formData, body)
  let scheme = call_773355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773355.url(scheme.get, call_773355.host, call_773355.base,
                         call_773355.route, valid.getOrDefault("path"))
  result = hook(call_773355, url, valid)

proc call*(call_773356: Call_CreateCustomMetadata_773341; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_773357 = newJObject()
  var query_773358 = newJObject()
  var body_773359 = newJObject()
  add(query_773358, "versionid", newJString(versionid))
  add(path_773357, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_773359 = body
  result = call_773356.call(path_773357, query_773358, nil, nil, body_773359)

var createCustomMetadata* = Call_CreateCustomMetadata_773341(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_773342, base: "/",
    url: url_CreateCustomMetadata_773343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_773360 = ref object of OpenApiRestCall_772597
proc url_DeleteCustomMetadata_773362(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCustomMetadata_773361(path: JsonNode; query: JsonNode;
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
  var valid_773363 = path.getOrDefault("ResourceId")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = nil)
  if valid_773363 != nil:
    section.add "ResourceId", valid_773363
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  section = newJObject()
  var valid_773364 = query.getOrDefault("versionId")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "versionId", valid_773364
  var valid_773365 = query.getOrDefault("keys")
  valid_773365 = validateParameter(valid_773365, JArray, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "keys", valid_773365
  var valid_773366 = query.getOrDefault("deleteAll")
  valid_773366 = validateParameter(valid_773366, JBool, required = false, default = nil)
  if valid_773366 != nil:
    section.add "deleteAll", valid_773366
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
  var valid_773367 = header.getOrDefault("X-Amz-Date")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Date", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Security-Token")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Security-Token", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Content-Sha256", valid_773369
  var valid_773370 = header.getOrDefault("Authentication")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "Authentication", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Algorithm")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Algorithm", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Signature")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Signature", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-SignedHeaders", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Credential")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Credential", valid_773374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773375: Call_DeleteCustomMetadata_773360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_773375.validator(path, query, header, formData, body)
  let scheme = call_773375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773375.url(scheme.get, call_773375.host, call_773375.base,
                         call_773375.route, valid.getOrDefault("path"))
  result = hook(call_773375, url, valid)

proc call*(call_773376: Call_DeleteCustomMetadata_773360; ResourceId: string;
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
  var path_773377 = newJObject()
  var query_773378 = newJObject()
  add(query_773378, "versionId", newJString(versionId))
  if keys != nil:
    query_773378.add "keys", keys
  add(path_773377, "ResourceId", newJString(ResourceId))
  add(query_773378, "deleteAll", newJBool(deleteAll))
  result = call_773376.call(path_773377, query_773378, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_773360(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_773361, base: "/",
    url: url_DeleteCustomMetadata_773362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_773379 = ref object of OpenApiRestCall_772597
proc url_CreateFolder_773381(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFolder_773380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773382 = header.getOrDefault("X-Amz-Date")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Date", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Security-Token")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Security-Token", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Content-Sha256", valid_773384
  var valid_773385 = header.getOrDefault("Authentication")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "Authentication", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Algorithm")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Algorithm", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Signature")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Signature", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-SignedHeaders", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Credential")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Credential", valid_773389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773391: Call_CreateFolder_773379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_773391.validator(path, query, header, formData, body)
  let scheme = call_773391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773391.url(scheme.get, call_773391.host, call_773391.base,
                         call_773391.route, valid.getOrDefault("path"))
  result = hook(call_773391, url, valid)

proc call*(call_773392: Call_CreateFolder_773379; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_773393 = newJObject()
  if body != nil:
    body_773393 = body
  result = call_773392.call(nil, nil, nil, nil, body_773393)

var createFolder* = Call_CreateFolder_773379(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_773380, base: "/",
    url: url_CreateFolder_773381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_773394 = ref object of OpenApiRestCall_772597
proc url_CreateLabels_773396(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLabels_773395(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773397 = path.getOrDefault("ResourceId")
  valid_773397 = validateParameter(valid_773397, JString, required = true,
                                 default = nil)
  if valid_773397 != nil:
    section.add "ResourceId", valid_773397
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
  var valid_773398 = header.getOrDefault("X-Amz-Date")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Date", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Security-Token")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Security-Token", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Content-Sha256", valid_773400
  var valid_773401 = header.getOrDefault("Authentication")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "Authentication", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Algorithm")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Algorithm", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Signature")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Signature", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-SignedHeaders", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Credential")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Credential", valid_773405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773407: Call_CreateLabels_773394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_773407.validator(path, query, header, formData, body)
  let scheme = call_773407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773407.url(scheme.get, call_773407.host, call_773407.base,
                         call_773407.route, valid.getOrDefault("path"))
  result = hook(call_773407, url, valid)

proc call*(call_773408: Call_CreateLabels_773394; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_773409 = newJObject()
  var body_773410 = newJObject()
  add(path_773409, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_773410 = body
  result = call_773408.call(path_773409, nil, nil, nil, body_773410)

var createLabels* = Call_CreateLabels_773394(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_773395, base: "/", url: url_CreateLabels_773396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_773411 = ref object of OpenApiRestCall_772597
proc url_DeleteLabels_773413(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLabels_773412(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773414 = path.getOrDefault("ResourceId")
  valid_773414 = validateParameter(valid_773414, JString, required = true,
                                 default = nil)
  if valid_773414 != nil:
    section.add "ResourceId", valid_773414
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_773415 = query.getOrDefault("labels")
  valid_773415 = validateParameter(valid_773415, JArray, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "labels", valid_773415
  var valid_773416 = query.getOrDefault("deleteAll")
  valid_773416 = validateParameter(valid_773416, JBool, required = false, default = nil)
  if valid_773416 != nil:
    section.add "deleteAll", valid_773416
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
  var valid_773417 = header.getOrDefault("X-Amz-Date")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Date", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Security-Token")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Security-Token", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Content-Sha256", valid_773419
  var valid_773420 = header.getOrDefault("Authentication")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "Authentication", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Algorithm")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Algorithm", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Signature")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Signature", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-SignedHeaders", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Credential")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Credential", valid_773424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773425: Call_DeleteLabels_773411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_773425.validator(path, query, header, formData, body)
  let scheme = call_773425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773425.url(scheme.get, call_773425.host, call_773425.base,
                         call_773425.route, valid.getOrDefault("path"))
  result = hook(call_773425, url, valid)

proc call*(call_773426: Call_DeleteLabels_773411; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  var path_773427 = newJObject()
  var query_773428 = newJObject()
  if labels != nil:
    query_773428.add "labels", labels
  add(path_773427, "ResourceId", newJString(ResourceId))
  add(query_773428, "deleteAll", newJBool(deleteAll))
  result = call_773426.call(path_773427, query_773428, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_773411(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_773412, base: "/", url: url_DeleteLabels_773413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_773446 = ref object of OpenApiRestCall_772597
proc url_CreateNotificationSubscription_773448(protocol: Scheme; host: string;
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

proc validate_CreateNotificationSubscription_773447(path: JsonNode;
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
  var valid_773449 = path.getOrDefault("OrganizationId")
  valid_773449 = validateParameter(valid_773449, JString, required = true,
                                 default = nil)
  if valid_773449 != nil:
    section.add "OrganizationId", valid_773449
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
  var valid_773450 = header.getOrDefault("X-Amz-Date")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Date", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Security-Token")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Security-Token", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Content-Sha256", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Algorithm")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Algorithm", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Signature")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Signature", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-SignedHeaders", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Credential")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Credential", valid_773456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773458: Call_CreateNotificationSubscription_773446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_773458.validator(path, query, header, formData, body)
  let scheme = call_773458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773458.url(scheme.get, call_773458.host, call_773458.base,
                         call_773458.route, valid.getOrDefault("path"))
  result = hook(call_773458, url, valid)

proc call*(call_773459: Call_CreateNotificationSubscription_773446;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_773460 = newJObject()
  var body_773461 = newJObject()
  add(path_773460, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_773461 = body
  result = call_773459.call(path_773460, nil, nil, nil, body_773461)

var createNotificationSubscription* = Call_CreateNotificationSubscription_773446(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_773447, base: "/",
    url: url_CreateNotificationSubscription_773448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_773429 = ref object of OpenApiRestCall_772597
proc url_DescribeNotificationSubscriptions_773431(protocol: Scheme; host: string;
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

proc validate_DescribeNotificationSubscriptions_773430(path: JsonNode;
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
  var valid_773432 = path.getOrDefault("OrganizationId")
  valid_773432 = validateParameter(valid_773432, JString, required = true,
                                 default = nil)
  if valid_773432 != nil:
    section.add "OrganizationId", valid_773432
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_773433 = query.getOrDefault("marker")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "marker", valid_773433
  var valid_773434 = query.getOrDefault("limit")
  valid_773434 = validateParameter(valid_773434, JInt, required = false, default = nil)
  if valid_773434 != nil:
    section.add "limit", valid_773434
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
  var valid_773435 = header.getOrDefault("X-Amz-Date")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Date", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Security-Token")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Security-Token", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Content-Sha256", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Algorithm")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Algorithm", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Signature")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Signature", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-SignedHeaders", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Credential")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Credential", valid_773441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773442: Call_DescribeNotificationSubscriptions_773429;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_773442.validator(path, query, header, formData, body)
  let scheme = call_773442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773442.url(scheme.get, call_773442.host, call_773442.base,
                         call_773442.route, valid.getOrDefault("path"))
  result = hook(call_773442, url, valid)

proc call*(call_773443: Call_DescribeNotificationSubscriptions_773429;
          OrganizationId: string; marker: string = ""; limit: int = 0): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  var path_773444 = newJObject()
  var query_773445 = newJObject()
  add(path_773444, "OrganizationId", newJString(OrganizationId))
  add(query_773445, "marker", newJString(marker))
  add(query_773445, "limit", newJInt(limit))
  result = call_773443.call(path_773444, query_773445, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_773429(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_773430, base: "/",
    url: url_DescribeNotificationSubscriptions_773431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_773500 = ref object of OpenApiRestCall_772597
proc url_CreateUser_773502(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUser_773501(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773503 = header.getOrDefault("X-Amz-Date")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Date", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Security-Token")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Security-Token", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Content-Sha256", valid_773505
  var valid_773506 = header.getOrDefault("Authentication")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "Authentication", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Algorithm")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Algorithm", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Signature")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Signature", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-SignedHeaders", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Credential")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Credential", valid_773510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773512: Call_CreateUser_773500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_773512.validator(path, query, header, formData, body)
  let scheme = call_773512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773512.url(scheme.get, call_773512.host, call_773512.base,
                         call_773512.route, valid.getOrDefault("path"))
  result = hook(call_773512, url, valid)

proc call*(call_773513: Call_CreateUser_773500; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_773514 = newJObject()
  if body != nil:
    body_773514 = body
  result = call_773513.call(nil, nil, nil, nil, body_773514)

var createUser* = Call_CreateUser_773500(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_773501,
                                      base: "/", url: url_CreateUser_773502,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_773462 = ref object of OpenApiRestCall_772597
proc url_DescribeUsers_773464(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUsers_773463(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773465 = query.getOrDefault("fields")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "fields", valid_773465
  var valid_773466 = query.getOrDefault("query")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "query", valid_773466
  var valid_773480 = query.getOrDefault("sort")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_773480 != nil:
    section.add "sort", valid_773480
  var valid_773481 = query.getOrDefault("order")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_773481 != nil:
    section.add "order", valid_773481
  var valid_773482 = query.getOrDefault("Limit")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "Limit", valid_773482
  var valid_773483 = query.getOrDefault("include")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = newJString("ALL"))
  if valid_773483 != nil:
    section.add "include", valid_773483
  var valid_773484 = query.getOrDefault("organizationId")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "organizationId", valid_773484
  var valid_773485 = query.getOrDefault("marker")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "marker", valid_773485
  var valid_773486 = query.getOrDefault("Marker")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "Marker", valid_773486
  var valid_773487 = query.getOrDefault("limit")
  valid_773487 = validateParameter(valid_773487, JInt, required = false, default = nil)
  if valid_773487 != nil:
    section.add "limit", valid_773487
  var valid_773488 = query.getOrDefault("userIds")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "userIds", valid_773488
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
  var valid_773489 = header.getOrDefault("X-Amz-Date")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Date", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Security-Token")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Security-Token", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Content-Sha256", valid_773491
  var valid_773492 = header.getOrDefault("Authentication")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "Authentication", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Algorithm")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Algorithm", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Signature")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Signature", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-SignedHeaders", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Credential")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Credential", valid_773496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773497: Call_DescribeUsers_773462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_773497.validator(path, query, header, formData, body)
  let scheme = call_773497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773497.url(scheme.get, call_773497.host, call_773497.base,
                         call_773497.route, valid.getOrDefault("path"))
  result = hook(call_773497, url, valid)

proc call*(call_773498: Call_DescribeUsers_773462; fields: string = "";
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
  var query_773499 = newJObject()
  add(query_773499, "fields", newJString(fields))
  add(query_773499, "query", newJString(query))
  add(query_773499, "sort", newJString(sort))
  add(query_773499, "order", newJString(order))
  add(query_773499, "Limit", newJString(Limit))
  add(query_773499, "include", newJString(`include`))
  add(query_773499, "organizationId", newJString(organizationId))
  add(query_773499, "marker", newJString(marker))
  add(query_773499, "Marker", newJString(Marker))
  add(query_773499, "limit", newJInt(limit))
  add(query_773499, "userIds", newJString(userIds))
  result = call_773498.call(nil, query_773499, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_773462(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_773463, base: "/",
    url: url_DescribeUsers_773464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_773515 = ref object of OpenApiRestCall_772597
proc url_DeleteComment_773517(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteComment_773516(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773518 = path.getOrDefault("CommentId")
  valid_773518 = validateParameter(valid_773518, JString, required = true,
                                 default = nil)
  if valid_773518 != nil:
    section.add "CommentId", valid_773518
  var valid_773519 = path.getOrDefault("VersionId")
  valid_773519 = validateParameter(valid_773519, JString, required = true,
                                 default = nil)
  if valid_773519 != nil:
    section.add "VersionId", valid_773519
  var valid_773520 = path.getOrDefault("DocumentId")
  valid_773520 = validateParameter(valid_773520, JString, required = true,
                                 default = nil)
  if valid_773520 != nil:
    section.add "DocumentId", valid_773520
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
  var valid_773521 = header.getOrDefault("X-Amz-Date")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Date", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Security-Token")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Security-Token", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Content-Sha256", valid_773523
  var valid_773524 = header.getOrDefault("Authentication")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "Authentication", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Algorithm")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Algorithm", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-Signature")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-Signature", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-SignedHeaders", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Credential")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Credential", valid_773528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773529: Call_DeleteComment_773515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_773529.validator(path, query, header, formData, body)
  let scheme = call_773529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773529.url(scheme.get, call_773529.host, call_773529.base,
                         call_773529.route, valid.getOrDefault("path"))
  result = hook(call_773529, url, valid)

proc call*(call_773530: Call_DeleteComment_773515; CommentId: string;
          VersionId: string; DocumentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_773531 = newJObject()
  add(path_773531, "CommentId", newJString(CommentId))
  add(path_773531, "VersionId", newJString(VersionId))
  add(path_773531, "DocumentId", newJString(DocumentId))
  result = call_773530.call(path_773531, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_773515(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_773516, base: "/", url: url_DeleteComment_773517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_773532 = ref object of OpenApiRestCall_772597
proc url_GetDocument_773534(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_773533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773535 = path.getOrDefault("DocumentId")
  valid_773535 = validateParameter(valid_773535, JString, required = true,
                                 default = nil)
  if valid_773535 != nil:
    section.add "DocumentId", valid_773535
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_773536 = query.getOrDefault("includeCustomMetadata")
  valid_773536 = validateParameter(valid_773536, JBool, required = false, default = nil)
  if valid_773536 != nil:
    section.add "includeCustomMetadata", valid_773536
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
  var valid_773537 = header.getOrDefault("X-Amz-Date")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Date", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Security-Token")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Security-Token", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Content-Sha256", valid_773539
  var valid_773540 = header.getOrDefault("Authentication")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "Authentication", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-Algorithm")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-Algorithm", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Signature")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Signature", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-SignedHeaders", valid_773543
  var valid_773544 = header.getOrDefault("X-Amz-Credential")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Credential", valid_773544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773545: Call_GetDocument_773532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_773545.validator(path, query, header, formData, body)
  let scheme = call_773545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773545.url(scheme.get, call_773545.host, call_773545.base,
                         call_773545.route, valid.getOrDefault("path"))
  result = hook(call_773545, url, valid)

proc call*(call_773546: Call_GetDocument_773532; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_773547 = newJObject()
  var query_773548 = newJObject()
  add(query_773548, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_773547, "DocumentId", newJString(DocumentId))
  result = call_773546.call(path_773547, query_773548, nil, nil, nil)

var getDocument* = Call_GetDocument_773532(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_773533,
                                        base: "/", url: url_GetDocument_773534,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_773564 = ref object of OpenApiRestCall_772597
proc url_UpdateDocument_773566(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_773565(path: JsonNode; query: JsonNode;
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
  var valid_773567 = path.getOrDefault("DocumentId")
  valid_773567 = validateParameter(valid_773567, JString, required = true,
                                 default = nil)
  if valid_773567 != nil:
    section.add "DocumentId", valid_773567
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
  var valid_773568 = header.getOrDefault("X-Amz-Date")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Date", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Security-Token")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Security-Token", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Content-Sha256", valid_773570
  var valid_773571 = header.getOrDefault("Authentication")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "Authentication", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Algorithm")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Algorithm", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Signature")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Signature", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-SignedHeaders", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Credential")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Credential", valid_773575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773577: Call_UpdateDocument_773564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_773577.validator(path, query, header, formData, body)
  let scheme = call_773577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773577.url(scheme.get, call_773577.host, call_773577.base,
                         call_773577.route, valid.getOrDefault("path"))
  result = hook(call_773577, url, valid)

proc call*(call_773578: Call_UpdateDocument_773564; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_773579 = newJObject()
  var body_773580 = newJObject()
  add(path_773579, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_773580 = body
  result = call_773578.call(path_773579, nil, nil, nil, body_773580)

var updateDocument* = Call_UpdateDocument_773564(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_773565,
    base: "/", url: url_UpdateDocument_773566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_773549 = ref object of OpenApiRestCall_772597
proc url_DeleteDocument_773551(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_773550(path: JsonNode; query: JsonNode;
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
  var valid_773552 = path.getOrDefault("DocumentId")
  valid_773552 = validateParameter(valid_773552, JString, required = true,
                                 default = nil)
  if valid_773552 != nil:
    section.add "DocumentId", valid_773552
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
  var valid_773553 = header.getOrDefault("X-Amz-Date")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Date", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Security-Token")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Security-Token", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Content-Sha256", valid_773555
  var valid_773556 = header.getOrDefault("Authentication")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "Authentication", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Algorithm")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Algorithm", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Signature")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Signature", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-SignedHeaders", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Credential")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Credential", valid_773560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773561: Call_DeleteDocument_773549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_773561.validator(path, query, header, formData, body)
  let scheme = call_773561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773561.url(scheme.get, call_773561.host, call_773561.base,
                         call_773561.route, valid.getOrDefault("path"))
  result = hook(call_773561, url, valid)

proc call*(call_773562: Call_DeleteDocument_773549; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_773563 = newJObject()
  add(path_773563, "DocumentId", newJString(DocumentId))
  result = call_773562.call(path_773563, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_773549(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_773550,
    base: "/", url: url_DeleteDocument_773551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_773581 = ref object of OpenApiRestCall_772597
proc url_GetFolder_773583(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFolder_773582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773584 = path.getOrDefault("FolderId")
  valid_773584 = validateParameter(valid_773584, JString, required = true,
                                 default = nil)
  if valid_773584 != nil:
    section.add "FolderId", valid_773584
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_773585 = query.getOrDefault("includeCustomMetadata")
  valid_773585 = validateParameter(valid_773585, JBool, required = false, default = nil)
  if valid_773585 != nil:
    section.add "includeCustomMetadata", valid_773585
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
  var valid_773586 = header.getOrDefault("X-Amz-Date")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Date", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Security-Token")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Security-Token", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Content-Sha256", valid_773588
  var valid_773589 = header.getOrDefault("Authentication")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "Authentication", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Algorithm")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Algorithm", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Signature")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Signature", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-SignedHeaders", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-Credential")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Credential", valid_773593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773594: Call_GetFolder_773581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_773594.validator(path, query, header, formData, body)
  let scheme = call_773594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773594.url(scheme.get, call_773594.host, call_773594.base,
                         call_773594.route, valid.getOrDefault("path"))
  result = hook(call_773594, url, valid)

proc call*(call_773595: Call_GetFolder_773581; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  var path_773596 = newJObject()
  var query_773597 = newJObject()
  add(path_773596, "FolderId", newJString(FolderId))
  add(query_773597, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_773595.call(path_773596, query_773597, nil, nil, nil)

var getFolder* = Call_GetFolder_773581(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_773582,
                                    base: "/", url: url_GetFolder_773583,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_773613 = ref object of OpenApiRestCall_772597
proc url_UpdateFolder_773615(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFolder_773614(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773616 = path.getOrDefault("FolderId")
  valid_773616 = validateParameter(valid_773616, JString, required = true,
                                 default = nil)
  if valid_773616 != nil:
    section.add "FolderId", valid_773616
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
  var valid_773617 = header.getOrDefault("X-Amz-Date")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Date", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Security-Token")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Security-Token", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Content-Sha256", valid_773619
  var valid_773620 = header.getOrDefault("Authentication")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "Authentication", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Algorithm")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Algorithm", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Signature")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Signature", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-SignedHeaders", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Credential")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Credential", valid_773624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773626: Call_UpdateFolder_773613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_773626.validator(path, query, header, formData, body)
  let scheme = call_773626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773626.url(scheme.get, call_773626.host, call_773626.base,
                         call_773626.route, valid.getOrDefault("path"))
  result = hook(call_773626, url, valid)

proc call*(call_773627: Call_UpdateFolder_773613; FolderId: string; body: JsonNode): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   body: JObject (required)
  var path_773628 = newJObject()
  var body_773629 = newJObject()
  add(path_773628, "FolderId", newJString(FolderId))
  if body != nil:
    body_773629 = body
  result = call_773627.call(path_773628, nil, nil, nil, body_773629)

var updateFolder* = Call_UpdateFolder_773613(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_773614,
    base: "/", url: url_UpdateFolder_773615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_773598 = ref object of OpenApiRestCall_772597
proc url_DeleteFolder_773600(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolder_773599(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773601 = path.getOrDefault("FolderId")
  valid_773601 = validateParameter(valid_773601, JString, required = true,
                                 default = nil)
  if valid_773601 != nil:
    section.add "FolderId", valid_773601
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
  var valid_773602 = header.getOrDefault("X-Amz-Date")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Date", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Security-Token")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Security-Token", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Content-Sha256", valid_773604
  var valid_773605 = header.getOrDefault("Authentication")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "Authentication", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Algorithm")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Algorithm", valid_773606
  var valid_773607 = header.getOrDefault("X-Amz-Signature")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Signature", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-SignedHeaders", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Credential")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Credential", valid_773609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773610: Call_DeleteFolder_773598; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_773610.validator(path, query, header, formData, body)
  let scheme = call_773610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773610.url(scheme.get, call_773610.host, call_773610.base,
                         call_773610.route, valid.getOrDefault("path"))
  result = hook(call_773610, url, valid)

proc call*(call_773611: Call_DeleteFolder_773598; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_773612 = newJObject()
  add(path_773612, "FolderId", newJString(FolderId))
  result = call_773611.call(path_773612, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_773598(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_773599,
    base: "/", url: url_DeleteFolder_773600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_773630 = ref object of OpenApiRestCall_772597
proc url_DescribeFolderContents_773632(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFolderContents_773631(path: JsonNode; query: JsonNode;
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
  var valid_773633 = path.getOrDefault("FolderId")
  valid_773633 = validateParameter(valid_773633, JString, required = true,
                                 default = nil)
  if valid_773633 != nil:
    section.add "FolderId", valid_773633
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
  var valid_773634 = query.getOrDefault("sort")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = newJString("DATE"))
  if valid_773634 != nil:
    section.add "sort", valid_773634
  var valid_773635 = query.getOrDefault("type")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = newJString("ALL"))
  if valid_773635 != nil:
    section.add "type", valid_773635
  var valid_773636 = query.getOrDefault("order")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_773636 != nil:
    section.add "order", valid_773636
  var valid_773637 = query.getOrDefault("Limit")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "Limit", valid_773637
  var valid_773638 = query.getOrDefault("include")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "include", valid_773638
  var valid_773639 = query.getOrDefault("marker")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "marker", valid_773639
  var valid_773640 = query.getOrDefault("Marker")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "Marker", valid_773640
  var valid_773641 = query.getOrDefault("limit")
  valid_773641 = validateParameter(valid_773641, JInt, required = false, default = nil)
  if valid_773641 != nil:
    section.add "limit", valid_773641
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
  var valid_773642 = header.getOrDefault("X-Amz-Date")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Date", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Security-Token")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Security-Token", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Content-Sha256", valid_773644
  var valid_773645 = header.getOrDefault("Authentication")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "Authentication", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Algorithm")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Algorithm", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Signature")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Signature", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-SignedHeaders", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Credential")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Credential", valid_773649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773650: Call_DescribeFolderContents_773630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_773650.validator(path, query, header, formData, body)
  let scheme = call_773650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773650.url(scheme.get, call_773650.host, call_773650.base,
                         call_773650.route, valid.getOrDefault("path"))
  result = hook(call_773650, url, valid)

proc call*(call_773651: Call_DescribeFolderContents_773630; FolderId: string;
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
  var path_773652 = newJObject()
  var query_773653 = newJObject()
  add(query_773653, "sort", newJString(sort))
  add(query_773653, "type", newJString(`type`))
  add(query_773653, "order", newJString(order))
  add(query_773653, "Limit", newJString(Limit))
  add(query_773653, "include", newJString(`include`))
  add(path_773652, "FolderId", newJString(FolderId))
  add(query_773653, "marker", newJString(marker))
  add(query_773653, "Marker", newJString(Marker))
  add(query_773653, "limit", newJInt(limit))
  result = call_773651.call(path_773652, query_773653, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_773630(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_773631, base: "/",
    url: url_DescribeFolderContents_773632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_773654 = ref object of OpenApiRestCall_772597
proc url_DeleteFolderContents_773656(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolderContents_773655(path: JsonNode; query: JsonNode;
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
  var valid_773657 = path.getOrDefault("FolderId")
  valid_773657 = validateParameter(valid_773657, JString, required = true,
                                 default = nil)
  if valid_773657 != nil:
    section.add "FolderId", valid_773657
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
  var valid_773658 = header.getOrDefault("X-Amz-Date")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Date", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Security-Token")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Security-Token", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Content-Sha256", valid_773660
  var valid_773661 = header.getOrDefault("Authentication")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "Authentication", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Algorithm")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Algorithm", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Signature")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Signature", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-SignedHeaders", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Credential")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Credential", valid_773665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773666: Call_DeleteFolderContents_773654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_773666.validator(path, query, header, formData, body)
  let scheme = call_773666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773666.url(scheme.get, call_773666.host, call_773666.base,
                         call_773666.route, valid.getOrDefault("path"))
  result = hook(call_773666, url, valid)

proc call*(call_773667: Call_DeleteFolderContents_773654; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_773668 = newJObject()
  add(path_773668, "FolderId", newJString(FolderId))
  result = call_773667.call(path_773668, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_773654(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_773655, base: "/",
    url: url_DeleteFolderContents_773656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_773669 = ref object of OpenApiRestCall_772597
proc url_DeleteNotificationSubscription_773671(protocol: Scheme; host: string;
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

proc validate_DeleteNotificationSubscription_773670(path: JsonNode;
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
  var valid_773672 = path.getOrDefault("SubscriptionId")
  valid_773672 = validateParameter(valid_773672, JString, required = true,
                                 default = nil)
  if valid_773672 != nil:
    section.add "SubscriptionId", valid_773672
  var valid_773673 = path.getOrDefault("OrganizationId")
  valid_773673 = validateParameter(valid_773673, JString, required = true,
                                 default = nil)
  if valid_773673 != nil:
    section.add "OrganizationId", valid_773673
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
  var valid_773674 = header.getOrDefault("X-Amz-Date")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Date", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Security-Token")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Security-Token", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Content-Sha256", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Algorithm")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Algorithm", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Signature")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Signature", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-SignedHeaders", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Credential")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Credential", valid_773680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773681: Call_DeleteNotificationSubscription_773669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_773681.validator(path, query, header, formData, body)
  let scheme = call_773681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773681.url(scheme.get, call_773681.host, call_773681.base,
                         call_773681.route, valid.getOrDefault("path"))
  result = hook(call_773681, url, valid)

proc call*(call_773682: Call_DeleteNotificationSubscription_773669;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_773683 = newJObject()
  add(path_773683, "SubscriptionId", newJString(SubscriptionId))
  add(path_773683, "OrganizationId", newJString(OrganizationId))
  result = call_773682.call(path_773683, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_773669(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_773670, base: "/",
    url: url_DeleteNotificationSubscription_773671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_773699 = ref object of OpenApiRestCall_772597
proc url_UpdateUser_773701(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_773700(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773702 = path.getOrDefault("UserId")
  valid_773702 = validateParameter(valid_773702, JString, required = true,
                                 default = nil)
  if valid_773702 != nil:
    section.add "UserId", valid_773702
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
  var valid_773703 = header.getOrDefault("X-Amz-Date")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Date", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Security-Token")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Security-Token", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Content-Sha256", valid_773705
  var valid_773706 = header.getOrDefault("Authentication")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "Authentication", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Algorithm")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Algorithm", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Signature")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Signature", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-SignedHeaders", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Credential")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Credential", valid_773710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773712: Call_UpdateUser_773699; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_773712.validator(path, query, header, formData, body)
  let scheme = call_773712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773712.url(scheme.get, call_773712.host, call_773712.base,
                         call_773712.route, valid.getOrDefault("path"))
  result = hook(call_773712, url, valid)

proc call*(call_773713: Call_UpdateUser_773699; body: JsonNode; UserId: string): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_773714 = newJObject()
  var body_773715 = newJObject()
  if body != nil:
    body_773715 = body
  add(path_773714, "UserId", newJString(UserId))
  result = call_773713.call(path_773714, nil, nil, nil, body_773715)

var updateUser* = Call_UpdateUser_773699(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_773700,
                                      base: "/", url: url_UpdateUser_773701,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_773684 = ref object of OpenApiRestCall_772597
proc url_DeleteUser_773686(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_773685(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773687 = path.getOrDefault("UserId")
  valid_773687 = validateParameter(valid_773687, JString, required = true,
                                 default = nil)
  if valid_773687 != nil:
    section.add "UserId", valid_773687
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
  var valid_773688 = header.getOrDefault("X-Amz-Date")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Date", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Security-Token")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Security-Token", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Content-Sha256", valid_773690
  var valid_773691 = header.getOrDefault("Authentication")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "Authentication", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Algorithm")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Algorithm", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Signature")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Signature", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-SignedHeaders", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Credential")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Credential", valid_773695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773696: Call_DeleteUser_773684; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_773696.validator(path, query, header, formData, body)
  let scheme = call_773696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773696.url(scheme.get, call_773696.host, call_773696.base,
                         call_773696.route, valid.getOrDefault("path"))
  result = hook(call_773696, url, valid)

proc call*(call_773697: Call_DeleteUser_773684; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_773698 = newJObject()
  add(path_773698, "UserId", newJString(UserId))
  result = call_773697.call(path_773698, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_773684(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_773685,
                                      base: "/", url: url_DeleteUser_773686,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_773716 = ref object of OpenApiRestCall_772597
proc url_DescribeActivities_773718(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeActivities_773717(path: JsonNode; query: JsonNode;
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
  var valid_773719 = query.getOrDefault("endTime")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "endTime", valid_773719
  var valid_773720 = query.getOrDefault("organizationId")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "organizationId", valid_773720
  var valid_773721 = query.getOrDefault("includeIndirectActivities")
  valid_773721 = validateParameter(valid_773721, JBool, required = false, default = nil)
  if valid_773721 != nil:
    section.add "includeIndirectActivities", valid_773721
  var valid_773722 = query.getOrDefault("activityTypes")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "activityTypes", valid_773722
  var valid_773723 = query.getOrDefault("marker")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "marker", valid_773723
  var valid_773724 = query.getOrDefault("resourceId")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "resourceId", valid_773724
  var valid_773725 = query.getOrDefault("startTime")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "startTime", valid_773725
  var valid_773726 = query.getOrDefault("limit")
  valid_773726 = validateParameter(valid_773726, JInt, required = false, default = nil)
  if valid_773726 != nil:
    section.add "limit", valid_773726
  var valid_773727 = query.getOrDefault("userId")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "userId", valid_773727
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
  var valid_773728 = header.getOrDefault("X-Amz-Date")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Date", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Security-Token")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Security-Token", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Content-Sha256", valid_773730
  var valid_773731 = header.getOrDefault("Authentication")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "Authentication", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Algorithm")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Algorithm", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Signature")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Signature", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-SignedHeaders", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-Credential")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Credential", valid_773735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773736: Call_DescribeActivities_773716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_773736.validator(path, query, header, formData, body)
  let scheme = call_773736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773736.url(scheme.get, call_773736.host, call_773736.base,
                         call_773736.route, valid.getOrDefault("path"))
  result = hook(call_773736, url, valid)

proc call*(call_773737: Call_DescribeActivities_773716; endTime: string = "";
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
  var query_773738 = newJObject()
  add(query_773738, "endTime", newJString(endTime))
  add(query_773738, "organizationId", newJString(organizationId))
  add(query_773738, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_773738, "activityTypes", newJString(activityTypes))
  add(query_773738, "marker", newJString(marker))
  add(query_773738, "resourceId", newJString(resourceId))
  add(query_773738, "startTime", newJString(startTime))
  add(query_773738, "limit", newJInt(limit))
  add(query_773738, "userId", newJString(userId))
  result = call_773737.call(nil, query_773738, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_773716(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_773717, base: "/",
    url: url_DescribeActivities_773718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_773739 = ref object of OpenApiRestCall_772597
proc url_DescribeComments_773741(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeComments_773740(path: JsonNode; query: JsonNode;
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
  var valid_773742 = path.getOrDefault("VersionId")
  valid_773742 = validateParameter(valid_773742, JString, required = true,
                                 default = nil)
  if valid_773742 != nil:
    section.add "VersionId", valid_773742
  var valid_773743 = path.getOrDefault("DocumentId")
  valid_773743 = validateParameter(valid_773743, JString, required = true,
                                 default = nil)
  if valid_773743 != nil:
    section.add "DocumentId", valid_773743
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   limit: JInt
  ##        : The maximum number of items to return.
  section = newJObject()
  var valid_773744 = query.getOrDefault("marker")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "marker", valid_773744
  var valid_773745 = query.getOrDefault("limit")
  valid_773745 = validateParameter(valid_773745, JInt, required = false, default = nil)
  if valid_773745 != nil:
    section.add "limit", valid_773745
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
  var valid_773746 = header.getOrDefault("X-Amz-Date")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Date", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Security-Token")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Security-Token", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Content-Sha256", valid_773748
  var valid_773749 = header.getOrDefault("Authentication")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "Authentication", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Algorithm")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Algorithm", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Signature")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Signature", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-SignedHeaders", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Credential")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Credential", valid_773753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773754: Call_DescribeComments_773739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_773754.validator(path, query, header, formData, body)
  let scheme = call_773754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773754.url(scheme.get, call_773754.host, call_773754.base,
                         call_773754.route, valid.getOrDefault("path"))
  result = hook(call_773754, url, valid)

proc call*(call_773755: Call_DescribeComments_773739; VersionId: string;
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
  var path_773756 = newJObject()
  var query_773757 = newJObject()
  add(path_773756, "VersionId", newJString(VersionId))
  add(query_773757, "marker", newJString(marker))
  add(path_773756, "DocumentId", newJString(DocumentId))
  add(query_773757, "limit", newJInt(limit))
  result = call_773755.call(path_773756, query_773757, nil, nil, nil)

var describeComments* = Call_DescribeComments_773739(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_773740, base: "/",
    url: url_DescribeComments_773741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_773758 = ref object of OpenApiRestCall_772597
proc url_DescribeDocumentVersions_773760(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentVersions_773759(path: JsonNode; query: JsonNode;
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
  var valid_773761 = path.getOrDefault("DocumentId")
  valid_773761 = validateParameter(valid_773761, JString, required = true,
                                 default = nil)
  if valid_773761 != nil:
    section.add "DocumentId", valid_773761
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
  var valid_773762 = query.getOrDefault("fields")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "fields", valid_773762
  var valid_773763 = query.getOrDefault("Limit")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "Limit", valid_773763
  var valid_773764 = query.getOrDefault("include")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "include", valid_773764
  var valid_773765 = query.getOrDefault("marker")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "marker", valid_773765
  var valid_773766 = query.getOrDefault("Marker")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "Marker", valid_773766
  var valid_773767 = query.getOrDefault("limit")
  valid_773767 = validateParameter(valid_773767, JInt, required = false, default = nil)
  if valid_773767 != nil:
    section.add "limit", valid_773767
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
  var valid_773768 = header.getOrDefault("X-Amz-Date")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Date", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-Security-Token")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Security-Token", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Content-Sha256", valid_773770
  var valid_773771 = header.getOrDefault("Authentication")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "Authentication", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Algorithm")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Algorithm", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-Signature")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-Signature", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-SignedHeaders", valid_773774
  var valid_773775 = header.getOrDefault("X-Amz-Credential")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-Credential", valid_773775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773776: Call_DescribeDocumentVersions_773758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_773776.validator(path, query, header, formData, body)
  let scheme = call_773776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773776.url(scheme.get, call_773776.host, call_773776.base,
                         call_773776.route, valid.getOrDefault("path"))
  result = hook(call_773776, url, valid)

proc call*(call_773777: Call_DescribeDocumentVersions_773758; DocumentId: string;
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
  var path_773778 = newJObject()
  var query_773779 = newJObject()
  add(query_773779, "fields", newJString(fields))
  add(query_773779, "Limit", newJString(Limit))
  add(query_773779, "include", newJString(`include`))
  add(query_773779, "marker", newJString(marker))
  add(query_773779, "Marker", newJString(Marker))
  add(path_773778, "DocumentId", newJString(DocumentId))
  add(query_773779, "limit", newJInt(limit))
  result = call_773777.call(path_773778, query_773779, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_773758(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_773759, base: "/",
    url: url_DescribeDocumentVersions_773760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_773780 = ref object of OpenApiRestCall_772597
proc url_DescribeGroups_773782(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeGroups_773781(path: JsonNode; query: JsonNode;
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
  var valid_773783 = query.getOrDefault("searchQuery")
  valid_773783 = validateParameter(valid_773783, JString, required = true,
                                 default = nil)
  if valid_773783 != nil:
    section.add "searchQuery", valid_773783
  var valid_773784 = query.getOrDefault("organizationId")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "organizationId", valid_773784
  var valid_773785 = query.getOrDefault("marker")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "marker", valid_773785
  var valid_773786 = query.getOrDefault("limit")
  valid_773786 = validateParameter(valid_773786, JInt, required = false, default = nil)
  if valid_773786 != nil:
    section.add "limit", valid_773786
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
  var valid_773787 = header.getOrDefault("X-Amz-Date")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Date", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Security-Token")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Security-Token", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Content-Sha256", valid_773789
  var valid_773790 = header.getOrDefault("Authentication")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "Authentication", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Algorithm")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Algorithm", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-Signature")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Signature", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-SignedHeaders", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Credential")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Credential", valid_773794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773795: Call_DescribeGroups_773780; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_773795.validator(path, query, header, formData, body)
  let scheme = call_773795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773795.url(scheme.get, call_773795.host, call_773795.base,
                         call_773795.route, valid.getOrDefault("path"))
  result = hook(call_773795, url, valid)

proc call*(call_773796: Call_DescribeGroups_773780; searchQuery: string;
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
  var query_773797 = newJObject()
  add(query_773797, "searchQuery", newJString(searchQuery))
  add(query_773797, "organizationId", newJString(organizationId))
  add(query_773797, "marker", newJString(marker))
  add(query_773797, "limit", newJInt(limit))
  result = call_773796.call(nil, query_773797, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_773780(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_773781,
    base: "/", url: url_DescribeGroups_773782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_773798 = ref object of OpenApiRestCall_772597
proc url_DescribeRootFolders_773800(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRootFolders_773799(path: JsonNode; query: JsonNode;
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
  var valid_773801 = query.getOrDefault("marker")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "marker", valid_773801
  var valid_773802 = query.getOrDefault("limit")
  valid_773802 = validateParameter(valid_773802, JInt, required = false, default = nil)
  if valid_773802 != nil:
    section.add "limit", valid_773802
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
  var valid_773803 = header.getOrDefault("X-Amz-Date")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Date", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Security-Token")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Security-Token", valid_773804
  var valid_773805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Content-Sha256", valid_773805
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_773806 = header.getOrDefault("Authentication")
  valid_773806 = validateParameter(valid_773806, JString, required = true,
                                 default = nil)
  if valid_773806 != nil:
    section.add "Authentication", valid_773806
  var valid_773807 = header.getOrDefault("X-Amz-Algorithm")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "X-Amz-Algorithm", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Signature")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Signature", valid_773808
  var valid_773809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-SignedHeaders", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-Credential")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-Credential", valid_773810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773811: Call_DescribeRootFolders_773798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_773811.validator(path, query, header, formData, body)
  let scheme = call_773811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773811.url(scheme.get, call_773811.host, call_773811.base,
                         call_773811.route, valid.getOrDefault("path"))
  result = hook(call_773811, url, valid)

proc call*(call_773812: Call_DescribeRootFolders_773798; marker: string = "";
          limit: int = 0): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return.
  var query_773813 = newJObject()
  add(query_773813, "marker", newJString(marker))
  add(query_773813, "limit", newJInt(limit))
  result = call_773812.call(nil, query_773813, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_773798(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_773799, base: "/",
    url: url_DescribeRootFolders_773800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_773814 = ref object of OpenApiRestCall_772597
proc url_GetCurrentUser_773816(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCurrentUser_773815(path: JsonNode; query: JsonNode;
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
  var valid_773817 = header.getOrDefault("X-Amz-Date")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Date", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Security-Token")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Security-Token", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Content-Sha256", valid_773819
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_773820 = header.getOrDefault("Authentication")
  valid_773820 = validateParameter(valid_773820, JString, required = true,
                                 default = nil)
  if valid_773820 != nil:
    section.add "Authentication", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Algorithm")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Algorithm", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-Signature")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-Signature", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-SignedHeaders", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Credential")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Credential", valid_773824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773825: Call_GetCurrentUser_773814; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_773825.validator(path, query, header, formData, body)
  let scheme = call_773825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773825.url(scheme.get, call_773825.host, call_773825.base,
                         call_773825.route, valid.getOrDefault("path"))
  result = hook(call_773825, url, valid)

proc call*(call_773826: Call_GetCurrentUser_773814): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_773826.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_773814(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_773815,
    base: "/", url: url_GetCurrentUser_773816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_773827 = ref object of OpenApiRestCall_772597
proc url_GetDocumentPath_773829(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentPath_773828(path: JsonNode; query: JsonNode;
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
  var valid_773830 = path.getOrDefault("DocumentId")
  valid_773830 = validateParameter(valid_773830, JString, required = true,
                                 default = nil)
  if valid_773830 != nil:
    section.add "DocumentId", valid_773830
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_773831 = query.getOrDefault("fields")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "fields", valid_773831
  var valid_773832 = query.getOrDefault("marker")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "marker", valid_773832
  var valid_773833 = query.getOrDefault("limit")
  valid_773833 = validateParameter(valid_773833, JInt, required = false, default = nil)
  if valid_773833 != nil:
    section.add "limit", valid_773833
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
  var valid_773834 = header.getOrDefault("X-Amz-Date")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Date", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Security-Token")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Security-Token", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Content-Sha256", valid_773836
  var valid_773837 = header.getOrDefault("Authentication")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "Authentication", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Algorithm")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Algorithm", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Signature")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Signature", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-SignedHeaders", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-Credential")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-Credential", valid_773841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773842: Call_GetDocumentPath_773827; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_773842.validator(path, query, header, formData, body)
  let scheme = call_773842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773842.url(scheme.get, call_773842.host, call_773842.base,
                         call_773842.route, valid.getOrDefault("path"))
  result = hook(call_773842, url, valid)

proc call*(call_773843: Call_GetDocumentPath_773827; DocumentId: string;
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
  var path_773844 = newJObject()
  var query_773845 = newJObject()
  add(query_773845, "fields", newJString(fields))
  add(query_773845, "marker", newJString(marker))
  add(path_773844, "DocumentId", newJString(DocumentId))
  add(query_773845, "limit", newJInt(limit))
  result = call_773843.call(path_773844, query_773845, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_773827(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_773828, base: "/", url: url_GetDocumentPath_773829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_773846 = ref object of OpenApiRestCall_772597
proc url_GetFolderPath_773848(protocol: Scheme; host: string; base: string;
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

proc validate_GetFolderPath_773847(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773849 = path.getOrDefault("FolderId")
  valid_773849 = validateParameter(valid_773849, JString, required = true,
                                 default = nil)
  if valid_773849 != nil:
    section.add "FolderId", valid_773849
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_773850 = query.getOrDefault("fields")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "fields", valid_773850
  var valid_773851 = query.getOrDefault("marker")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "marker", valid_773851
  var valid_773852 = query.getOrDefault("limit")
  valid_773852 = validateParameter(valid_773852, JInt, required = false, default = nil)
  if valid_773852 != nil:
    section.add "limit", valid_773852
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
  var valid_773853 = header.getOrDefault("X-Amz-Date")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Date", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Security-Token")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Security-Token", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Content-Sha256", valid_773855
  var valid_773856 = header.getOrDefault("Authentication")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "Authentication", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Algorithm")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Algorithm", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Signature")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Signature", valid_773858
  var valid_773859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "X-Amz-SignedHeaders", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Credential")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Credential", valid_773860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773861: Call_GetFolderPath_773846; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_773861.validator(path, query, header, formData, body)
  let scheme = call_773861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773861.url(scheme.get, call_773861.host, call_773861.base,
                         call_773861.route, valid.getOrDefault("path"))
  result = hook(call_773861, url, valid)

proc call*(call_773862: Call_GetFolderPath_773846; FolderId: string;
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
  var path_773863 = newJObject()
  var query_773864 = newJObject()
  add(query_773864, "fields", newJString(fields))
  add(path_773863, "FolderId", newJString(FolderId))
  add(query_773864, "marker", newJString(marker))
  add(query_773864, "limit", newJInt(limit))
  result = call_773862.call(path_773863, query_773864, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_773846(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_773847,
    base: "/", url: url_GetFolderPath_773848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_773865 = ref object of OpenApiRestCall_772597
proc url_GetResources_773867(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResources_773866(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773868 = query.getOrDefault("collectionType")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_773868 != nil:
    section.add "collectionType", valid_773868
  var valid_773869 = query.getOrDefault("marker")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "marker", valid_773869
  var valid_773870 = query.getOrDefault("limit")
  valid_773870 = validateParameter(valid_773870, JInt, required = false, default = nil)
  if valid_773870 != nil:
    section.add "limit", valid_773870
  var valid_773871 = query.getOrDefault("userId")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "userId", valid_773871
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
  var valid_773872 = header.getOrDefault("X-Amz-Date")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Date", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Security-Token")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Security-Token", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-Content-Sha256", valid_773874
  var valid_773875 = header.getOrDefault("Authentication")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "Authentication", valid_773875
  var valid_773876 = header.getOrDefault("X-Amz-Algorithm")
  valid_773876 = validateParameter(valid_773876, JString, required = false,
                                 default = nil)
  if valid_773876 != nil:
    section.add "X-Amz-Algorithm", valid_773876
  var valid_773877 = header.getOrDefault("X-Amz-Signature")
  valid_773877 = validateParameter(valid_773877, JString, required = false,
                                 default = nil)
  if valid_773877 != nil:
    section.add "X-Amz-Signature", valid_773877
  var valid_773878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773878 = validateParameter(valid_773878, JString, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "X-Amz-SignedHeaders", valid_773878
  var valid_773879 = header.getOrDefault("X-Amz-Credential")
  valid_773879 = validateParameter(valid_773879, JString, required = false,
                                 default = nil)
  if valid_773879 != nil:
    section.add "X-Amz-Credential", valid_773879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773880: Call_GetResources_773865; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_773880.validator(path, query, header, formData, body)
  let scheme = call_773880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773880.url(scheme.get, call_773880.host, call_773880.base,
                         call_773880.route, valid.getOrDefault("path"))
  result = hook(call_773880, url, valid)

proc call*(call_773881: Call_GetResources_773865;
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
  var query_773882 = newJObject()
  add(query_773882, "collectionType", newJString(collectionType))
  add(query_773882, "marker", newJString(marker))
  add(query_773882, "limit", newJInt(limit))
  add(query_773882, "userId", newJString(userId))
  result = call_773881.call(nil, query_773882, nil, nil, nil)

var getResources* = Call_GetResources_773865(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_773866, base: "/",
    url: url_GetResources_773867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_773883 = ref object of OpenApiRestCall_772597
proc url_InitiateDocumentVersionUpload_773885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InitiateDocumentVersionUpload_773884(path: JsonNode; query: JsonNode;
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
  var valid_773886 = header.getOrDefault("X-Amz-Date")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-Date", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-Security-Token")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Security-Token", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Content-Sha256", valid_773888
  var valid_773889 = header.getOrDefault("Authentication")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "Authentication", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Algorithm")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Algorithm", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Signature")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Signature", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-SignedHeaders", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Credential")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Credential", valid_773893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773895: Call_InitiateDocumentVersionUpload_773883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_773895.validator(path, query, header, formData, body)
  let scheme = call_773895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773895.url(scheme.get, call_773895.host, call_773895.base,
                         call_773895.route, valid.getOrDefault("path"))
  result = hook(call_773895, url, valid)

proc call*(call_773896: Call_InitiateDocumentVersionUpload_773883; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_773897 = newJObject()
  if body != nil:
    body_773897 = body
  result = call_773896.call(nil, nil, nil, nil, body_773897)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_773883(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_773884, base: "/",
    url: url_InitiateDocumentVersionUpload_773885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_773898 = ref object of OpenApiRestCall_772597
proc url_RemoveResourcePermission_773900(protocol: Scheme; host: string;
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

proc validate_RemoveResourcePermission_773899(path: JsonNode; query: JsonNode;
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
  var valid_773901 = path.getOrDefault("ResourceId")
  valid_773901 = validateParameter(valid_773901, JString, required = true,
                                 default = nil)
  if valid_773901 != nil:
    section.add "ResourceId", valid_773901
  var valid_773902 = path.getOrDefault("PrincipalId")
  valid_773902 = validateParameter(valid_773902, JString, required = true,
                                 default = nil)
  if valid_773902 != nil:
    section.add "PrincipalId", valid_773902
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_773903 = query.getOrDefault("type")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = newJString("USER"))
  if valid_773903 != nil:
    section.add "type", valid_773903
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
  var valid_773904 = header.getOrDefault("X-Amz-Date")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Date", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Security-Token")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Security-Token", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Content-Sha256", valid_773906
  var valid_773907 = header.getOrDefault("Authentication")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "Authentication", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-Algorithm")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-Algorithm", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-Signature")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-Signature", valid_773909
  var valid_773910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-SignedHeaders", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Credential")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Credential", valid_773911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773912: Call_RemoveResourcePermission_773898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_773912.validator(path, query, header, formData, body)
  let scheme = call_773912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773912.url(scheme.get, call_773912.host, call_773912.base,
                         call_773912.route, valid.getOrDefault("path"))
  result = hook(call_773912, url, valid)

proc call*(call_773913: Call_RemoveResourcePermission_773898; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_773914 = newJObject()
  var query_773915 = newJObject()
  add(query_773915, "type", newJString(`type`))
  add(path_773914, "ResourceId", newJString(ResourceId))
  add(path_773914, "PrincipalId", newJString(PrincipalId))
  result = call_773913.call(path_773914, query_773915, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_773898(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_773899, base: "/",
    url: url_RemoveResourcePermission_773900, schemes: {Scheme.Https, Scheme.Http})
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
