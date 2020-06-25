
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_GetDocumentVersion_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetDocumentVersion_21625781(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentVersion_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625895 = path.getOrDefault("VersionId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "VersionId", valid_21625895
  var valid_21625896 = path.getOrDefault("DocumentId")
  valid_21625896 = validateParameter(valid_21625896, JString, required = true,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "DocumentId", valid_21625896
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_21625897 = query.getOrDefault("fields")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "fields", valid_21625897
  var valid_21625898 = query.getOrDefault("includeCustomMetadata")
  valid_21625898 = validateParameter(valid_21625898, JBool, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "includeCustomMetadata", valid_21625898
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
  var valid_21625899 = header.getOrDefault("X-Amz-Date")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Date", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Security-Token", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625901
  var valid_21625902 = header.getOrDefault("Authentication")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "Authentication", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Algorithm", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Signature")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Signature", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625905
  var valid_21625906 = header.getOrDefault("X-Amz-Credential")
  valid_21625906 = validateParameter(valid_21625906, JString, required = false,
                                   default = nil)
  if valid_21625906 != nil:
    section.add "X-Amz-Credential", valid_21625906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625931: Call_GetDocumentVersion_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_21625931.validator(path, query, header, formData, body, _)
  let scheme = call_21625931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625931.makeUrl(scheme.get, call_21625931.host, call_21625931.base,
                               call_21625931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625931, uri, valid, _)

proc call*(call_21625994: Call_GetDocumentVersion_21625779; VersionId: string;
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
  var path_21625996 = newJObject()
  var query_21625998 = newJObject()
  add(query_21625998, "fields", newJString(fields))
  add(path_21625996, "VersionId", newJString(VersionId))
  add(query_21625998, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_21625996, "DocumentId", newJString(DocumentId))
  result = call_21625994.call(path_21625996, query_21625998, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_21625779(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_21625780, base: "/",
    makeUrl: url_GetDocumentVersion_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_21626052 = ref object of OpenApiRestCall_21625435
proc url_UpdateDocumentVersion_21626054(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_UpdateDocumentVersion_21626053(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626055 = path.getOrDefault("VersionId")
  valid_21626055 = validateParameter(valid_21626055, JString, required = true,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "VersionId", valid_21626055
  var valid_21626056 = path.getOrDefault("DocumentId")
  valid_21626056 = validateParameter(valid_21626056, JString, required = true,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "DocumentId", valid_21626056
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
  var valid_21626057 = header.getOrDefault("X-Amz-Date")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Date", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Security-Token", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626059
  var valid_21626060 = header.getOrDefault("Authentication")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "Authentication", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Algorithm", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Signature")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Signature", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Credential")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Credential", valid_21626064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626066: Call_UpdateDocumentVersion_21626052;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_21626066.validator(path, query, header, formData, body, _)
  let scheme = call_21626066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626066.makeUrl(scheme.get, call_21626066.host, call_21626066.base,
                               call_21626066.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626066, uri, valid, _)

proc call*(call_21626067: Call_UpdateDocumentVersion_21626052; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_21626068 = newJObject()
  var body_21626069 = newJObject()
  add(path_21626068, "VersionId", newJString(VersionId))
  add(path_21626068, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_21626069 = body
  result = call_21626067.call(path_21626068, nil, nil, nil, body_21626069)

var updateDocumentVersion* = Call_UpdateDocumentVersion_21626052(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_21626053, base: "/",
    makeUrl: url_UpdateDocumentVersion_21626054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_21626036 = ref object of OpenApiRestCall_21625435
proc url_AbortDocumentVersionUpload_21626038(protocol: Scheme; host: string;
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

proc validate_AbortDocumentVersionUpload_21626037(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626039 = path.getOrDefault("VersionId")
  valid_21626039 = validateParameter(valid_21626039, JString, required = true,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "VersionId", valid_21626039
  var valid_21626040 = path.getOrDefault("DocumentId")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "DocumentId", valid_21626040
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
  var valid_21626041 = header.getOrDefault("X-Amz-Date")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Date", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Security-Token", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626043
  var valid_21626044 = header.getOrDefault("Authentication")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "Authentication", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Algorithm", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Signature")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Signature", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Credential")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Credential", valid_21626048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626049: Call_AbortDocumentVersionUpload_21626036;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_21626049.validator(path, query, header, formData, body, _)
  let scheme = call_21626049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626049.makeUrl(scheme.get, call_21626049.host, call_21626049.base,
                               call_21626049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626049, uri, valid, _)

proc call*(call_21626050: Call_AbortDocumentVersionUpload_21626036;
          VersionId: string; DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_21626051 = newJObject()
  add(path_21626051, "VersionId", newJString(VersionId))
  add(path_21626051, "DocumentId", newJString(DocumentId))
  result = call_21626050.call(path_21626051, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_21626036(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_21626037, base: "/",
    makeUrl: url_AbortDocumentVersionUpload_21626038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_21626070 = ref object of OpenApiRestCall_21625435
proc url_ActivateUser_21626072(protocol: Scheme; host: string; base: string;
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

proc validate_ActivateUser_21626071(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_21626073 = path.getOrDefault("UserId")
  valid_21626073 = validateParameter(valid_21626073, JString, required = true,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "UserId", valid_21626073
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
  var valid_21626074 = header.getOrDefault("X-Amz-Date")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Date", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Security-Token", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626076
  var valid_21626077 = header.getOrDefault("Authentication")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "Authentication", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Algorithm", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Signature")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Signature", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Credential")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Credential", valid_21626081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626082: Call_ActivateUser_21626070; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_21626082.validator(path, query, header, formData, body, _)
  let scheme = call_21626082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626082.makeUrl(scheme.get, call_21626082.host, call_21626082.base,
                               call_21626082.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626082, uri, valid, _)

proc call*(call_21626083: Call_ActivateUser_21626070; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_21626084 = newJObject()
  add(path_21626084, "UserId", newJString(UserId))
  result = call_21626083.call(path_21626084, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_21626070(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_21626071,
    base: "/", makeUrl: url_ActivateUser_21626072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_21626085 = ref object of OpenApiRestCall_21625435
proc url_DeactivateUser_21626087(protocol: Scheme; host: string; base: string;
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

proc validate_DeactivateUser_21626086(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_21626088 = path.getOrDefault("UserId")
  valid_21626088 = validateParameter(valid_21626088, JString, required = true,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "UserId", valid_21626088
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
  var valid_21626089 = header.getOrDefault("X-Amz-Date")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Date", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Security-Token", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626091
  var valid_21626092 = header.getOrDefault("Authentication")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "Authentication", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Algorithm", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Signature")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Signature", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Credential")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Credential", valid_21626096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626097: Call_DeactivateUser_21626085; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_21626097.validator(path, query, header, formData, body, _)
  let scheme = call_21626097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626097.makeUrl(scheme.get, call_21626097.host, call_21626097.base,
                               call_21626097.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626097, uri, valid, _)

proc call*(call_21626098: Call_DeactivateUser_21626085; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_21626099 = newJObject()
  add(path_21626099, "UserId", newJString(UserId))
  result = call_21626098.call(path_21626099, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_21626085(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_21626086, base: "/",
    makeUrl: url_DeactivateUser_21626087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_21626119 = ref object of OpenApiRestCall_21625435
proc url_AddResourcePermissions_21626121(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_AddResourcePermissions_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626122 = path.getOrDefault("ResourceId")
  valid_21626122 = validateParameter(valid_21626122, JString, required = true,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "ResourceId", valid_21626122
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
  var valid_21626123 = header.getOrDefault("X-Amz-Date")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Date", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Security-Token", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("Authentication")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "Authentication", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Algorithm", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Signature")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Signature", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Credential")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Credential", valid_21626130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626132: Call_AddResourcePermissions_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_21626132.validator(path, query, header, formData, body, _)
  let scheme = call_21626132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626132.makeUrl(scheme.get, call_21626132.host, call_21626132.base,
                               call_21626132.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626132, uri, valid, _)

proc call*(call_21626133: Call_AddResourcePermissions_21626119; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_21626134 = newJObject()
  var body_21626135 = newJObject()
  add(path_21626134, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_21626135 = body
  result = call_21626133.call(path_21626134, nil, nil, nil, body_21626135)

var addResourcePermissions* = Call_AddResourcePermissions_21626119(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_21626120, base: "/",
    makeUrl: url_AddResourcePermissions_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_21626100 = ref object of OpenApiRestCall_21625435
proc url_DescribeResourcePermissions_21626102(protocol: Scheme; host: string;
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

proc validate_DescribeResourcePermissions_21626101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626103 = path.getOrDefault("ResourceId")
  valid_21626103 = validateParameter(valid_21626103, JString, required = true,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "ResourceId", valid_21626103
  result.add "path", section
  ## parameters in `query` object:
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_21626104 = query.getOrDefault("principalId")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "principalId", valid_21626104
  var valid_21626105 = query.getOrDefault("marker")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "marker", valid_21626105
  var valid_21626106 = query.getOrDefault("limit")
  valid_21626106 = validateParameter(valid_21626106, JInt, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "limit", valid_21626106
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626109
  var valid_21626110 = header.getOrDefault("Authentication")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "Authentication", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626115: Call_DescribeResourcePermissions_21626100;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_21626115.validator(path, query, header, formData, body, _)
  let scheme = call_21626115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626115.makeUrl(scheme.get, call_21626115.host, call_21626115.base,
                               call_21626115.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626115, uri, valid, _)

proc call*(call_21626116: Call_DescribeResourcePermissions_21626100;
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
  var path_21626117 = newJObject()
  var query_21626118 = newJObject()
  add(query_21626118, "principalId", newJString(principalId))
  add(query_21626118, "marker", newJString(marker))
  add(path_21626117, "ResourceId", newJString(ResourceId))
  add(query_21626118, "limit", newJInt(limit))
  result = call_21626116.call(path_21626117, query_21626118, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_21626100(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_21626101, base: "/",
    makeUrl: url_DescribeResourcePermissions_21626102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_21626136 = ref object of OpenApiRestCall_21625435
proc url_RemoveAllResourcePermissions_21626138(protocol: Scheme; host: string;
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

proc validate_RemoveAllResourcePermissions_21626137(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626139 = path.getOrDefault("ResourceId")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "ResourceId", valid_21626139
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
  var valid_21626140 = header.getOrDefault("X-Amz-Date")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Date", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Security-Token", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("Authentication")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "Authentication", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Algorithm", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Signature")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Signature", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Credential")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Credential", valid_21626147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626148: Call_RemoveAllResourcePermissions_21626136;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_RemoveAllResourcePermissions_21626136;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_21626150 = newJObject()
  add(path_21626150, "ResourceId", newJString(ResourceId))
  result = call_21626149.call(path_21626150, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_21626136(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_21626137, base: "/",
    makeUrl: url_RemoveAllResourcePermissions_21626138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_21626151 = ref object of OpenApiRestCall_21625435
proc url_CreateComment_21626153(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComment_21626152(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626154 = path.getOrDefault("VersionId")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "VersionId", valid_21626154
  var valid_21626155 = path.getOrDefault("DocumentId")
  valid_21626155 = validateParameter(valid_21626155, JString, required = true,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "DocumentId", valid_21626155
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
  var valid_21626156 = header.getOrDefault("X-Amz-Date")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Date", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Security-Token", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626158
  var valid_21626159 = header.getOrDefault("Authentication")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "Authentication", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Algorithm", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Signature")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Signature", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Credential")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Credential", valid_21626163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626165: Call_CreateComment_21626151; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_21626165.validator(path, query, header, formData, body, _)
  let scheme = call_21626165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626165.makeUrl(scheme.get, call_21626165.host, call_21626165.base,
                               call_21626165.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626165, uri, valid, _)

proc call*(call_21626166: Call_CreateComment_21626151; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_21626167 = newJObject()
  var body_21626168 = newJObject()
  add(path_21626167, "VersionId", newJString(VersionId))
  add(path_21626167, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_21626168 = body
  result = call_21626166.call(path_21626167, nil, nil, nil, body_21626168)

var createComment* = Call_CreateComment_21626151(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_21626152, base: "/",
    makeUrl: url_CreateComment_21626153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_21626169 = ref object of OpenApiRestCall_21625435
proc url_CreateCustomMetadata_21626171(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCustomMetadata_21626170(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626172 = path.getOrDefault("ResourceId")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "ResourceId", valid_21626172
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_21626173 = query.getOrDefault("versionid")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "versionid", valid_21626173
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
  var valid_21626174 = header.getOrDefault("X-Amz-Date")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Date", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Security-Token", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626176
  var valid_21626177 = header.getOrDefault("Authentication")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "Authentication", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Algorithm", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Signature")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Signature", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Credential")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Credential", valid_21626181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626183: Call_CreateCustomMetadata_21626169; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_21626183.validator(path, query, header, formData, body, _)
  let scheme = call_21626183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626183.makeUrl(scheme.get, call_21626183.host, call_21626183.base,
                               call_21626183.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626183, uri, valid, _)

proc call*(call_21626184: Call_CreateCustomMetadata_21626169; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_21626185 = newJObject()
  var query_21626186 = newJObject()
  var body_21626187 = newJObject()
  add(query_21626186, "versionid", newJString(versionid))
  add(path_21626185, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_21626187 = body
  result = call_21626184.call(path_21626185, query_21626186, nil, nil, body_21626187)

var createCustomMetadata* = Call_CreateCustomMetadata_21626169(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_21626170, base: "/",
    makeUrl: url_CreateCustomMetadata_21626171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_21626188 = ref object of OpenApiRestCall_21625435
proc url_DeleteCustomMetadata_21626190(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCustomMetadata_21626189(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626191 = path.getOrDefault("ResourceId")
  valid_21626191 = validateParameter(valid_21626191, JString, required = true,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "ResourceId", valid_21626191
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  section = newJObject()
  var valid_21626192 = query.getOrDefault("versionId")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "versionId", valid_21626192
  var valid_21626193 = query.getOrDefault("keys")
  valid_21626193 = validateParameter(valid_21626193, JArray, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "keys", valid_21626193
  var valid_21626194 = query.getOrDefault("deleteAll")
  valid_21626194 = validateParameter(valid_21626194, JBool, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "deleteAll", valid_21626194
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
  var valid_21626195 = header.getOrDefault("X-Amz-Date")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Date", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Security-Token", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626197
  var valid_21626198 = header.getOrDefault("Authentication")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "Authentication", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Algorithm", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Signature")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Signature", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Credential")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Credential", valid_21626202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626203: Call_DeleteCustomMetadata_21626188; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_21626203.validator(path, query, header, formData, body, _)
  let scheme = call_21626203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626203.makeUrl(scheme.get, call_21626203.host, call_21626203.base,
                               call_21626203.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626203, uri, valid, _)

proc call*(call_21626204: Call_DeleteCustomMetadata_21626188; ResourceId: string;
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
  var path_21626205 = newJObject()
  var query_21626206 = newJObject()
  add(query_21626206, "versionId", newJString(versionId))
  if keys != nil:
    query_21626206.add "keys", keys
  add(path_21626205, "ResourceId", newJString(ResourceId))
  add(query_21626206, "deleteAll", newJBool(deleteAll))
  result = call_21626204.call(path_21626205, query_21626206, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_21626188(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_21626189, base: "/",
    makeUrl: url_DeleteCustomMetadata_21626190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_21626207 = ref object of OpenApiRestCall_21625435
proc url_CreateFolder_21626209(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFolder_21626208(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626210 = header.getOrDefault("X-Amz-Date")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Date", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Security-Token", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626212
  var valid_21626213 = header.getOrDefault("Authentication")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "Authentication", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Algorithm", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Signature")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Signature", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Credential")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Credential", valid_21626217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626219: Call_CreateFolder_21626207; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_CreateFolder_21626207; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_21626221 = newJObject()
  if body != nil:
    body_21626221 = body
  result = call_21626220.call(nil, nil, nil, nil, body_21626221)

var createFolder* = Call_CreateFolder_21626207(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_21626208, base: "/",
    makeUrl: url_CreateFolder_21626209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_21626222 = ref object of OpenApiRestCall_21625435
proc url_CreateLabels_21626224(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLabels_21626223(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626225 = path.getOrDefault("ResourceId")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "ResourceId", valid_21626225
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
  var valid_21626226 = header.getOrDefault("X-Amz-Date")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Date", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Security-Token", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626228
  var valid_21626229 = header.getOrDefault("Authentication")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "Authentication", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Algorithm", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Signature")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Signature", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Credential")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Credential", valid_21626233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626235: Call_CreateLabels_21626222; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_21626235.validator(path, query, header, formData, body, _)
  let scheme = call_21626235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626235.makeUrl(scheme.get, call_21626235.host, call_21626235.base,
                               call_21626235.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626235, uri, valid, _)

proc call*(call_21626236: Call_CreateLabels_21626222; ResourceId: string;
          body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_21626237 = newJObject()
  var body_21626238 = newJObject()
  add(path_21626237, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_21626238 = body
  result = call_21626236.call(path_21626237, nil, nil, nil, body_21626238)

var createLabels* = Call_CreateLabels_21626222(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_21626223, base: "/", makeUrl: url_CreateLabels_21626224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_21626239 = ref object of OpenApiRestCall_21625435
proc url_DeleteLabels_21626241(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLabels_21626240(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626242 = path.getOrDefault("ResourceId")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "ResourceId", valid_21626242
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_21626243 = query.getOrDefault("labels")
  valid_21626243 = validateParameter(valid_21626243, JArray, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "labels", valid_21626243
  var valid_21626244 = query.getOrDefault("deleteAll")
  valid_21626244 = validateParameter(valid_21626244, JBool, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "deleteAll", valid_21626244
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
  var valid_21626245 = header.getOrDefault("X-Amz-Date")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Date", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Security-Token", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("Authentication")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "Authentication", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Algorithm", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Signature")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Signature", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Credential")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Credential", valid_21626252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626253: Call_DeleteLabels_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_DeleteLabels_21626239; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  var path_21626255 = newJObject()
  var query_21626256 = newJObject()
  if labels != nil:
    query_21626256.add "labels", labels
  add(path_21626255, "ResourceId", newJString(ResourceId))
  add(query_21626256, "deleteAll", newJBool(deleteAll))
  result = call_21626254.call(path_21626255, query_21626256, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_21626239(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_21626240, base: "/", makeUrl: url_DeleteLabels_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_21626274 = ref object of OpenApiRestCall_21625435
proc url_CreateNotificationSubscription_21626276(protocol: Scheme; host: string;
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

proc validate_CreateNotificationSubscription_21626275(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626277 = path.getOrDefault("OrganizationId")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "OrganizationId", valid_21626277
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
  var valid_21626278 = header.getOrDefault("X-Amz-Date")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Date", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Security-Token", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Algorithm", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Signature")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Signature", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Credential")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Credential", valid_21626284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626286: Call_CreateNotificationSubscription_21626274;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_21626286.validator(path, query, header, formData, body, _)
  let scheme = call_21626286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626286.makeUrl(scheme.get, call_21626286.host, call_21626286.base,
                               call_21626286.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626286, uri, valid, _)

proc call*(call_21626287: Call_CreateNotificationSubscription_21626274;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_21626288 = newJObject()
  var body_21626289 = newJObject()
  add(path_21626288, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_21626289 = body
  result = call_21626287.call(path_21626288, nil, nil, nil, body_21626289)

var createNotificationSubscription* = Call_CreateNotificationSubscription_21626274(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_21626275, base: "/",
    makeUrl: url_CreateNotificationSubscription_21626276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_21626257 = ref object of OpenApiRestCall_21625435
proc url_DescribeNotificationSubscriptions_21626259(protocol: Scheme; host: string;
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

proc validate_DescribeNotificationSubscriptions_21626258(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626260 = path.getOrDefault("OrganizationId")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "OrganizationId", valid_21626260
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  section = newJObject()
  var valid_21626261 = query.getOrDefault("marker")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "marker", valid_21626261
  var valid_21626262 = query.getOrDefault("limit")
  valid_21626262 = validateParameter(valid_21626262, JInt, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "limit", valid_21626262
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
  var valid_21626263 = header.getOrDefault("X-Amz-Date")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Date", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Security-Token", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Algorithm", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Signature")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Signature", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Credential")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Credential", valid_21626269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626270: Call_DescribeNotificationSubscriptions_21626257;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_21626270.validator(path, query, header, formData, body, _)
  let scheme = call_21626270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626270.makeUrl(scheme.get, call_21626270.host, call_21626270.base,
                               call_21626270.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626270, uri, valid, _)

proc call*(call_21626271: Call_DescribeNotificationSubscriptions_21626257;
          OrganizationId: string; marker: string = ""; limit: int = 0): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  var path_21626272 = newJObject()
  var query_21626273 = newJObject()
  add(path_21626272, "OrganizationId", newJString(OrganizationId))
  add(query_21626273, "marker", newJString(marker))
  add(query_21626273, "limit", newJInt(limit))
  result = call_21626271.call(path_21626272, query_21626273, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_21626257(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_21626258, base: "/",
    makeUrl: url_DescribeNotificationSubscriptions_21626259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_21626330 = ref object of OpenApiRestCall_21625435
proc url_CreateUser_21626332(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_21626331(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626333 = header.getOrDefault("X-Amz-Date")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Date", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Security-Token", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("Authentication")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "Authentication", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Algorithm", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Signature")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Signature", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Credential")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Credential", valid_21626340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626342: Call_CreateUser_21626330; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_21626342.validator(path, query, header, formData, body, _)
  let scheme = call_21626342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626342.makeUrl(scheme.get, call_21626342.host, call_21626342.base,
                               call_21626342.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626342, uri, valid, _)

proc call*(call_21626343: Call_CreateUser_21626330; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_21626344 = newJObject()
  if body != nil:
    body_21626344 = body
  result = call_21626343.call(nil, nil, nil, nil, body_21626344)

var createUser* = Call_CreateUser_21626330(name: "createUser",
                                        meth: HttpMethod.HttpPost,
                                        host: "workdocs.amazonaws.com",
                                        route: "/api/v1/users",
                                        validator: validate_CreateUser_21626331,
                                        base: "/", makeUrl: url_CreateUser_21626332,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_21626290 = ref object of OpenApiRestCall_21625435
proc url_DescribeUsers_21626292(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUsers_21626291(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626293 = query.getOrDefault("fields")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "fields", valid_21626293
  var valid_21626294 = query.getOrDefault("query")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "query", valid_21626294
  var valid_21626309 = query.getOrDefault("sort")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = newJString("USER_NAME"))
  if valid_21626309 != nil:
    section.add "sort", valid_21626309
  var valid_21626310 = query.getOrDefault("order")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = newJString("ASCENDING"))
  if valid_21626310 != nil:
    section.add "order", valid_21626310
  var valid_21626311 = query.getOrDefault("Limit")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "Limit", valid_21626311
  var valid_21626312 = query.getOrDefault("include")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = newJString("ALL"))
  if valid_21626312 != nil:
    section.add "include", valid_21626312
  var valid_21626313 = query.getOrDefault("organizationId")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "organizationId", valid_21626313
  var valid_21626314 = query.getOrDefault("marker")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "marker", valid_21626314
  var valid_21626315 = query.getOrDefault("Marker")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "Marker", valid_21626315
  var valid_21626316 = query.getOrDefault("limit")
  valid_21626316 = validateParameter(valid_21626316, JInt, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "limit", valid_21626316
  var valid_21626317 = query.getOrDefault("userIds")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "userIds", valid_21626317
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
  var valid_21626318 = header.getOrDefault("X-Amz-Date")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Date", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Security-Token", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("Authentication")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "Authentication", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Algorithm", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Signature")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Signature", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Credential")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Credential", valid_21626325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626326: Call_DescribeUsers_21626290; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_DescribeUsers_21626290; fields: string = "";
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
  var query_21626328 = newJObject()
  add(query_21626328, "fields", newJString(fields))
  add(query_21626328, "query", newJString(query))
  add(query_21626328, "sort", newJString(sort))
  add(query_21626328, "order", newJString(order))
  add(query_21626328, "Limit", newJString(Limit))
  add(query_21626328, "include", newJString(`include`))
  add(query_21626328, "organizationId", newJString(organizationId))
  add(query_21626328, "marker", newJString(marker))
  add(query_21626328, "Marker", newJString(Marker))
  add(query_21626328, "limit", newJInt(limit))
  add(query_21626328, "userIds", newJString(userIds))
  result = call_21626327.call(nil, query_21626328, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_21626290(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_21626291, base: "/",
    makeUrl: url_DescribeUsers_21626292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_21626345 = ref object of OpenApiRestCall_21625435
proc url_DeleteComment_21626347(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteComment_21626346(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626348 = path.getOrDefault("CommentId")
  valid_21626348 = validateParameter(valid_21626348, JString, required = true,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "CommentId", valid_21626348
  var valid_21626349 = path.getOrDefault("VersionId")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "VersionId", valid_21626349
  var valid_21626350 = path.getOrDefault("DocumentId")
  valid_21626350 = validateParameter(valid_21626350, JString, required = true,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "DocumentId", valid_21626350
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
  var valid_21626351 = header.getOrDefault("X-Amz-Date")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Date", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Security-Token", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626353
  var valid_21626354 = header.getOrDefault("Authentication")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "Authentication", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Algorithm", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Signature")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Signature", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Credential")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Credential", valid_21626358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626359: Call_DeleteComment_21626345; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_21626359.validator(path, query, header, formData, body, _)
  let scheme = call_21626359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626359.makeUrl(scheme.get, call_21626359.host, call_21626359.base,
                               call_21626359.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626359, uri, valid, _)

proc call*(call_21626360: Call_DeleteComment_21626345; CommentId: string;
          VersionId: string; DocumentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_21626361 = newJObject()
  add(path_21626361, "CommentId", newJString(CommentId))
  add(path_21626361, "VersionId", newJString(VersionId))
  add(path_21626361, "DocumentId", newJString(DocumentId))
  result = call_21626360.call(path_21626361, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_21626345(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_21626346, base: "/",
    makeUrl: url_DeleteComment_21626347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_21626362 = ref object of OpenApiRestCall_21625435
proc url_GetDocument_21626364(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_21626363(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626365 = path.getOrDefault("DocumentId")
  valid_21626365 = validateParameter(valid_21626365, JString, required = true,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "DocumentId", valid_21626365
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_21626366 = query.getOrDefault("includeCustomMetadata")
  valid_21626366 = validateParameter(valid_21626366, JBool, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "includeCustomMetadata", valid_21626366
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
  var valid_21626367 = header.getOrDefault("X-Amz-Date")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Date", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Security-Token", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626369
  var valid_21626370 = header.getOrDefault("Authentication")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "Authentication", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Algorithm", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Signature")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Signature", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Credential")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Credential", valid_21626374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626375: Call_GetDocument_21626362; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_21626375.validator(path, query, header, formData, body, _)
  let scheme = call_21626375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626375.makeUrl(scheme.get, call_21626375.host, call_21626375.base,
                               call_21626375.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626375, uri, valid, _)

proc call*(call_21626376: Call_GetDocument_21626362; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_21626377 = newJObject()
  var query_21626378 = newJObject()
  add(query_21626378, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_21626377, "DocumentId", newJString(DocumentId))
  result = call_21626376.call(path_21626377, query_21626378, nil, nil, nil)

var getDocument* = Call_GetDocument_21626362(name: "getDocument",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_GetDocument_21626363,
    base: "/", makeUrl: url_GetDocument_21626364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_21626394 = ref object of OpenApiRestCall_21625435
proc url_UpdateDocument_21626396(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_21626395(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626397 = path.getOrDefault("DocumentId")
  valid_21626397 = validateParameter(valid_21626397, JString, required = true,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "DocumentId", valid_21626397
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
  var valid_21626398 = header.getOrDefault("X-Amz-Date")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Date", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Security-Token", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626400
  var valid_21626401 = header.getOrDefault("Authentication")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "Authentication", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Algorithm", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Signature")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Signature", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Credential")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Credential", valid_21626405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626407: Call_UpdateDocument_21626394; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_21626407.validator(path, query, header, formData, body, _)
  let scheme = call_21626407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626407.makeUrl(scheme.get, call_21626407.host, call_21626407.base,
                               call_21626407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626407, uri, valid, _)

proc call*(call_21626408: Call_UpdateDocument_21626394; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_21626409 = newJObject()
  var body_21626410 = newJObject()
  add(path_21626409, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_21626410 = body
  result = call_21626408.call(path_21626409, nil, nil, nil, body_21626410)

var updateDocument* = Call_UpdateDocument_21626394(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_21626395,
    base: "/", makeUrl: url_UpdateDocument_21626396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_21626379 = ref object of OpenApiRestCall_21625435
proc url_DeleteDocument_21626381(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_21626380(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626382 = path.getOrDefault("DocumentId")
  valid_21626382 = validateParameter(valid_21626382, JString, required = true,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "DocumentId", valid_21626382
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
  var valid_21626383 = header.getOrDefault("X-Amz-Date")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Date", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Security-Token", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626385
  var valid_21626386 = header.getOrDefault("Authentication")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "Authentication", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Algorithm", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Signature")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Signature", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Credential")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Credential", valid_21626390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626391: Call_DeleteDocument_21626379; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_21626391.validator(path, query, header, formData, body, _)
  let scheme = call_21626391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626391.makeUrl(scheme.get, call_21626391.host, call_21626391.base,
                               call_21626391.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626391, uri, valid, _)

proc call*(call_21626392: Call_DeleteDocument_21626379; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_21626393 = newJObject()
  add(path_21626393, "DocumentId", newJString(DocumentId))
  result = call_21626392.call(path_21626393, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_21626379(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_21626380,
    base: "/", makeUrl: url_DeleteDocument_21626381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_21626411 = ref object of OpenApiRestCall_21625435
proc url_GetFolder_21626413(protocol: Scheme; host: string; base: string;
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

proc validate_GetFolder_21626412(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the metadata of the specified folder.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_21626414 = path.getOrDefault("FolderId")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "FolderId", valid_21626414
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_21626415 = query.getOrDefault("includeCustomMetadata")
  valid_21626415 = validateParameter(valid_21626415, JBool, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "includeCustomMetadata", valid_21626415
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
  var valid_21626416 = header.getOrDefault("X-Amz-Date")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Date", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Security-Token", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626418
  var valid_21626419 = header.getOrDefault("Authentication")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "Authentication", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Algorithm", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Signature")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Signature", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Credential")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Credential", valid_21626423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626424: Call_GetFolder_21626411; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_21626424.validator(path, query, header, formData, body, _)
  let scheme = call_21626424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626424.makeUrl(scheme.get, call_21626424.host, call_21626424.base,
                               call_21626424.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626424, uri, valid, _)

proc call*(call_21626425: Call_GetFolder_21626411; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  var path_21626426 = newJObject()
  var query_21626427 = newJObject()
  add(path_21626426, "FolderId", newJString(FolderId))
  add(query_21626427, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_21626425.call(path_21626426, query_21626427, nil, nil, nil)

var getFolder* = Call_GetFolder_21626411(name: "getFolder", meth: HttpMethod.HttpGet,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/folders/{FolderId}",
                                      validator: validate_GetFolder_21626412,
                                      base: "/", makeUrl: url_GetFolder_21626413,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_21626443 = ref object of OpenApiRestCall_21625435
proc url_UpdateFolder_21626445(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFolder_21626444(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_21626446 = path.getOrDefault("FolderId")
  valid_21626446 = validateParameter(valid_21626446, JString, required = true,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "FolderId", valid_21626446
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
  var valid_21626447 = header.getOrDefault("X-Amz-Date")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Date", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Security-Token", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626449
  var valid_21626450 = header.getOrDefault("Authentication")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "Authentication", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Algorithm", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Signature")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Signature", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Credential")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Credential", valid_21626454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626456: Call_UpdateFolder_21626443; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_21626456.validator(path, query, header, formData, body, _)
  let scheme = call_21626456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626456.makeUrl(scheme.get, call_21626456.host, call_21626456.base,
                               call_21626456.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626456, uri, valid, _)

proc call*(call_21626457: Call_UpdateFolder_21626443; FolderId: string;
          body: JsonNode): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  ##   body: JObject (required)
  var path_21626458 = newJObject()
  var body_21626459 = newJObject()
  add(path_21626458, "FolderId", newJString(FolderId))
  if body != nil:
    body_21626459 = body
  result = call_21626457.call(path_21626458, nil, nil, nil, body_21626459)

var updateFolder* = Call_UpdateFolder_21626443(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_21626444,
    base: "/", makeUrl: url_UpdateFolder_21626445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_21626428 = ref object of OpenApiRestCall_21625435
proc url_DeleteFolder_21626430(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolder_21626429(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Permanently deletes the specified folder and its contents.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_21626431 = path.getOrDefault("FolderId")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "FolderId", valid_21626431
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
  var valid_21626432 = header.getOrDefault("X-Amz-Date")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Date", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Security-Token", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626434
  var valid_21626435 = header.getOrDefault("Authentication")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "Authentication", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Algorithm", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Signature")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Signature", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Credential")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Credential", valid_21626439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626440: Call_DeleteFolder_21626428; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_21626440.validator(path, query, header, formData, body, _)
  let scheme = call_21626440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626440.makeUrl(scheme.get, call_21626440.host, call_21626440.base,
                               call_21626440.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626440, uri, valid, _)

proc call*(call_21626441: Call_DeleteFolder_21626428; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_21626442 = newJObject()
  add(path_21626442, "FolderId", newJString(FolderId))
  result = call_21626441.call(path_21626442, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_21626428(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_21626429,
    base: "/", makeUrl: url_DeleteFolder_21626430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_21626460 = ref object of OpenApiRestCall_21625435
proc url_DescribeFolderContents_21626462(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_DescribeFolderContents_21626461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_21626463 = path.getOrDefault("FolderId")
  valid_21626463 = validateParameter(valid_21626463, JString, required = true,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "FolderId", valid_21626463
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
  var valid_21626464 = query.getOrDefault("sort")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = newJString("DATE"))
  if valid_21626464 != nil:
    section.add "sort", valid_21626464
  var valid_21626465 = query.getOrDefault("type")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = newJString("ALL"))
  if valid_21626465 != nil:
    section.add "type", valid_21626465
  var valid_21626466 = query.getOrDefault("order")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = newJString("ASCENDING"))
  if valid_21626466 != nil:
    section.add "order", valid_21626466
  var valid_21626467 = query.getOrDefault("Limit")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "Limit", valid_21626467
  var valid_21626468 = query.getOrDefault("include")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "include", valid_21626468
  var valid_21626469 = query.getOrDefault("marker")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "marker", valid_21626469
  var valid_21626470 = query.getOrDefault("Marker")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "Marker", valid_21626470
  var valid_21626471 = query.getOrDefault("limit")
  valid_21626471 = validateParameter(valid_21626471, JInt, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "limit", valid_21626471
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
  var valid_21626472 = header.getOrDefault("X-Amz-Date")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Date", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Security-Token", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626474
  var valid_21626475 = header.getOrDefault("Authentication")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "Authentication", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Algorithm", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Signature")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Signature", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Credential")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Credential", valid_21626479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626480: Call_DescribeFolderContents_21626460;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_21626480.validator(path, query, header, formData, body, _)
  let scheme = call_21626480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626480.makeUrl(scheme.get, call_21626480.host, call_21626480.base,
                               call_21626480.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626480, uri, valid, _)

proc call*(call_21626481: Call_DescribeFolderContents_21626460; FolderId: string;
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
  var path_21626482 = newJObject()
  var query_21626483 = newJObject()
  add(query_21626483, "sort", newJString(sort))
  add(query_21626483, "type", newJString(`type`))
  add(query_21626483, "order", newJString(order))
  add(query_21626483, "Limit", newJString(Limit))
  add(query_21626483, "include", newJString(`include`))
  add(path_21626482, "FolderId", newJString(FolderId))
  add(query_21626483, "marker", newJString(marker))
  add(query_21626483, "Marker", newJString(Marker))
  add(query_21626483, "limit", newJInt(limit))
  result = call_21626481.call(path_21626482, query_21626483, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_21626460(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_21626461, base: "/",
    makeUrl: url_DescribeFolderContents_21626462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_21626484 = ref object of OpenApiRestCall_21625435
proc url_DeleteFolderContents_21626486(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolderContents_21626485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the contents of the specified folder.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_21626487 = path.getOrDefault("FolderId")
  valid_21626487 = validateParameter(valid_21626487, JString, required = true,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "FolderId", valid_21626487
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
  var valid_21626488 = header.getOrDefault("X-Amz-Date")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Date", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Security-Token", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626490
  var valid_21626491 = header.getOrDefault("Authentication")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "Authentication", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Algorithm", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Signature")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Signature", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Credential")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Credential", valid_21626495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626496: Call_DeleteFolderContents_21626484; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_21626496.validator(path, query, header, formData, body, _)
  let scheme = call_21626496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626496.makeUrl(scheme.get, call_21626496.host, call_21626496.base,
                               call_21626496.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626496, uri, valid, _)

proc call*(call_21626497: Call_DeleteFolderContents_21626484; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_21626498 = newJObject()
  add(path_21626498, "FolderId", newJString(FolderId))
  result = call_21626497.call(path_21626498, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_21626484(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_21626485, base: "/",
    makeUrl: url_DeleteFolderContents_21626486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_21626499 = ref object of OpenApiRestCall_21625435
proc url_DeleteNotificationSubscription_21626501(protocol: Scheme; host: string;
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

proc validate_DeleteNotificationSubscription_21626500(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626502 = path.getOrDefault("SubscriptionId")
  valid_21626502 = validateParameter(valid_21626502, JString, required = true,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "SubscriptionId", valid_21626502
  var valid_21626503 = path.getOrDefault("OrganizationId")
  valid_21626503 = validateParameter(valid_21626503, JString, required = true,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "OrganizationId", valid_21626503
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
  var valid_21626504 = header.getOrDefault("X-Amz-Date")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Date", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Security-Token", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Algorithm", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Signature")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Signature", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Credential")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Credential", valid_21626510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626511: Call_DeleteNotificationSubscription_21626499;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_21626511.validator(path, query, header, formData, body, _)
  let scheme = call_21626511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626511.makeUrl(scheme.get, call_21626511.host, call_21626511.base,
                               call_21626511.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626511, uri, valid, _)

proc call*(call_21626512: Call_DeleteNotificationSubscription_21626499;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_21626513 = newJObject()
  add(path_21626513, "SubscriptionId", newJString(SubscriptionId))
  add(path_21626513, "OrganizationId", newJString(OrganizationId))
  result = call_21626512.call(path_21626513, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_21626499(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_21626500, base: "/",
    makeUrl: url_DeleteNotificationSubscription_21626501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_21626529 = ref object of OpenApiRestCall_21625435
proc url_UpdateUser_21626531(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateUser_21626530(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_21626532 = path.getOrDefault("UserId")
  valid_21626532 = validateParameter(valid_21626532, JString, required = true,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "UserId", valid_21626532
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
  var valid_21626533 = header.getOrDefault("X-Amz-Date")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Date", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Security-Token", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626535
  var valid_21626536 = header.getOrDefault("Authentication")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "Authentication", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Algorithm", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Signature")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Signature", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-Credential")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Credential", valid_21626540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626542: Call_UpdateUser_21626529; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_21626542.validator(path, query, header, formData, body, _)
  let scheme = call_21626542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626542.makeUrl(scheme.get, call_21626542.host, call_21626542.base,
                               call_21626542.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626542, uri, valid, _)

proc call*(call_21626543: Call_UpdateUser_21626529; body: JsonNode; UserId: string): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_21626544 = newJObject()
  var body_21626545 = newJObject()
  if body != nil:
    body_21626545 = body
  add(path_21626544, "UserId", newJString(UserId))
  result = call_21626543.call(path_21626544, nil, nil, nil, body_21626545)

var updateUser* = Call_UpdateUser_21626529(name: "updateUser",
                                        meth: HttpMethod.HttpPatch,
                                        host: "workdocs.amazonaws.com",
                                        route: "/api/v1/users/{UserId}",
                                        validator: validate_UpdateUser_21626530,
                                        base: "/", makeUrl: url_UpdateUser_21626531,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_21626514 = ref object of OpenApiRestCall_21625435
proc url_DeleteUser_21626516(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteUser_21626515(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The ID of the user.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_21626517 = path.getOrDefault("UserId")
  valid_21626517 = validateParameter(valid_21626517, JString, required = true,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "UserId", valid_21626517
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
  var valid_21626518 = header.getOrDefault("X-Amz-Date")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Date", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Security-Token", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626520
  var valid_21626521 = header.getOrDefault("Authentication")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "Authentication", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Algorithm", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Signature")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Signature", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-Credential")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Credential", valid_21626525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626526: Call_DeleteUser_21626514; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_21626526.validator(path, query, header, formData, body, _)
  let scheme = call_21626526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626526.makeUrl(scheme.get, call_21626526.host, call_21626526.base,
                               call_21626526.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626526, uri, valid, _)

proc call*(call_21626527: Call_DeleteUser_21626514; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_21626528 = newJObject()
  add(path_21626528, "UserId", newJString(UserId))
  result = call_21626527.call(path_21626528, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_21626514(name: "deleteUser",
                                        meth: HttpMethod.HttpDelete,
                                        host: "workdocs.amazonaws.com",
                                        route: "/api/v1/users/{UserId}",
                                        validator: validate_DeleteUser_21626515,
                                        base: "/", makeUrl: url_DeleteUser_21626516,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_21626546 = ref object of OpenApiRestCall_21625435
proc url_DescribeActivities_21626548(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivities_21626547(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626549 = query.getOrDefault("endTime")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "endTime", valid_21626549
  var valid_21626550 = query.getOrDefault("organizationId")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "organizationId", valid_21626550
  var valid_21626551 = query.getOrDefault("includeIndirectActivities")
  valid_21626551 = validateParameter(valid_21626551, JBool, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "includeIndirectActivities", valid_21626551
  var valid_21626552 = query.getOrDefault("activityTypes")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "activityTypes", valid_21626552
  var valid_21626553 = query.getOrDefault("marker")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "marker", valid_21626553
  var valid_21626554 = query.getOrDefault("resourceId")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "resourceId", valid_21626554
  var valid_21626555 = query.getOrDefault("startTime")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "startTime", valid_21626555
  var valid_21626556 = query.getOrDefault("limit")
  valid_21626556 = validateParameter(valid_21626556, JInt, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "limit", valid_21626556
  var valid_21626557 = query.getOrDefault("userId")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "userId", valid_21626557
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
  var valid_21626558 = header.getOrDefault("X-Amz-Date")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Date", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Security-Token", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("Authentication")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "Authentication", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Algorithm", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Signature")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Signature", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Credential")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Credential", valid_21626565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626566: Call_DescribeActivities_21626546; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_DescribeActivities_21626546; endTime: string = "";
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
  var query_21626568 = newJObject()
  add(query_21626568, "endTime", newJString(endTime))
  add(query_21626568, "organizationId", newJString(organizationId))
  add(query_21626568, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_21626568, "activityTypes", newJString(activityTypes))
  add(query_21626568, "marker", newJString(marker))
  add(query_21626568, "resourceId", newJString(resourceId))
  add(query_21626568, "startTime", newJString(startTime))
  add(query_21626568, "limit", newJInt(limit))
  add(query_21626568, "userId", newJString(userId))
  result = call_21626567.call(nil, query_21626568, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_21626546(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_21626547, base: "/",
    makeUrl: url_DescribeActivities_21626548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_21626569 = ref object of OpenApiRestCall_21625435
proc url_DescribeComments_21626571(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeComments_21626570(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626572 = path.getOrDefault("VersionId")
  valid_21626572 = validateParameter(valid_21626572, JString, required = true,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "VersionId", valid_21626572
  var valid_21626573 = path.getOrDefault("DocumentId")
  valid_21626573 = validateParameter(valid_21626573, JString, required = true,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "DocumentId", valid_21626573
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   limit: JInt
  ##        : The maximum number of items to return.
  section = newJObject()
  var valid_21626574 = query.getOrDefault("marker")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "marker", valid_21626574
  var valid_21626575 = query.getOrDefault("limit")
  valid_21626575 = validateParameter(valid_21626575, JInt, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "limit", valid_21626575
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
  var valid_21626576 = header.getOrDefault("X-Amz-Date")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Date", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Security-Token", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626578
  var valid_21626579 = header.getOrDefault("Authentication")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "Authentication", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Algorithm", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Signature")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Signature", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Credential")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Credential", valid_21626583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626584: Call_DescribeComments_21626569; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_21626584.validator(path, query, header, formData, body, _)
  let scheme = call_21626584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626584.makeUrl(scheme.get, call_21626584.host, call_21626584.base,
                               call_21626584.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626584, uri, valid, _)

proc call*(call_21626585: Call_DescribeComments_21626569; VersionId: string;
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
  var path_21626586 = newJObject()
  var query_21626587 = newJObject()
  add(path_21626586, "VersionId", newJString(VersionId))
  add(query_21626587, "marker", newJString(marker))
  add(path_21626586, "DocumentId", newJString(DocumentId))
  add(query_21626587, "limit", newJInt(limit))
  result = call_21626585.call(path_21626586, query_21626587, nil, nil, nil)

var describeComments* = Call_DescribeComments_21626569(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_21626570, base: "/",
    makeUrl: url_DescribeComments_21626571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_21626588 = ref object of OpenApiRestCall_21625435
proc url_DescribeDocumentVersions_21626590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeDocumentVersions_21626589(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626591 = path.getOrDefault("DocumentId")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "DocumentId", valid_21626591
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
  var valid_21626592 = query.getOrDefault("fields")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "fields", valid_21626592
  var valid_21626593 = query.getOrDefault("Limit")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "Limit", valid_21626593
  var valid_21626594 = query.getOrDefault("include")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "include", valid_21626594
  var valid_21626595 = query.getOrDefault("marker")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "marker", valid_21626595
  var valid_21626596 = query.getOrDefault("Marker")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "Marker", valid_21626596
  var valid_21626597 = query.getOrDefault("limit")
  valid_21626597 = validateParameter(valid_21626597, JInt, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "limit", valid_21626597
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
  var valid_21626598 = header.getOrDefault("X-Amz-Date")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Date", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Security-Token", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626600
  var valid_21626601 = header.getOrDefault("Authentication")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "Authentication", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Algorithm", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Signature")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Signature", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Credential")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Credential", valid_21626605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626606: Call_DescribeDocumentVersions_21626588;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_21626606.validator(path, query, header, formData, body, _)
  let scheme = call_21626606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626606.makeUrl(scheme.get, call_21626606.host, call_21626606.base,
                               call_21626606.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626606, uri, valid, _)

proc call*(call_21626607: Call_DescribeDocumentVersions_21626588;
          DocumentId: string; fields: string = ""; Limit: string = "";
          `include`: string = ""; marker: string = ""; Marker: string = ""; limit: int = 0): Recallable =
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
  var path_21626608 = newJObject()
  var query_21626609 = newJObject()
  add(query_21626609, "fields", newJString(fields))
  add(query_21626609, "Limit", newJString(Limit))
  add(query_21626609, "include", newJString(`include`))
  add(query_21626609, "marker", newJString(marker))
  add(query_21626609, "Marker", newJString(Marker))
  add(path_21626608, "DocumentId", newJString(DocumentId))
  add(query_21626609, "limit", newJInt(limit))
  result = call_21626607.call(path_21626608, query_21626609, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_21626588(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_21626589, base: "/",
    makeUrl: url_DescribeDocumentVersions_21626590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_21626610 = ref object of OpenApiRestCall_21625435
proc url_DescribeGroups_21626612(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGroups_21626611(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626613 = query.getOrDefault("searchQuery")
  valid_21626613 = validateParameter(valid_21626613, JString, required = true,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "searchQuery", valid_21626613
  var valid_21626614 = query.getOrDefault("organizationId")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "organizationId", valid_21626614
  var valid_21626615 = query.getOrDefault("marker")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "marker", valid_21626615
  var valid_21626616 = query.getOrDefault("limit")
  valid_21626616 = validateParameter(valid_21626616, JInt, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "limit", valid_21626616
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
  var valid_21626617 = header.getOrDefault("X-Amz-Date")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Date", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Security-Token", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626619
  var valid_21626620 = header.getOrDefault("Authentication")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "Authentication", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Algorithm", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Signature")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Signature", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Credential")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Credential", valid_21626624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626625: Call_DescribeGroups_21626610; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_21626625.validator(path, query, header, formData, body, _)
  let scheme = call_21626625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626625.makeUrl(scheme.get, call_21626625.host, call_21626625.base,
                               call_21626625.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626625, uri, valid, _)

proc call*(call_21626626: Call_DescribeGroups_21626610; searchQuery: string;
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
  var query_21626627 = newJObject()
  add(query_21626627, "searchQuery", newJString(searchQuery))
  add(query_21626627, "organizationId", newJString(organizationId))
  add(query_21626627, "marker", newJString(marker))
  add(query_21626627, "limit", newJInt(limit))
  result = call_21626626.call(nil, query_21626627, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_21626610(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_21626611,
    base: "/", makeUrl: url_DescribeGroups_21626612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_21626628 = ref object of OpenApiRestCall_21625435
proc url_DescribeRootFolders_21626630(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRootFolders_21626629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626631 = query.getOrDefault("marker")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "marker", valid_21626631
  var valid_21626632 = query.getOrDefault("limit")
  valid_21626632 = validateParameter(valid_21626632, JInt, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "limit", valid_21626632
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
  var valid_21626633 = header.getOrDefault("X-Amz-Date")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Date", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Security-Token", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626635
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_21626636 = header.getOrDefault("Authentication")
  valid_21626636 = validateParameter(valid_21626636, JString, required = true,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "Authentication", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Algorithm", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-Signature")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-Signature", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626639
  var valid_21626640 = header.getOrDefault("X-Amz-Credential")
  valid_21626640 = validateParameter(valid_21626640, JString, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "X-Amz-Credential", valid_21626640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626641: Call_DescribeRootFolders_21626628; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_DescribeRootFolders_21626628; marker: string = "";
          limit: int = 0): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   limit: int
  ##        : The maximum number of items to return.
  var query_21626643 = newJObject()
  add(query_21626643, "marker", newJString(marker))
  add(query_21626643, "limit", newJInt(limit))
  result = call_21626642.call(nil, query_21626643, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_21626628(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_21626629, base: "/",
    makeUrl: url_DescribeRootFolders_21626630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_21626644 = ref object of OpenApiRestCall_21625435
proc url_GetCurrentUser_21626646(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCurrentUser_21626645(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626647 = header.getOrDefault("X-Amz-Date")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Date", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Security-Token", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626649
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_21626650 = header.getOrDefault("Authentication")
  valid_21626650 = validateParameter(valid_21626650, JString, required = true,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "Authentication", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Algorithm", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Signature")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Signature", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Credential")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Credential", valid_21626654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626655: Call_GetCurrentUser_21626644; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_21626655.validator(path, query, header, formData, body, _)
  let scheme = call_21626655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626655.makeUrl(scheme.get, call_21626655.host, call_21626655.base,
                               call_21626655.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626655, uri, valid, _)

proc call*(call_21626656: Call_GetCurrentUser_21626644): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_21626656.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_21626644(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_21626645,
    base: "/", makeUrl: url_GetCurrentUser_21626646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_21626657 = ref object of OpenApiRestCall_21625435
proc url_GetDocumentPath_21626659(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentPath_21626658(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626660 = path.getOrDefault("DocumentId")
  valid_21626660 = validateParameter(valid_21626660, JString, required = true,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "DocumentId", valid_21626660
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_21626661 = query.getOrDefault("fields")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "fields", valid_21626661
  var valid_21626662 = query.getOrDefault("marker")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "marker", valid_21626662
  var valid_21626663 = query.getOrDefault("limit")
  valid_21626663 = validateParameter(valid_21626663, JInt, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "limit", valid_21626663
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
  var valid_21626664 = header.getOrDefault("X-Amz-Date")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Date", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Security-Token", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626666
  var valid_21626667 = header.getOrDefault("Authentication")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "Authentication", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Algorithm", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Signature")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Signature", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626670
  var valid_21626671 = header.getOrDefault("X-Amz-Credential")
  valid_21626671 = validateParameter(valid_21626671, JString, required = false,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "X-Amz-Credential", valid_21626671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626672: Call_GetDocumentPath_21626657; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_21626672.validator(path, query, header, formData, body, _)
  let scheme = call_21626672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626672.makeUrl(scheme.get, call_21626672.host, call_21626672.base,
                               call_21626672.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626672, uri, valid, _)

proc call*(call_21626673: Call_GetDocumentPath_21626657; DocumentId: string;
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
  var path_21626674 = newJObject()
  var query_21626675 = newJObject()
  add(query_21626675, "fields", newJString(fields))
  add(query_21626675, "marker", newJString(marker))
  add(path_21626674, "DocumentId", newJString(DocumentId))
  add(query_21626675, "limit", newJInt(limit))
  result = call_21626673.call(path_21626674, query_21626675, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_21626657(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_21626658, base: "/",
    makeUrl: url_GetDocumentPath_21626659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_21626676 = ref object of OpenApiRestCall_21625435
proc url_GetFolderPath_21626678(protocol: Scheme; host: string; base: string;
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

proc validate_GetFolderPath_21626677(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
  ##           : The ID of the folder.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `FolderId` field"
  var valid_21626679 = path.getOrDefault("FolderId")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "FolderId", valid_21626679
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  section = newJObject()
  var valid_21626680 = query.getOrDefault("fields")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "fields", valid_21626680
  var valid_21626681 = query.getOrDefault("marker")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "marker", valid_21626681
  var valid_21626682 = query.getOrDefault("limit")
  valid_21626682 = validateParameter(valid_21626682, JInt, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "limit", valid_21626682
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
  var valid_21626683 = header.getOrDefault("X-Amz-Date")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Date", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Security-Token", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626685
  var valid_21626686 = header.getOrDefault("Authentication")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "Authentication", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Algorithm", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-Signature")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Signature", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Credential")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Credential", valid_21626690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626691: Call_GetFolderPath_21626676; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_21626691.validator(path, query, header, formData, body, _)
  let scheme = call_21626691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626691.makeUrl(scheme.get, call_21626691.host, call_21626691.base,
                               call_21626691.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626691, uri, valid, _)

proc call*(call_21626692: Call_GetFolderPath_21626676; FolderId: string;
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
  var path_21626693 = newJObject()
  var query_21626694 = newJObject()
  add(query_21626694, "fields", newJString(fields))
  add(path_21626693, "FolderId", newJString(FolderId))
  add(query_21626694, "marker", newJString(marker))
  add(query_21626694, "limit", newJInt(limit))
  result = call_21626692.call(path_21626693, query_21626694, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_21626676(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_21626677,
    base: "/", makeUrl: url_GetFolderPath_21626678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_21626695 = ref object of OpenApiRestCall_21625435
proc url_GetResources_21626697(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResources_21626696(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626698 = query.getOrDefault("collectionType")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = newJString("SHARED_WITH_ME"))
  if valid_21626698 != nil:
    section.add "collectionType", valid_21626698
  var valid_21626699 = query.getOrDefault("marker")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "marker", valid_21626699
  var valid_21626700 = query.getOrDefault("limit")
  valid_21626700 = validateParameter(valid_21626700, JInt, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "limit", valid_21626700
  var valid_21626701 = query.getOrDefault("userId")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "userId", valid_21626701
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
  var valid_21626702 = header.getOrDefault("X-Amz-Date")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Date", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Security-Token", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626704
  var valid_21626705 = header.getOrDefault("Authentication")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "Authentication", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Algorithm", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Signature")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Signature", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Credential")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Credential", valid_21626709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626710: Call_GetResources_21626695; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_21626710.validator(path, query, header, formData, body, _)
  let scheme = call_21626710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626710.makeUrl(scheme.get, call_21626710.host, call_21626710.base,
                               call_21626710.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626710, uri, valid, _)

proc call*(call_21626711: Call_GetResources_21626695;
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
  var query_21626712 = newJObject()
  add(query_21626712, "collectionType", newJString(collectionType))
  add(query_21626712, "marker", newJString(marker))
  add(query_21626712, "limit", newJInt(limit))
  add(query_21626712, "userId", newJString(userId))
  result = call_21626711.call(nil, query_21626712, nil, nil, nil)

var getResources* = Call_GetResources_21626695(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_21626696,
    base: "/", makeUrl: url_GetResources_21626697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_21626713 = ref object of OpenApiRestCall_21625435
proc url_InitiateDocumentVersionUpload_21626715(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateDocumentVersionUpload_21626714(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626716 = header.getOrDefault("X-Amz-Date")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Date", valid_21626716
  var valid_21626717 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Security-Token", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626718
  var valid_21626719 = header.getOrDefault("Authentication")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "Authentication", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Algorithm", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Signature")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Signature", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Credential")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Credential", valid_21626723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626725: Call_InitiateDocumentVersionUpload_21626713;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_21626725.validator(path, query, header, formData, body, _)
  let scheme = call_21626725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626725.makeUrl(scheme.get, call_21626725.host, call_21626725.base,
                               call_21626725.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626725, uri, valid, _)

proc call*(call_21626726: Call_InitiateDocumentVersionUpload_21626713;
          body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_21626727 = newJObject()
  if body != nil:
    body_21626727 = body
  result = call_21626726.call(nil, nil, nil, nil, body_21626727)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_21626713(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_21626714, base: "/",
    makeUrl: url_InitiateDocumentVersionUpload_21626715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_21626728 = ref object of OpenApiRestCall_21625435
proc url_RemoveResourcePermission_21626730(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_RemoveResourcePermission_21626729(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626731 = path.getOrDefault("ResourceId")
  valid_21626731 = validateParameter(valid_21626731, JString, required = true,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "ResourceId", valid_21626731
  var valid_21626732 = path.getOrDefault("PrincipalId")
  valid_21626732 = validateParameter(valid_21626732, JString, required = true,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "PrincipalId", valid_21626732
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_21626733 = query.getOrDefault("type")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = newJString("USER"))
  if valid_21626733 != nil:
    section.add "type", valid_21626733
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
  var valid_21626734 = header.getOrDefault("X-Amz-Date")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Date", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Security-Token", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626736
  var valid_21626737 = header.getOrDefault("Authentication")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "Authentication", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Algorithm", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Signature")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Signature", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Credential")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Credential", valid_21626741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626742: Call_RemoveResourcePermission_21626728;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_21626742.validator(path, query, header, formData, body, _)
  let scheme = call_21626742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626742.makeUrl(scheme.get, call_21626742.host, call_21626742.base,
                               call_21626742.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626742, uri, valid, _)

proc call*(call_21626743: Call_RemoveResourcePermission_21626728;
          ResourceId: string; PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_21626744 = newJObject()
  var query_21626745 = newJObject()
  add(query_21626745, "type", newJString(`type`))
  add(path_21626744, "ResourceId", newJString(ResourceId))
  add(path_21626744, "PrincipalId", newJString(PrincipalId))
  result = call_21626743.call(path_21626744, query_21626745, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_21626728(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_21626729, base: "/",
    makeUrl: url_RemoveResourcePermission_21626730,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}