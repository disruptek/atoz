
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetDocumentVersion_602770 = ref object of OpenApiRestCall_602433
proc url_GetDocumentVersion_602772(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDocumentVersion_602771(path: JsonNode; query: JsonNode;
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
  var valid_602898 = path.getOrDefault("VersionId")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "VersionId", valid_602898
  var valid_602899 = path.getOrDefault("DocumentId")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = nil)
  if valid_602899 != nil:
    section.add "DocumentId", valid_602899
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_602900 = query.getOrDefault("fields")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "fields", valid_602900
  var valid_602901 = query.getOrDefault("includeCustomMetadata")
  valid_602901 = validateParameter(valid_602901, JBool, required = false, default = nil)
  if valid_602901 != nil:
    section.add "includeCustomMetadata", valid_602901
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
  var valid_602902 = header.getOrDefault("X-Amz-Date")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Date", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Security-Token")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Security-Token", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Content-Sha256", valid_602904
  var valid_602905 = header.getOrDefault("Authentication")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "Authentication", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Algorithm")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Algorithm", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Signature")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Signature", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-SignedHeaders", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Credential")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Credential", valid_602909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602932: Call_GetDocumentVersion_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_602932.validator(path, query, header, formData, body)
  let scheme = call_602932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602932.url(scheme.get, call_602932.host, call_602932.base,
                         call_602932.route, valid.getOrDefault("path"))
  result = hook(call_602932, url, valid)

