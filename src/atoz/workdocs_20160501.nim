
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_GetDocumentVersion_601727 = ref object of OpenApiRestCall_601389
proc url_GetDocumentVersion_601729(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentVersion_601728(path: JsonNode; query: JsonNode;
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
  var valid_601855 = path.getOrDefault("VersionId")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "VersionId", valid_601855
  var valid_601856 = path.getOrDefault("DocumentId")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = nil)
  if valid_601856 != nil:
    section.add "DocumentId", valid_601856
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  section = newJObject()
  var valid_601857 = query.getOrDefault("includeCustomMetadata")
  valid_601857 = validateParameter(valid_601857, JBool, required = false, default = nil)
  if valid_601857 != nil:
    section.add "includeCustomMetadata", valid_601857
  var valid_601858 = query.getOrDefault("fields")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "fields", valid_601858
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
  var valid_601859 = header.getOrDefault("X-Amz-Signature")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Signature", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Content-Sha256", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Date")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Date", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Credential")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Credential", valid_601862
  var valid_601863 = header.getOrDefault("Authentication")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "Authentication", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Security-Token")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Security-Token", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Algorithm")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Algorithm", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-SignedHeaders", valid_601866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601889: Call_GetDocumentVersion_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_601889.validator(path, query, header, formData, body)
  let scheme = call_601889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601889.url(scheme.get, call_601889.host, call_601889.base,
                         call_601889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601889, url, valid)

proc call*(call_601960: Call_GetDocumentVersion_601727; VersionId: string;
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
  var path_601961 = newJObject()
  var query_601963 = newJObject()
  add(path_601961, "VersionId", newJString(VersionId))
  add(path_601961, "DocumentId", newJString(DocumentId))
  add(query_601963, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(query_601963, "fields", newJString(fields))
  result = call_601960.call(path_601961, query_601963, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_601727(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_601728, base: "/",
    url: url_GetDocumentVersion_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_602018 = ref object of OpenApiRestCall_601389
proc url_UpdateDocumentVersion_602020(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentVersion_602019(path: JsonNode; query: JsonNode;
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
  var valid_602021 = path.getOrDefault("VersionId")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = nil)
  if valid_602021 != nil:
    section.add "VersionId", valid_602021
  var valid_602022 = path.getOrDefault("DocumentId")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = nil)
  if valid_602022 != nil:
    section.add "DocumentId", valid_602022
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
  var valid_602023 = header.getOrDefault("X-Amz-Signature")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Signature", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Date")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Date", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Credential")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Credential", valid_602026
  var valid_602027 = header.getOrDefault("Authentication")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "Authentication", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Security-Token")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Security-Token", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-SignedHeaders", valid_602030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602032: Call_UpdateDocumentVersion_602018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_602032.validator(path, query, header, formData, body)
  let scheme = call_602032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602032.url(scheme.get, call_602032.host, call_602032.base,
                         call_602032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602032, url, valid)

proc call*(call_602033: Call_UpdateDocumentVersion_602018; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_602034 = newJObject()
  var body_602035 = newJObject()
  add(path_602034, "VersionId", newJString(VersionId))
  add(path_602034, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_602035 = body
  result = call_602033.call(path_602034, nil, nil, nil, body_602035)

var updateDocumentVersion* = Call_UpdateDocumentVersion_602018(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_602019, base: "/",
    url: url_UpdateDocumentVersion_602020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_602002 = ref object of OpenApiRestCall_601389
proc url_AbortDocumentVersionUpload_602004(protocol: Scheme; host: string;
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

proc validate_AbortDocumentVersionUpload_602003(path: JsonNode; query: JsonNode;
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
  var valid_602005 = path.getOrDefault("VersionId")
  valid_602005 = validateParameter(valid_602005, JString, required = true,
                                 default = nil)
  if valid_602005 != nil:
    section.add "VersionId", valid_602005
  var valid_602006 = path.getOrDefault("DocumentId")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = nil)
  if valid_602006 != nil:
    section.add "DocumentId", valid_602006
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
  var valid_602007 = header.getOrDefault("X-Amz-Signature")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Signature", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Content-Sha256", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Date")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Date", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Credential")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Credential", valid_602010
  var valid_602011 = header.getOrDefault("Authentication")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "Authentication", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Security-Token")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Security-Token", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Algorithm")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Algorithm", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-SignedHeaders", valid_602014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602015: Call_AbortDocumentVersionUpload_602002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_602015.validator(path, query, header, formData, body)
  let scheme = call_602015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602015.url(scheme.get, call_602015.host, call_602015.base,
                         call_602015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602015, url, valid)

proc call*(call_602016: Call_AbortDocumentVersionUpload_602002; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_602017 = newJObject()
  add(path_602017, "VersionId", newJString(VersionId))
  add(path_602017, "DocumentId", newJString(DocumentId))
  result = call_602016.call(path_602017, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_602002(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_602003, base: "/",
    url: url_AbortDocumentVersionUpload_602004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_602036 = ref object of OpenApiRestCall_601389
proc url_ActivateUser_602038(protocol: Scheme; host: string; base: string;
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

proc validate_ActivateUser_602037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602039 = path.getOrDefault("UserId")
  valid_602039 = validateParameter(valid_602039, JString, required = true,
                                 default = nil)
  if valid_602039 != nil:
    section.add "UserId", valid_602039
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
  var valid_602040 = header.getOrDefault("X-Amz-Signature")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Signature", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Content-Sha256", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Date")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Date", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Credential")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Credential", valid_602043
  var valid_602044 = header.getOrDefault("Authentication")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "Authentication", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Algorithm")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Algorithm", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-SignedHeaders", valid_602047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602048: Call_ActivateUser_602036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_602048.validator(path, query, header, formData, body)
  let scheme = call_602048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602048.url(scheme.get, call_602048.host, call_602048.base,
                         call_602048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602048, url, valid)

proc call*(call_602049: Call_ActivateUser_602036; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_602050 = newJObject()
  add(path_602050, "UserId", newJString(UserId))
  result = call_602049.call(path_602050, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_602036(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_602037,
    base: "/", url: url_ActivateUser_602038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_602051 = ref object of OpenApiRestCall_601389
proc url_DeactivateUser_602053(protocol: Scheme; host: string; base: string;
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

proc validate_DeactivateUser_602052(path: JsonNode; query: JsonNode;
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
  var valid_602054 = path.getOrDefault("UserId")
  valid_602054 = validateParameter(valid_602054, JString, required = true,
                                 default = nil)
  if valid_602054 != nil:
    section.add "UserId", valid_602054
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
  var valid_602055 = header.getOrDefault("X-Amz-Signature")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Signature", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Content-Sha256", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Date")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Date", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Credential")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Credential", valid_602058
  var valid_602059 = header.getOrDefault("Authentication")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "Authentication", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Security-Token")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Security-Token", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Algorithm")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Algorithm", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-SignedHeaders", valid_602062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602063: Call_DeactivateUser_602051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_602063.validator(path, query, header, formData, body)
  let scheme = call_602063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602063.url(scheme.get, call_602063.host, call_602063.base,
                         call_602063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602063, url, valid)

proc call*(call_602064: Call_DeactivateUser_602051; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_602065 = newJObject()
  add(path_602065, "UserId", newJString(UserId))
  result = call_602064.call(path_602065, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_602051(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_602052, base: "/", url: url_DeactivateUser_602053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_602085 = ref object of OpenApiRestCall_601389
proc url_AddResourcePermissions_602087(protocol: Scheme; host: string; base: string;
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

proc validate_AddResourcePermissions_602086(path: JsonNode; query: JsonNode;
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
  var valid_602088 = path.getOrDefault("ResourceId")
  valid_602088 = validateParameter(valid_602088, JString, required = true,
                                 default = nil)
  if valid_602088 != nil:
    section.add "ResourceId", valid_602088
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
  var valid_602089 = header.getOrDefault("X-Amz-Signature")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Signature", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Content-Sha256", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Date")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Date", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Credential")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Credential", valid_602092
  var valid_602093 = header.getOrDefault("Authentication")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "Authentication", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_AddResourcePermissions_602085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_AddResourcePermissions_602085; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_602100 = newJObject()
  var body_602101 = newJObject()
  add(path_602100, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_602101 = body
  result = call_602099.call(path_602100, nil, nil, nil, body_602101)

var addResourcePermissions* = Call_AddResourcePermissions_602085(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_602086, base: "/",
    url: url_AddResourcePermissions_602087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_602066 = ref object of OpenApiRestCall_601389
proc url_DescribeResourcePermissions_602068(protocol: Scheme; host: string;
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

proc validate_DescribeResourcePermissions_602067(path: JsonNode; query: JsonNode;
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
  var valid_602069 = path.getOrDefault("ResourceId")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = nil)
  if valid_602069 != nil:
    section.add "ResourceId", valid_602069
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  section = newJObject()
  var valid_602070 = query.getOrDefault("limit")
  valid_602070 = validateParameter(valid_602070, JInt, required = false, default = nil)
  if valid_602070 != nil:
    section.add "limit", valid_602070
  var valid_602071 = query.getOrDefault("principalId")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "principalId", valid_602071
  var valid_602072 = query.getOrDefault("marker")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "marker", valid_602072
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
  var valid_602073 = header.getOrDefault("X-Amz-Signature")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Signature", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Content-Sha256", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Date")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Date", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Credential")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Credential", valid_602076
  var valid_602077 = header.getOrDefault("Authentication")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "Authentication", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Security-Token")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Security-Token", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Algorithm")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Algorithm", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-SignedHeaders", valid_602080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_DescribeResourcePermissions_602066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602081, url, valid)

proc call*(call_602082: Call_DescribeResourcePermissions_602066;
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
  var path_602083 = newJObject()
  var query_602084 = newJObject()
  add(query_602084, "limit", newJInt(limit))
  add(path_602083, "ResourceId", newJString(ResourceId))
  add(query_602084, "principalId", newJString(principalId))
  add(query_602084, "marker", newJString(marker))
  result = call_602082.call(path_602083, query_602084, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_602066(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_602067, base: "/",
    url: url_DescribeResourcePermissions_602068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_602102 = ref object of OpenApiRestCall_601389
proc url_RemoveAllResourcePermissions_602104(protocol: Scheme; host: string;
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

proc validate_RemoveAllResourcePermissions_602103(path: JsonNode; query: JsonNode;
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
  var valid_602105 = path.getOrDefault("ResourceId")
  valid_602105 = validateParameter(valid_602105, JString, required = true,
                                 default = nil)
  if valid_602105 != nil:
    section.add "ResourceId", valid_602105
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
  var valid_602106 = header.getOrDefault("X-Amz-Signature")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Signature", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Content-Sha256", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Date")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Date", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Credential")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Credential", valid_602109
  var valid_602110 = header.getOrDefault("Authentication")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "Authentication", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Security-Token")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Security-Token", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Algorithm")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Algorithm", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-SignedHeaders", valid_602113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602114: Call_RemoveAllResourcePermissions_602102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_602114.validator(path, query, header, formData, body)
  let scheme = call_602114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602114.url(scheme.get, call_602114.host, call_602114.base,
                         call_602114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602114, url, valid)

proc call*(call_602115: Call_RemoveAllResourcePermissions_602102;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_602116 = newJObject()
  add(path_602116, "ResourceId", newJString(ResourceId))
  result = call_602115.call(path_602116, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_602102(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_602103, base: "/",
    url: url_RemoveAllResourcePermissions_602104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_602117 = ref object of OpenApiRestCall_601389
proc url_CreateComment_602119(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComment_602118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602120 = path.getOrDefault("VersionId")
  valid_602120 = validateParameter(valid_602120, JString, required = true,
                                 default = nil)
  if valid_602120 != nil:
    section.add "VersionId", valid_602120
  var valid_602121 = path.getOrDefault("DocumentId")
  valid_602121 = validateParameter(valid_602121, JString, required = true,
                                 default = nil)
  if valid_602121 != nil:
    section.add "DocumentId", valid_602121
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
  var valid_602122 = header.getOrDefault("X-Amz-Signature")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Signature", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Content-Sha256", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Date")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Date", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Credential")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Credential", valid_602125
  var valid_602126 = header.getOrDefault("Authentication")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "Authentication", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Security-Token")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Security-Token", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Algorithm")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Algorithm", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602131: Call_CreateComment_602117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_602131.validator(path, query, header, formData, body)
  let scheme = call_602131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602131.url(scheme.get, call_602131.host, call_602131.base,
                         call_602131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602131, url, valid)

proc call*(call_602132: Call_CreateComment_602117; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_602133 = newJObject()
  var body_602134 = newJObject()
  add(path_602133, "VersionId", newJString(VersionId))
  add(path_602133, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_602134 = body
  result = call_602132.call(path_602133, nil, nil, nil, body_602134)

var createComment* = Call_CreateComment_602117(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_602118, base: "/", url: url_CreateComment_602119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_602135 = ref object of OpenApiRestCall_601389
proc url_CreateCustomMetadata_602137(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCustomMetadata_602136(path: JsonNode; query: JsonNode;
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
  var valid_602138 = path.getOrDefault("ResourceId")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "ResourceId", valid_602138
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_602139 = query.getOrDefault("versionid")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "versionid", valid_602139
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
  var valid_602140 = header.getOrDefault("X-Amz-Signature")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Signature", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Content-Sha256", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Date")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Date", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Credential")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Credential", valid_602143
  var valid_602144 = header.getOrDefault("Authentication")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "Authentication", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Security-Token")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Security-Token", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Algorithm")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Algorithm", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_CreateCustomMetadata_602135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602149, url, valid)

proc call*(call_602150: Call_CreateCustomMetadata_602135; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_602151 = newJObject()
  var query_602152 = newJObject()
  var body_602153 = newJObject()
  add(query_602152, "versionid", newJString(versionid))
  add(path_602151, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_602153 = body
  result = call_602150.call(path_602151, query_602152, nil, nil, body_602153)

var createCustomMetadata* = Call_CreateCustomMetadata_602135(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_602136, base: "/",
    url: url_CreateCustomMetadata_602137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_602154 = ref object of OpenApiRestCall_601389
proc url_DeleteCustomMetadata_602156(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCustomMetadata_602155(path: JsonNode; query: JsonNode;
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
  var valid_602157 = path.getOrDefault("ResourceId")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = nil)
  if valid_602157 != nil:
    section.add "ResourceId", valid_602157
  result.add "path", section
  ## parameters in `query` object:
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  section = newJObject()
  var valid_602158 = query.getOrDefault("deleteAll")
  valid_602158 = validateParameter(valid_602158, JBool, required = false, default = nil)
  if valid_602158 != nil:
    section.add "deleteAll", valid_602158
  var valid_602159 = query.getOrDefault("keys")
  valid_602159 = validateParameter(valid_602159, JArray, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "keys", valid_602159
  var valid_602160 = query.getOrDefault("versionId")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "versionId", valid_602160
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
  var valid_602161 = header.getOrDefault("X-Amz-Signature")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Signature", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Content-Sha256", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Date")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Date", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Credential")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Credential", valid_602164
  var valid_602165 = header.getOrDefault("Authentication")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "Authentication", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Security-Token")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Security-Token", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Algorithm")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Algorithm", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-SignedHeaders", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602169: Call_DeleteCustomMetadata_602154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_602169.validator(path, query, header, formData, body)
  let scheme = call_602169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602169.url(scheme.get, call_602169.host, call_602169.base,
                         call_602169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602169, url, valid)

proc call*(call_602170: Call_DeleteCustomMetadata_602154; ResourceId: string;
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
  var path_602171 = newJObject()
  var query_602172 = newJObject()
  add(query_602172, "deleteAll", newJBool(deleteAll))
  add(path_602171, "ResourceId", newJString(ResourceId))
  if keys != nil:
    query_602172.add "keys", keys
  add(query_602172, "versionId", newJString(versionId))
  result = call_602170.call(path_602171, query_602172, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_602154(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_602155, base: "/",
    url: url_DeleteCustomMetadata_602156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_602173 = ref object of OpenApiRestCall_601389
proc url_CreateFolder_602175(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFolder_602174(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602176 = header.getOrDefault("X-Amz-Signature")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Signature", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Content-Sha256", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Date")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Date", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Credential")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Credential", valid_602179
  var valid_602180 = header.getOrDefault("Authentication")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "Authentication", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Security-Token")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Security-Token", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Algorithm")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Algorithm", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-SignedHeaders", valid_602183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602185: Call_CreateFolder_602173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602185, url, valid)

proc call*(call_602186: Call_CreateFolder_602173; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_602187 = newJObject()
  if body != nil:
    body_602187 = body
  result = call_602186.call(nil, nil, nil, nil, body_602187)

var createFolder* = Call_CreateFolder_602173(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_602174, base: "/",
    url: url_CreateFolder_602175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_602188 = ref object of OpenApiRestCall_601389
proc url_CreateLabels_602190(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLabels_602189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602191 = path.getOrDefault("ResourceId")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = nil)
  if valid_602191 != nil:
    section.add "ResourceId", valid_602191
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
  var valid_602192 = header.getOrDefault("X-Amz-Signature")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Signature", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Content-Sha256", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Date")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Date", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Credential")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Credential", valid_602195
  var valid_602196 = header.getOrDefault("Authentication")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "Authentication", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Security-Token")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Security-Token", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Algorithm")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Algorithm", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-SignedHeaders", valid_602199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602201: Call_CreateLabels_602188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_602201.validator(path, query, header, formData, body)
  let scheme = call_602201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602201.url(scheme.get, call_602201.host, call_602201.base,
                         call_602201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602201, url, valid)

proc call*(call_602202: Call_CreateLabels_602188; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_602203 = newJObject()
  var body_602204 = newJObject()
  add(path_602203, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_602204 = body
  result = call_602202.call(path_602203, nil, nil, nil, body_602204)

var createLabels* = Call_CreateLabels_602188(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_602189, base: "/", url: url_CreateLabels_602190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_602205 = ref object of OpenApiRestCall_601389
proc url_DeleteLabels_602207(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLabels_602206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602208 = path.getOrDefault("ResourceId")
  valid_602208 = validateParameter(valid_602208, JString, required = true,
                                 default = nil)
  if valid_602208 != nil:
    section.add "ResourceId", valid_602208
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_602209 = query.getOrDefault("labels")
  valid_602209 = validateParameter(valid_602209, JArray, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "labels", valid_602209
  var valid_602210 = query.getOrDefault("deleteAll")
  valid_602210 = validateParameter(valid_602210, JBool, required = false, default = nil)
  if valid_602210 != nil:
    section.add "deleteAll", valid_602210
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
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("Authentication")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "Authentication", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Security-Token")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Security-Token", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Algorithm")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Algorithm", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-SignedHeaders", valid_602218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602219: Call_DeleteLabels_602205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_602219.validator(path, query, header, formData, body)
  let scheme = call_602219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602219.url(scheme.get, call_602219.host, call_602219.base,
                         call_602219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602219, url, valid)

proc call*(call_602220: Call_DeleteLabels_602205; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_602221 = newJObject()
  var query_602222 = newJObject()
  if labels != nil:
    query_602222.add "labels", labels
  add(query_602222, "deleteAll", newJBool(deleteAll))
  add(path_602221, "ResourceId", newJString(ResourceId))
  result = call_602220.call(path_602221, query_602222, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_602205(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_602206, base: "/", url: url_DeleteLabels_602207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_602240 = ref object of OpenApiRestCall_601389
proc url_CreateNotificationSubscription_602242(protocol: Scheme; host: string;
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

proc validate_CreateNotificationSubscription_602241(path: JsonNode;
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
  var valid_602243 = path.getOrDefault("OrganizationId")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "OrganizationId", valid_602243
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
  var valid_602244 = header.getOrDefault("X-Amz-Signature")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Signature", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Content-Sha256", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Date")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Date", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Credential")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Credential", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Security-Token")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Security-Token", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Algorithm")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Algorithm", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-SignedHeaders", valid_602250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602252: Call_CreateNotificationSubscription_602240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_602252.validator(path, query, header, formData, body)
  let scheme = call_602252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602252.url(scheme.get, call_602252.host, call_602252.base,
                         call_602252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602252, url, valid)

proc call*(call_602253: Call_CreateNotificationSubscription_602240;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_602254 = newJObject()
  var body_602255 = newJObject()
  add(path_602254, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_602255 = body
  result = call_602253.call(path_602254, nil, nil, nil, body_602255)

var createNotificationSubscription* = Call_CreateNotificationSubscription_602240(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_602241, base: "/",
    url: url_CreateNotificationSubscription_602242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_602223 = ref object of OpenApiRestCall_601389
proc url_DescribeNotificationSubscriptions_602225(protocol: Scheme; host: string;
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

proc validate_DescribeNotificationSubscriptions_602224(path: JsonNode;
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
  var valid_602226 = path.getOrDefault("OrganizationId")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = nil)
  if valid_602226 != nil:
    section.add "OrganizationId", valid_602226
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_602227 = query.getOrDefault("limit")
  valid_602227 = validateParameter(valid_602227, JInt, required = false, default = nil)
  if valid_602227 != nil:
    section.add "limit", valid_602227
  var valid_602228 = query.getOrDefault("marker")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "marker", valid_602228
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
  var valid_602229 = header.getOrDefault("X-Amz-Signature")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Signature", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Content-Sha256", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Date")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Date", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Credential")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Credential", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Security-Token")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Security-Token", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Algorithm")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Algorithm", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-SignedHeaders", valid_602235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602236: Call_DescribeNotificationSubscriptions_602223;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_602236.validator(path, query, header, formData, body)
  let scheme = call_602236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602236.url(scheme.get, call_602236.host, call_602236.base,
                         call_602236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602236, url, valid)

proc call*(call_602237: Call_DescribeNotificationSubscriptions_602223;
          OrganizationId: string; limit: int = 0; marker: string = ""): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var path_602238 = newJObject()
  var query_602239 = newJObject()
  add(path_602238, "OrganizationId", newJString(OrganizationId))
  add(query_602239, "limit", newJInt(limit))
  add(query_602239, "marker", newJString(marker))
  result = call_602237.call(path_602238, query_602239, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_602223(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_602224, base: "/",
    url: url_DescribeNotificationSubscriptions_602225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_602294 = ref object of OpenApiRestCall_601389
proc url_CreateUser_602296(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_602295(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602297 = header.getOrDefault("X-Amz-Signature")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Signature", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Content-Sha256", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Date")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Date", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Credential")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Credential", valid_602300
  var valid_602301 = header.getOrDefault("Authentication")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "Authentication", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Security-Token")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Security-Token", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Algorithm")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Algorithm", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-SignedHeaders", valid_602304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602306: Call_CreateUser_602294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_602306.validator(path, query, header, formData, body)
  let scheme = call_602306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602306.url(scheme.get, call_602306.host, call_602306.base,
                         call_602306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602306, url, valid)

proc call*(call_602307: Call_CreateUser_602294; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_602308 = newJObject()
  if body != nil:
    body_602308 = body
  result = call_602307.call(nil, nil, nil, nil, body_602308)

var createUser* = Call_CreateUser_602294(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_602295,
                                      base: "/", url: url_CreateUser_602296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_602256 = ref object of OpenApiRestCall_601389
proc url_DescribeUsers_602258(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUsers_602257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602272 = query.getOrDefault("sort")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_602272 != nil:
    section.add "sort", valid_602272
  var valid_602273 = query.getOrDefault("Marker")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "Marker", valid_602273
  var valid_602274 = query.getOrDefault("order")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_602274 != nil:
    section.add "order", valid_602274
  var valid_602275 = query.getOrDefault("limit")
  valid_602275 = validateParameter(valid_602275, JInt, required = false, default = nil)
  if valid_602275 != nil:
    section.add "limit", valid_602275
  var valid_602276 = query.getOrDefault("Limit")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "Limit", valid_602276
  var valid_602277 = query.getOrDefault("userIds")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "userIds", valid_602277
  var valid_602278 = query.getOrDefault("include")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = newJString("ALL"))
  if valid_602278 != nil:
    section.add "include", valid_602278
  var valid_602279 = query.getOrDefault("query")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "query", valid_602279
  var valid_602280 = query.getOrDefault("organizationId")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "organizationId", valid_602280
  var valid_602281 = query.getOrDefault("fields")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "fields", valid_602281
  var valid_602282 = query.getOrDefault("marker")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "marker", valid_602282
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
  var valid_602283 = header.getOrDefault("X-Amz-Signature")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Signature", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Content-Sha256", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Date")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Date", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Credential")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Credential", valid_602286
  var valid_602287 = header.getOrDefault("Authentication")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "Authentication", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Security-Token")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Security-Token", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Algorithm")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Algorithm", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-SignedHeaders", valid_602290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_DescribeUsers_602256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602291, url, valid)

proc call*(call_602292: Call_DescribeUsers_602256; sort: string = "USER_NAME";
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
  var query_602293 = newJObject()
  add(query_602293, "sort", newJString(sort))
  add(query_602293, "Marker", newJString(Marker))
  add(query_602293, "order", newJString(order))
  add(query_602293, "limit", newJInt(limit))
  add(query_602293, "Limit", newJString(Limit))
  add(query_602293, "userIds", newJString(userIds))
  add(query_602293, "include", newJString(`include`))
  add(query_602293, "query", newJString(query))
  add(query_602293, "organizationId", newJString(organizationId))
  add(query_602293, "fields", newJString(fields))
  add(query_602293, "marker", newJString(marker))
  result = call_602292.call(nil, query_602293, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_602256(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_602257, base: "/",
    url: url_DescribeUsers_602258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_602309 = ref object of OpenApiRestCall_601389
proc url_DeleteComment_602311(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteComment_602310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602312 = path.getOrDefault("VersionId")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = nil)
  if valid_602312 != nil:
    section.add "VersionId", valid_602312
  var valid_602313 = path.getOrDefault("DocumentId")
  valid_602313 = validateParameter(valid_602313, JString, required = true,
                                 default = nil)
  if valid_602313 != nil:
    section.add "DocumentId", valid_602313
  var valid_602314 = path.getOrDefault("CommentId")
  valid_602314 = validateParameter(valid_602314, JString, required = true,
                                 default = nil)
  if valid_602314 != nil:
    section.add "CommentId", valid_602314
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
  var valid_602315 = header.getOrDefault("X-Amz-Signature")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Signature", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Content-Sha256", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Date")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Date", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Credential")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Credential", valid_602318
  var valid_602319 = header.getOrDefault("Authentication")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "Authentication", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Security-Token")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Security-Token", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Algorithm")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Algorithm", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-SignedHeaders", valid_602322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602323: Call_DeleteComment_602309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_602323.validator(path, query, header, formData, body)
  let scheme = call_602323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602323.url(scheme.get, call_602323.host, call_602323.base,
                         call_602323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602323, url, valid)

proc call*(call_602324: Call_DeleteComment_602309; VersionId: string;
          DocumentId: string; CommentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  var path_602325 = newJObject()
  add(path_602325, "VersionId", newJString(VersionId))
  add(path_602325, "DocumentId", newJString(DocumentId))
  add(path_602325, "CommentId", newJString(CommentId))
  result = call_602324.call(path_602325, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_602309(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_602310, base: "/", url: url_DeleteComment_602311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_602326 = ref object of OpenApiRestCall_601389
proc url_GetDocument_602328(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_602327(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602329 = path.getOrDefault("DocumentId")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "DocumentId", valid_602329
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_602330 = query.getOrDefault("includeCustomMetadata")
  valid_602330 = validateParameter(valid_602330, JBool, required = false, default = nil)
  if valid_602330 != nil:
    section.add "includeCustomMetadata", valid_602330
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
  var valid_602331 = header.getOrDefault("X-Amz-Signature")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Signature", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Content-Sha256", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Date")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Date", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Credential")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Credential", valid_602334
  var valid_602335 = header.getOrDefault("Authentication")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "Authentication", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Security-Token")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Security-Token", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Algorithm")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Algorithm", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-SignedHeaders", valid_602338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602339: Call_GetDocument_602326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_602339.validator(path, query, header, formData, body)
  let scheme = call_602339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602339.url(scheme.get, call_602339.host, call_602339.base,
                         call_602339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602339, url, valid)

proc call*(call_602340: Call_GetDocument_602326; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  var path_602341 = newJObject()
  var query_602342 = newJObject()
  add(path_602341, "DocumentId", newJString(DocumentId))
  add(query_602342, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_602340.call(path_602341, query_602342, nil, nil, nil)

var getDocument* = Call_GetDocument_602326(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_602327,
                                        base: "/", url: url_GetDocument_602328,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_602358 = ref object of OpenApiRestCall_601389
proc url_UpdateDocument_602360(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_602359(path: JsonNode; query: JsonNode;
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
  var valid_602361 = path.getOrDefault("DocumentId")
  valid_602361 = validateParameter(valid_602361, JString, required = true,
                                 default = nil)
  if valid_602361 != nil:
    section.add "DocumentId", valid_602361
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
  var valid_602362 = header.getOrDefault("X-Amz-Signature")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Signature", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Content-Sha256", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Date")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Date", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Credential")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Credential", valid_602365
  var valid_602366 = header.getOrDefault("Authentication")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "Authentication", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Security-Token")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Security-Token", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Algorithm")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Algorithm", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-SignedHeaders", valid_602369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602371: Call_UpdateDocument_602358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_602371.validator(path, query, header, formData, body)
  let scheme = call_602371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602371.url(scheme.get, call_602371.host, call_602371.base,
                         call_602371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602371, url, valid)

proc call*(call_602372: Call_UpdateDocument_602358; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_602373 = newJObject()
  var body_602374 = newJObject()
  add(path_602373, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_602374 = body
  result = call_602372.call(path_602373, nil, nil, nil, body_602374)

var updateDocument* = Call_UpdateDocument_602358(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_602359,
    base: "/", url: url_UpdateDocument_602360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_602343 = ref object of OpenApiRestCall_601389
proc url_DeleteDocument_602345(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_602344(path: JsonNode; query: JsonNode;
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
  var valid_602346 = path.getOrDefault("DocumentId")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = nil)
  if valid_602346 != nil:
    section.add "DocumentId", valid_602346
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
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("Authentication")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "Authentication", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Security-Token")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Security-Token", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Algorithm")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Algorithm", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-SignedHeaders", valid_602354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602355: Call_DeleteDocument_602343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_602355.validator(path, query, header, formData, body)
  let scheme = call_602355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602355.url(scheme.get, call_602355.host, call_602355.base,
                         call_602355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602355, url, valid)

proc call*(call_602356: Call_DeleteDocument_602343; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_602357 = newJObject()
  add(path_602357, "DocumentId", newJString(DocumentId))
  result = call_602356.call(path_602357, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_602343(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_602344,
    base: "/", url: url_DeleteDocument_602345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_602375 = ref object of OpenApiRestCall_601389
proc url_GetFolder_602377(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFolder_602376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602378 = path.getOrDefault("FolderId")
  valid_602378 = validateParameter(valid_602378, JString, required = true,
                                 default = nil)
  if valid_602378 != nil:
    section.add "FolderId", valid_602378
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_602379 = query.getOrDefault("includeCustomMetadata")
  valid_602379 = validateParameter(valid_602379, JBool, required = false, default = nil)
  if valid_602379 != nil:
    section.add "includeCustomMetadata", valid_602379
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
  var valid_602380 = header.getOrDefault("X-Amz-Signature")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Signature", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Content-Sha256", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Date")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Date", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Credential")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Credential", valid_602383
  var valid_602384 = header.getOrDefault("Authentication")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "Authentication", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Security-Token")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Security-Token", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Algorithm")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Algorithm", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-SignedHeaders", valid_602387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602388: Call_GetFolder_602375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_602388.validator(path, query, header, formData, body)
  let scheme = call_602388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602388.url(scheme.get, call_602388.host, call_602388.base,
                         call_602388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602388, url, valid)

proc call*(call_602389: Call_GetFolder_602375; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_602390 = newJObject()
  var query_602391 = newJObject()
  add(query_602391, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_602390, "FolderId", newJString(FolderId))
  result = call_602389.call(path_602390, query_602391, nil, nil, nil)

var getFolder* = Call_GetFolder_602375(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_602376,
                                    base: "/", url: url_GetFolder_602377,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_602407 = ref object of OpenApiRestCall_601389
proc url_UpdateFolder_602409(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFolder_602408(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602410 = path.getOrDefault("FolderId")
  valid_602410 = validateParameter(valid_602410, JString, required = true,
                                 default = nil)
  if valid_602410 != nil:
    section.add "FolderId", valid_602410
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
  var valid_602411 = header.getOrDefault("X-Amz-Signature")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Signature", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Content-Sha256", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Date")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Date", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Credential")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Credential", valid_602414
  var valid_602415 = header.getOrDefault("Authentication")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "Authentication", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Security-Token")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Security-Token", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Algorithm")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Algorithm", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-SignedHeaders", valid_602418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602420: Call_UpdateFolder_602407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_602420.validator(path, query, header, formData, body)
  let scheme = call_602420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602420.url(scheme.get, call_602420.host, call_602420.base,
                         call_602420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602420, url, valid)

proc call*(call_602421: Call_UpdateFolder_602407; body: JsonNode; FolderId: string): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   body: JObject (required)
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_602422 = newJObject()
  var body_602423 = newJObject()
  if body != nil:
    body_602423 = body
  add(path_602422, "FolderId", newJString(FolderId))
  result = call_602421.call(path_602422, nil, nil, nil, body_602423)

var updateFolder* = Call_UpdateFolder_602407(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_602408,
    base: "/", url: url_UpdateFolder_602409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_602392 = ref object of OpenApiRestCall_601389
proc url_DeleteFolder_602394(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolder_602393(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602395 = path.getOrDefault("FolderId")
  valid_602395 = validateParameter(valid_602395, JString, required = true,
                                 default = nil)
  if valid_602395 != nil:
    section.add "FolderId", valid_602395
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
  var valid_602396 = header.getOrDefault("X-Amz-Signature")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Signature", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Content-Sha256", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Date")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Date", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Credential")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Credential", valid_602399
  var valid_602400 = header.getOrDefault("Authentication")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "Authentication", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Security-Token")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Security-Token", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Algorithm")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Algorithm", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-SignedHeaders", valid_602403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602404: Call_DeleteFolder_602392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_602404.validator(path, query, header, formData, body)
  let scheme = call_602404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602404.url(scheme.get, call_602404.host, call_602404.base,
                         call_602404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602404, url, valid)

proc call*(call_602405: Call_DeleteFolder_602392; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_602406 = newJObject()
  add(path_602406, "FolderId", newJString(FolderId))
  result = call_602405.call(path_602406, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_602392(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_602393,
    base: "/", url: url_DeleteFolder_602394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_602424 = ref object of OpenApiRestCall_601389
proc url_DescribeFolderContents_602426(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFolderContents_602425(path: JsonNode; query: JsonNode;
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
  var valid_602427 = path.getOrDefault("FolderId")
  valid_602427 = validateParameter(valid_602427, JString, required = true,
                                 default = nil)
  if valid_602427 != nil:
    section.add "FolderId", valid_602427
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
  var valid_602428 = query.getOrDefault("sort")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = newJString("DATE"))
  if valid_602428 != nil:
    section.add "sort", valid_602428
  var valid_602429 = query.getOrDefault("Marker")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "Marker", valid_602429
  var valid_602430 = query.getOrDefault("order")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_602430 != nil:
    section.add "order", valid_602430
  var valid_602431 = query.getOrDefault("limit")
  valid_602431 = validateParameter(valid_602431, JInt, required = false, default = nil)
  if valid_602431 != nil:
    section.add "limit", valid_602431
  var valid_602432 = query.getOrDefault("Limit")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "Limit", valid_602432
  var valid_602433 = query.getOrDefault("type")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = newJString("ALL"))
  if valid_602433 != nil:
    section.add "type", valid_602433
  var valid_602434 = query.getOrDefault("include")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "include", valid_602434
  var valid_602435 = query.getOrDefault("marker")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "marker", valid_602435
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
  var valid_602436 = header.getOrDefault("X-Amz-Signature")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Signature", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Content-Sha256", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Date")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Date", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Credential")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Credential", valid_602439
  var valid_602440 = header.getOrDefault("Authentication")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "Authentication", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Security-Token")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Security-Token", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Algorithm")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Algorithm", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-SignedHeaders", valid_602443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602444: Call_DescribeFolderContents_602424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_602444.validator(path, query, header, formData, body)
  let scheme = call_602444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602444.url(scheme.get, call_602444.host, call_602444.base,
                         call_602444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602444, url, valid)

proc call*(call_602445: Call_DescribeFolderContents_602424; FolderId: string;
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
  var path_602446 = newJObject()
  var query_602447 = newJObject()
  add(query_602447, "sort", newJString(sort))
  add(query_602447, "Marker", newJString(Marker))
  add(query_602447, "order", newJString(order))
  add(query_602447, "limit", newJInt(limit))
  add(query_602447, "Limit", newJString(Limit))
  add(query_602447, "type", newJString(`type`))
  add(query_602447, "include", newJString(`include`))
  add(path_602446, "FolderId", newJString(FolderId))
  add(query_602447, "marker", newJString(marker))
  result = call_602445.call(path_602446, query_602447, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_602424(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_602425, base: "/",
    url: url_DescribeFolderContents_602426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_602448 = ref object of OpenApiRestCall_601389
proc url_DeleteFolderContents_602450(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolderContents_602449(path: JsonNode; query: JsonNode;
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
  var valid_602451 = path.getOrDefault("FolderId")
  valid_602451 = validateParameter(valid_602451, JString, required = true,
                                 default = nil)
  if valid_602451 != nil:
    section.add "FolderId", valid_602451
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
  var valid_602452 = header.getOrDefault("X-Amz-Signature")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Signature", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Content-Sha256", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Date")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Date", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Credential")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Credential", valid_602455
  var valid_602456 = header.getOrDefault("Authentication")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "Authentication", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Security-Token")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Security-Token", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Algorithm")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Algorithm", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-SignedHeaders", valid_602459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602460: Call_DeleteFolderContents_602448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_602460.validator(path, query, header, formData, body)
  let scheme = call_602460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602460.url(scheme.get, call_602460.host, call_602460.base,
                         call_602460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602460, url, valid)

proc call*(call_602461: Call_DeleteFolderContents_602448; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_602462 = newJObject()
  add(path_602462, "FolderId", newJString(FolderId))
  result = call_602461.call(path_602462, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_602448(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_602449, base: "/",
    url: url_DeleteFolderContents_602450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_602463 = ref object of OpenApiRestCall_601389
proc url_DeleteNotificationSubscription_602465(protocol: Scheme; host: string;
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

proc validate_DeleteNotificationSubscription_602464(path: JsonNode;
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
  var valid_602466 = path.getOrDefault("SubscriptionId")
  valid_602466 = validateParameter(valid_602466, JString, required = true,
                                 default = nil)
  if valid_602466 != nil:
    section.add "SubscriptionId", valid_602466
  var valid_602467 = path.getOrDefault("OrganizationId")
  valid_602467 = validateParameter(valid_602467, JString, required = true,
                                 default = nil)
  if valid_602467 != nil:
    section.add "OrganizationId", valid_602467
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
  var valid_602468 = header.getOrDefault("X-Amz-Signature")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Signature", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Content-Sha256", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Date")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Date", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Credential")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Credential", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Security-Token")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Security-Token", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Algorithm")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Algorithm", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-SignedHeaders", valid_602474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602475: Call_DeleteNotificationSubscription_602463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_602475.validator(path, query, header, formData, body)
  let scheme = call_602475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602475.url(scheme.get, call_602475.host, call_602475.base,
                         call_602475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602475, url, valid)

proc call*(call_602476: Call_DeleteNotificationSubscription_602463;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_602477 = newJObject()
  add(path_602477, "SubscriptionId", newJString(SubscriptionId))
  add(path_602477, "OrganizationId", newJString(OrganizationId))
  result = call_602476.call(path_602477, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_602463(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_602464, base: "/",
    url: url_DeleteNotificationSubscription_602465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_602493 = ref object of OpenApiRestCall_601389
proc url_UpdateUser_602495(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_602494(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602496 = path.getOrDefault("UserId")
  valid_602496 = validateParameter(valid_602496, JString, required = true,
                                 default = nil)
  if valid_602496 != nil:
    section.add "UserId", valid_602496
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
  var valid_602497 = header.getOrDefault("X-Amz-Signature")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Signature", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Content-Sha256", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Date")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Date", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Credential")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Credential", valid_602500
  var valid_602501 = header.getOrDefault("Authentication")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "Authentication", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Security-Token")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Security-Token", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Algorithm")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Algorithm", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-SignedHeaders", valid_602504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602506: Call_UpdateUser_602493; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_602506.validator(path, query, header, formData, body)
  let scheme = call_602506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602506.url(scheme.get, call_602506.host, call_602506.base,
                         call_602506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602506, url, valid)

proc call*(call_602507: Call_UpdateUser_602493; UserId: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   UserId: string (required)
  ##         : The ID of the user.
  ##   body: JObject (required)
  var path_602508 = newJObject()
  var body_602509 = newJObject()
  add(path_602508, "UserId", newJString(UserId))
  if body != nil:
    body_602509 = body
  result = call_602507.call(path_602508, nil, nil, nil, body_602509)

var updateUser* = Call_UpdateUser_602493(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_602494,
                                      base: "/", url: url_UpdateUser_602495,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_602478 = ref object of OpenApiRestCall_601389
proc url_DeleteUser_602480(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_602479(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602481 = path.getOrDefault("UserId")
  valid_602481 = validateParameter(valid_602481, JString, required = true,
                                 default = nil)
  if valid_602481 != nil:
    section.add "UserId", valid_602481
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
  var valid_602482 = header.getOrDefault("X-Amz-Signature")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Signature", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Content-Sha256", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Date")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Date", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Credential")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Credential", valid_602485
  var valid_602486 = header.getOrDefault("Authentication")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "Authentication", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Security-Token")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Security-Token", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Algorithm")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Algorithm", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-SignedHeaders", valid_602489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602490: Call_DeleteUser_602478; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_602490.validator(path, query, header, formData, body)
  let scheme = call_602490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602490.url(scheme.get, call_602490.host, call_602490.base,
                         call_602490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602490, url, valid)

proc call*(call_602491: Call_DeleteUser_602478; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_602492 = newJObject()
  add(path_602492, "UserId", newJString(UserId))
  result = call_602491.call(path_602492, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_602478(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_602479,
                                      base: "/", url: url_DeleteUser_602480,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_602510 = ref object of OpenApiRestCall_601389
proc url_DescribeActivities_602512(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActivities_602511(path: JsonNode; query: JsonNode;
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
  var valid_602513 = query.getOrDefault("endTime")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "endTime", valid_602513
  var valid_602514 = query.getOrDefault("userId")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "userId", valid_602514
  var valid_602515 = query.getOrDefault("resourceId")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "resourceId", valid_602515
  var valid_602516 = query.getOrDefault("limit")
  valid_602516 = validateParameter(valid_602516, JInt, required = false, default = nil)
  if valid_602516 != nil:
    section.add "limit", valid_602516
  var valid_602517 = query.getOrDefault("startTime")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "startTime", valid_602517
  var valid_602518 = query.getOrDefault("activityTypes")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "activityTypes", valid_602518
  var valid_602519 = query.getOrDefault("organizationId")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "organizationId", valid_602519
  var valid_602520 = query.getOrDefault("includeIndirectActivities")
  valid_602520 = validateParameter(valid_602520, JBool, required = false, default = nil)
  if valid_602520 != nil:
    section.add "includeIndirectActivities", valid_602520
  var valid_602521 = query.getOrDefault("marker")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "marker", valid_602521
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
  var valid_602522 = header.getOrDefault("X-Amz-Signature")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Signature", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Content-Sha256", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Date")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Date", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Credential")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Credential", valid_602525
  var valid_602526 = header.getOrDefault("Authentication")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "Authentication", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Security-Token")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Security-Token", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Algorithm")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Algorithm", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-SignedHeaders", valid_602529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602530: Call_DescribeActivities_602510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_602530.validator(path, query, header, formData, body)
  let scheme = call_602530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602530.url(scheme.get, call_602530.host, call_602530.base,
                         call_602530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602530, url, valid)

proc call*(call_602531: Call_DescribeActivities_602510; endTime: string = "";
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
  var query_602532 = newJObject()
  add(query_602532, "endTime", newJString(endTime))
  add(query_602532, "userId", newJString(userId))
  add(query_602532, "resourceId", newJString(resourceId))
  add(query_602532, "limit", newJInt(limit))
  add(query_602532, "startTime", newJString(startTime))
  add(query_602532, "activityTypes", newJString(activityTypes))
  add(query_602532, "organizationId", newJString(organizationId))
  add(query_602532, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_602532, "marker", newJString(marker))
  result = call_602531.call(nil, query_602532, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_602510(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_602511, base: "/",
    url: url_DescribeActivities_602512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_602533 = ref object of OpenApiRestCall_601389
proc url_DescribeComments_602535(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeComments_602534(path: JsonNode; query: JsonNode;
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
  var valid_602536 = path.getOrDefault("VersionId")
  valid_602536 = validateParameter(valid_602536, JString, required = true,
                                 default = nil)
  if valid_602536 != nil:
    section.add "VersionId", valid_602536
  var valid_602537 = path.getOrDefault("DocumentId")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = nil)
  if valid_602537 != nil:
    section.add "DocumentId", valid_602537
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  section = newJObject()
  var valid_602538 = query.getOrDefault("limit")
  valid_602538 = validateParameter(valid_602538, JInt, required = false, default = nil)
  if valid_602538 != nil:
    section.add "limit", valid_602538
  var valid_602539 = query.getOrDefault("marker")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "marker", valid_602539
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
  var valid_602540 = header.getOrDefault("X-Amz-Signature")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Signature", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Content-Sha256", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Date")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Date", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Credential")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Credential", valid_602543
  var valid_602544 = header.getOrDefault("Authentication")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "Authentication", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Security-Token")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Security-Token", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Algorithm")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Algorithm", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-SignedHeaders", valid_602547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602548: Call_DescribeComments_602533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_602548.validator(path, query, header, formData, body)
  let scheme = call_602548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602548.url(scheme.get, call_602548.host, call_602548.base,
                         call_602548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602548, url, valid)

proc call*(call_602549: Call_DescribeComments_602533; VersionId: string;
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
  var path_602550 = newJObject()
  var query_602551 = newJObject()
  add(path_602550, "VersionId", newJString(VersionId))
  add(path_602550, "DocumentId", newJString(DocumentId))
  add(query_602551, "limit", newJInt(limit))
  add(query_602551, "marker", newJString(marker))
  result = call_602549.call(path_602550, query_602551, nil, nil, nil)

var describeComments* = Call_DescribeComments_602533(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_602534, base: "/",
    url: url_DescribeComments_602535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_602552 = ref object of OpenApiRestCall_601389
proc url_DescribeDocumentVersions_602554(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentVersions_602553(path: JsonNode; query: JsonNode;
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
  var valid_602555 = path.getOrDefault("DocumentId")
  valid_602555 = validateParameter(valid_602555, JString, required = true,
                                 default = nil)
  if valid_602555 != nil:
    section.add "DocumentId", valid_602555
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
  var valid_602556 = query.getOrDefault("Marker")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "Marker", valid_602556
  var valid_602557 = query.getOrDefault("limit")
  valid_602557 = validateParameter(valid_602557, JInt, required = false, default = nil)
  if valid_602557 != nil:
    section.add "limit", valid_602557
  var valid_602558 = query.getOrDefault("Limit")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "Limit", valid_602558
  var valid_602559 = query.getOrDefault("include")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "include", valid_602559
  var valid_602560 = query.getOrDefault("fields")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "fields", valid_602560
  var valid_602561 = query.getOrDefault("marker")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "marker", valid_602561
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
  var valid_602562 = header.getOrDefault("X-Amz-Signature")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Signature", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Content-Sha256", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Date")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Date", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
  var valid_602566 = header.getOrDefault("Authentication")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "Authentication", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Security-Token")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Security-Token", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Algorithm")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Algorithm", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-SignedHeaders", valid_602569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602570: Call_DescribeDocumentVersions_602552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_602570.validator(path, query, header, formData, body)
  let scheme = call_602570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602570.url(scheme.get, call_602570.host, call_602570.base,
                         call_602570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602570, url, valid)

proc call*(call_602571: Call_DescribeDocumentVersions_602552; DocumentId: string;
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
  var path_602572 = newJObject()
  var query_602573 = newJObject()
  add(query_602573, "Marker", newJString(Marker))
  add(path_602572, "DocumentId", newJString(DocumentId))
  add(query_602573, "limit", newJInt(limit))
  add(query_602573, "Limit", newJString(Limit))
  add(query_602573, "include", newJString(`include`))
  add(query_602573, "fields", newJString(fields))
  add(query_602573, "marker", newJString(marker))
  result = call_602571.call(path_602572, query_602573, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_602552(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_602553, base: "/",
    url: url_DescribeDocumentVersions_602554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_602574 = ref object of OpenApiRestCall_601389
proc url_DescribeGroups_602576(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGroups_602575(path: JsonNode; query: JsonNode;
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
  var valid_602577 = query.getOrDefault("searchQuery")
  valid_602577 = validateParameter(valid_602577, JString, required = true,
                                 default = nil)
  if valid_602577 != nil:
    section.add "searchQuery", valid_602577
  var valid_602578 = query.getOrDefault("limit")
  valid_602578 = validateParameter(valid_602578, JInt, required = false, default = nil)
  if valid_602578 != nil:
    section.add "limit", valid_602578
  var valid_602579 = query.getOrDefault("organizationId")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "organizationId", valid_602579
  var valid_602580 = query.getOrDefault("marker")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "marker", valid_602580
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
  var valid_602581 = header.getOrDefault("X-Amz-Signature")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Signature", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Content-Sha256", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Date")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Date", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Credential")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Credential", valid_602584
  var valid_602585 = header.getOrDefault("Authentication")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "Authentication", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Security-Token")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Security-Token", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Algorithm")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Algorithm", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-SignedHeaders", valid_602588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602589: Call_DescribeGroups_602574; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_602589.validator(path, query, header, formData, body)
  let scheme = call_602589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602589.url(scheme.get, call_602589.host, call_602589.base,
                         call_602589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602589, url, valid)

proc call*(call_602590: Call_DescribeGroups_602574; searchQuery: string;
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
  var query_602591 = newJObject()
  add(query_602591, "searchQuery", newJString(searchQuery))
  add(query_602591, "limit", newJInt(limit))
  add(query_602591, "organizationId", newJString(organizationId))
  add(query_602591, "marker", newJString(marker))
  result = call_602590.call(nil, query_602591, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_602574(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_602575,
    base: "/", url: url_DescribeGroups_602576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_602592 = ref object of OpenApiRestCall_601389
proc url_DescribeRootFolders_602594(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRootFolders_602593(path: JsonNode; query: JsonNode;
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
  var valid_602595 = query.getOrDefault("limit")
  valid_602595 = validateParameter(valid_602595, JInt, required = false, default = nil)
  if valid_602595 != nil:
    section.add "limit", valid_602595
  var valid_602596 = query.getOrDefault("marker")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "marker", valid_602596
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
  var valid_602597 = header.getOrDefault("X-Amz-Signature")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Signature", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Content-Sha256", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Date")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Date", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Credential")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Credential", valid_602600
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_602601 = header.getOrDefault("Authentication")
  valid_602601 = validateParameter(valid_602601, JString, required = true,
                                 default = nil)
  if valid_602601 != nil:
    section.add "Authentication", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Security-Token")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Security-Token", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Algorithm")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Algorithm", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-SignedHeaders", valid_602604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602605: Call_DescribeRootFolders_602592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_602605.validator(path, query, header, formData, body)
  let scheme = call_602605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602605.url(scheme.get, call_602605.host, call_602605.base,
                         call_602605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602605, url, valid)

proc call*(call_602606: Call_DescribeRootFolders_602592; limit: int = 0;
          marker: string = ""): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var query_602607 = newJObject()
  add(query_602607, "limit", newJInt(limit))
  add(query_602607, "marker", newJString(marker))
  result = call_602606.call(nil, query_602607, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_602592(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_602593, base: "/",
    url: url_DescribeRootFolders_602594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_602608 = ref object of OpenApiRestCall_601389
proc url_GetCurrentUser_602610(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentUser_602609(path: JsonNode; query: JsonNode;
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
  var valid_602611 = header.getOrDefault("X-Amz-Signature")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Signature", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Content-Sha256", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Date")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Date", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Credential")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Credential", valid_602614
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_602615 = header.getOrDefault("Authentication")
  valid_602615 = validateParameter(valid_602615, JString, required = true,
                                 default = nil)
  if valid_602615 != nil:
    section.add "Authentication", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Security-Token")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Security-Token", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-Algorithm")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Algorithm", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-SignedHeaders", valid_602618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602619: Call_GetCurrentUser_602608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_602619.validator(path, query, header, formData, body)
  let scheme = call_602619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602619.url(scheme.get, call_602619.host, call_602619.base,
                         call_602619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602619, url, valid)

proc call*(call_602620: Call_GetCurrentUser_602608): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_602620.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_602608(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_602609,
    base: "/", url: url_GetCurrentUser_602610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_602621 = ref object of OpenApiRestCall_601389
proc url_GetDocumentPath_602623(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentPath_602622(path: JsonNode; query: JsonNode;
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
  var valid_602624 = path.getOrDefault("DocumentId")
  valid_602624 = validateParameter(valid_602624, JString, required = true,
                                 default = nil)
  if valid_602624 != nil:
    section.add "DocumentId", valid_602624
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_602625 = query.getOrDefault("limit")
  valid_602625 = validateParameter(valid_602625, JInt, required = false, default = nil)
  if valid_602625 != nil:
    section.add "limit", valid_602625
  var valid_602626 = query.getOrDefault("fields")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "fields", valid_602626
  var valid_602627 = query.getOrDefault("marker")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "marker", valid_602627
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
  var valid_602628 = header.getOrDefault("X-Amz-Signature")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Signature", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Content-Sha256", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Date")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Date", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Credential")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Credential", valid_602631
  var valid_602632 = header.getOrDefault("Authentication")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "Authentication", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Security-Token")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Security-Token", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Algorithm")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Algorithm", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-SignedHeaders", valid_602635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602636: Call_GetDocumentPath_602621; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_602636.validator(path, query, header, formData, body)
  let scheme = call_602636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602636.url(scheme.get, call_602636.host, call_602636.base,
                         call_602636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602636, url, valid)

proc call*(call_602637: Call_GetDocumentPath_602621; DocumentId: string;
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
  var path_602638 = newJObject()
  var query_602639 = newJObject()
  add(path_602638, "DocumentId", newJString(DocumentId))
  add(query_602639, "limit", newJInt(limit))
  add(query_602639, "fields", newJString(fields))
  add(query_602639, "marker", newJString(marker))
  result = call_602637.call(path_602638, query_602639, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_602621(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_602622, base: "/", url: url_GetDocumentPath_602623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_602640 = ref object of OpenApiRestCall_601389
proc url_GetFolderPath_602642(protocol: Scheme; host: string; base: string;
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

proc validate_GetFolderPath_602641(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602643 = path.getOrDefault("FolderId")
  valid_602643 = validateParameter(valid_602643, JString, required = true,
                                 default = nil)
  if valid_602643 != nil:
    section.add "FolderId", valid_602643
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_602644 = query.getOrDefault("limit")
  valid_602644 = validateParameter(valid_602644, JInt, required = false, default = nil)
  if valid_602644 != nil:
    section.add "limit", valid_602644
  var valid_602645 = query.getOrDefault("fields")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "fields", valid_602645
  var valid_602646 = query.getOrDefault("marker")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "marker", valid_602646
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
  var valid_602647 = header.getOrDefault("X-Amz-Signature")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Signature", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Content-Sha256", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Date")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Date", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Credential")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Credential", valid_602650
  var valid_602651 = header.getOrDefault("Authentication")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "Authentication", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Security-Token")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Security-Token", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Algorithm")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Algorithm", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-SignedHeaders", valid_602654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602655: Call_GetFolderPath_602640; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_602655.validator(path, query, header, formData, body)
  let scheme = call_602655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602655.url(scheme.get, call_602655.host, call_602655.base,
                         call_602655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602655, url, valid)

proc call*(call_602656: Call_GetFolderPath_602640; FolderId: string; limit: int = 0;
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
  var path_602657 = newJObject()
  var query_602658 = newJObject()
  add(query_602658, "limit", newJInt(limit))
  add(path_602657, "FolderId", newJString(FolderId))
  add(query_602658, "fields", newJString(fields))
  add(query_602658, "marker", newJString(marker))
  result = call_602656.call(path_602657, query_602658, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_602640(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_602641,
    base: "/", url: url_GetFolderPath_602642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_602659 = ref object of OpenApiRestCall_601389
proc url_GetResources_602661(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_602660(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602662 = query.getOrDefault("userId")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "userId", valid_602662
  var valid_602663 = query.getOrDefault("limit")
  valid_602663 = validateParameter(valid_602663, JInt, required = false, default = nil)
  if valid_602663 != nil:
    section.add "limit", valid_602663
  var valid_602664 = query.getOrDefault("collectionType")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_602664 != nil:
    section.add "collectionType", valid_602664
  var valid_602665 = query.getOrDefault("marker")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "marker", valid_602665
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
  var valid_602666 = header.getOrDefault("X-Amz-Signature")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Signature", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Content-Sha256", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Date")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Date", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-Credential")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Credential", valid_602669
  var valid_602670 = header.getOrDefault("Authentication")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "Authentication", valid_602670
  var valid_602671 = header.getOrDefault("X-Amz-Security-Token")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Security-Token", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Algorithm")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Algorithm", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-SignedHeaders", valid_602673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602674: Call_GetResources_602659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_602674.validator(path, query, header, formData, body)
  let scheme = call_602674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602674.url(scheme.get, call_602674.host, call_602674.base,
                         call_602674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602674, url, valid)

proc call*(call_602675: Call_GetResources_602659; userId: string = ""; limit: int = 0;
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
  var query_602676 = newJObject()
  add(query_602676, "userId", newJString(userId))
  add(query_602676, "limit", newJInt(limit))
  add(query_602676, "collectionType", newJString(collectionType))
  add(query_602676, "marker", newJString(marker))
  result = call_602675.call(nil, query_602676, nil, nil, nil)

var getResources* = Call_GetResources_602659(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_602660, base: "/",
    url: url_GetResources_602661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_602677 = ref object of OpenApiRestCall_601389
proc url_InitiateDocumentVersionUpload_602679(protocol: Scheme; host: string;
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

proc validate_InitiateDocumentVersionUpload_602678(path: JsonNode; query: JsonNode;
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
  var valid_602680 = header.getOrDefault("X-Amz-Signature")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Signature", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Content-Sha256", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Date")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Date", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Credential")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Credential", valid_602683
  var valid_602684 = header.getOrDefault("Authentication")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "Authentication", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Security-Token")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Security-Token", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Algorithm")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Algorithm", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-SignedHeaders", valid_602687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602689: Call_InitiateDocumentVersionUpload_602677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_602689.validator(path, query, header, formData, body)
  let scheme = call_602689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602689.url(scheme.get, call_602689.host, call_602689.base,
                         call_602689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602689, url, valid)

proc call*(call_602690: Call_InitiateDocumentVersionUpload_602677; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_602691 = newJObject()
  if body != nil:
    body_602691 = body
  result = call_602690.call(nil, nil, nil, nil, body_602691)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_602677(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_602678, base: "/",
    url: url_InitiateDocumentVersionUpload_602679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_602692 = ref object of OpenApiRestCall_601389
proc url_RemoveResourcePermission_602694(protocol: Scheme; host: string;
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

proc validate_RemoveResourcePermission_602693(path: JsonNode; query: JsonNode;
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
  var valid_602695 = path.getOrDefault("ResourceId")
  valid_602695 = validateParameter(valid_602695, JString, required = true,
                                 default = nil)
  if valid_602695 != nil:
    section.add "ResourceId", valid_602695
  var valid_602696 = path.getOrDefault("PrincipalId")
  valid_602696 = validateParameter(valid_602696, JString, required = true,
                                 default = nil)
  if valid_602696 != nil:
    section.add "PrincipalId", valid_602696
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_602697 = query.getOrDefault("type")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = newJString("USER"))
  if valid_602697 != nil:
    section.add "type", valid_602697
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
  var valid_602698 = header.getOrDefault("X-Amz-Signature")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Signature", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Content-Sha256", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Date")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Date", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Credential")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Credential", valid_602701
  var valid_602702 = header.getOrDefault("Authentication")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "Authentication", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-Security-Token")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-Security-Token", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-Algorithm")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Algorithm", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-SignedHeaders", valid_602705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602706: Call_RemoveResourcePermission_602692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_602706.validator(path, query, header, formData, body)
  let scheme = call_602706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602706.url(scheme.get, call_602706.host, call_602706.base,
                         call_602706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602706, url, valid)

proc call*(call_602707: Call_RemoveResourcePermission_602692; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_602708 = newJObject()
  var query_602709 = newJObject()
  add(path_602708, "ResourceId", newJString(ResourceId))
  add(query_602709, "type", newJString(`type`))
  add(path_602708, "PrincipalId", newJString(PrincipalId))
  result = call_602707.call(path_602708, query_602709, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_602692(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_602693, base: "/",
    url: url_RemoveResourcePermission_602694, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
