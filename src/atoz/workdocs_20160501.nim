
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_GetDocumentVersion_605927 = ref object of OpenApiRestCall_605589
proc url_GetDocumentVersion_605929(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentVersion_605928(path: JsonNode; query: JsonNode;
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
  var valid_606055 = path.getOrDefault("VersionId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "VersionId", valid_606055
  var valid_606056 = path.getOrDefault("DocumentId")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = nil)
  if valid_606056 != nil:
    section.add "DocumentId", valid_606056
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to TRUE to include custom metadata in the response.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  section = newJObject()
  var valid_606057 = query.getOrDefault("includeCustomMetadata")
  valid_606057 = validateParameter(valid_606057, JBool, required = false, default = nil)
  if valid_606057 != nil:
    section.add "includeCustomMetadata", valid_606057
  var valid_606058 = query.getOrDefault("fields")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "fields", valid_606058
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
  var valid_606059 = header.getOrDefault("X-Amz-Signature")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Signature", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Content-Sha256", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Date")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Date", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Credential")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Credential", valid_606062
  var valid_606063 = header.getOrDefault("Authentication")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "Authentication", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-Security-Token")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-Security-Token", valid_606064
  var valid_606065 = header.getOrDefault("X-Amz-Algorithm")
  valid_606065 = validateParameter(valid_606065, JString, required = false,
                                 default = nil)
  if valid_606065 != nil:
    section.add "X-Amz-Algorithm", valid_606065
  var valid_606066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606066 = validateParameter(valid_606066, JString, required = false,
                                 default = nil)
  if valid_606066 != nil:
    section.add "X-Amz-SignedHeaders", valid_606066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606089: Call_GetDocumentVersion_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves version metadata for the specified document.
  ## 
  let valid = call_606089.validator(path, query, header, formData, body)
  let scheme = call_606089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606089.url(scheme.get, call_606089.host, call_606089.base,
                         call_606089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606089, url, valid)

proc call*(call_606160: Call_GetDocumentVersion_605927; VersionId: string;
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
  var path_606161 = newJObject()
  var query_606163 = newJObject()
  add(path_606161, "VersionId", newJString(VersionId))
  add(path_606161, "DocumentId", newJString(DocumentId))
  add(query_606163, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(query_606163, "fields", newJString(fields))
  result = call_606160.call(path_606161, query_606163, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_605927(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_605928, base: "/",
    url: url_GetDocumentVersion_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_606218 = ref object of OpenApiRestCall_605589
proc url_UpdateDocumentVersion_606220(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocumentVersion_606219(path: JsonNode; query: JsonNode;
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
  var valid_606221 = path.getOrDefault("VersionId")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "VersionId", valid_606221
  var valid_606222 = path.getOrDefault("DocumentId")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = nil)
  if valid_606222 != nil:
    section.add "DocumentId", valid_606222
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
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("Authentication")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "Authentication", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Security-Token")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Security-Token", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Algorithm")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Algorithm", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-SignedHeaders", valid_606230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606232: Call_UpdateDocumentVersion_606218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ## 
  let valid = call_606232.validator(path, query, header, formData, body)
  let scheme = call_606232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606232.url(scheme.get, call_606232.host, call_606232.base,
                         call_606232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606232, url, valid)

proc call*(call_606233: Call_UpdateDocumentVersion_606218; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   VersionId: string (required)
  ##            : The version ID of the document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_606234 = newJObject()
  var body_606235 = newJObject()
  add(path_606234, "VersionId", newJString(VersionId))
  add(path_606234, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_606235 = body
  result = call_606233.call(path_606234, nil, nil, nil, body_606235)

var updateDocumentVersion* = Call_UpdateDocumentVersion_606218(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_606219, base: "/",
    url: url_UpdateDocumentVersion_606220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_606202 = ref object of OpenApiRestCall_605589
proc url_AbortDocumentVersionUpload_606204(protocol: Scheme; host: string;
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

proc validate_AbortDocumentVersionUpload_606203(path: JsonNode; query: JsonNode;
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
  var valid_606205 = path.getOrDefault("VersionId")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "VersionId", valid_606205
  var valid_606206 = path.getOrDefault("DocumentId")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = nil)
  if valid_606206 != nil:
    section.add "DocumentId", valid_606206
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
  var valid_606207 = header.getOrDefault("X-Amz-Signature")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Signature", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Content-Sha256", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Date")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Date", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Credential")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Credential", valid_606210
  var valid_606211 = header.getOrDefault("Authentication")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "Authentication", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Security-Token")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Security-Token", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Algorithm")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Algorithm", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-SignedHeaders", valid_606214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606215: Call_AbortDocumentVersionUpload_606202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ## 
  let valid = call_606215.validator(path, query, header, formData, body)
  let scheme = call_606215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606215.url(scheme.get, call_606215.host, call_606215.base,
                         call_606215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606215, url, valid)

proc call*(call_606216: Call_AbortDocumentVersionUpload_606202; VersionId: string;
          DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   VersionId: string (required)
  ##            : The ID of the version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_606217 = newJObject()
  add(path_606217, "VersionId", newJString(VersionId))
  add(path_606217, "DocumentId", newJString(DocumentId))
  result = call_606216.call(path_606217, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_606202(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_606203, base: "/",
    url: url_AbortDocumentVersionUpload_606204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_606236 = ref object of OpenApiRestCall_605589
proc url_ActivateUser_606238(protocol: Scheme; host: string; base: string;
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

proc validate_ActivateUser_606237(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606239 = path.getOrDefault("UserId")
  valid_606239 = validateParameter(valid_606239, JString, required = true,
                                 default = nil)
  if valid_606239 != nil:
    section.add "UserId", valid_606239
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
  var valid_606240 = header.getOrDefault("X-Amz-Signature")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Signature", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Content-Sha256", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Date")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Date", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Credential")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Credential", valid_606243
  var valid_606244 = header.getOrDefault("Authentication")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "Authentication", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Security-Token")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Security-Token", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Algorithm")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Algorithm", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-SignedHeaders", valid_606247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606248: Call_ActivateUser_606236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ## 
  let valid = call_606248.validator(path, query, header, formData, body)
  let scheme = call_606248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606248.url(scheme.get, call_606248.host, call_606248.base,
                         call_606248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606248, url, valid)

proc call*(call_606249: Call_ActivateUser_606236; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_606250 = newJObject()
  add(path_606250, "UserId", newJString(UserId))
  result = call_606249.call(path_606250, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_606236(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation", validator: validate_ActivateUser_606237,
    base: "/", url: url_ActivateUser_606238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_606251 = ref object of OpenApiRestCall_605589
proc url_DeactivateUser_606253(protocol: Scheme; host: string; base: string;
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

proc validate_DeactivateUser_606252(path: JsonNode; query: JsonNode;
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
  var valid_606254 = path.getOrDefault("UserId")
  valid_606254 = validateParameter(valid_606254, JString, required = true,
                                 default = nil)
  if valid_606254 != nil:
    section.add "UserId", valid_606254
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
  var valid_606255 = header.getOrDefault("X-Amz-Signature")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Signature", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Content-Sha256", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Date")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Date", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Credential")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Credential", valid_606258
  var valid_606259 = header.getOrDefault("Authentication")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "Authentication", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Security-Token")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Security-Token", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Algorithm")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Algorithm", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-SignedHeaders", valid_606262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606263: Call_DeactivateUser_606251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ## 
  let valid = call_606263.validator(path, query, header, formData, body)
  let scheme = call_606263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606263.url(scheme.get, call_606263.host, call_606263.base,
                         call_606263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606263, url, valid)

proc call*(call_606264: Call_DeactivateUser_606251; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_606265 = newJObject()
  add(path_606265, "UserId", newJString(UserId))
  result = call_606264.call(path_606265, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_606251(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_606252, base: "/", url: url_DeactivateUser_606253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_606285 = ref object of OpenApiRestCall_605589
proc url_AddResourcePermissions_606287(protocol: Scheme; host: string; base: string;
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

proc validate_AddResourcePermissions_606286(path: JsonNode; query: JsonNode;
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
  var valid_606288 = path.getOrDefault("ResourceId")
  valid_606288 = validateParameter(valid_606288, JString, required = true,
                                 default = nil)
  if valid_606288 != nil:
    section.add "ResourceId", valid_606288
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
  var valid_606289 = header.getOrDefault("X-Amz-Signature")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Signature", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Content-Sha256", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Date")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Date", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Credential")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Credential", valid_606292
  var valid_606293 = header.getOrDefault("Authentication")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "Authentication", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_AddResourcePermissions_606285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_AddResourcePermissions_606285; ResourceId: string;
          body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_606300 = newJObject()
  var body_606301 = newJObject()
  add(path_606300, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_606301 = body
  result = call_606299.call(path_606300, nil, nil, nil, body_606301)

var addResourcePermissions* = Call_AddResourcePermissions_606285(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_606286, base: "/",
    url: url_AddResourcePermissions_606287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_606266 = ref object of OpenApiRestCall_605589
proc url_DescribeResourcePermissions_606268(protocol: Scheme; host: string;
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

proc validate_DescribeResourcePermissions_606267(path: JsonNode; query: JsonNode;
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
  var valid_606269 = path.getOrDefault("ResourceId")
  valid_606269 = validateParameter(valid_606269, JString, required = true,
                                 default = nil)
  if valid_606269 != nil:
    section.add "ResourceId", valid_606269
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   principalId: JString
  ##              : The ID of the principal to filter permissions by.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call)
  section = newJObject()
  var valid_606270 = query.getOrDefault("limit")
  valid_606270 = validateParameter(valid_606270, JInt, required = false, default = nil)
  if valid_606270 != nil:
    section.add "limit", valid_606270
  var valid_606271 = query.getOrDefault("principalId")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "principalId", valid_606271
  var valid_606272 = query.getOrDefault("marker")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "marker", valid_606272
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
  var valid_606273 = header.getOrDefault("X-Amz-Signature")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Signature", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Content-Sha256", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Date")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Date", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Credential")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Credential", valid_606276
  var valid_606277 = header.getOrDefault("Authentication")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "Authentication", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Security-Token")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Security-Token", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Algorithm")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Algorithm", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-SignedHeaders", valid_606280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606281: Call_DescribeResourcePermissions_606266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the permissions of a specified resource.
  ## 
  let valid = call_606281.validator(path, query, header, formData, body)
  let scheme = call_606281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606281.url(scheme.get, call_606281.host, call_606281.base,
                         call_606281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606281, url, valid)

proc call*(call_606282: Call_DescribeResourcePermissions_606266;
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
  var path_606283 = newJObject()
  var query_606284 = newJObject()
  add(query_606284, "limit", newJInt(limit))
  add(path_606283, "ResourceId", newJString(ResourceId))
  add(query_606284, "principalId", newJString(principalId))
  add(query_606284, "marker", newJString(marker))
  result = call_606282.call(path_606283, query_606284, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_606266(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_606267, base: "/",
    url: url_DescribeResourcePermissions_606268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_606302 = ref object of OpenApiRestCall_605589
proc url_RemoveAllResourcePermissions_606304(protocol: Scheme; host: string;
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

proc validate_RemoveAllResourcePermissions_606303(path: JsonNode; query: JsonNode;
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
  var valid_606305 = path.getOrDefault("ResourceId")
  valid_606305 = validateParameter(valid_606305, JString, required = true,
                                 default = nil)
  if valid_606305 != nil:
    section.add "ResourceId", valid_606305
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
  var valid_606306 = header.getOrDefault("X-Amz-Signature")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Signature", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Content-Sha256", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Date")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Date", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Credential")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Credential", valid_606309
  var valid_606310 = header.getOrDefault("Authentication")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "Authentication", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Security-Token")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Security-Token", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Algorithm")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Algorithm", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-SignedHeaders", valid_606313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606314: Call_RemoveAllResourcePermissions_606302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes all the permissions from the specified resource.
  ## 
  let valid = call_606314.validator(path, query, header, formData, body)
  let scheme = call_606314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606314.url(scheme.get, call_606314.host, call_606314.base,
                         call_606314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606314, url, valid)

proc call*(call_606315: Call_RemoveAllResourcePermissions_606302;
          ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_606316 = newJObject()
  add(path_606316, "ResourceId", newJString(ResourceId))
  result = call_606315.call(path_606316, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_606302(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_606303, base: "/",
    url: url_RemoveAllResourcePermissions_606304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_606317 = ref object of OpenApiRestCall_605589
proc url_CreateComment_606319(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComment_606318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606320 = path.getOrDefault("VersionId")
  valid_606320 = validateParameter(valid_606320, JString, required = true,
                                 default = nil)
  if valid_606320 != nil:
    section.add "VersionId", valid_606320
  var valid_606321 = path.getOrDefault("DocumentId")
  valid_606321 = validateParameter(valid_606321, JString, required = true,
                                 default = nil)
  if valid_606321 != nil:
    section.add "DocumentId", valid_606321
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
  var valid_606322 = header.getOrDefault("X-Amz-Signature")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Signature", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Content-Sha256", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Date")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Date", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Credential")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Credential", valid_606325
  var valid_606326 = header.getOrDefault("Authentication")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "Authentication", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Security-Token")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Security-Token", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Algorithm")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Algorithm", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-SignedHeaders", valid_606329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606331: Call_CreateComment_606317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new comment to the specified document version.
  ## 
  let valid = call_606331.validator(path, query, header, formData, body)
  let scheme = call_606331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606331.url(scheme.get, call_606331.host, call_606331.base,
                         call_606331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606331, url, valid)

proc call*(call_606332: Call_CreateComment_606317; VersionId: string;
          DocumentId: string; body: JsonNode): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_606333 = newJObject()
  var body_606334 = newJObject()
  add(path_606333, "VersionId", newJString(VersionId))
  add(path_606333, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_606334 = body
  result = call_606332.call(path_606333, nil, nil, nil, body_606334)

var createComment* = Call_CreateComment_606317(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_606318, base: "/", url: url_CreateComment_606319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_606335 = ref object of OpenApiRestCall_605589
proc url_CreateCustomMetadata_606337(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCustomMetadata_606336(path: JsonNode; query: JsonNode;
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
  var valid_606338 = path.getOrDefault("ResourceId")
  valid_606338 = validateParameter(valid_606338, JString, required = true,
                                 default = nil)
  if valid_606338 != nil:
    section.add "ResourceId", valid_606338
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_606339 = query.getOrDefault("versionid")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "versionid", valid_606339
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
  var valid_606340 = header.getOrDefault("X-Amz-Signature")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Signature", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Content-Sha256", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Date")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Date", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Credential")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Credential", valid_606343
  var valid_606344 = header.getOrDefault("Authentication")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "Authentication", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Security-Token")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Security-Token", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Algorithm")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Algorithm", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-SignedHeaders", valid_606347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606349: Call_CreateCustomMetadata_606335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ## 
  let valid = call_606349.validator(path, query, header, formData, body)
  let scheme = call_606349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606349.url(scheme.get, call_606349.host, call_606349.base,
                         call_606349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606349, url, valid)

proc call*(call_606350: Call_CreateCustomMetadata_606335; ResourceId: string;
          body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   versionid: string
  ##            : The ID of the version, if the custom metadata is being added to a document version.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_606351 = newJObject()
  var query_606352 = newJObject()
  var body_606353 = newJObject()
  add(query_606352, "versionid", newJString(versionid))
  add(path_606351, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_606353 = body
  result = call_606350.call(path_606351, query_606352, nil, nil, body_606353)

var createCustomMetadata* = Call_CreateCustomMetadata_606335(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_606336, base: "/",
    url: url_CreateCustomMetadata_606337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_606354 = ref object of OpenApiRestCall_605589
proc url_DeleteCustomMetadata_606356(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCustomMetadata_606355(path: JsonNode; query: JsonNode;
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
  var valid_606357 = path.getOrDefault("ResourceId")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = nil)
  if valid_606357 != nil:
    section.add "ResourceId", valid_606357
  result.add "path", section
  ## parameters in `query` object:
  ##   deleteAll: JBool
  ##            : Flag to indicate removal of all custom metadata properties from the specified resource.
  ##   keys: JArray
  ##       : List of properties to remove.
  ##   versionId: JString
  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  section = newJObject()
  var valid_606358 = query.getOrDefault("deleteAll")
  valid_606358 = validateParameter(valid_606358, JBool, required = false, default = nil)
  if valid_606358 != nil:
    section.add "deleteAll", valid_606358
  var valid_606359 = query.getOrDefault("keys")
  valid_606359 = validateParameter(valid_606359, JArray, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "keys", valid_606359
  var valid_606360 = query.getOrDefault("versionId")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "versionId", valid_606360
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
  var valid_606361 = header.getOrDefault("X-Amz-Signature")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Signature", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Content-Sha256", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Date")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Date", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Credential")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Credential", valid_606364
  var valid_606365 = header.getOrDefault("Authentication")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "Authentication", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Security-Token")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Security-Token", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Algorithm")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Algorithm", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-SignedHeaders", valid_606368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606369: Call_DeleteCustomMetadata_606354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes custom metadata from the specified resource.
  ## 
  let valid = call_606369.validator(path, query, header, formData, body)
  let scheme = call_606369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606369.url(scheme.get, call_606369.host, call_606369.base,
                         call_606369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606369, url, valid)

proc call*(call_606370: Call_DeleteCustomMetadata_606354; ResourceId: string;
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
  var path_606371 = newJObject()
  var query_606372 = newJObject()
  add(query_606372, "deleteAll", newJBool(deleteAll))
  add(path_606371, "ResourceId", newJString(ResourceId))
  if keys != nil:
    query_606372.add "keys", keys
  add(query_606372, "versionId", newJString(versionId))
  result = call_606370.call(path_606371, query_606372, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_606354(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_606355, base: "/",
    url: url_DeleteCustomMetadata_606356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_606373 = ref object of OpenApiRestCall_605589
proc url_CreateFolder_606375(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFolder_606374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606376 = header.getOrDefault("X-Amz-Signature")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Signature", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Content-Sha256", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Date")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Date", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Credential")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Credential", valid_606379
  var valid_606380 = header.getOrDefault("Authentication")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "Authentication", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Security-Token")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Security-Token", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Algorithm")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Algorithm", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-SignedHeaders", valid_606383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606385: Call_CreateFolder_606373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a folder with the specified name and parent folder.
  ## 
  let valid = call_606385.validator(path, query, header, formData, body)
  let scheme = call_606385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606385.url(scheme.get, call_606385.host, call_606385.base,
                         call_606385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606385, url, valid)

proc call*(call_606386: Call_CreateFolder_606373; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_606387 = newJObject()
  if body != nil:
    body_606387 = body
  result = call_606386.call(nil, nil, nil, nil, body_606387)

var createFolder* = Call_CreateFolder_606373(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_606374, base: "/",
    url: url_CreateFolder_606375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_606388 = ref object of OpenApiRestCall_605589
proc url_CreateLabels_606390(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLabels_606389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606391 = path.getOrDefault("ResourceId")
  valid_606391 = validateParameter(valid_606391, JString, required = true,
                                 default = nil)
  if valid_606391 != nil:
    section.add "ResourceId", valid_606391
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
  var valid_606392 = header.getOrDefault("X-Amz-Signature")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Signature", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Content-Sha256", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Date")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Date", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Credential")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Credential", valid_606395
  var valid_606396 = header.getOrDefault("Authentication")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "Authentication", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Security-Token")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Security-Token", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Algorithm")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Algorithm", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-SignedHeaders", valid_606399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606401: Call_CreateLabels_606388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
  ## 
  let valid = call_606401.validator(path, query, header, formData, body)
  let scheme = call_606401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606401.url(scheme.get, call_606401.host, call_606401.base,
                         call_606401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606401, url, valid)

proc call*(call_606402: Call_CreateLabels_606388; ResourceId: string; body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   body: JObject (required)
  var path_606403 = newJObject()
  var body_606404 = newJObject()
  add(path_606403, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_606404 = body
  result = call_606402.call(path_606403, nil, nil, nil, body_606404)

var createLabels* = Call_CreateLabels_606388(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_606389, base: "/", url: url_CreateLabels_606390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_606405 = ref object of OpenApiRestCall_605589
proc url_DeleteLabels_606407(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLabels_606406(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606408 = path.getOrDefault("ResourceId")
  valid_606408 = validateParameter(valid_606408, JString, required = true,
                                 default = nil)
  if valid_606408 != nil:
    section.add "ResourceId", valid_606408
  result.add "path", section
  ## parameters in `query` object:
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: JBool
  ##            : Flag to request removal of all labels from the specified resource.
  section = newJObject()
  var valid_606409 = query.getOrDefault("labels")
  valid_606409 = validateParameter(valid_606409, JArray, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "labels", valid_606409
  var valid_606410 = query.getOrDefault("deleteAll")
  valid_606410 = validateParameter(valid_606410, JBool, required = false, default = nil)
  if valid_606410 != nil:
    section.add "deleteAll", valid_606410
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
  var valid_606411 = header.getOrDefault("X-Amz-Signature")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Signature", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Content-Sha256", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Date")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Date", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Credential")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Credential", valid_606414
  var valid_606415 = header.getOrDefault("Authentication")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "Authentication", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Security-Token")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Security-Token", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Algorithm")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Algorithm", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-SignedHeaders", valid_606418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606419: Call_DeleteLabels_606405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified list of labels from a resource.
  ## 
  let valid = call_606419.validator(path, query, header, formData, body)
  let scheme = call_606419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606419.url(scheme.get, call_606419.host, call_606419.base,
                         call_606419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606419, url, valid)

proc call*(call_606420: Call_DeleteLabels_606405; ResourceId: string;
          labels: JsonNode = nil; deleteAll: bool = false): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   labels: JArray
  ##         : List of labels to delete from the resource.
  ##   deleteAll: bool
  ##            : Flag to request removal of all labels from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  var path_606421 = newJObject()
  var query_606422 = newJObject()
  if labels != nil:
    query_606422.add "labels", labels
  add(query_606422, "deleteAll", newJBool(deleteAll))
  add(path_606421, "ResourceId", newJString(ResourceId))
  result = call_606420.call(path_606421, query_606422, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_606405(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_606406, base: "/", url: url_DeleteLabels_606407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_606440 = ref object of OpenApiRestCall_605589
proc url_CreateNotificationSubscription_606442(protocol: Scheme; host: string;
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

proc validate_CreateNotificationSubscription_606441(path: JsonNode;
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
  var valid_606443 = path.getOrDefault("OrganizationId")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "OrganizationId", valid_606443
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
  var valid_606444 = header.getOrDefault("X-Amz-Signature")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Signature", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Content-Sha256", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Date")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Date", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Credential")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Credential", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Security-Token")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Security-Token", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Algorithm")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Algorithm", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-SignedHeaders", valid_606450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_CreateNotificationSubscription_606440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_CreateNotificationSubscription_606440;
          OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   body: JObject (required)
  var path_606454 = newJObject()
  var body_606455 = newJObject()
  add(path_606454, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_606455 = body
  result = call_606453.call(path_606454, nil, nil, nil, body_606455)

var createNotificationSubscription* = Call_CreateNotificationSubscription_606440(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_606441, base: "/",
    url: url_CreateNotificationSubscription_606442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_606423 = ref object of OpenApiRestCall_605589
proc url_DescribeNotificationSubscriptions_606425(protocol: Scheme; host: string;
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

proc validate_DescribeNotificationSubscriptions_606424(path: JsonNode;
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
  var valid_606426 = path.getOrDefault("OrganizationId")
  valid_606426 = validateParameter(valid_606426, JString, required = true,
                                 default = nil)
  if valid_606426 != nil:
    section.add "OrganizationId", valid_606426
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return with this call.
  ##   marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  section = newJObject()
  var valid_606427 = query.getOrDefault("limit")
  valid_606427 = validateParameter(valid_606427, JInt, required = false, default = nil)
  if valid_606427 != nil:
    section.add "limit", valid_606427
  var valid_606428 = query.getOrDefault("marker")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "marker", valid_606428
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
  var valid_606429 = header.getOrDefault("X-Amz-Signature")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Signature", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Content-Sha256", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Date")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Date", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Credential")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Credential", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Security-Token")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Security-Token", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Algorithm")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Algorithm", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-SignedHeaders", valid_606435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606436: Call_DescribeNotificationSubscriptions_606423;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the specified notification subscriptions.
  ## 
  let valid = call_606436.validator(path, query, header, formData, body)
  let scheme = call_606436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606436.url(scheme.get, call_606436.host, call_606436.base,
                         call_606436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606436, url, valid)

proc call*(call_606437: Call_DescribeNotificationSubscriptions_606423;
          OrganizationId: string; limit: int = 0; marker: string = ""): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  ##   limit: int
  ##        : The maximum number of items to return with this call.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var path_606438 = newJObject()
  var query_606439 = newJObject()
  add(path_606438, "OrganizationId", newJString(OrganizationId))
  add(query_606439, "limit", newJInt(limit))
  add(query_606439, "marker", newJString(marker))
  result = call_606437.call(path_606438, query_606439, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_606423(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_606424, base: "/",
    url: url_DescribeNotificationSubscriptions_606425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_606494 = ref object of OpenApiRestCall_605589
proc url_CreateUser_606496(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_606495(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606497 = header.getOrDefault("X-Amz-Signature")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Signature", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Content-Sha256", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Date")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Date", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Credential")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Credential", valid_606500
  var valid_606501 = header.getOrDefault("Authentication")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "Authentication", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Security-Token")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Security-Token", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Algorithm")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Algorithm", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-SignedHeaders", valid_606504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606506: Call_CreateUser_606494; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ## 
  let valid = call_606506.validator(path, query, header, formData, body)
  let scheme = call_606506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606506.url(scheme.get, call_606506.host, call_606506.base,
                         call_606506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606506, url, valid)

proc call*(call_606507: Call_CreateUser_606494; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   body: JObject (required)
  var body_606508 = newJObject()
  if body != nil:
    body_606508 = body
  result = call_606507.call(nil, nil, nil, nil, body_606508)

var createUser* = Call_CreateUser_606494(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users",
                                      validator: validate_CreateUser_606495,
                                      base: "/", url: url_CreateUser_606496,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_606456 = ref object of OpenApiRestCall_605589
proc url_DescribeUsers_606458(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUsers_606457(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606472 = query.getOrDefault("sort")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = newJString("USER_NAME"))
  if valid_606472 != nil:
    section.add "sort", valid_606472
  var valid_606473 = query.getOrDefault("Marker")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "Marker", valid_606473
  var valid_606474 = query.getOrDefault("order")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_606474 != nil:
    section.add "order", valid_606474
  var valid_606475 = query.getOrDefault("limit")
  valid_606475 = validateParameter(valid_606475, JInt, required = false, default = nil)
  if valid_606475 != nil:
    section.add "limit", valid_606475
  var valid_606476 = query.getOrDefault("Limit")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "Limit", valid_606476
  var valid_606477 = query.getOrDefault("userIds")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "userIds", valid_606477
  var valid_606478 = query.getOrDefault("include")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = newJString("ALL"))
  if valid_606478 != nil:
    section.add "include", valid_606478
  var valid_606479 = query.getOrDefault("query")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "query", valid_606479
  var valid_606480 = query.getOrDefault("organizationId")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "organizationId", valid_606480
  var valid_606481 = query.getOrDefault("fields")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "fields", valid_606481
  var valid_606482 = query.getOrDefault("marker")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "marker", valid_606482
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
  var valid_606483 = header.getOrDefault("X-Amz-Signature")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Signature", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Content-Sha256", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Date")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Date", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Credential")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Credential", valid_606486
  var valid_606487 = header.getOrDefault("Authentication")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "Authentication", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Security-Token")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Security-Token", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Algorithm")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Algorithm", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-SignedHeaders", valid_606490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606491: Call_DescribeUsers_606456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ## 
  let valid = call_606491.validator(path, query, header, formData, body)
  let scheme = call_606491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606491.url(scheme.get, call_606491.host, call_606491.base,
                         call_606491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606491, url, valid)

proc call*(call_606492: Call_DescribeUsers_606456; sort: string = "USER_NAME";
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
  var query_606493 = newJObject()
  add(query_606493, "sort", newJString(sort))
  add(query_606493, "Marker", newJString(Marker))
  add(query_606493, "order", newJString(order))
  add(query_606493, "limit", newJInt(limit))
  add(query_606493, "Limit", newJString(Limit))
  add(query_606493, "userIds", newJString(userIds))
  add(query_606493, "include", newJString(`include`))
  add(query_606493, "query", newJString(query))
  add(query_606493, "organizationId", newJString(organizationId))
  add(query_606493, "fields", newJString(fields))
  add(query_606493, "marker", newJString(marker))
  result = call_606492.call(nil, query_606493, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_606456(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_606457, base: "/",
    url: url_DescribeUsers_606458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_606509 = ref object of OpenApiRestCall_605589
proc url_DeleteComment_606511(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteComment_606510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606512 = path.getOrDefault("VersionId")
  valid_606512 = validateParameter(valid_606512, JString, required = true,
                                 default = nil)
  if valid_606512 != nil:
    section.add "VersionId", valid_606512
  var valid_606513 = path.getOrDefault("DocumentId")
  valid_606513 = validateParameter(valid_606513, JString, required = true,
                                 default = nil)
  if valid_606513 != nil:
    section.add "DocumentId", valid_606513
  var valid_606514 = path.getOrDefault("CommentId")
  valid_606514 = validateParameter(valid_606514, JString, required = true,
                                 default = nil)
  if valid_606514 != nil:
    section.add "CommentId", valid_606514
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
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("Authentication")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "Authentication", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Security-Token")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Security-Token", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Algorithm")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Algorithm", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-SignedHeaders", valid_606522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_DeleteComment_606509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified comment from the document version.
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_DeleteComment_606509; VersionId: string;
          DocumentId: string; CommentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   VersionId: string (required)
  ##            : The ID of the document version.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   CommentId: string (required)
  ##            : The ID of the comment.
  var path_606525 = newJObject()
  add(path_606525, "VersionId", newJString(VersionId))
  add(path_606525, "DocumentId", newJString(DocumentId))
  add(path_606525, "CommentId", newJString(CommentId))
  result = call_606524.call(path_606525, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_606509(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_606510, base: "/", url: url_DeleteComment_606511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_606526 = ref object of OpenApiRestCall_605589
proc url_GetDocument_606528(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_606527(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606529 = path.getOrDefault("DocumentId")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "DocumentId", valid_606529
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_606530 = query.getOrDefault("includeCustomMetadata")
  valid_606530 = validateParameter(valid_606530, JBool, required = false, default = nil)
  if valid_606530 != nil:
    section.add "includeCustomMetadata", valid_606530
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
  var valid_606531 = header.getOrDefault("X-Amz-Signature")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Signature", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Content-Sha256", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Date")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Date", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Credential")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Credential", valid_606534
  var valid_606535 = header.getOrDefault("Authentication")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "Authentication", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Security-Token")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Security-Token", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Algorithm")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Algorithm", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-SignedHeaders", valid_606538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606539: Call_GetDocument_606526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of a document.
  ## 
  let valid = call_606539.validator(path, query, header, formData, body)
  let scheme = call_606539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606539.url(scheme.get, call_606539.host, call_606539.base,
                         call_606539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606539, url, valid)

proc call*(call_606540: Call_GetDocument_606526; DocumentId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   includeCustomMetadata: bool
  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  var path_606541 = newJObject()
  var query_606542 = newJObject()
  add(path_606541, "DocumentId", newJString(DocumentId))
  add(query_606542, "includeCustomMetadata", newJBool(includeCustomMetadata))
  result = call_606540.call(path_606541, query_606542, nil, nil, nil)

var getDocument* = Call_GetDocument_606526(name: "getDocument",
                                        meth: HttpMethod.HttpGet,
                                        host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}",
                                        validator: validate_GetDocument_606527,
                                        base: "/", url: url_GetDocument_606528,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_606558 = ref object of OpenApiRestCall_605589
proc url_UpdateDocument_606560(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_606559(path: JsonNode; query: JsonNode;
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
  var valid_606561 = path.getOrDefault("DocumentId")
  valid_606561 = validateParameter(valid_606561, JString, required = true,
                                 default = nil)
  if valid_606561 != nil:
    section.add "DocumentId", valid_606561
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
  var valid_606562 = header.getOrDefault("X-Amz-Signature")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Signature", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Content-Sha256", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Date")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Date", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Credential")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Credential", valid_606565
  var valid_606566 = header.getOrDefault("Authentication")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "Authentication", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Security-Token")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Security-Token", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Algorithm")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Algorithm", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-SignedHeaders", valid_606569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606571: Call_UpdateDocument_606558; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ## 
  let valid = call_606571.validator(path, query, header, formData, body)
  let scheme = call_606571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606571.url(scheme.get, call_606571.host, call_606571.base,
                         call_606571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606571, url, valid)

proc call*(call_606572: Call_UpdateDocument_606558; DocumentId: string;
          body: JsonNode): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  ##   body: JObject (required)
  var path_606573 = newJObject()
  var body_606574 = newJObject()
  add(path_606573, "DocumentId", newJString(DocumentId))
  if body != nil:
    body_606574 = body
  result = call_606572.call(path_606573, nil, nil, nil, body_606574)

var updateDocument* = Call_UpdateDocument_606558(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_606559,
    base: "/", url: url_UpdateDocument_606560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_606543 = ref object of OpenApiRestCall_605589
proc url_DeleteDocument_606545(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_606544(path: JsonNode; query: JsonNode;
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
  var valid_606546 = path.getOrDefault("DocumentId")
  valid_606546 = validateParameter(valid_606546, JString, required = true,
                                 default = nil)
  if valid_606546 != nil:
    section.add "DocumentId", valid_606546
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
  var valid_606547 = header.getOrDefault("X-Amz-Signature")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Signature", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Content-Sha256", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Date")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Date", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Credential")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Credential", valid_606550
  var valid_606551 = header.getOrDefault("Authentication")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "Authentication", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Security-Token")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Security-Token", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Algorithm")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Algorithm", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-SignedHeaders", valid_606554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606555: Call_DeleteDocument_606543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
  ## 
  let valid = call_606555.validator(path, query, header, formData, body)
  let scheme = call_606555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606555.url(scheme.get, call_606555.host, call_606555.base,
                         call_606555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606555, url, valid)

proc call*(call_606556: Call_DeleteDocument_606543; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   DocumentId: string (required)
  ##             : The ID of the document.
  var path_606557 = newJObject()
  add(path_606557, "DocumentId", newJString(DocumentId))
  result = call_606556.call(path_606557, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_606543(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_606544,
    base: "/", url: url_DeleteDocument_606545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_606575 = ref object of OpenApiRestCall_605589
proc url_GetFolder_606577(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFolder_606576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606578 = path.getOrDefault("FolderId")
  valid_606578 = validateParameter(valid_606578, JString, required = true,
                                 default = nil)
  if valid_606578 != nil:
    section.add "FolderId", valid_606578
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_606579 = query.getOrDefault("includeCustomMetadata")
  valid_606579 = validateParameter(valid_606579, JBool, required = false, default = nil)
  if valid_606579 != nil:
    section.add "includeCustomMetadata", valid_606579
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
  var valid_606580 = header.getOrDefault("X-Amz-Signature")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Signature", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Content-Sha256", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Date")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Date", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Credential")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Credential", valid_606583
  var valid_606584 = header.getOrDefault("Authentication")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "Authentication", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606588: Call_GetFolder_606575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata of the specified folder.
  ## 
  let valid = call_606588.validator(path, query, header, formData, body)
  let scheme = call_606588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606588.url(scheme.get, call_606588.host, call_606588.base,
                         call_606588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606588, url, valid)

proc call*(call_606589: Call_GetFolder_606575; FolderId: string;
          includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   includeCustomMetadata: bool
  ##                        : Set to TRUE to include custom metadata in the response.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_606590 = newJObject()
  var query_606591 = newJObject()
  add(query_606591, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_606590, "FolderId", newJString(FolderId))
  result = call_606589.call(path_606590, query_606591, nil, nil, nil)

var getFolder* = Call_GetFolder_606575(name: "getFolder", meth: HttpMethod.HttpGet,
                                    host: "workdocs.amazonaws.com",
                                    route: "/api/v1/folders/{FolderId}",
                                    validator: validate_GetFolder_606576,
                                    base: "/", url: url_GetFolder_606577,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_606607 = ref object of OpenApiRestCall_605589
proc url_UpdateFolder_606609(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFolder_606608(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606610 = path.getOrDefault("FolderId")
  valid_606610 = validateParameter(valid_606610, JString, required = true,
                                 default = nil)
  if valid_606610 != nil:
    section.add "FolderId", valid_606610
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
  var valid_606611 = header.getOrDefault("X-Amz-Signature")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Signature", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Content-Sha256", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Date")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Date", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Credential")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Credential", valid_606614
  var valid_606615 = header.getOrDefault("Authentication")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "Authentication", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Security-Token")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Security-Token", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Algorithm")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Algorithm", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-SignedHeaders", valid_606618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606620: Call_UpdateFolder_606607; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ## 
  let valid = call_606620.validator(path, query, header, formData, body)
  let scheme = call_606620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606620.url(scheme.get, call_606620.host, call_606620.base,
                         call_606620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606620, url, valid)

proc call*(call_606621: Call_UpdateFolder_606607; body: JsonNode; FolderId: string): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   body: JObject (required)
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_606622 = newJObject()
  var body_606623 = newJObject()
  if body != nil:
    body_606623 = body
  add(path_606622, "FolderId", newJString(FolderId))
  result = call_606621.call(path_606622, nil, nil, nil, body_606623)

var updateFolder* = Call_UpdateFolder_606607(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_606608,
    base: "/", url: url_UpdateFolder_606609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_606592 = ref object of OpenApiRestCall_605589
proc url_DeleteFolder_606594(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolder_606593(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606595 = path.getOrDefault("FolderId")
  valid_606595 = validateParameter(valid_606595, JString, required = true,
                                 default = nil)
  if valid_606595 != nil:
    section.add "FolderId", valid_606595
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
  var valid_606596 = header.getOrDefault("X-Amz-Signature")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Signature", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Content-Sha256", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Date")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Date", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Credential")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Credential", valid_606599
  var valid_606600 = header.getOrDefault("Authentication")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "Authentication", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Security-Token")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Security-Token", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Algorithm")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Algorithm", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-SignedHeaders", valid_606603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606604: Call_DeleteFolder_606592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified folder and its contents.
  ## 
  let valid = call_606604.validator(path, query, header, formData, body)
  let scheme = call_606604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606604.url(scheme.get, call_606604.host, call_606604.base,
                         call_606604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606604, url, valid)

proc call*(call_606605: Call_DeleteFolder_606592; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_606606 = newJObject()
  add(path_606606, "FolderId", newJString(FolderId))
  result = call_606605.call(path_606606, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_606592(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_606593,
    base: "/", url: url_DeleteFolder_606594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_606624 = ref object of OpenApiRestCall_605589
proc url_DescribeFolderContents_606626(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFolderContents_606625(path: JsonNode; query: JsonNode;
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
  var valid_606627 = path.getOrDefault("FolderId")
  valid_606627 = validateParameter(valid_606627, JString, required = true,
                                 default = nil)
  if valid_606627 != nil:
    section.add "FolderId", valid_606627
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
  var valid_606628 = query.getOrDefault("sort")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = newJString("DATE"))
  if valid_606628 != nil:
    section.add "sort", valid_606628
  var valid_606629 = query.getOrDefault("Marker")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "Marker", valid_606629
  var valid_606630 = query.getOrDefault("order")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = newJString("ASCENDING"))
  if valid_606630 != nil:
    section.add "order", valid_606630
  var valid_606631 = query.getOrDefault("limit")
  valid_606631 = validateParameter(valid_606631, JInt, required = false, default = nil)
  if valid_606631 != nil:
    section.add "limit", valid_606631
  var valid_606632 = query.getOrDefault("Limit")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "Limit", valid_606632
  var valid_606633 = query.getOrDefault("type")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = newJString("ALL"))
  if valid_606633 != nil:
    section.add "type", valid_606633
  var valid_606634 = query.getOrDefault("include")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "include", valid_606634
  var valid_606635 = query.getOrDefault("marker")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "marker", valid_606635
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
  var valid_606636 = header.getOrDefault("X-Amz-Signature")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Signature", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Content-Sha256", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Date")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Date", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Credential")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Credential", valid_606639
  var valid_606640 = header.getOrDefault("Authentication")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "Authentication", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Security-Token")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Security-Token", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Algorithm")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Algorithm", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-SignedHeaders", valid_606643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606644: Call_DescribeFolderContents_606624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ## 
  let valid = call_606644.validator(path, query, header, formData, body)
  let scheme = call_606644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606644.url(scheme.get, call_606644.host, call_606644.base,
                         call_606644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606644, url, valid)

proc call*(call_606645: Call_DescribeFolderContents_606624; FolderId: string;
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
  var path_606646 = newJObject()
  var query_606647 = newJObject()
  add(query_606647, "sort", newJString(sort))
  add(query_606647, "Marker", newJString(Marker))
  add(query_606647, "order", newJString(order))
  add(query_606647, "limit", newJInt(limit))
  add(query_606647, "Limit", newJString(Limit))
  add(query_606647, "type", newJString(`type`))
  add(query_606647, "include", newJString(`include`))
  add(path_606646, "FolderId", newJString(FolderId))
  add(query_606647, "marker", newJString(marker))
  result = call_606645.call(path_606646, query_606647, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_606624(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_606625, base: "/",
    url: url_DescribeFolderContents_606626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_606648 = ref object of OpenApiRestCall_605589
proc url_DeleteFolderContents_606650(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolderContents_606649(path: JsonNode; query: JsonNode;
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
  var valid_606651 = path.getOrDefault("FolderId")
  valid_606651 = validateParameter(valid_606651, JString, required = true,
                                 default = nil)
  if valid_606651 != nil:
    section.add "FolderId", valid_606651
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
  var valid_606652 = header.getOrDefault("X-Amz-Signature")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Signature", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Content-Sha256", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Date")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Date", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Credential")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Credential", valid_606655
  var valid_606656 = header.getOrDefault("Authentication")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "Authentication", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Security-Token")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Security-Token", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Algorithm")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Algorithm", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-SignedHeaders", valid_606659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606660: Call_DeleteFolderContents_606648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the contents of the specified folder.
  ## 
  let valid = call_606660.validator(path, query, header, formData, body)
  let scheme = call_606660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606660.url(scheme.get, call_606660.host, call_606660.base,
                         call_606660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606660, url, valid)

proc call*(call_606661: Call_DeleteFolderContents_606648; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
  ##           : The ID of the folder.
  var path_606662 = newJObject()
  add(path_606662, "FolderId", newJString(FolderId))
  result = call_606661.call(path_606662, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_606648(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_606649, base: "/",
    url: url_DeleteFolderContents_606650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_606663 = ref object of OpenApiRestCall_605589
proc url_DeleteNotificationSubscription_606665(protocol: Scheme; host: string;
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

proc validate_DeleteNotificationSubscription_606664(path: JsonNode;
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
  var valid_606666 = path.getOrDefault("SubscriptionId")
  valid_606666 = validateParameter(valid_606666, JString, required = true,
                                 default = nil)
  if valid_606666 != nil:
    section.add "SubscriptionId", valid_606666
  var valid_606667 = path.getOrDefault("OrganizationId")
  valid_606667 = validateParameter(valid_606667, JString, required = true,
                                 default = nil)
  if valid_606667 != nil:
    section.add "OrganizationId", valid_606667
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
  var valid_606668 = header.getOrDefault("X-Amz-Signature")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Signature", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Content-Sha256", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Date")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Date", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Credential")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Credential", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Security-Token")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Security-Token", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Algorithm")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Algorithm", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-SignedHeaders", valid_606674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606675: Call_DeleteNotificationSubscription_606663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified subscription from the specified organization.
  ## 
  let valid = call_606675.validator(path, query, header, formData, body)
  let scheme = call_606675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606675.url(scheme.get, call_606675.host, call_606675.base,
                         call_606675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606675, url, valid)

proc call*(call_606676: Call_DeleteNotificationSubscription_606663;
          SubscriptionId: string; OrganizationId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   SubscriptionId: string (required)
  ##                 : The ID of the subscription.
  ##   OrganizationId: string (required)
  ##                 : The ID of the organization.
  var path_606677 = newJObject()
  add(path_606677, "SubscriptionId", newJString(SubscriptionId))
  add(path_606677, "OrganizationId", newJString(OrganizationId))
  result = call_606676.call(path_606677, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_606663(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_606664, base: "/",
    url: url_DeleteNotificationSubscription_606665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_606693 = ref object of OpenApiRestCall_605589
proc url_UpdateUser_606695(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_606694(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606696 = path.getOrDefault("UserId")
  valid_606696 = validateParameter(valid_606696, JString, required = true,
                                 default = nil)
  if valid_606696 != nil:
    section.add "UserId", valid_606696
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
  var valid_606697 = header.getOrDefault("X-Amz-Signature")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Signature", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Content-Sha256", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Date")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Date", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Credential")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Credential", valid_606700
  var valid_606701 = header.getOrDefault("Authentication")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "Authentication", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Security-Token")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Security-Token", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Algorithm")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Algorithm", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-SignedHeaders", valid_606704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606706: Call_UpdateUser_606693; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ## 
  let valid = call_606706.validator(path, query, header, formData, body)
  let scheme = call_606706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606706.url(scheme.get, call_606706.host, call_606706.base,
                         call_606706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606706, url, valid)

proc call*(call_606707: Call_UpdateUser_606693; UserId: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   UserId: string (required)
  ##         : The ID of the user.
  ##   body: JObject (required)
  var path_606708 = newJObject()
  var body_606709 = newJObject()
  add(path_606708, "UserId", newJString(UserId))
  if body != nil:
    body_606709 = body
  result = call_606707.call(path_606708, nil, nil, nil, body_606709)

var updateUser* = Call_UpdateUser_606693(name: "updateUser",
                                      meth: HttpMethod.HttpPatch,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_UpdateUser_606694,
                                      base: "/", url: url_UpdateUser_606695,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_606678 = ref object of OpenApiRestCall_605589
proc url_DeleteUser_606680(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_606679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606681 = path.getOrDefault("UserId")
  valid_606681 = validateParameter(valid_606681, JString, required = true,
                                 default = nil)
  if valid_606681 != nil:
    section.add "UserId", valid_606681
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
  var valid_606682 = header.getOrDefault("X-Amz-Signature")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Signature", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Content-Sha256", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Date")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Date", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Credential")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Credential", valid_606685
  var valid_606686 = header.getOrDefault("Authentication")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "Authentication", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Security-Token")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Security-Token", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Algorithm")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Algorithm", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-SignedHeaders", valid_606689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606690: Call_DeleteUser_606678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ## 
  let valid = call_606690.validator(path, query, header, formData, body)
  let scheme = call_606690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606690.url(scheme.get, call_606690.host, call_606690.base,
                         call_606690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606690, url, valid)

proc call*(call_606691: Call_DeleteUser_606678; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   UserId: string (required)
  ##         : The ID of the user.
  var path_606692 = newJObject()
  add(path_606692, "UserId", newJString(UserId))
  result = call_606691.call(path_606692, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_606678(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "workdocs.amazonaws.com",
                                      route: "/api/v1/users/{UserId}",
                                      validator: validate_DeleteUser_606679,
                                      base: "/", url: url_DeleteUser_606680,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_606710 = ref object of OpenApiRestCall_605589
proc url_DescribeActivities_606712(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActivities_606711(path: JsonNode; query: JsonNode;
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
  var valid_606713 = query.getOrDefault("endTime")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "endTime", valid_606713
  var valid_606714 = query.getOrDefault("userId")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "userId", valid_606714
  var valid_606715 = query.getOrDefault("resourceId")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "resourceId", valid_606715
  var valid_606716 = query.getOrDefault("limit")
  valid_606716 = validateParameter(valid_606716, JInt, required = false, default = nil)
  if valid_606716 != nil:
    section.add "limit", valid_606716
  var valid_606717 = query.getOrDefault("startTime")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "startTime", valid_606717
  var valid_606718 = query.getOrDefault("activityTypes")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "activityTypes", valid_606718
  var valid_606719 = query.getOrDefault("organizationId")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "organizationId", valid_606719
  var valid_606720 = query.getOrDefault("includeIndirectActivities")
  valid_606720 = validateParameter(valid_606720, JBool, required = false, default = nil)
  if valid_606720 != nil:
    section.add "includeIndirectActivities", valid_606720
  var valid_606721 = query.getOrDefault("marker")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "marker", valid_606721
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
  var valid_606722 = header.getOrDefault("X-Amz-Signature")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Signature", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Content-Sha256", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Date")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Date", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Credential")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Credential", valid_606725
  var valid_606726 = header.getOrDefault("Authentication")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "Authentication", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Security-Token")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Security-Token", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Algorithm")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Algorithm", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-SignedHeaders", valid_606729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606730: Call_DescribeActivities_606710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user activities in a specified time period.
  ## 
  let valid = call_606730.validator(path, query, header, formData, body)
  let scheme = call_606730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606730.url(scheme.get, call_606730.host, call_606730.base,
                         call_606730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606730, url, valid)

proc call*(call_606731: Call_DescribeActivities_606710; endTime: string = "";
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
  var query_606732 = newJObject()
  add(query_606732, "endTime", newJString(endTime))
  add(query_606732, "userId", newJString(userId))
  add(query_606732, "resourceId", newJString(resourceId))
  add(query_606732, "limit", newJInt(limit))
  add(query_606732, "startTime", newJString(startTime))
  add(query_606732, "activityTypes", newJString(activityTypes))
  add(query_606732, "organizationId", newJString(organizationId))
  add(query_606732, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_606732, "marker", newJString(marker))
  result = call_606731.call(nil, query_606732, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_606710(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_606711, base: "/",
    url: url_DescribeActivities_606712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_606733 = ref object of OpenApiRestCall_605589
proc url_DescribeComments_606735(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeComments_606734(path: JsonNode; query: JsonNode;
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
  var valid_606736 = path.getOrDefault("VersionId")
  valid_606736 = validateParameter(valid_606736, JString, required = true,
                                 default = nil)
  if valid_606736 != nil:
    section.add "VersionId", valid_606736
  var valid_606737 = path.getOrDefault("DocumentId")
  valid_606737 = validateParameter(valid_606737, JString, required = true,
                                 default = nil)
  if valid_606737 != nil:
    section.add "DocumentId", valid_606737
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of items to return.
  ##   marker: JString
  ##         : The marker for the next set of results. This marker was received from a previous call.
  section = newJObject()
  var valid_606738 = query.getOrDefault("limit")
  valid_606738 = validateParameter(valid_606738, JInt, required = false, default = nil)
  if valid_606738 != nil:
    section.add "limit", valid_606738
  var valid_606739 = query.getOrDefault("marker")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "marker", valid_606739
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
  var valid_606740 = header.getOrDefault("X-Amz-Signature")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Signature", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Content-Sha256", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Date")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Date", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Credential")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Credential", valid_606743
  var valid_606744 = header.getOrDefault("Authentication")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "Authentication", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Security-Token")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Security-Token", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Algorithm")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Algorithm", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-SignedHeaders", valid_606747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_DescribeComments_606733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all the comments for the specified document version.
  ## 
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_DescribeComments_606733; VersionId: string;
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
  var path_606750 = newJObject()
  var query_606751 = newJObject()
  add(path_606750, "VersionId", newJString(VersionId))
  add(path_606750, "DocumentId", newJString(DocumentId))
  add(query_606751, "limit", newJInt(limit))
  add(query_606751, "marker", newJString(marker))
  result = call_606749.call(path_606750, query_606751, nil, nil, nil)

var describeComments* = Call_DescribeComments_606733(name: "describeComments",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_606734, base: "/",
    url: url_DescribeComments_606735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_606752 = ref object of OpenApiRestCall_605589
proc url_DescribeDocumentVersions_606754(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentVersions_606753(path: JsonNode; query: JsonNode;
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
  var valid_606755 = path.getOrDefault("DocumentId")
  valid_606755 = validateParameter(valid_606755, JString, required = true,
                                 default = nil)
  if valid_606755 != nil:
    section.add "DocumentId", valid_606755
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
  var valid_606756 = query.getOrDefault("Marker")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "Marker", valid_606756
  var valid_606757 = query.getOrDefault("limit")
  valid_606757 = validateParameter(valid_606757, JInt, required = false, default = nil)
  if valid_606757 != nil:
    section.add "limit", valid_606757
  var valid_606758 = query.getOrDefault("Limit")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "Limit", valid_606758
  var valid_606759 = query.getOrDefault("include")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "include", valid_606759
  var valid_606760 = query.getOrDefault("fields")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "fields", valid_606760
  var valid_606761 = query.getOrDefault("marker")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "marker", valid_606761
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
  var valid_606762 = header.getOrDefault("X-Amz-Signature")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Signature", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Content-Sha256", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Date")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Date", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Credential")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Credential", valid_606765
  var valid_606766 = header.getOrDefault("Authentication")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "Authentication", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Security-Token")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Security-Token", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Algorithm")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Algorithm", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-SignedHeaders", valid_606769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606770: Call_DescribeDocumentVersions_606752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ## 
  let valid = call_606770.validator(path, query, header, formData, body)
  let scheme = call_606770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606770.url(scheme.get, call_606770.host, call_606770.base,
                         call_606770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606770, url, valid)

proc call*(call_606771: Call_DescribeDocumentVersions_606752; DocumentId: string;
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
  var path_606772 = newJObject()
  var query_606773 = newJObject()
  add(query_606773, "Marker", newJString(Marker))
  add(path_606772, "DocumentId", newJString(DocumentId))
  add(query_606773, "limit", newJInt(limit))
  add(query_606773, "Limit", newJString(Limit))
  add(query_606773, "include", newJString(`include`))
  add(query_606773, "fields", newJString(fields))
  add(query_606773, "marker", newJString(marker))
  result = call_606771.call(path_606772, query_606773, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_606752(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_606753, base: "/",
    url: url_DescribeDocumentVersions_606754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_606774 = ref object of OpenApiRestCall_605589
proc url_DescribeGroups_606776(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGroups_606775(path: JsonNode; query: JsonNode;
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
  var valid_606777 = query.getOrDefault("searchQuery")
  valid_606777 = validateParameter(valid_606777, JString, required = true,
                                 default = nil)
  if valid_606777 != nil:
    section.add "searchQuery", valid_606777
  var valid_606778 = query.getOrDefault("limit")
  valid_606778 = validateParameter(valid_606778, JInt, required = false, default = nil)
  if valid_606778 != nil:
    section.add "limit", valid_606778
  var valid_606779 = query.getOrDefault("organizationId")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "organizationId", valid_606779
  var valid_606780 = query.getOrDefault("marker")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "marker", valid_606780
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
  var valid_606781 = header.getOrDefault("X-Amz-Signature")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Signature", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Content-Sha256", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Date")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Date", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Credential")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Credential", valid_606784
  var valid_606785 = header.getOrDefault("Authentication")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "Authentication", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Security-Token")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Security-Token", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Algorithm")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Algorithm", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-SignedHeaders", valid_606788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606789: Call_DescribeGroups_606774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ## 
  let valid = call_606789.validator(path, query, header, formData, body)
  let scheme = call_606789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606789.url(scheme.get, call_606789.host, call_606789.base,
                         call_606789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606789, url, valid)

proc call*(call_606790: Call_DescribeGroups_606774; searchQuery: string;
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
  var query_606791 = newJObject()
  add(query_606791, "searchQuery", newJString(searchQuery))
  add(query_606791, "limit", newJInt(limit))
  add(query_606791, "organizationId", newJString(organizationId))
  add(query_606791, "marker", newJString(marker))
  result = call_606790.call(nil, query_606791, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_606774(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_606775,
    base: "/", url: url_DescribeGroups_606776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_606792 = ref object of OpenApiRestCall_605589
proc url_DescribeRootFolders_606794(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRootFolders_606793(path: JsonNode; query: JsonNode;
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
  var valid_606795 = query.getOrDefault("limit")
  valid_606795 = validateParameter(valid_606795, JInt, required = false, default = nil)
  if valid_606795 != nil:
    section.add "limit", valid_606795
  var valid_606796 = query.getOrDefault("marker")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "marker", valid_606796
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
  var valid_606797 = header.getOrDefault("X-Amz-Signature")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Signature", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Content-Sha256", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Date")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Date", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Credential")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Credential", valid_606800
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_606801 = header.getOrDefault("Authentication")
  valid_606801 = validateParameter(valid_606801, JString, required = true,
                                 default = nil)
  if valid_606801 != nil:
    section.add "Authentication", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Security-Token")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Security-Token", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Algorithm")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Algorithm", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-SignedHeaders", valid_606804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606805: Call_DescribeRootFolders_606792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ## 
  let valid = call_606805.validator(path, query, header, formData, body)
  let scheme = call_606805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606805.url(scheme.get, call_606805.host, call_606805.base,
                         call_606805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606805, url, valid)

proc call*(call_606806: Call_DescribeRootFolders_606792; limit: int = 0;
          marker: string = ""): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   limit: int
  ##        : The maximum number of items to return.
  ##   marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  var query_606807 = newJObject()
  add(query_606807, "limit", newJInt(limit))
  add(query_606807, "marker", newJString(marker))
  result = call_606806.call(nil, query_606807, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_606792(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_606793, base: "/",
    url: url_DescribeRootFolders_606794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_606808 = ref object of OpenApiRestCall_605589
proc url_GetCurrentUser_606810(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentUser_606809(path: JsonNode; query: JsonNode;
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
  var valid_606811 = header.getOrDefault("X-Amz-Signature")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Signature", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Content-Sha256", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Date")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Date", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Credential")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Credential", valid_606814
  assert header != nil,
        "header argument is necessary due to required `Authentication` field"
  var valid_606815 = header.getOrDefault("Authentication")
  valid_606815 = validateParameter(valid_606815, JString, required = true,
                                 default = nil)
  if valid_606815 != nil:
    section.add "Authentication", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Security-Token")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Security-Token", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Algorithm")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Algorithm", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-SignedHeaders", valid_606818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606819: Call_GetCurrentUser_606808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  ## 
  let valid = call_606819.validator(path, query, header, formData, body)
  let scheme = call_606819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606819.url(scheme.get, call_606819.host, call_606819.base,
                         call_606819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606819, url, valid)

proc call*(call_606820: Call_GetCurrentUser_606808): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_606820.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_606808(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_606809,
    base: "/", url: url_GetCurrentUser_606810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_606821 = ref object of OpenApiRestCall_605589
proc url_GetDocumentPath_606823(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocumentPath_606822(path: JsonNode; query: JsonNode;
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
  var valid_606824 = path.getOrDefault("DocumentId")
  valid_606824 = validateParameter(valid_606824, JString, required = true,
                                 default = nil)
  if valid_606824 != nil:
    section.add "DocumentId", valid_606824
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_606825 = query.getOrDefault("limit")
  valid_606825 = validateParameter(valid_606825, JInt, required = false, default = nil)
  if valid_606825 != nil:
    section.add "limit", valid_606825
  var valid_606826 = query.getOrDefault("fields")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "fields", valid_606826
  var valid_606827 = query.getOrDefault("marker")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "marker", valid_606827
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
  var valid_606828 = header.getOrDefault("X-Amz-Signature")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Signature", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Content-Sha256", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Date")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Date", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Credential")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Credential", valid_606831
  var valid_606832 = header.getOrDefault("Authentication")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "Authentication", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Security-Token")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Security-Token", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Algorithm")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Algorithm", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-SignedHeaders", valid_606835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606836: Call_GetDocumentPath_606821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ## 
  let valid = call_606836.validator(path, query, header, formData, body)
  let scheme = call_606836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606836.url(scheme.get, call_606836.host, call_606836.base,
                         call_606836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606836, url, valid)

proc call*(call_606837: Call_GetDocumentPath_606821; DocumentId: string;
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
  var path_606838 = newJObject()
  var query_606839 = newJObject()
  add(path_606838, "DocumentId", newJString(DocumentId))
  add(query_606839, "limit", newJInt(limit))
  add(query_606839, "fields", newJString(fields))
  add(query_606839, "marker", newJString(marker))
  result = call_606837.call(path_606838, query_606839, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_606821(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_606822, base: "/", url: url_GetDocumentPath_606823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_606840 = ref object of OpenApiRestCall_605589
proc url_GetFolderPath_606842(protocol: Scheme; host: string; base: string;
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

proc validate_GetFolderPath_606841(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606843 = path.getOrDefault("FolderId")
  valid_606843 = validateParameter(valid_606843, JString, required = true,
                                 default = nil)
  if valid_606843 != nil:
    section.add "FolderId", valid_606843
  result.add "path", section
  ## parameters in `query` object:
  ##   limit: JInt
  ##        : The maximum number of levels in the hierarchy to return.
  ##   fields: JString
  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   marker: JString
  ##         : This value is not supported.
  section = newJObject()
  var valid_606844 = query.getOrDefault("limit")
  valid_606844 = validateParameter(valid_606844, JInt, required = false, default = nil)
  if valid_606844 != nil:
    section.add "limit", valid_606844
  var valid_606845 = query.getOrDefault("fields")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "fields", valid_606845
  var valid_606846 = query.getOrDefault("marker")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "marker", valid_606846
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
  var valid_606847 = header.getOrDefault("X-Amz-Signature")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Signature", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Content-Sha256", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Date")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Date", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Credential")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Credential", valid_606850
  var valid_606851 = header.getOrDefault("Authentication")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "Authentication", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-Security-Token")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Security-Token", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-Algorithm")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-Algorithm", valid_606853
  var valid_606854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-SignedHeaders", valid_606854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606855: Call_GetFolderPath_606840; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ## 
  let valid = call_606855.validator(path, query, header, formData, body)
  let scheme = call_606855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606855.url(scheme.get, call_606855.host, call_606855.base,
                         call_606855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606855, url, valid)

proc call*(call_606856: Call_GetFolderPath_606840; FolderId: string; limit: int = 0;
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
  var path_606857 = newJObject()
  var query_606858 = newJObject()
  add(query_606858, "limit", newJInt(limit))
  add(path_606857, "FolderId", newJString(FolderId))
  add(query_606858, "fields", newJString(fields))
  add(query_606858, "marker", newJString(marker))
  result = call_606856.call(path_606857, query_606858, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_606840(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_606841,
    base: "/", url: url_GetFolderPath_606842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_606859 = ref object of OpenApiRestCall_605589
proc url_GetResources_606861(protocol: Scheme; host: string; base: string;
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

proc validate_GetResources_606860(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606862 = query.getOrDefault("userId")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "userId", valid_606862
  var valid_606863 = query.getOrDefault("limit")
  valid_606863 = validateParameter(valid_606863, JInt, required = false, default = nil)
  if valid_606863 != nil:
    section.add "limit", valid_606863
  var valid_606864 = query.getOrDefault("collectionType")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = newJString("SHARED_WITH_ME"))
  if valid_606864 != nil:
    section.add "collectionType", valid_606864
  var valid_606865 = query.getOrDefault("marker")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "marker", valid_606865
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
  var valid_606866 = header.getOrDefault("X-Amz-Signature")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-Signature", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Content-Sha256", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Date")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Date", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Credential")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Credential", valid_606869
  var valid_606870 = header.getOrDefault("Authentication")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "Authentication", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Security-Token")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Security-Token", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Algorithm")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Algorithm", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-SignedHeaders", valid_606873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606874: Call_GetResources_606859; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ## 
  let valid = call_606874.validator(path, query, header, formData, body)
  let scheme = call_606874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606874.url(scheme.get, call_606874.host, call_606874.base,
                         call_606874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606874, url, valid)

proc call*(call_606875: Call_GetResources_606859; userId: string = ""; limit: int = 0;
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
  var query_606876 = newJObject()
  add(query_606876, "userId", newJString(userId))
  add(query_606876, "limit", newJInt(limit))
  add(query_606876, "collectionType", newJString(collectionType))
  add(query_606876, "marker", newJString(marker))
  result = call_606875.call(nil, query_606876, nil, nil, nil)

var getResources* = Call_GetResources_606859(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_606860, base: "/",
    url: url_GetResources_606861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_606877 = ref object of OpenApiRestCall_605589
proc url_InitiateDocumentVersionUpload_606879(protocol: Scheme; host: string;
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

proc validate_InitiateDocumentVersionUpload_606878(path: JsonNode; query: JsonNode;
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
  var valid_606880 = header.getOrDefault("X-Amz-Signature")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-Signature", valid_606880
  var valid_606881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Content-Sha256", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Date")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Date", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Credential")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Credential", valid_606883
  var valid_606884 = header.getOrDefault("Authentication")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "Authentication", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Security-Token")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Security-Token", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Algorithm")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Algorithm", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-SignedHeaders", valid_606887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606889: Call_InitiateDocumentVersionUpload_606877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ## 
  let valid = call_606889.validator(path, query, header, formData, body)
  let scheme = call_606889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606889.url(scheme.get, call_606889.host, call_606889.base,
                         call_606889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606889, url, valid)

proc call*(call_606890: Call_InitiateDocumentVersionUpload_606877; body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   body: JObject (required)
  var body_606891 = newJObject()
  if body != nil:
    body_606891 = body
  result = call_606890.call(nil, nil, nil, nil, body_606891)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_606877(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_606878, base: "/",
    url: url_InitiateDocumentVersionUpload_606879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_606892 = ref object of OpenApiRestCall_605589
proc url_RemoveResourcePermission_606894(protocol: Scheme; host: string;
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

proc validate_RemoveResourcePermission_606893(path: JsonNode; query: JsonNode;
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
  var valid_606895 = path.getOrDefault("ResourceId")
  valid_606895 = validateParameter(valid_606895, JString, required = true,
                                 default = nil)
  if valid_606895 != nil:
    section.add "ResourceId", valid_606895
  var valid_606896 = path.getOrDefault("PrincipalId")
  valid_606896 = validateParameter(valid_606896, JString, required = true,
                                 default = nil)
  if valid_606896 != nil:
    section.add "PrincipalId", valid_606896
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The principal type of the resource.
  section = newJObject()
  var valid_606897 = query.getOrDefault("type")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = newJString("USER"))
  if valid_606897 != nil:
    section.add "type", valid_606897
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
  var valid_606898 = header.getOrDefault("X-Amz-Signature")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Signature", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Content-Sha256", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Date")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Date", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Credential")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Credential", valid_606901
  var valid_606902 = header.getOrDefault("Authentication")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "Authentication", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Security-Token")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Security-Token", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Algorithm")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Algorithm", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-SignedHeaders", valid_606905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606906: Call_RemoveResourcePermission_606892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
  ## 
  let valid = call_606906.validator(path, query, header, formData, body)
  let scheme = call_606906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606906.url(scheme.get, call_606906.host, call_606906.base,
                         call_606906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606906, url, valid)

proc call*(call_606907: Call_RemoveResourcePermission_606892; ResourceId: string;
          PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   ResourceId: string (required)
  ##             : The ID of the resource.
  ##   type: string
  ##       : The principal type of the resource.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the resource.
  var path_606908 = newJObject()
  var query_606909 = newJObject()
  add(path_606908, "ResourceId", newJString(ResourceId))
  add(query_606909, "type", newJString(`type`))
  add(path_606908, "PrincipalId", newJString(PrincipalId))
  result = call_606907.call(path_606908, query_606909, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_606892(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_606893, base: "/",
    url: url_RemoveResourcePermission_606894, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