proc call*(call_603003: Call_GetDocumentVersion_602770; VersionId: string;
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
  var path_603004 = newJObject()
  var query_603006 = newJObject()
  add(query_603006, "fields", newJString(fields))
  add(path_603004, "VersionId", newJString(VersionId))
  add(query_603006, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_603004, "DocumentId", newJString(DocumentId))
  result = call_603003.call(path_603004, query_603006, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_602770(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_602771, base: "/",
    url: url_GetDocumentVersion_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_603061 = ref object of OpenApiRestCall_602433
proc url_UpdateDocumentVersion_603063(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateDocumentVersion_603062(path: JsonNode; query: JsonNode;
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
  var valid_603064 = path.getOrDefault("VersionId")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = nil)
  if valid_603064 != nil:
    section.add "VersionId", valid_603064
  var valid_603065 = path.getOrDefault("DocumentId")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = nil)
  if valid_603065 != nil:
    section.add "DocumentId", valid_603065
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
  var valid_603066 = header.getOrDefault("X-Amz-Date")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Date", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Security-Token")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Security-Token", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Content-Sha256", valid_603068
  var valid_603069 = header.getOrDefault("Authentication")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "Authentication", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Algorithm")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Algorithm", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Signature")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Signature", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Credential")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Credential", valid_603073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603075: Call_UpdateDocumentVersion_603061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_603075.validator(path, query, header, formData, body)
  let scheme = call_603075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603075.url(scheme.get, call_603075.host, call_603075.base,
                         call_603075.route, valid.getOrDefault("path"))
  result = hook(call_603075, url, valid)

proc call*(call_603076: Call_UpdateDocumentVersion_603061; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_603077 = newJObject()
  var body_603078 = newJObject()
  add(path_603077, "VersionId", newJString(VersionId))
  add(path_603077, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_603078 = body
  result = call_603076.call(path_603077, nil, nil, nil, body_603078)

var updateDocumentVersion* = Call_UpdateDocumentVersion_603061(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_603062, base: "/",
    url: url_UpdateDocumentVersion_603063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_603045 = ref object of OpenApiRestCall_602433
proc url_AbortDocumentVersionUpload_603047(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_AbortDocumentVersionUpload_603046(path: JsonNode; query: JsonNode;
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
  var valid_603048 = path.getOrDefault("VersionId")
  valid_603048 = validateParameter(valid_603048, JString, required = true,
                                 default = nil)
  if valid_603048 != nil:
    section.add "VersionId", valid_603048
  var valid_603049 = path.getOrDefault("DocumentId")
  valid_603049 = validateParameter(valid_603049, JString, required = true,
                                 default = nil)
  if valid_603049 != nil:
    section.add "DocumentId", valid_603049
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
  var valid_603050 = header.getOrDefault("X-Amz-Date")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Date", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Security-Token")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Security-Token", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Content-Sha256", valid_603052
  var valid_603053 = header.getOrDefault("Authentication")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "Authentication", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Algorithm")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Algorithm", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Signature")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Signature", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-SignedHeaders", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Credential")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Credential", valid_603057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_AbortDocumentVersionUpload_603045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"))
  result = hook(call_603058, url, valid)

proc call*(call_603059: Call_AbortDocumentVersionUpload_603045; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_603060 = newJObject()
  add(path_603060, "VersionId", newJString(VersionId))
  add(path_603060, "DocumentId", newJString(DocumentId))
  result = call_603059.call(path_603060, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_603045(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_603046, base: "/",
    url: url_AbortDocumentVersionUpload_603047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_603079 = ref object of OpenApiRestCall_602433
proc url_ActivateUser_603081(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ActivateUser_603080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603082 = path.getOrDefault("UserId")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = nil)
  if valid_603082 != nil:
    section.add "UserId", valid_603082
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
  var valid_603083 = header.getOrDefault("X-Amz-Date")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Date", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Security-Token")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Security-Token", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Content-Sha256", valid_603085
  var valid_603086 = header.getOrDefault("Authentication")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "Authentication", valid_603086
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
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603091: Call_ActivateUser_603079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_603091.validator(path, query, header, formData, body)
  let scheme = call_603091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603091.url(scheme.get, call_603091.host, call_603091.base,
                         call_603091.route, valid.getOrDefault("path"))
  result = hook(call_603091, url, valid)

proc call*(call_603092: Call_ActivateUser_603079; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_603093 = newJObject()
  add(path_603093, "UserId", newJString(UserId))
  result = call_603092.call(path_603093, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_603079(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_603080,
    base: "/", url: url_ActivateUser_603081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_603094 = ref object of OpenApiRestCall_602433
proc url_DeactivateUser_603096(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeactivateUser_603095(path: JsonNode; query: JsonNode;
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
  var valid_603097 = path.getOrDefault("UserId")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = nil)
  if valid_603097 != nil:
    section.add "UserId", valid_603097
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
  var valid_603098 = header.getOrDefault("X-Amz-Date")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Date", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Security-Token")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Security-Token", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Content-Sha256", valid_603100
  var valid_603101 = header.getOrDefault("Authentication")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "Authentication", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Algorithm")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Algorithm", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Signature")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Signature", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Credential")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Credential", valid_603105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_DeactivateUser_603094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"))
  result = hook(call_603106, url, valid)

proc call*(call_603107: Call_DeactivateUser_603094; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_603108 = newJObject()
  add(path_603108, "UserId", newJString(UserId))
  result = call_603107.call(path_603108, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_603094(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_603095, base: "/", url: url_DeactivateUser_603096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_603128 = ref object of OpenApiRestCall_602433
proc url_AddResourcePermissions_603130(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_AddResourcePermissions_603129(path: JsonNode; query: JsonNode;
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
  var valid_603131 = path.getOrDefault("ResourceId")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = nil)
  if valid_603131 != nil:
    section.add "ResourceId", valid_603131
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
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Content-Sha256", valid_603134
  var valid_603135 = header.getOrDefault("Authentication")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "Authentication", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_AddResourcePermissions_603128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_AddResourcePermissions_603128; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_603143 = newJObject()
  var body_603144 = newJObject()
  add(path_603143, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_603144 = body
  result = call_603142.call(path_603143, nil, nil, nil, body_603144)

var addResourcePermissions* = Call_AddResourcePermissions_603128(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_603129, base: "/",
    url: url_AddResourcePermissions_603130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_603109 = ref object of OpenApiRestCall_602433
proc url_DescribeResourcePermissions_603111(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeResourcePermissions_603110(path: JsonNode; query: JsonNode;
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
  var valid_603112 = path.getOrDefault("ResourceId")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = nil)
  if valid_603112 != nil:
    section.add "ResourceId", valid_603112
  result.add "path", section
  ## parameters in `query` object:
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_603113 = query.getOrDefault("principalId")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "principalId", valid_603113
  var valid_603114 = query.getOrDefault("marker")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "marker", valid_603114
  var valid_603115 = query.getOrDefault("limit")
  valid_603115 = validateParameter(valid_603115, JInt, required = false, default = nil)
  if valid_603115 != nil:
    section.add "limit", valid_603115
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
  var valid_603116 = header.getOrDefault("X-Amz-Date")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Date", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Security-Token")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Security-Token", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Content-Sha256", valid_603118
  var valid_603119 = header.getOrDefault("Authentication")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "Authentication", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Algorithm")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Algorithm", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Signature")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Signature", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-SignedHeaders", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Credential")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Credential", valid_603123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603124: Call_DescribeResourcePermissions_603109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_603124.validator(path, query, header, formData, body)
  let scheme = call_603124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603124.url(scheme.get, call_603124.host, call_603124.base,
                         call_603124.route, valid.getOrDefault("path"))
  result = hook(call_603124, url, valid)

proc call*(call_603125: Call_DescribeResourcePermissions_603109;
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
  var path_603126 = newJObject()
  var query_603127 = newJObject()
  add(query_603127, "principalId", newJString(principalId))
  add(query_603127, "marker", newJString(marker))
  add(path_603126, "ResourceId", newJString(ResourceId))
  add(query_603127, "limit", newJInt(limit))
  result = call_603125.call(path_603126, query_603127, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_603109(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_603110, base: "/",
    url: url_DescribeResourcePermissions_603111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_603145 = ref object of OpenApiRestCall_602433
proc url_RemoveAllResourcePermissions_603147(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_RemoveAllResourcePermissions_603146(path: JsonNode; query: JsonNode;
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
  var valid_603148 = path.getOrDefault("ResourceId")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = nil)
  if valid_603148 != nil:
    section.add "ResourceId", valid_603148
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
  var valid_603149 = header.getOrDefault("X-Amz-Date")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Date", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Security-Token")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Security-Token", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Content-Sha256", valid_603151
  var valid_603152 = header.getOrDefault("Authentication")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "Authentication", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Algorithm")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Algorithm", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Signature")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Signature", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-SignedHeaders", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Credential")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Credential", valid_603156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603157: Call_RemoveAllResourcePermissions_603145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_603157.validator(path, query, header, formData, body)
  let scheme = call_603157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603157.url(scheme.get, call_603157.host, call_603157.base,
                         call_603157.route, valid.getOrDefault("path"))
  result = hook(call_603157, url, valid)

proc call*(call_603158: Call_RemoveAllResourcePermissions_603145;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_603159 = newJObject()
  add(path_603159, "ResourceId", newJString(ResourceId))
  result = call_603158.call(path_603159, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_603145(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_603146, base: "/",
    url: url_RemoveAllResourcePermissions_603147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_603160 = ref object of OpenApiRestCall_602433
proc url_CreateComment_603162(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateComment_603161(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603163 = path.getOrDefault("VersionId")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "VersionId", valid_603163
  var valid_603164 = path.getOrDefault("DocumentId")
  valid_603164 = validateParameter(valid_603164, JString, required = true,
                                 default = nil)
  if valid_603164 != nil:
    section.add "DocumentId", valid_603164
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
  var valid_603167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Content-Sha256", valid_603167
  var valid_603168 = header.getOrDefault("Authentication")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "Authentication", valid_603168
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

proc call*(call_603174: Call_CreateComment_603160; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateComment_603160; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_603176 = newJObject()
  var body_603177 = newJObject()
  add(path_603176, "VersionId", newJString(VersionId))
  add(path_603176, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_603177 = body
  result = call_603175.call(path_603176, nil, nil, nil, body_603177)

var createComment* = Call_CreateComment_603160(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_603161, base: "/", url: url_CreateComment_603162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_603178 = ref object of OpenApiRestCall_602433
proc url_CreateCustomMetadata_603180(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateCustomMetadata_603179(path: JsonNode; query: JsonNode;
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
  var valid_603181 = path.getOrDefault("ResourceId")
  valid_603181 = validateParameter(valid_603181, JString, required = true,
                                 default = nil)
  if valid_603181 != nil:
    section.add "ResourceId", valid_603181
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_603182 = query.getOrDefault("versionid")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "versionid", valid_603182
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
  var valid_603183 = header.getOrDefault("X-Amz-Date")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Date", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Security-Token")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Security-Token", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Content-Sha256", valid_603185
  var valid_603186 = header.getOrDefault("Authentication")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "Authentication", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Algorithm")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Algorithm", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Signature")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Signature", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Credential")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Credential", valid_603190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603192: Call_CreateCustomMetadata_603178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_603192.validator(path, query, header, formData, body)
  let scheme = call_603192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603192.url(scheme.get, call_603192.host, call_603192.base,
                         call_603192.route, valid.getOrDefault("path"))
  result = hook(call_603192, url, valid)

proc call*(call_603193: Call_CreateCustomMetadata_603178; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_603194 = newJObject()
  var query_603195 = newJObject()
  var body_603196 = newJObject()
  add(query_603195, "versionid", newJString(versionid))
  add(path_603194, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_603196 = body
  result = call_603193.call(path_603194, query_603195, nil, nil, body_603196)

var createCustomMetadata* = Call_CreateCustomMetadata_603178(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_603179, base: "/",
    url: url_CreateCustomMetadata_603180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_603197 = ref object of OpenApiRestCall_602433
proc url_DeleteCustomMetadata_603199(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteCustomMetadata_603198(path: JsonNode; query: JsonNode;
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
  var valid_603200 = path.getOrDefault("ResourceId")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = nil)
  if valid_603200 != nil:
    section.add "ResourceId", valid_603200
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  section = newJObject()
  var valid_603201 = query.getOrDefault("versionId")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "versionId", valid_603201
  var valid_603202 = query.getOrDefault("keys")
  valid_603202 = validateParameter(valid_603202, JArray, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "keys", valid_603202
  var valid_603203 = query.getOrDefault("deleteAll")
  valid_603203 = validateParameter(valid_603203, JBool, required = false, default = nil)
  if valid_603203 != nil:
    section.add "deleteAll", valid_603203
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
  var valid_603204 = header.getOrDefault("X-Amz-Date")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Date", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Security-Token")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Security-Token", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Content-Sha256", valid_603206
  var valid_603207 = header.getOrDefault("Authentication")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "Authentication", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Algorithm")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Algorithm", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Signature")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Signature", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Credential")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Credential", valid_603211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603212: Call_DeleteCustomMetadata_603197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_603212.validator(path, query, header, formData, body)
  let scheme = call_603212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603212.url(scheme.get, call_603212.host, call_603212.base,
                         call_603212.route, valid.getOrDefault("path"))
  result = hook(call_603212, url, valid)

proc call*(call_603213: Call_DeleteCustomMetadata_603197; ResourceId: string;
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
  var path_603214 = newJObject()
  var query_603215 = newJObject()
  add(query_603215, "versionId", newJString(versionId))
  if keys != nil:
    query_603215.add "keys", keys
  add(path_603214, "ResourceId", newJString(ResourceId))
  add(query_603215, "deleteAll", newJBool(deleteAll))
  result = call_603213.call(path_603214, query_603215, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_603197(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_603198, base: "/",
    url: url_DeleteCustomMetadata_603199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_603216 = ref object of OpenApiRestCall_602433
proc url_CreateFolder_603218(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFolder_603217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603219 = header.getOrDefault("X-Amz-Date")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Date", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Security-Token")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Security-Token", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Content-Sha256", valid_603221
  var valid_603222 = header.getOrDefault("Authentication")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "Authentication", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Algorithm")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Algorithm", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Signature")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Signature", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-SignedHeaders", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Credential")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Credential", valid_603226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603228: Call_CreateFolder_603216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_603228.validator(path, query, header, formData, body)
  let scheme = call_603228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603228.url(scheme.get, call_603228.host, call_603228.base,
                         call_603228.route, valid.getOrDefault("path"))
  result = hook(call_603228, url, valid)

proc call*(call_603229: Call_CreateFolder_603216; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_603230 = newJObject()
  if body != nil:
    body_603230 = body
  result = call_603229.call(nil, nil, nil, nil, body_603230)

var createFolder* = Call_CreateFolder_603216(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_603217, base: "/",
    url: url_CreateFolder_603218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_603231 = ref object of OpenApiRestCall_602433
proc url_CreateLabels_603233(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateLabels_603232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603234 = path.getOrDefault("ResourceId")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = nil)
  if valid_603234 != nil:
    section.add "ResourceId", valid_603234
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
  var valid_603235 = header.getOrDefault("X-Amz-Date")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Date", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Security-Token")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Security-Token", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Content-Sha256", valid_603237
  var valid_603238 = header.getOrDefault("Authentication")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "Authentication", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Algorithm")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Algorithm", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Signature")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Signature", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-SignedHeaders", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Credential")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Credential", valid_603242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_CreateLabels_603231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"))
  result = hook(call_603244, url, valid)

proc call*(call_603245: Call_CreateLabels_603231; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_603246 = newJObject()
  var body_603247 = newJObject()
  add(path_603246, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_603247 = body
  result = call_603245.call(path_603246, nil, nil, nil, body_603247)

var createLabels* = Call_CreateLabels_603231(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_603232, base: "/", url: url_CreateLabels_603233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_603248 = ref object of OpenApiRestCall_602433
proc url_DeleteLabels_603250(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteLabels_603249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603251 = path.getOrDefault("ResourceId")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = nil)
  if valid_603251 != nil:
    section.add "ResourceId", valid_603251
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_603252 = query.getOrDefault("labels")
  valid_603252 = validateParameter(valid_603252, JArray, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "labels", valid_603252
  var valid_603253 = query.getOrDefault("deleteAll")
  valid_603253 = validateParameter(valid_603253, JBool, required = false, default = nil)
  if valid_603253 != nil:
    section.add "deleteAll", valid_603253
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
  var valid_603254 = header.getOrDefault("X-Amz-Date")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Date", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Security-Token")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Security-Token", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Content-Sha256", valid_603256
  var valid_603257 = header.getOrDefault("Authentication")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "Authentication", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Algorithm")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Algorithm", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Signature")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Signature", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-SignedHeaders", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Credential")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Credential", valid_603261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603262: Call_DeleteLabels_603248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_603262.validator(path, query, header, formData, body)
  let scheme = call_603262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603262.url(scheme.get, call_603262.host, call_603262.base,
                         call_603262.route, valid.getOrDefault("path"))
  result = hook(call_603262, url, valid)

proc call*(call_603263: Call_DeleteLabels_603248; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  var path_603264 = newJObject()
  var query_603265 = newJObject()
  if labels != nil:
    query_603265.add "labels", labels
  add(path_603264, "ResourceId", newJString(ResourceId))
  add(query_603265, "deleteAll", newJBool(deleteAll))
  result = call_603263.call(path_603264, query_603265, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_603248(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_603249, base: "/", url: url_DeleteLabels_603250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_603283 = ref object of OpenApiRestCall_602433
proc url_CreateNotificationSubscription_603285(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateNotificationSubscription_603284(path: JsonNode;
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
  var valid_603286 = path.getOrDefault("OrganizationId")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = nil)
  if valid_603286 != nil:
    section.add "OrganizationId", valid_603286
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
  var valid_603287 = header.getOrDefault("X-Amz-Date")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Date", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Security-Token")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Security-Token", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Content-Sha256", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Algorithm")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Algorithm", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Signature")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Signature", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-SignedHeaders", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Credential")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Credential", valid_603293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603295: Call_CreateNotificationSubscription_603283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_603295.validator(path, query, header, formData, body)
  let scheme = call_603295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603295.url(scheme.get, call_603295.host, call_603295.base,
                         call_603295.route, valid.getOrDefault("path"))
  result = hook(call_603295, url, valid)

proc call*(call_603296: Call_CreateNotificationSubscription_603283;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_603297 = newJObject()
  var body_603298 = newJObject()
  add(path_603297, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_603298 = body
  result = call_603296.call(path_603297, nil, nil, nil, body_603298)

var createNotificationSubscription* = Call_CreateNotificationSubscription_603283(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_603284, base: "/",
    url: url_CreateNotificationSubscription_603285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_603266 = ref object of OpenApiRestCall_602433
proc url_DescribeNotificationSubscriptions_603268(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeNotificationSubscriptions_603267(path: JsonNode;
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
  var valid_603269 = path.getOrDefault("OrganizationId")
  valid_603269 = validateParameter(valid_603269, JString, required = true,
                                 default = nil)
  if valid_603269 != nil:
    section.add "OrganizationId", valid_603269
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_603270 = query.getOrDefault("marker")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "marker", valid_603270
  var valid_603271 = query.getOrDefault("limit")
  valid_603271 = validateParameter(valid_603271, JInt, required = false, default = nil)
  if valid_603271 != nil:
    section.add "limit", valid_603271
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
  var valid_603272 = header.getOrDefault("X-Amz-Date")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Date", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Security-Token")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Security-Token", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Content-Sha256", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Algorithm")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Algorithm", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Signature")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Signature", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-SignedHeaders", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Credential")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Credential", valid_603278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_DescribeNotificationSubscriptions_603266;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_DescribeNotificationSubscriptions_603266;
          OrganizationId: string; marker: string = ""; limit: int = 0): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  var path_603281 = newJObject()
  var query_603282 = newJObject()
  add(path_603281, "OrganizationId", newJString(OrganizationId))
  add(query_603282, "marker", newJString(marker))
  add(query_603282, "limit", newJInt(limit))
  result = call_603280.call(path_603281, query_603282, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_603266(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_603267, base: "/",
    url: url_DescribeNotificationSubscriptions_603268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_603337 = ref object of OpenApiRestCall_602433
proc url_CreateUser_603339(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUser_603338(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603343 = header.getOrDefault("Authentication")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "Authentication", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Algorithm")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Algorithm", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Signature")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Signature", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-SignedHeaders", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Credential")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Credential", valid_603347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603349: Call_CreateUser_603337; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_603349.validator(path, query, header, formData, body)
  let scheme = call_603349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603349.url(scheme.get, call_603349.host, call_603349.base,
                         call_603349.route, valid.getOrDefault("path"))
  result = hook(call_603349, url, valid)

proc call*(call_603350: Call_CreateUser_603337; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_603351 = newJObject()
  if body != nil:
    body_603351 = body
  result = call_603350.call(nil, nil, nil, nil, body_603351)

var createUser* = Call_CreateUser_603337(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_603338,
                                      base: "/", url: url_CreateUser_603339,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_603299 = ref object of OpenApiRestCall_602433
proc url_DescribeUsers_603301(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUsers_603300(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603302 = query.getOrDefault("fields")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "fields", valid_603302
  var valid_603303 = query.getOrDefault("query")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "query", valid_603303
  var valid_603317 = query.getOrDefault("sort")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_603317 != nil:
    section.add "sort", valid_603317
  var valid_603318 = query.getOrDefault("order")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_603318 != nil:
    section.add "order", valid_603318
  var valid_603319 = query.getOrDefault("Limit")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "Limit", valid_603319
  var valid_603320 = query.getOrDefault("include")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = newJString("ALL"))
  if valid_603320 != nil:
    section.add "include", valid_603320
  var valid_603321 = query.getOrDefault("organizationId")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "organizationId", valid_603321
  var valid_603322 = query.getOrDefault("marker")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "marker", valid_603322
  var valid_603323 = query.getOrDefault("Marker")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "Marker", valid_603323
  var valid_603324 = query.getOrDefault("limit")
  valid_603324 = validateParameter(valid_603324, JInt, required = false, default = nil)
  if valid_603324 != nil:
    section.add "limit", valid_603324
  var valid_603325 = query.getOrDefault("userIds")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "userIds", valid_603325
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
  var valid_603326 = header.getOrDefault("X-Amz-Date")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Date", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Security-Token")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Security-Token", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Content-Sha256", valid_603328
  var valid_603329 = header.getOrDefault("Authentication")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "Authentication", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Algorithm")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Algorithm", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Signature")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Signature", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-SignedHeaders", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Credential")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Credential", valid_603333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603334: Call_DescribeUsers_603299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_603334.validator(path, query, header, formData, body)
  let scheme = call_603334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603334.url(scheme.get, call_603334.host, call_603334.base,
                         call_603334.route, valid.getOrDefault("path"))
  result = hook(call_603334, url, valid)

proc call*(call_603335: Call_DescribeUsers_603299; fields: string = "";
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
  var query_603336 = newJObject()
  add(query_603336, "fields", newJString(fields))
  add(query_603336, "query", newJString(query))
  add(query_603336, "sort", newJString(sort))
  add(query_603336, "order", newJString(order))
  add(query_603336, "Limit", newJString(Limit))
  add(query_603336, "include", newJString(`include`))
  add(query_603336, "organizationId", newJString(organizationId))
  add(query_603336, "marker", newJString(marker))
  add(query_603336, "Marker", newJString(Marker))
  add(query_603336, "limit", newJInt(limit))
  add(query_603336, "userIds", newJString(userIds))
  result = call_603335.call(nil, query_603336, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_603299(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_603300, base: "/",
    url: url_DescribeUsers_603301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_603352 = ref object of OpenApiRestCall_602433
proc url_DeleteComment_603354(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteComment_603353(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603355 = path.getOrDefault("CommentId")
  valid_603355 = validateParameter(valid_603355, JString, required = true,
                                 default = nil)
  if valid_603355 != nil:
    section.add "CommentId", valid_603355
  var valid_603356 = path.getOrDefault("VersionId")
  valid_603356 = validateParameter(valid_603356, JString, required = true,
                                 default = nil)
  if valid_603356 != nil:
    section.add "VersionId", valid_603356
  var valid_603357 = path.getOrDefault("DocumentId")
  valid_603357 = validateParameter(valid_603357, JString, required = true,
                                 default = nil)
  if valid_603357 != nil:
    section.add "DocumentId", valid_603357
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
  var valid_603358 = header.getOrDefault("X-Amz-Date")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Date", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Content-Sha256", valid_603360
  var valid_603361 = header.getOrDefault("Authentication")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "Authentication", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603366: Call_DeleteComment_603352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_603366.validator(path, query, header, formData, body)
  let scheme = call_603366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603366.url(scheme.get, call_603366.host, call_603366.base,
                         call_603366.route, valid.getOrDefault("path"))
  result = hook(call_603366, url, valid)

proc call*(call_603367: Call_DeleteComment_603352; CommentId: string;
          VersionId: string; DocumentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_603368 = newJObject()
  add(path_603368, "CommentId", newJString(CommentId))
  add(path_603368, "VersionId", newJString(VersionId))
  add(path_603368, "DocumentId", newJString(DocumentId))
  result = call_603367.call(path_603368, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_603352(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_603353, base: "/", url: url_DeleteComment_603354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_603369 = ref object of OpenApiRestCall_602433
proc url_GetDocument_603371(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDocument_603370(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603372 = path.getOrDefault("DocumentId")
  valid_603372 = validateParameter(valid_603372, JString, required = true,
                                 default = nil)
  if valid_603372 != nil:
    section.add "DocumentId", valid_603372
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_603373 = query.getOrDefault("includeCustomMetadata")
  valid_603373 = validateParameter(valid_603373, JBool, required = false, default = nil)
  if valid_603373 != nil:
    section.add "includeCustomMetadata", valid_603373
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
  var valid_603374 = header.getOrDefault("X-Amz-Date")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Date", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Security-Token")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Security-Token", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Content-Sha256", valid_603376
  var valid_603377 = header.getOrDefault("Authentication")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "Authentication", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Algorithm")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Algorithm", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Signature")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Signature", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-SignedHeaders", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Credential")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Credential", valid_603381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603382: Call_GetDocument_603369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_603382.validator(path, query, header, formData, body)
  let scheme = call_603382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603382.url(scheme.get, call_603382.host, call_603382.base,
                         call_603382.route, valid.getOrDefault("path"))
  result = hook(call_603382, url, valid)

proc call*(call_603383: Call_GetDocument_603369; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_603384 = newJObject()
  var query_603385 = newJObject()
  add(query_603385, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_603384, "DocumentId", newJString(DocumentId))
  result = call_603383.call(path_603384, query_603385, nil, nil, nil)

var getDocument* = Call_GetDocument_603369(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_603370,
                                        base: "/", url: url_GetDocument_603371,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_603401 = ref object of OpenApiRestCall_602433
proc url_UpdateDocument_603403(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateDocument_603402(path: JsonNode; query: JsonNode;
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
  var valid_603404 = path.getOrDefault("DocumentId")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = nil)
  if valid_603404 != nil:
    section.add "DocumentId", valid_603404
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
  var valid_603407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Content-Sha256", valid_603407
  var valid_603408 = header.getOrDefault("Authentication")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "Authentication", valid_603408
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

proc call*(call_603414: Call_UpdateDocument_603401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_UpdateDocument_603401; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_603416 = newJObject()
  var body_603417 = newJObject()
  add(path_603416, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_603417 = body
  result = call_603415.call(path_603416, nil, nil, nil, body_603417)

var updateDocument* = Call_UpdateDocument_603401(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_603402,
    base: "/", url: url_UpdateDocument_603403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_603386 = ref object of OpenApiRestCall_602433
proc url_DeleteDocument_603388(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DocumentId" in path, "`DocumentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/documents/"),
               (kind: VariableSegment, value: "DocumentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteDocument_603387(path: JsonNode; query: JsonNode;
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
  var valid_603389 = path.getOrDefault("DocumentId")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = nil)
  if valid_603389 != nil:
    section.add "DocumentId", valid_603389
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
  var valid_603392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Content-Sha256", valid_603392
  var valid_603393 = header.getOrDefault("Authentication")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "Authentication", valid_603393
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
  if body != nil:
    result.add "body", body

proc call*(call_603398: Call_DeleteDocument_603386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_603398.validator(path, query, header, formData, body)
  let scheme = call_603398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603398.url(scheme.get, call_603398.host, call_603398.base,
                         call_603398.route, valid.getOrDefault("path"))
  result = hook(call_603398, url, valid)

proc call*(call_603399: Call_DeleteDocument_603386; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_603400 = newJObject()
  add(path_603400, "DocumentId", newJString(DocumentId))
  result = call_603399.call(path_603400, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_603386(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_603387,
    base: "/", url: url_DeleteDocument_603388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_603418 = ref object of OpenApiRestCall_602433
proc url_GetFolder_603420(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetFolder_603419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603421 = path.getOrDefault("FolderId")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = nil)
  if valid_603421 != nil:
    section.add "FolderId", valid_603421
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_603422 = query.getOrDefault("includeCustomMetadata")
  valid_603422 = validateParameter(valid_603422, JBool, required = false, default = nil)
  if valid_603422 != nil:
    section.add "includeCustomMetadata", valid_603422
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
  var valid_603423 = header.getOrDefault("X-Amz-Date")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Date", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Security-Token")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Security-Token", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Content-Sha256", valid_603425
  var valid_603426 = header.getOrDefault("Authentication")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "Authentication", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Algorithm")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Algorithm", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Signature")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Signature", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-SignedHeaders", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Credential")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Credential", valid_603430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603431: Call_GetFolder_603418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_603431.validator(path, query, header, formData, body)
  let scheme = call_603431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603431.url(scheme.get, call_603431.host, call_603431.base,
                         call_603431.route, valid.getOrDefault("path"))
  result = hook(call_603431, url, valid)

proc call*(call_603432: Call_GetFolder_603418; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  var path_603433 = newJObject()
  var query_603434 = newJObject()
  add(path_603433, "FolderId", newJString(FolderId))
  add(query_603434, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_603432.call(path_603433, query_603434, nil, nil, nil)

var getFolder* = Call_GetFolder_603418(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_603419,
                                    base: "/", url: url_GetFolder_603420,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_603450 = ref object of OpenApiRestCall_602433
proc url_UpdateFolder_603452(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateFolder_603451(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603453 = path.getOrDefault("FolderId")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = nil)
  if valid_603453 != nil:
    section.add "FolderId", valid_603453
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
  var valid_603457 = header.getOrDefault("Authentication")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "Authentication", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_UpdateFolder_603450; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"))
  result = hook(call_603463, url, valid)

proc call*(call_603464: Call_UpdateFolder_603450; FolderId: string; body: JsonNode): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   body: JObject (required)
  var path_603465 = newJObject()
  var body_603466 = newJObject()
  add(path_603465, "FolderId", newJString(FolderId))
  if body != nil:
    body_603466 = body
  result = call_603464.call(path_603465, nil, nil, nil, body_603466)

var updateFolder* = Call_UpdateFolder_603450(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_603451,
    base: "/", url: url_UpdateFolder_603452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_603435 = ref object of OpenApiRestCall_602433
proc url_DeleteFolder_603437(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "FolderId" in path, "`FolderId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/folders/"),
               (kind: VariableSegment, value: "FolderId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteFolder_603436(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603438 = path.getOrDefault("FolderId")
  valid_603438 = validateParameter(valid_603438, JString, required = true,
                                 default = nil)
  if valid_603438 != nil:
    section.add "FolderId", valid_603438
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
  var valid_603439 = header.getOrDefault("X-Amz-Date")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Date", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Security-Token")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Security-Token", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Content-Sha256", valid_603441
  var valid_603442 = header.getOrDefault("Authentication")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "Authentication", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Algorithm")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Algorithm", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Signature")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Signature", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-SignedHeaders", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Credential")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Credential", valid_603446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603447: Call_DeleteFolder_603435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_603447.validator(path, query, header, formData, body)
  let scheme = call_603447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603447.url(scheme.get, call_603447.host, call_603447.base,
                         call_603447.route, valid.getOrDefault("path"))
  result = hook(call_603447, url, valid)

proc call*(call_603448: Call_DeleteFolder_603435; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_603449 = newJObject()
  add(path_603449, "FolderId", newJString(FolderId))
  result = call_603448.call(path_603449, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_603435(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_603436,
    base: "/", url: url_DeleteFolder_603437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_603467 = ref object of OpenApiRestCall_602433
proc url_DescribeFolderContents_603469(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeFolderContents_603468(path: JsonNode; query: JsonNode;
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
  var valid_603470 = path.getOrDefault("FolderId")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = nil)
  if valid_603470 != nil:
    section.add "FolderId", valid_603470
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
  var valid_603471 = query.getOrDefault("sort")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = newJString("DATE"))
  if valid_603471 != nil:
    section.add "sort", valid_603471
  var valid_603472 = query.getOrDefault("type")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = newJString("ALL"))
  if valid_603472 != nil:
    section.add "type", valid_603472
  var valid_603473 = query.getOrDefault("order")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_603473 != nil:
    section.add "order", valid_603473
  var valid_603474 = query.getOrDefault("Limit")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "Limit", valid_603474
  var valid_603475 = query.getOrDefault("include")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "include", valid_603475
  var valid_603476 = query.getOrDefault("marker")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "marker", valid_603476
  var valid_603477 = query.getOrDefault("Marker")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "Marker", valid_603477
  var valid_603478 = query.getOrDefault("limit")
  valid_603478 = validateParameter(valid_603478, JInt, required = false, default = nil)
  if valid_603478 != nil:
    section.add "limit", valid_603478
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
  var valid_603479 = header.getOrDefault("X-Amz-Date")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Date", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Security-Token")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Security-Token", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Content-Sha256", valid_603481
  var valid_603482 = header.getOrDefault("Authentication")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "Authentication", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Algorithm")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Algorithm", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Signature")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Signature", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-SignedHeaders", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Credential")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Credential", valid_603486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603487: Call_DescribeFolderContents_603467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_603487.validator(path, query, header, formData, body)
  let scheme = call_603487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603487.url(scheme.get, call_603487.host, call_603487.base,
                         call_603487.route, valid.getOrDefault("path"))
  result = hook(call_603487, url, valid)

proc call*(call_603488: Call_DescribeFolderContents_603467; FolderId: string;
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
  var path_603489 = newJObject()
  var query_603490 = newJObject()
  add(query_603490, "sort", newJString(sort))
  add(query_603490, "type", newJString(`type`))
  add(query_603490, "order", newJString(order))
  add(query_603490, "Limit", newJString(Limit))
  add(query_603490, "include", newJString(`include`))
  add(path_603489, "FolderId", newJString(FolderId))
  add(query_603490, "marker", newJString(marker))
  add(query_603490, "Marker", newJString(Marker))
  add(query_603490, "limit", newJInt(limit))
  result = call_603488.call(path_603489, query_603490, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_603467(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_603468, base: "/",
    url: url_DescribeFolderContents_603469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_603491 = ref object of OpenApiRestCall_602433
proc url_DeleteFolderContents_603493(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteFolderContents_603492(path: JsonNode; query: JsonNode;
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
  var valid_603494 = path.getOrDefault("FolderId")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = nil)
  if valid_603494 != nil:
    section.add "FolderId", valid_603494
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
  var valid_603495 = header.getOrDefault("X-Amz-Date")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Date", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Content-Sha256", valid_603497
  var valid_603498 = header.getOrDefault("Authentication")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "Authentication", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603503: Call_DeleteFolderContents_603491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_603503.validator(path, query, header, formData, body)
  let scheme = call_603503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603503.url(scheme.get, call_603503.host, call_603503.base,
                         call_603503.route, valid.getOrDefault("path"))
  result = hook(call_603503, url, valid)

proc call*(call_603504: Call_DeleteFolderContents_603491; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_603505 = newJObject()
  add(path_603505, "FolderId", newJString(FolderId))
  result = call_603504.call(path_603505, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_603491(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_603492, base: "/",
    url: url_DeleteFolderContents_603493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_603506 = ref object of OpenApiRestCall_602433
proc url_DeleteNotificationSubscription_603508(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteNotificationSubscription_603507(path: JsonNode;
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
  var valid_603509 = path.getOrDefault("SubscriptionId")
  valid_603509 = validateParameter(valid_603509, JString, required = true,
                                 default = nil)
  if valid_603509 != nil:
    section.add "SubscriptionId", valid_603509
  var valid_603510 = path.getOrDefault("OrganizationId")
  valid_603510 = validateParameter(valid_603510, JString, required = true,
                                 default = nil)
  if valid_603510 != nil:
    section.add "OrganizationId", valid_603510
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
  var valid_603511 = header.getOrDefault("X-Amz-Date")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Date", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Security-Token")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Security-Token", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Credential")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Credential", valid_603517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603518: Call_DeleteNotificationSubscription_603506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_603518.validator(path, query, header, formData, body)
  let scheme = call_603518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603518.url(scheme.get, call_603518.host, call_603518.base,
                         call_603518.route, valid.getOrDefault("path"))
  result = hook(call_603518, url, valid)

proc call*(call_603519: Call_DeleteNotificationSubscription_603506;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_603520 = newJObject()
  add(path_603520, "SubscriptionId", newJString(SubscriptionId))
  add(path_603520, "OrganizationId", newJString(OrganizationId))
  result = call_603519.call(path_603520, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_603506(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_603507, base: "/",
    url: url_DeleteNotificationSubscription_603508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_603536 = ref object of OpenApiRestCall_602433
proc url_UpdateUser_603538(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateUser_603537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603539 = path.getOrDefault("UserId")
  valid_603539 = validateParameter(valid_603539, JString, required = true,
                                 default = nil)
  if valid_603539 != nil:
    section.add "UserId", valid_603539
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
  var valid_603540 = header.getOrDefault("X-Amz-Date")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Date", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Security-Token")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Security-Token", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Content-Sha256", valid_603542
  var valid_603543 = header.getOrDefault("Authentication")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "Authentication", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603549: Call_UpdateUser_603536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_603549.validator(path, query, header, formData, body)
  let scheme = call_603549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603549.url(scheme.get, call_603549.host, call_603549.base,
                         call_603549.route, valid.getOrDefault("path"))
  result = hook(call_603549, url, valid)

proc call*(call_603550: Call_UpdateUser_603536; body: JsonNode; UserId: string): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_603551 = newJObject()
  var body_603552 = newJObject()
  if body != nil:
    body_603552 = body
  add(path_603551, "UserId", newJString(UserId))
  result = call_603550.call(path_603551, nil, nil, nil, body_603552)

var updateUser* = Call_UpdateUser_603536(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_603537,
                                      base: "/", url: url_UpdateUser_603538,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_603521 = ref object of OpenApiRestCall_602433
proc url_DeleteUser_603523(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/api/v1/users/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteUser_603522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603524 = path.getOrDefault("UserId")
  valid_603524 = validateParameter(valid_603524, JString, required = true,
                                 default = nil)
  if valid_603524 != nil:
    section.add "UserId", valid_603524
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
  var valid_603525 = header.getOrDefault("X-Amz-Date")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Date", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Security-Token")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Security-Token", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Content-Sha256", valid_603527
  var valid_603528 = header.getOrDefault("Authentication")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "Authentication", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Credential")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Credential", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603533: Call_DeleteUser_603521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_603533.validator(path, query, header, formData, body)
  let scheme = call_603533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603533.url(scheme.get, call_603533.host, call_603533.base,
                         call_603533.route, valid.getOrDefault("path"))
  result = hook(call_603533, url, valid)

proc call*(call_603534: Call_DeleteUser_603521; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_603535 = newJObject()
  add(path_603535, "UserId", newJString(UserId))
  result = call_603534.call(path_603535, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_603521(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_603522,
                                      base: "/", url: url_DeleteUser_603523,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_603553 = ref object of OpenApiRestCall_602433
proc url_DescribeActivities_603555(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeActivities_603554(path: JsonNode; query: JsonNode;
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
  var valid_603556 = query.getOrDefault("endTime")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "endTime", valid_603556
  var valid_603557 = query.getOrDefault("organizationId")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "organizationId", valid_603557
  var valid_603558 = query.getOrDefault("includeIndirectActivities")
  valid_603558 = validateParameter(valid_603558, JBool, required = false, default = nil)
  if valid_603558 != nil:
    section.add "includeIndirectActivities", valid_603558
  var valid_603559 = query.getOrDefault("activityTypes")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "activityTypes", valid_603559
  var valid_603560 = query.getOrDefault("marker")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "marker", valid_603560
  var valid_603561 = query.getOrDefault("resourceId")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "resourceId", valid_603561
  var valid_603562 = query.getOrDefault("startTime")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "startTime", valid_603562
  var valid_603563 = query.getOrDefault("limit")
  valid_603563 = validateParameter(valid_603563, JInt, required = false, default = nil)
  if valid_603563 != nil:
    section.add "limit", valid_603563
  var valid_603564 = query.getOrDefault("userId")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "userId", valid_603564
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
  var valid_603565 = header.getOrDefault("X-Amz-Date")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Date", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Security-Token")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Security-Token", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Content-Sha256", valid_603567
  var valid_603568 = header.getOrDefault("Authentication")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "Authentication", valid_603568
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

proc call*(call_603573: Call_DescribeActivities_603553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_603573.validator(path, query, header, formData, body)
  let scheme = call_603573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603573.url(scheme.get, call_603573.host, call_603573.base,
                         call_603573.route, valid.getOrDefault("path"))
  result = hook(call_603573, url, valid)

proc call*(call_603574: Call_DescribeActivities_603553; endTime: string = "";
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
  var query_603575 = newJObject()
  add(query_603575, "endTime", newJString(endTime))
  add(query_603575, "organizationId", newJString(organizationId))
  add(query_603575, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_603575, "activityTypes", newJString(activityTypes))
  add(query_603575, "marker", newJString(marker))
  add(query_603575, "resourceId", newJString(resourceId))
  add(query_603575, "startTime", newJString(startTime))
  add(query_603575, "limit", newJInt(limit))
  add(query_603575, "userId", newJString(userId))
  result = call_603574.call(nil, query_603575, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_603553(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_603554, base: "/",
    url: url_DescribeActivities_603555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_603576 = ref object of OpenApiRestCall_602433
proc url_DescribeComments_603578(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeComments_603577(path: JsonNode; query: JsonNode;
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
  var valid_603579 = path.getOrDefault("VersionId")
  valid_603579 = validateParameter(valid_603579, JString, required = true,
                                 default = nil)
  if valid_603579 != nil:
    section.add "VersionId", valid_603579
  var valid_603580 = path.getOrDefault("DocumentId")
  valid_603580 = validateParameter(valid_603580, JString, required = true,
                                 default = nil)
  if valid_603580 != nil:
    section.add "DocumentId", valid_603580
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   limit: JInt
  ##        : The maximum number of items to return.
  section = newJObject()
  var valid_603581 = query.getOrDefault("marker")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "marker", valid_603581
  var valid_603582 = query.getOrDefault("limit")
  valid_603582 = validateParameter(valid_603582, JInt, required = false, default = nil)
  if valid_603582 != nil:
    section.add "limit", valid_603582
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
  var valid_603586 = header.getOrDefault("Authentication")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "Authentication", valid_603586
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
  if body != nil:
    result.add "body", body

proc call*(call_603591: Call_DescribeComments_603576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_603591.validator(path, query, header, formData, body)
  let scheme = call_603591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603591.url(scheme.get, call_603591.host, call_603591.base,
                         call_603591.route, valid.getOrDefault("path"))
  result = hook(call_603591, url, valid)

proc call*(call_603592: Call_DescribeComments_603576; VersionId: string;
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
  var path_603593 = newJObject()
  var query_603594 = newJObject()
  add(path_603593, "VersionId", newJString(VersionId))
  add(query_603594, "marker", newJString(marker))
  add(path_603593, "DocumentId", newJString(DocumentId))
  add(query_603594, "limit", newJInt(limit))
  result = call_603592.call(path_603593, query_603594, nil, nil, nil)

var describeComments* = Call_DescribeComments_603576(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_603577, base: "/",
    url: url_DescribeComments_603578, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_603595 = ref object of OpenApiRestCall_602433
proc url_DescribeDocumentVersions_603597(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DescribeDocumentVersions_603596(path: JsonNode; query: JsonNode;
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
  var valid_603598 = path.getOrDefault("DocumentId")
  valid_603598 = validateParameter(valid_603598, JString, required = true,
                                 default = nil)
  if valid_603598 != nil:
    section.add "DocumentId", valid_603598
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
  var valid_603599 = query.getOrDefault("fields")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "fields", valid_603599
  var valid_603600 = query.getOrDefault("Limit")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "Limit", valid_603600
  var valid_603601 = query.getOrDefault("include")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "include", valid_603601
  var valid_603602 = query.getOrDefault("marker")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "marker", valid_603602
  var valid_603603 = query.getOrDefault("Marker")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "Marker", valid_603603
  var valid_603604 = query.getOrDefault("limit")
  valid_603604 = validateParameter(valid_603604, JInt, required = false, default = nil)
  if valid_603604 != nil:
    section.add "limit", valid_603604
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
  var valid_603605 = header.getOrDefault("X-Amz-Date")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Date", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Security-Token")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Security-Token", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Content-Sha256", valid_603607
  var valid_603608 = header.getOrDefault("Authentication")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "Authentication", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Algorithm")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Algorithm", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Signature")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Signature", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-SignedHeaders", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Credential")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Credential", valid_603612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603613: Call_DescribeDocumentVersions_603595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_603613.validator(path, query, header, formData, body)
  let scheme = call_603613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603613.url(scheme.get, call_603613.host, call_603613.base,
                         call_603613.route, valid.getOrDefault("path"))
  result = hook(call_603613, url, valid)

proc call*(call_603614: Call_DescribeDocumentVersions_603595; DocumentId: string;
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
  var path_603615 = newJObject()
  var query_603616 = newJObject()
  add(query_603616, "fields", newJString(fields))
  add(query_603616, "Limit", newJString(Limit))
  add(query_603616, "include", newJString(`include`))
  add(query_603616, "marker", newJString(marker))
  add(query_603616, "Marker", newJString(Marker))
  add(path_603615, "DocumentId", newJString(DocumentId))
  add(query_603616, "limit", newJInt(limit))
  result = call_603614.call(path_603615, query_603616, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_603595(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_603596, base: "/",
    url: url_DescribeDocumentVersions_603597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_603617 = ref object of OpenApiRestCall_602433
proc url_DescribeGroups_603619(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeGroups_603618(path: JsonNode; query: JsonNode;
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
  var valid_603620 = query.getOrDefault("searchQuery")
  valid_603620 = validateParameter(valid_603620, JString, required = true,
                                 default = nil)
  if valid_603620 != nil:
    section.add "searchQuery", valid_603620
  var valid_603621 = query.getOrDefault("organizationId")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "organizationId", valid_603621
  var valid_603622 = query.getOrDefault("marker")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "marker", valid_603622
  var valid_603623 = query.getOrDefault("limit")
  valid_603623 = validateParameter(valid_603623, JInt, required = false, default = nil)
  if valid_603623 != nil:
    section.add "limit", valid_603623
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
  var valid_603624 = header.getOrDefault("X-Amz-Date")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Date", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Security-Token")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Security-Token", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Content-Sha256", valid_603626
  var valid_603627 = header.getOrDefault("Authentication")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "Authentication", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Algorithm")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Algorithm", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Signature")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Signature", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-SignedHeaders", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Credential")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Credential", valid_603631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603632: Call_DescribeGroups_603617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_603632.validator(path, query, header, formData, body)
  let scheme = call_603632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603632.url(scheme.get, call_603632.host, call_603632.base,
                         call_603632.route, valid.getOrDefault("path"))
  result = hook(call_603632, url, valid)

proc call*(call_603633: Call_DescribeGroups_603617; searchQuery: string;
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
  var query_603634 = newJObject()
  add(query_603634, "searchQuery", newJString(searchQuery))
  add(query_603634, "organizationId", newJString(organizationId))
  add(query_603634, "marker", newJString(marker))
  add(query_603634, "limit", newJInt(limit))
  result = call_603633.call(nil, query_603634, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_603617(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_603618,
    base: "/", url: url_DescribeGroups_603619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_603635 = ref object of OpenApiRestCall_602433
proc url_DescribeRootFolders_603637(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRootFolders_603636(path: JsonNode; query: JsonNode;
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
  var valid_603638 = query.getOrDefault("marker")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "marker", valid_603638
  var valid_603639 = query.getOrDefault("limit")
  valid_603639 = validateParameter(valid_603639, JInt, required = false, default = nil)
  if valid_603639 != nil:
    section.add "limit", valid_603639
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
  var valid_603640 = header.getOrDefault("X-Amz-Date")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Date", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Security-Token")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Security-Token", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Content-Sha256", valid_603642
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_603643 = header.getOrDefault("Authentication")
  valid_603643 = validateParameter(valid_603643, JString, required = true,
                                 default = nil)
  if valid_603643 != nil:
    section.add "Authentication", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Algorithm")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Algorithm", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Signature")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Signature", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-SignedHeaders", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Credential")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Credential", valid_603647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603648: Call_DescribeRootFolders_603635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_603648.validator(path, query, header, formData, body)
  let scheme = call_603648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603648.url(scheme.get, call_603648.host, call_603648.base,
                         call_603648.route, valid.getOrDefault("path"))
  result = hook(call_603648, url, valid)

proc call*(call_603649: Call_DescribeRootFolders_603635; marker: string = "";
          limit: int = 0): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return.
  var query_603650 = newJObject()
  add(query_603650, "marker", newJString(marker))
  add(query_603650, "limit", newJInt(limit))
  result = call_603649.call(nil, query_603650, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_603635(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_603636, base: "/",
    url: url_DescribeRootFolders_603637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_603651 = ref object of OpenApiRestCall_602433
proc url_GetCurrentUser_603653(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCurrentUser_603652(path: JsonNode; query: JsonNode;
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
  var valid_603654 = header.getOrDefault("X-Amz-Date")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Date", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Security-Token")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Security-Token", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Content-Sha256", valid_603656
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_603657 = header.getOrDefault("Authentication")
  valid_603657 = validateParameter(valid_603657, JString, required = true,
                                 default = nil)
  if valid_603657 != nil:
    section.add "Authentication", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Algorithm")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Algorithm", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Signature")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Signature", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-SignedHeaders", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Credential")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Credential", valid_603661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603662: Call_GetCurrentUser_603651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_603662.validator(path, query, header, formData, body)
  let scheme = call_603662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603662.url(scheme.get, call_603662.host, call_603662.base,
                         call_603662.route, valid.getOrDefault("path"))
  result = hook(call_603662, url, valid)

proc call*(call_603663: Call_GetCurrentUser_603651): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_603663.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_603651(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_603652,
    base: "/", url: url_GetCurrentUser_603653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_603664 = ref object of OpenApiRestCall_602433
proc url_GetDocumentPath_603666(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDocumentPath_603665(path: JsonNode; query: JsonNode;
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
  var valid_603667 = path.getOrDefault("DocumentId")
  valid_603667 = validateParameter(valid_603667, JString, required = true,
                                 default = nil)
  if valid_603667 != nil:
    section.add "DocumentId", valid_603667
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_603668 = query.getOrDefault("fields")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "fields", valid_603668
  var valid_603669 = query.getOrDefault("marker")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "marker", valid_603669
  var valid_603670 = query.getOrDefault("limit")
  valid_603670 = validateParameter(valid_603670, JInt, required = false, default = nil)
  if valid_603670 != nil:
    section.add "limit", valid_603670
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
  var valid_603671 = header.getOrDefault("X-Amz-Date")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Date", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Security-Token")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Security-Token", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Content-Sha256", valid_603673
  var valid_603674 = header.getOrDefault("Authentication")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "Authentication", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Algorithm")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Algorithm", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Signature")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Signature", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-SignedHeaders", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Credential")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Credential", valid_603678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603679: Call_GetDocumentPath_603664; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_603679.validator(path, query, header, formData, body)
  let scheme = call_603679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603679.url(scheme.get, call_603679.host, call_603679.base,
                         call_603679.route, valid.getOrDefault("path"))
  result = hook(call_603679, url, valid)

proc call*(call_603680: Call_GetDocumentPath_603664; DocumentId: string;
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
  var path_603681 = newJObject()
  var query_603682 = newJObject()
  add(query_603682, "fields", newJString(fields))
  add(query_603682, "marker", newJString(marker))
  add(path_603681, "DocumentId", newJString(DocumentId))
  add(query_603682, "limit", newJInt(limit))
  result = call_603680.call(path_603681, query_603682, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_603664(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_603665, base: "/", url: url_GetDocumentPath_603666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_603683 = ref object of OpenApiRestCall_602433
proc url_GetFolderPath_603685(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetFolderPath_603684(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603686 = path.getOrDefault("FolderId")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = nil)
  if valid_603686 != nil:
    section.add "FolderId", valid_603686
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_603687 = query.getOrDefault("fields")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "fields", valid_603687
  var valid_603688 = query.getOrDefault("marker")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "marker", valid_603688
  var valid_603689 = query.getOrDefault("limit")
  valid_603689 = validateParameter(valid_603689, JInt, required = false, default = nil)
  if valid_603689 != nil:
    section.add "limit", valid_603689
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
  var valid_603690 = header.getOrDefault("X-Amz-Date")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Date", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Security-Token")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Security-Token", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Content-Sha256", valid_603692
  var valid_603693 = header.getOrDefault("Authentication")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "Authentication", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Algorithm")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Algorithm", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Signature")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Signature", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-SignedHeaders", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Credential")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Credential", valid_603697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_GetFolderPath_603683; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"))
  result = hook(call_603698, url, valid)

proc call*(call_603699: Call_GetFolderPath_603683; FolderId: string;
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
  var path_603700 = newJObject()
  var query_603701 = newJObject()
  add(query_603701, "fields", newJString(fields))
  add(path_603700, "FolderId", newJString(FolderId))
  add(query_603701, "marker", newJString(marker))
  add(query_603701, "limit", newJInt(limit))
  result = call_603699.call(path_603700, query_603701, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_603683(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_603684,
    base: "/", url: url_GetFolderPath_603685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_603702 = ref object of OpenApiRestCall_602433
proc url_GetResources_603704(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResources_603703(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603705 = query.getOrDefault("collectionType")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_603705 != nil:
    section.add "collectionType", valid_603705
  var valid_603706 = query.getOrDefault("marker")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "marker", valid_603706
  var valid_603707 = query.getOrDefault("limit")
  valid_603707 = validateParameter(valid_603707, JInt, required = false, default = nil)
  if valid_603707 != nil:
    section.add "limit", valid_603707
  var valid_603708 = query.getOrDefault("userId")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "userId", valid_603708
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
  var valid_603709 = header.getOrDefault("X-Amz-Date")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Date", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Security-Token")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Security-Token", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Content-Sha256", valid_603711
  var valid_603712 = header.getOrDefault("Authentication")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "Authentication", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Algorithm")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Algorithm", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Signature")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Signature", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-SignedHeaders", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Credential")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Credential", valid_603716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603717: Call_GetResources_603702; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_603717.validator(path, query, header, formData, body)
  let scheme = call_603717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603717.url(scheme.get, call_603717.host, call_603717.base,
                         call_603717.route, valid.getOrDefault("path"))
  result = hook(call_603717, url, valid)

proc call*(call_603718: Call_GetResources_603702;
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
  var query_603719 = newJObject()
  add(query_603719, "collectionType", newJString(collectionType))
  add(query_603719, "marker", newJString(marker))
  add(query_603719, "limit", newJInt(limit))
  add(query_603719, "userId", newJString(userId))
  result = call_603718.call(nil, query_603719, nil, nil, nil)

var getResources* = Call_GetResources_603702(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_603703, base: "/",
    url: url_GetResources_603704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_603720 = ref object of OpenApiRestCall_602433
proc url_InitiateDocumentVersionUpload_603722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InitiateDocumentVersionUpload_603721(path: JsonNode; query: JsonNode;
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
  var valid_603723 = header.getOrDefault("X-Amz-Date")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Date", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Security-Token")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Security-Token", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Content-Sha256", valid_603725
  var valid_603726 = header.getOrDefault("Authentication")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "Authentication", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Algorithm")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Algorithm", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Signature")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Signature", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-SignedHeaders", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Credential")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Credential", valid_603730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603732: Call_InitiateDocumentVersionUpload_603720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_603732.validator(path, query, header, formData, body)
  let scheme = call_603732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603732.url(scheme.get, call_603732.host, call_603732.base,
                         call_603732.route, valid.getOrDefault("path"))
  result = hook(call_603732, url, valid)

proc call*(call_603733: Call_InitiateDocumentVersionUpload_603720; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_603734 = newJObject()
  if body != nil:
    body_603734 = body
  result = call_603733.call(nil, nil, nil, nil, body_603734)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_603720(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_603721, base: "/",
    url: url_InitiateDocumentVersionUpload_603722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_603735 = ref object of OpenApiRestCall_602433
proc url_RemoveResourcePermission_603737(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_RemoveResourcePermission_603736(path: JsonNode; query: JsonNode;
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
  var valid_603738 = path.getOrDefault("ResourceId")
  valid_603738 = validateParameter(valid_603738, JString, required = true,
                                 default = nil)
  if valid_603738 != nil:
    section.add "ResourceId", valid_603738
  var valid_603739 = path.getOrDefault("PrincipalId")
  valid_603739 = validateParameter(valid_603739, JString, required = true,
                                 default = nil)
  if valid_603739 != nil:
    section.add "PrincipalId", valid_603739
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_603740 = query.getOrDefault("type")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = newJString("USER"))
  if valid_603740 != nil:
    section.add "type", valid_603740
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
  var valid_603741 = header.getOrDefault("X-Amz-Date")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Date", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Security-Token")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Security-Token", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Content-Sha256", valid_603743
  var valid_603744 = header.getOrDefault("Authentication")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "Authentication", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Algorithm")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Algorithm", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Signature")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Signature", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-SignedHeaders", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Credential")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Credential", valid_603748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603749: Call_RemoveResourcePermission_603735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_603749.validator(path, query, header, formData, body)
  let scheme = call_603749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603749.url(scheme.get, call_603749.host, call_603749.base,
                         call_603749.route, valid.getOrDefault("path"))
  result = hook(call_603749, url, valid)

proc call*(call_603750: Call_RemoveResourcePermission_603735; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_603751 = newJObject()
  var query_603752 = newJObject()
  add(query_603752, "type", newJString(`type`))
  add(path_603751, "ResourceId", newJString(ResourceId))
  add(path_603751, "PrincipalId", newJString(PrincipalId))
  result = call_603750.call(path_603751, query_603752, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_603735(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_603736, base: "/",
    url: url_RemoveResourcePermission_603737, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
