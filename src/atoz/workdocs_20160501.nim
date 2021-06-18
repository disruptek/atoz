
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "workdocs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "workdocs.ap-southeast-1.amazonaws.com",
                               "us-west-2": "workdocs.us-west-2.amazonaws.com",
                               "eu-west-2": "workdocs.eu-west-2.amazonaws.com", "ap-northeast-3": "workdocs.ap-northeast-3.amazonaws.com", "eu-central-1": "workdocs.eu-central-1.amazonaws.com",
                               "us-east-2": "workdocs.us-east-2.amazonaws.com",
                               "us-east-1": "workdocs.us-east-1.amazonaws.com", "cn-northwest-1": "workdocs.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "workdocs.ap-south-1.amazonaws.com", "eu-north-1": "workdocs.eu-north-1.amazonaws.com", "ap-northeast-2": "workdocs.ap-northeast-2.amazonaws.com",
                               "us-west-1": "workdocs.us-west-1.amazonaws.com", "us-gov-east-1": "workdocs.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "workdocs.eu-west-3.amazonaws.com", "cn-north-1": "workdocs.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "workdocs.sa-east-1.amazonaws.com",
                               "eu-west-1": "workdocs.eu-west-1.amazonaws.com", "us-gov-west-1": "workdocs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "workdocs.ap-southeast-2.amazonaws.com", "ca-central-1": "workdocs.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_GetDocumentVersion_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetDocumentVersion_402656296(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetDocumentVersion_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves version metadata for the specified document.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
                                 ##            : The version ID of the document.
  ##   
                                                                                ## DocumentId: JString (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## The 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## document.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `VersionId` field"
  var valid_402656389 = path.getOrDefault("VersionId")
  valid_402656389 = validateParameter(valid_402656389, JString, required = true,
                                      default = nil)
  if valid_402656389 != nil:
    section.add "VersionId", valid_402656389
  var valid_402656390 = path.getOrDefault("DocumentId")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true,
                                      default = nil)
  if valid_402656390 != nil:
    section.add "DocumentId", valid_402656390
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
                                  ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  ##   
                                                                                                                                           ## includeCustomMetadata: JBool
                                                                                                                                           ##                        
                                                                                                                                           ## : 
                                                                                                                                           ## Set 
                                                                                                                                           ## this 
                                                                                                                                           ## to 
                                                                                                                                           ## TRUE 
                                                                                                                                           ## to 
                                                                                                                                           ## include 
                                                                                                                                           ## custom 
                                                                                                                                           ## metadata 
                                                                                                                                           ## in 
                                                                                                                                           ## the 
                                                                                                                                           ## response.
  section = newJObject()
  var valid_402656391 = query.getOrDefault("fields")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "fields", valid_402656391
  var valid_402656392 = query.getOrDefault("includeCustomMetadata")
  valid_402656392 = validateParameter(valid_402656392, JBool, required = false,
                                      default = nil)
  if valid_402656392 != nil:
    section.add "includeCustomMetadata", valid_402656392
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656393 = header.getOrDefault("Authentication")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "Authentication", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Security-Token", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Signature")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Signature", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-Algorithm", valid_402656397
  var valid_402656398 = header.getOrDefault("X-Amz-Date")
  valid_402656398 = validateParameter(valid_402656398, JString,
                                      required = false, default = nil)
  if valid_402656398 != nil:
    section.add "X-Amz-Date", valid_402656398
  var valid_402656399 = header.getOrDefault("X-Amz-Credential")
  valid_402656399 = validateParameter(valid_402656399, JString,
                                      required = false, default = nil)
  if valid_402656399 != nil:
    section.add "X-Amz-Credential", valid_402656399
  var valid_402656400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656400 = validateParameter(valid_402656400, JString,
                                      required = false, default = nil)
  if valid_402656400 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656414: Call_GetDocumentVersion_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves version metadata for the specified document.
                                                                                         ## 
  let valid = call_402656414.validator(path, query, header, formData, body, _)
  let scheme = call_402656414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656414.makeUrl(scheme.get, call_402656414.host, call_402656414.base,
                                   call_402656414.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656414, uri, valid, _)

proc call*(call_402656463: Call_GetDocumentVersion_402656294; VersionId: string;
           DocumentId: string; fields: string = "";
           includeCustomMetadata: bool = false): Recallable =
  ## getDocumentVersion
  ## Retrieves version metadata for the specified document.
  ##   fields: string
                                                           ##         : A comma-separated list of values. Specify "SOURCE" to include a URL for the source document.
  ##   
                                                                                                                                                                    ## includeCustomMetadata: bool
                                                                                                                                                                    ##                        
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## Set 
                                                                                                                                                                    ## this 
                                                                                                                                                                    ## to 
                                                                                                                                                                    ## TRUE 
                                                                                                                                                                    ## to 
                                                                                                                                                                    ## include 
                                                                                                                                                                    ## custom 
                                                                                                                                                                    ## metadata 
                                                                                                                                                                    ## in 
                                                                                                                                                                    ## the 
                                                                                                                                                                    ## response.
  ##   
                                                                                                                                                                                ## VersionId: string (required)
                                                                                                                                                                                ##            
                                                                                                                                                                                ## : 
                                                                                                                                                                                ## The 
                                                                                                                                                                                ## version 
                                                                                                                                                                                ## ID 
                                                                                                                                                                                ## of 
                                                                                                                                                                                ## the 
                                                                                                                                                                                ## document.
  ##   
                                                                                                                                                                                            ## DocumentId: string (required)
                                                                                                                                                                                            ##             
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## The 
                                                                                                                                                                                            ## ID 
                                                                                                                                                                                            ## of 
                                                                                                                                                                                            ## the 
                                                                                                                                                                                            ## document.
  var path_402656464 = newJObject()
  var query_402656466 = newJObject()
  add(query_402656466, "fields", newJString(fields))
  add(query_402656466, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_402656464, "VersionId", newJString(VersionId))
  add(path_402656464, "DocumentId", newJString(DocumentId))
  result = call_402656463.call(path_402656464, query_402656466, nil, nil, nil)

var getDocumentVersion* = Call_GetDocumentVersion_402656294(
    name: "getDocumentVersion", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_GetDocumentVersion_402656295, base: "/",
    makeUrl: url_GetDocumentVersion_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentVersion_402656508 = ref object of OpenApiRestCall_402656044
proc url_UpdateDocumentVersion_402656510(protocol: Scheme; host: string;
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

proc validate_UpdateDocumentVersion_402656509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
                                 ##            : The version ID of the document.
  ##   
                                                                                ## DocumentId: JString (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## The 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## document.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `VersionId` field"
  var valid_402656511 = path.getOrDefault("VersionId")
  valid_402656511 = validateParameter(valid_402656511, JString, required = true,
                                      default = nil)
  if valid_402656511 != nil:
    section.add "VersionId", valid_402656511
  var valid_402656512 = path.getOrDefault("DocumentId")
  valid_402656512 = validateParameter(valid_402656512, JString, required = true,
                                      default = nil)
  if valid_402656512 != nil:
    section.add "DocumentId", valid_402656512
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656513 = header.getOrDefault("Authentication")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "Authentication", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Security-Token", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Signature")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Signature", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Algorithm", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Date")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Date", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Credential")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Credential", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656520
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

proc call*(call_402656522: Call_UpdateDocumentVersion_402656508;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_UpdateDocumentVersion_402656508; body: JsonNode;
           VersionId: string; DocumentId: string): Recallable =
  ## updateDocumentVersion
  ## <p>Changes the status of the document version to ACTIVE. </p> <p>Amazon WorkDocs also sets its document container to ACTIVE. This is the last step in a document upload, after the client uploads the document to an S3-presigned URL returned by <a>InitiateDocumentVersionUpload</a>. </p>
  ##   
                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                            ## VersionId: string (required)
                                                                                                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                            ## version 
                                                                                                                                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                            ## document.
  ##   
                                                                                                                                                                                                                                                                                                                                        ## DocumentId: string (required)
                                                                                                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                        ## ID 
                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                        ## document.
  var path_402656524 = newJObject()
  var body_402656525 = newJObject()
  if body != nil:
    body_402656525 = body
  add(path_402656524, "VersionId", newJString(VersionId))
  add(path_402656524, "DocumentId", newJString(DocumentId))
  result = call_402656523.call(path_402656524, nil, nil, nil, body_402656525)

var updateDocumentVersion* = Call_UpdateDocumentVersion_402656508(
    name: "updateDocumentVersion", meth: HttpMethod.HttpPatch,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_UpdateDocumentVersion_402656509, base: "/",
    makeUrl: url_UpdateDocumentVersion_402656510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AbortDocumentVersionUpload_402656492 = ref object of OpenApiRestCall_402656044
proc url_AbortDocumentVersionUpload_402656494(protocol: Scheme; host: string;
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

proc validate_AbortDocumentVersionUpload_402656493(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
                                 ##            : The ID of the version.
  ##   
                                                                       ## DocumentId: JString (required)
                                                                       ##             
                                                                       ## : 
                                                                       ## The ID of the 
                                                                       ## document.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `VersionId` field"
  var valid_402656495 = path.getOrDefault("VersionId")
  valid_402656495 = validateParameter(valid_402656495, JString, required = true,
                                      default = nil)
  if valid_402656495 != nil:
    section.add "VersionId", valid_402656495
  var valid_402656496 = path.getOrDefault("DocumentId")
  valid_402656496 = validateParameter(valid_402656496, JString, required = true,
                                      default = nil)
  if valid_402656496 != nil:
    section.add "DocumentId", valid_402656496
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656497 = header.getOrDefault("Authentication")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "Authentication", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Security-Token", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Signature")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Signature", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Algorithm", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Date")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Date", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Credential")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Credential", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656505: Call_AbortDocumentVersionUpload_402656492;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
                                                                                         ## 
  let valid = call_402656505.validator(path, query, header, formData, body, _)
  let scheme = call_402656505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656505.makeUrl(scheme.get, call_402656505.host, call_402656505.base,
                                   call_402656505.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656505, uri, valid, _)

proc call*(call_402656506: Call_AbortDocumentVersionUpload_402656492;
           VersionId: string; DocumentId: string): Recallable =
  ## abortDocumentVersionUpload
  ## Aborts the upload of the specified document version that was previously initiated by <a>InitiateDocumentVersionUpload</a>. The client should make this call only when it no longer intends to upload the document version, or fails to do so.
  ##   
                                                                                                                                                                                                                                                  ## VersionId: string (required)
                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                  ## ID 
                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                  ## version.
  ##   
                                                                                                                                                                                                                                                             ## DocumentId: string (required)
                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                             ## ID 
                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                             ## document.
  var path_402656507 = newJObject()
  add(path_402656507, "VersionId", newJString(VersionId))
  add(path_402656507, "DocumentId", newJString(DocumentId))
  result = call_402656506.call(path_402656507, nil, nil, nil, nil)

var abortDocumentVersionUpload* = Call_AbortDocumentVersionUpload_402656492(
    name: "abortDocumentVersionUpload", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}",
    validator: validate_AbortDocumentVersionUpload_402656493, base: "/",
    makeUrl: url_AbortDocumentVersionUpload_402656494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ActivateUser_402656526 = ref object of OpenApiRestCall_402656044
proc url_ActivateUser_402656528(protocol: Scheme; host: string; base: string;
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

proc validate_ActivateUser_402656527(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
                                 ##         : The ID of the user.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `UserId` field"
  var valid_402656529 = path.getOrDefault("UserId")
  valid_402656529 = validateParameter(valid_402656529, JString, required = true,
                                      default = nil)
  if valid_402656529 != nil:
    section.add "UserId", valid_402656529
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656530 = header.getOrDefault("Authentication")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "Authentication", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Security-Token", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Signature")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Signature", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Algorithm", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Date")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Date", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Credential")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Credential", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656538: Call_ActivateUser_402656526; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
                                                                                         ## 
  let valid = call_402656538.validator(path, query, header, formData, body, _)
  let scheme = call_402656538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656538.makeUrl(scheme.get, call_402656538.host, call_402656538.base,
                                   call_402656538.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656538, uri, valid, _)

proc call*(call_402656539: Call_ActivateUser_402656526; UserId: string): Recallable =
  ## activateUser
  ## Activates the specified user. Only active users can access Amazon WorkDocs.
  ##   
                                                                                ## UserId: string (required)
                                                                                ##         
                                                                                ## : 
                                                                                ## The 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## user.
  var path_402656540 = newJObject()
  add(path_402656540, "UserId", newJString(UserId))
  result = call_402656539.call(path_402656540, nil, nil, nil, nil)

var activateUser* = Call_ActivateUser_402656526(name: "activateUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_ActivateUser_402656527, base: "/",
    makeUrl: url_ActivateUser_402656528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateUser_402656541 = ref object of OpenApiRestCall_402656044
proc url_DeactivateUser_402656543(protocol: Scheme; host: string; base: string;
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

proc validate_DeactivateUser_402656542(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `UserId` field"
  var valid_402656544 = path.getOrDefault("UserId")
  valid_402656544 = validateParameter(valid_402656544, JString, required = true,
                                      default = nil)
  if valid_402656544 != nil:
    section.add "UserId", valid_402656544
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656545 = header.getOrDefault("Authentication")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "Authentication", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Security-Token", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Signature")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Signature", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Algorithm", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Date")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Date", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Credential")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Credential", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656553: Call_DeactivateUser_402656541; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
                                                                                         ## 
  let valid = call_402656553.validator(path, query, header, formData, body, _)
  let scheme = call_402656553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656553.makeUrl(scheme.get, call_402656553.host, call_402656553.base,
                                   call_402656553.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656553, uri, valid, _)

proc call*(call_402656554: Call_DeactivateUser_402656541; UserId: string): Recallable =
  ## deactivateUser
  ## Deactivates the specified user, which revokes the user's access to Amazon WorkDocs.
  ##   
                                                                                        ## UserId: string (required)
                                                                                        ##         
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## ID 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## user.
  var path_402656555 = newJObject()
  add(path_402656555, "UserId", newJString(UserId))
  result = call_402656554.call(path_402656555, nil, nil, nil, nil)

var deactivateUser* = Call_DeactivateUser_402656541(name: "deactivateUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}/activation",
    validator: validate_DeactivateUser_402656542, base: "/",
    makeUrl: url_DeactivateUser_402656543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddResourcePermissions_402656575 = ref object of OpenApiRestCall_402656044
proc url_AddResourcePermissions_402656577(protocol: Scheme; host: string;
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

proc validate_AddResourcePermissions_402656576(path: JsonNode; query: JsonNode;
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
  var valid_402656578 = path.getOrDefault("ResourceId")
  valid_402656578 = validateParameter(valid_402656578, JString, required = true,
                                      default = nil)
  if valid_402656578 != nil:
    section.add "ResourceId", valid_402656578
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656579 = header.getOrDefault("Authentication")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "Authentication", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Security-Token", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Signature")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Signature", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Algorithm", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Date")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Date", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Credential")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Credential", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656586
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

proc call*(call_402656588: Call_AddResourcePermissions_402656575;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
                                                                                         ## 
  let valid = call_402656588.validator(path, query, header, formData, body, _)
  let scheme = call_402656588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656588.makeUrl(scheme.get, call_402656588.host, call_402656588.base,
                                   call_402656588.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656588, uri, valid, _)

proc call*(call_402656589: Call_AddResourcePermissions_402656575;
           ResourceId: string; body: JsonNode): Recallable =
  ## addResourcePermissions
  ## Creates a set of permissions for the specified folder or document. The resource permissions are overwritten if the principals already have different permissions.
  ##   
                                                                                                                                                                      ## ResourceId: string (required)
                                                                                                                                                                      ##             
                                                                                                                                                                      ## : 
                                                                                                                                                                      ## The 
                                                                                                                                                                      ## ID 
                                                                                                                                                                      ## of 
                                                                                                                                                                      ## the 
                                                                                                                                                                      ## resource.
  ##   
                                                                                                                                                                                  ## body: JObject (required)
  var path_402656590 = newJObject()
  var body_402656591 = newJObject()
  add(path_402656590, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_402656591 = body
  result = call_402656589.call(path_402656590, nil, nil, nil, body_402656591)

var addResourcePermissions* = Call_AddResourcePermissions_402656575(
    name: "addResourcePermissions", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_AddResourcePermissions_402656576, base: "/",
    makeUrl: url_AddResourcePermissions_402656577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourcePermissions_402656556 = ref object of OpenApiRestCall_402656044
proc url_DescribeResourcePermissions_402656558(protocol: Scheme; host: string;
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

proc validate_DescribeResourcePermissions_402656557(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656559 = path.getOrDefault("ResourceId")
  valid_402656559 = validateParameter(valid_402656559, JString, required = true,
                                      default = nil)
  if valid_402656559 != nil:
    section.add "ResourceId", valid_402656559
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
                                  ##         : The marker for the next set of results. (You received this marker from a previous call)
  ##   
                                                                                                                                      ## limit: JInt
                                                                                                                                      ##        
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## maximum 
                                                                                                                                      ## number 
                                                                                                                                      ## of 
                                                                                                                                      ## items 
                                                                                                                                      ## to 
                                                                                                                                      ## return 
                                                                                                                                      ## with 
                                                                                                                                      ## this 
                                                                                                                                      ## call.
  ##   
                                                                                                                                              ## principalId: JString
                                                                                                                                              ##              
                                                                                                                                              ## : 
                                                                                                                                              ## The 
                                                                                                                                              ## ID 
                                                                                                                                              ## of 
                                                                                                                                              ## the 
                                                                                                                                              ## principal 
                                                                                                                                              ## to 
                                                                                                                                              ## filter 
                                                                                                                                              ## permissions 
                                                                                                                                              ## by.
  section = newJObject()
  var valid_402656560 = query.getOrDefault("marker")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "marker", valid_402656560
  var valid_402656561 = query.getOrDefault("limit")
  valid_402656561 = validateParameter(valid_402656561, JInt, required = false,
                                      default = nil)
  if valid_402656561 != nil:
    section.add "limit", valid_402656561
  var valid_402656562 = query.getOrDefault("principalId")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "principalId", valid_402656562
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656563 = header.getOrDefault("Authentication")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "Authentication", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Security-Token", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Signature")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Signature", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Algorithm", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Date")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Date", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Credential")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Credential", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656571: Call_DescribeResourcePermissions_402656556;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the permissions of a specified resource.
                                                                                         ## 
  let valid = call_402656571.validator(path, query, header, formData, body, _)
  let scheme = call_402656571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656571.makeUrl(scheme.get, call_402656571.host, call_402656571.base,
                                   call_402656571.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656571, uri, valid, _)

proc call*(call_402656572: Call_DescribeResourcePermissions_402656556;
           ResourceId: string; marker: string = ""; limit: int = 0;
           principalId: string = ""): Recallable =
  ## describeResourcePermissions
  ## Describes the permissions of a specified resource.
  ##   marker: string
                                                       ##         : The marker for the next set of results. (You received this marker from a previous call)
  ##   
                                                                                                                                                           ## ResourceId: string (required)
                                                                                                                                                           ##             
                                                                                                                                                           ## : 
                                                                                                                                                           ## The 
                                                                                                                                                           ## ID 
                                                                                                                                                           ## of 
                                                                                                                                                           ## the 
                                                                                                                                                           ## resource.
  ##   
                                                                                                                                                                       ## limit: int
                                                                                                                                                                       ##        
                                                                                                                                                                       ## : 
                                                                                                                                                                       ## The 
                                                                                                                                                                       ## maximum 
                                                                                                                                                                       ## number 
                                                                                                                                                                       ## of 
                                                                                                                                                                       ## items 
                                                                                                                                                                       ## to 
                                                                                                                                                                       ## return 
                                                                                                                                                                       ## with 
                                                                                                                                                                       ## this 
                                                                                                                                                                       ## call.
  ##   
                                                                                                                                                                               ## principalId: string
                                                                                                                                                                               ##              
                                                                                                                                                                               ## : 
                                                                                                                                                                               ## The 
                                                                                                                                                                               ## ID 
                                                                                                                                                                               ## of 
                                                                                                                                                                               ## the 
                                                                                                                                                                               ## principal 
                                                                                                                                                                               ## to 
                                                                                                                                                                               ## filter 
                                                                                                                                                                               ## permissions 
                                                                                                                                                                               ## by.
  var path_402656573 = newJObject()
  var query_402656574 = newJObject()
  add(query_402656574, "marker", newJString(marker))
  add(path_402656573, "ResourceId", newJString(ResourceId))
  add(query_402656574, "limit", newJInt(limit))
  add(query_402656574, "principalId", newJString(principalId))
  result = call_402656572.call(path_402656573, query_402656574, nil, nil, nil)

var describeResourcePermissions* = Call_DescribeResourcePermissions_402656556(
    name: "describeResourcePermissions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_DescribeResourcePermissions_402656557, base: "/",
    makeUrl: url_DescribeResourcePermissions_402656558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAllResourcePermissions_402656592 = ref object of OpenApiRestCall_402656044
proc url_RemoveAllResourcePermissions_402656594(protocol: Scheme; host: string;
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

proc validate_RemoveAllResourcePermissions_402656593(path: JsonNode;
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
  var valid_402656595 = path.getOrDefault("ResourceId")
  valid_402656595 = validateParameter(valid_402656595, JString, required = true,
                                      default = nil)
  if valid_402656595 != nil:
    section.add "ResourceId", valid_402656595
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656596 = header.getOrDefault("Authentication")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "Authentication", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Security-Token", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Signature")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Signature", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Algorithm", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Date")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Date", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Credential")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Credential", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656604: Call_RemoveAllResourcePermissions_402656592;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes all the permissions from the specified resource.
                                                                                         ## 
  let valid = call_402656604.validator(path, query, header, formData, body, _)
  let scheme = call_402656604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656604.makeUrl(scheme.get, call_402656604.host, call_402656604.base,
                                   call_402656604.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656604, uri, valid, _)

proc call*(call_402656605: Call_RemoveAllResourcePermissions_402656592;
           ResourceId: string): Recallable =
  ## removeAllResourcePermissions
  ## Removes all the permissions from the specified resource.
  ##   ResourceId: string (required)
                                                             ##             : The ID of the resource.
  var path_402656606 = newJObject()
  add(path_402656606, "ResourceId", newJString(ResourceId))
  result = call_402656605.call(path_402656606, nil, nil, nil, nil)

var removeAllResourcePermissions* = Call_RemoveAllResourcePermissions_402656592(
    name: "removeAllResourcePermissions", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions",
    validator: validate_RemoveAllResourcePermissions_402656593, base: "/",
    makeUrl: url_RemoveAllResourcePermissions_402656594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComment_402656607 = ref object of OpenApiRestCall_402656044
proc url_CreateComment_402656609(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComment_402656608(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a new comment to the specified document version.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
                                 ##            : The ID of the document version.
  ##   
                                                                                ## DocumentId: JString (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## The 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## document.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `VersionId` field"
  var valid_402656610 = path.getOrDefault("VersionId")
  valid_402656610 = validateParameter(valid_402656610, JString, required = true,
                                      default = nil)
  if valid_402656610 != nil:
    section.add "VersionId", valid_402656610
  var valid_402656611 = path.getOrDefault("DocumentId")
  valid_402656611 = validateParameter(valid_402656611, JString, required = true,
                                      default = nil)
  if valid_402656611 != nil:
    section.add "DocumentId", valid_402656611
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("Authentication")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "Authentication", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
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

proc call*(call_402656621: Call_CreateComment_402656607; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new comment to the specified document version.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_CreateComment_402656607; body: JsonNode;
           VersionId: string; DocumentId: string): Recallable =
  ## createComment
  ## Adds a new comment to the specified document version.
  ##   body: JObject (required)
  ##   VersionId: string (required)
                               ##            : The ID of the document version.
  ##   
                                                                              ## DocumentId: string (required)
                                                                              ##             
                                                                              ## : 
                                                                              ## The 
                                                                              ## ID 
                                                                              ## of 
                                                                              ## the 
                                                                              ## document.
  var path_402656623 = newJObject()
  var body_402656624 = newJObject()
  if body != nil:
    body_402656624 = body
  add(path_402656623, "VersionId", newJString(VersionId))
  add(path_402656623, "DocumentId", newJString(DocumentId))
  result = call_402656622.call(path_402656623, nil, nil, nil, body_402656624)

var createComment* = Call_CreateComment_402656607(name: "createComment",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment",
    validator: validate_CreateComment_402656608, base: "/",
    makeUrl: url_CreateComment_402656609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCustomMetadata_402656625 = ref object of OpenApiRestCall_402656044
proc url_CreateCustomMetadata_402656627(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateCustomMetadata_402656626(path: JsonNode; query: JsonNode;
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
  var valid_402656628 = path.getOrDefault("ResourceId")
  valid_402656628 = validateParameter(valid_402656628, JString, required = true,
                                      default = nil)
  if valid_402656628 != nil:
    section.add "ResourceId", valid_402656628
  result.add "path", section
  ## parameters in `query` object:
  ##   versionid: JString
                                  ##            : The ID of the version, if the custom metadata is being added to a document version.
  section = newJObject()
  var valid_402656629 = query.getOrDefault("versionid")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "versionid", valid_402656629
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656630 = header.getOrDefault("Authentication")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "Authentication", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Security-Token", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Signature")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Signature", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Algorithm", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Date")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Date", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Credential")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Credential", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656637
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

proc call*(call_402656639: Call_CreateCustomMetadata_402656625;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
                                                                                         ## 
  let valid = call_402656639.validator(path, query, header, formData, body, _)
  let scheme = call_402656639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656639.makeUrl(scheme.get, call_402656639.host, call_402656639.base,
                                   call_402656639.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656639, uri, valid, _)

proc call*(call_402656640: Call_CreateCustomMetadata_402656625;
           ResourceId: string; body: JsonNode; versionid: string = ""): Recallable =
  ## createCustomMetadata
  ## Adds one or more custom properties to the specified resource (a folder, document, or version).
  ##   
                                                                                                   ## ResourceId: string (required)
                                                                                                   ##             
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## ID 
                                                                                                   ## of 
                                                                                                   ## the 
                                                                                                   ## resource.
  ##   
                                                                                                               ## body: JObject (required)
  ##   
                                                                                                                                          ## versionid: string
                                                                                                                                          ##            
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## ID 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## version, 
                                                                                                                                          ## if 
                                                                                                                                          ## the 
                                                                                                                                          ## custom 
                                                                                                                                          ## metadata 
                                                                                                                                          ## is 
                                                                                                                                          ## being 
                                                                                                                                          ## added 
                                                                                                                                          ## to 
                                                                                                                                          ## a 
                                                                                                                                          ## document 
                                                                                                                                          ## version.
  var path_402656641 = newJObject()
  var query_402656642 = newJObject()
  var body_402656643 = newJObject()
  add(path_402656641, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_402656643 = body
  add(query_402656642, "versionid", newJString(versionid))
  result = call_402656640.call(path_402656641, query_402656642, nil, nil, body_402656643)

var createCustomMetadata* = Call_CreateCustomMetadata_402656625(
    name: "createCustomMetadata", meth: HttpMethod.HttpPut,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_CreateCustomMetadata_402656626, base: "/",
    makeUrl: url_CreateCustomMetadata_402656627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCustomMetadata_402656644 = ref object of OpenApiRestCall_402656044
proc url_DeleteCustomMetadata_402656646(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteCustomMetadata_402656645(path: JsonNode; query: JsonNode;
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
  var valid_402656647 = path.getOrDefault("ResourceId")
  valid_402656647 = validateParameter(valid_402656647, JString, required = true,
                                      default = nil)
  if valid_402656647 != nil:
    section.add "ResourceId", valid_402656647
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
                                  ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  ##   
                                                                                                                                         ## deleteAll: JBool
                                                                                                                                         ##            
                                                                                                                                         ## : 
                                                                                                                                         ## Flag 
                                                                                                                                         ## to 
                                                                                                                                         ## indicate 
                                                                                                                                         ## removal 
                                                                                                                                         ## of 
                                                                                                                                         ## all 
                                                                                                                                         ## custom 
                                                                                                                                         ## metadata 
                                                                                                                                         ## properties 
                                                                                                                                         ## from 
                                                                                                                                         ## the 
                                                                                                                                         ## specified 
                                                                                                                                         ## resource.
  ##   
                                                                                                                                                     ## keys: JArray
                                                                                                                                                     ##       
                                                                                                                                                     ## : 
                                                                                                                                                     ## List 
                                                                                                                                                     ## of 
                                                                                                                                                     ## properties 
                                                                                                                                                     ## to 
                                                                                                                                                     ## remove.
  section = newJObject()
  var valid_402656648 = query.getOrDefault("versionId")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "versionId", valid_402656648
  var valid_402656649 = query.getOrDefault("deleteAll")
  valid_402656649 = validateParameter(valid_402656649, JBool, required = false,
                                      default = nil)
  if valid_402656649 != nil:
    section.add "deleteAll", valid_402656649
  var valid_402656650 = query.getOrDefault("keys")
  valid_402656650 = validateParameter(valid_402656650, JArray, required = false,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "keys", valid_402656650
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656651 = header.getOrDefault("Authentication")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "Authentication", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Security-Token", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Signature")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Signature", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Algorithm", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Date")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Date", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Credential")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Credential", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656659: Call_DeleteCustomMetadata_402656644;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes custom metadata from the specified resource.
                                                                                         ## 
  let valid = call_402656659.validator(path, query, header, formData, body, _)
  let scheme = call_402656659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656659.makeUrl(scheme.get, call_402656659.host, call_402656659.base,
                                   call_402656659.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656659, uri, valid, _)

proc call*(call_402656660: Call_DeleteCustomMetadata_402656644;
           ResourceId: string; versionId: string = ""; deleteAll: bool = false;
           keys: JsonNode = nil): Recallable =
  ## deleteCustomMetadata
  ## Deletes custom metadata from the specified resource.
  ##   versionId: string
                                                         ##            : The ID of the version, if the custom metadata is being deleted from a document version.
  ##   
                                                                                                                                                                ## deleteAll: bool
                                                                                                                                                                ##            
                                                                                                                                                                ## : 
                                                                                                                                                                ## Flag 
                                                                                                                                                                ## to 
                                                                                                                                                                ## indicate 
                                                                                                                                                                ## removal 
                                                                                                                                                                ## of 
                                                                                                                                                                ## all 
                                                                                                                                                                ## custom 
                                                                                                                                                                ## metadata 
                                                                                                                                                                ## properties 
                                                                                                                                                                ## from 
                                                                                                                                                                ## the 
                                                                                                                                                                ## specified 
                                                                                                                                                                ## resource.
  ##   
                                                                                                                                                                            ## ResourceId: string (required)
                                                                                                                                                                            ##             
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## The 
                                                                                                                                                                            ## ID 
                                                                                                                                                                            ## of 
                                                                                                                                                                            ## the 
                                                                                                                                                                            ## resource, 
                                                                                                                                                                            ## either 
                                                                                                                                                                            ## a 
                                                                                                                                                                            ## document 
                                                                                                                                                                            ## or 
                                                                                                                                                                            ## folder.
  ##   
                                                                                                                                                                                      ## keys: JArray
                                                                                                                                                                                      ##       
                                                                                                                                                                                      ## : 
                                                                                                                                                                                      ## List 
                                                                                                                                                                                      ## of 
                                                                                                                                                                                      ## properties 
                                                                                                                                                                                      ## to 
                                                                                                                                                                                      ## remove.
  var path_402656661 = newJObject()
  var query_402656662 = newJObject()
  add(query_402656662, "versionId", newJString(versionId))
  add(query_402656662, "deleteAll", newJBool(deleteAll))
  add(path_402656661, "ResourceId", newJString(ResourceId))
  if keys != nil:
    query_402656662.add "keys", keys
  result = call_402656660.call(path_402656661, query_402656662, nil, nil, nil)

var deleteCustomMetadata* = Call_DeleteCustomMetadata_402656644(
    name: "deleteCustomMetadata", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/customMetadata",
    validator: validate_DeleteCustomMetadata_402656645, base: "/",
    makeUrl: url_DeleteCustomMetadata_402656646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFolder_402656663 = ref object of OpenApiRestCall_402656044
proc url_CreateFolder_402656665(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFolder_402656664(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a folder with the specified name and parent folder.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656666 = header.getOrDefault("Authentication")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "Authentication", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Security-Token", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Signature")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Signature", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Algorithm", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Date")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Date", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Credential")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Credential", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656673
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

proc call*(call_402656675: Call_CreateFolder_402656663; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a folder with the specified name and parent folder.
                                                                                         ## 
  let valid = call_402656675.validator(path, query, header, formData, body, _)
  let scheme = call_402656675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656675.makeUrl(scheme.get, call_402656675.host, call_402656675.base,
                                   call_402656675.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656675, uri, valid, _)

proc call*(call_402656676: Call_CreateFolder_402656663; body: JsonNode): Recallable =
  ## createFolder
  ## Creates a folder with the specified name and parent folder.
  ##   body: JObject (required)
  var body_402656677 = newJObject()
  if body != nil:
    body_402656677 = body
  result = call_402656676.call(nil, nil, nil, nil, body_402656677)

var createFolder* = Call_CreateFolder_402656663(name: "createFolder",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders", validator: validate_CreateFolder_402656664,
    base: "/", makeUrl: url_CreateFolder_402656665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabels_402656678 = ref object of OpenApiRestCall_402656044
proc url_CreateLabels_402656680(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLabels_402656679(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656681 = path.getOrDefault("ResourceId")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "ResourceId", valid_402656681
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656682 = header.getOrDefault("Authentication")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "Authentication", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Security-Token", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Signature")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Signature", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Algorithm", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Date")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Date", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Credential")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Credential", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656689
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

proc call*(call_402656691: Call_CreateLabels_402656678; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified list of labels to the given resource (a document or folder)
                                                                                         ## 
  let valid = call_402656691.validator(path, query, header, formData, body, _)
  let scheme = call_402656691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656691.makeUrl(scheme.get, call_402656691.host, call_402656691.base,
                                   call_402656691.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656691, uri, valid, _)

proc call*(call_402656692: Call_CreateLabels_402656678; ResourceId: string;
           body: JsonNode): Recallable =
  ## createLabels
  ## Adds the specified list of labels to the given resource (a document or folder)
  ##   
                                                                                   ## ResourceId: string (required)
                                                                                   ##             
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## ID 
                                                                                   ## of 
                                                                                   ## the 
                                                                                   ## resource.
  ##   
                                                                                               ## body: JObject (required)
  var path_402656693 = newJObject()
  var body_402656694 = newJObject()
  add(path_402656693, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_402656694 = body
  result = call_402656692.call(path_402656693, nil, nil, nil, body_402656694)

var createLabels* = Call_CreateLabels_402656678(name: "createLabels",
    meth: HttpMethod.HttpPut, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_CreateLabels_402656679, base: "/",
    makeUrl: url_CreateLabels_402656680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLabels_402656695 = ref object of OpenApiRestCall_402656044
proc url_DeleteLabels_402656697(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLabels_402656696(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656698 = path.getOrDefault("ResourceId")
  valid_402656698 = validateParameter(valid_402656698, JString, required = true,
                                      default = nil)
  if valid_402656698 != nil:
    section.add "ResourceId", valid_402656698
  result.add "path", section
  ## parameters in `query` object:
  ##   deleteAll: JBool
                                  ##            : Flag to request removal of all labels from the specified resource.
  ##   
                                                                                                                    ## labels: JArray
                                                                                                                    ##         
                                                                                                                    ## : 
                                                                                                                    ## List 
                                                                                                                    ## of 
                                                                                                                    ## labels 
                                                                                                                    ## to 
                                                                                                                    ## delete 
                                                                                                                    ## from 
                                                                                                                    ## the 
                                                                                                                    ## resource.
  section = newJObject()
  var valid_402656699 = query.getOrDefault("deleteAll")
  valid_402656699 = validateParameter(valid_402656699, JBool, required = false,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "deleteAll", valid_402656699
  var valid_402656700 = query.getOrDefault("labels")
  valid_402656700 = validateParameter(valid_402656700, JArray, required = false,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "labels", valid_402656700
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656701 = header.getOrDefault("Authentication")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "Authentication", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Security-Token", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Signature")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Signature", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Algorithm", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Date")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Date", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Credential")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Credential", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656709: Call_DeleteLabels_402656695; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified list of labels from a resource.
                                                                                         ## 
  let valid = call_402656709.validator(path, query, header, formData, body, _)
  let scheme = call_402656709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656709.makeUrl(scheme.get, call_402656709.host, call_402656709.base,
                                   call_402656709.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656709, uri, valid, _)

proc call*(call_402656710: Call_DeleteLabels_402656695; ResourceId: string;
           deleteAll: bool = false; labels: JsonNode = nil): Recallable =
  ## deleteLabels
  ## Deletes the specified list of labels from a resource.
  ##   deleteAll: bool
                                                          ##            : Flag to request removal of all labels from the specified resource.
  ##   
                                                                                                                                            ## ResourceId: string (required)
                                                                                                                                            ##             
                                                                                                                                            ## : 
                                                                                                                                            ## The 
                                                                                                                                            ## ID 
                                                                                                                                            ## of 
                                                                                                                                            ## the 
                                                                                                                                            ## resource.
  ##   
                                                                                                                                                        ## labels: JArray
                                                                                                                                                        ##         
                                                                                                                                                        ## : 
                                                                                                                                                        ## List 
                                                                                                                                                        ## of 
                                                                                                                                                        ## labels 
                                                                                                                                                        ## to 
                                                                                                                                                        ## delete 
                                                                                                                                                        ## from 
                                                                                                                                                        ## the 
                                                                                                                                                        ## resource.
  var path_402656711 = newJObject()
  var query_402656712 = newJObject()
  add(query_402656712, "deleteAll", newJBool(deleteAll))
  add(path_402656711, "ResourceId", newJString(ResourceId))
  if labels != nil:
    query_402656712.add "labels", labels
  result = call_402656710.call(path_402656711, query_402656712, nil, nil, nil)

var deleteLabels* = Call_DeleteLabels_402656695(name: "deleteLabels",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/labels",
    validator: validate_DeleteLabels_402656696, base: "/",
    makeUrl: url_DeleteLabels_402656697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotificationSubscription_402656730 = ref object of OpenApiRestCall_402656044
proc url_CreateNotificationSubscription_402656732(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path,
         "`OrganizationId` is a required path parameter"
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

proc validate_CreateNotificationSubscription_402656731(path: JsonNode;
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
  var valid_402656733 = path.getOrDefault("OrganizationId")
  valid_402656733 = validateParameter(valid_402656733, JString, required = true,
                                      default = nil)
  if valid_402656733 != nil:
    section.add "OrganizationId", valid_402656733
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656734 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Security-Token", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Signature")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Signature", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Algorithm", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Date")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Date", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Credential")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Credential", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656740
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

proc call*(call_402656742: Call_CreateNotificationSubscription_402656730;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656742.validator(path, query, header, formData, body, _)
  let scheme = call_402656742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656742.makeUrl(scheme.get, call_402656742.host, call_402656742.base,
                                   call_402656742.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656742, uri, valid, _)

proc call*(call_402656743: Call_CreateNotificationSubscription_402656730;
           OrganizationId: string; body: JsonNode): Recallable =
  ## createNotificationSubscription
  ## <p>Configure Amazon WorkDocs to use Amazon SNS notifications. The endpoint receives a confirmation message, and must confirm the subscription.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/subscribe-notifications.html">Subscribe to Notifications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                        ## OrganizationId: string (required)
                                                                                                                                                                                                                                                                                                                                                                        ##                 
                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                        ## ID 
                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                        ## organization.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var path_402656744 = newJObject()
  var body_402656745 = newJObject()
  add(path_402656744, "OrganizationId", newJString(OrganizationId))
  if body != nil:
    body_402656745 = body
  result = call_402656743.call(path_402656744, nil, nil, nil, body_402656745)

var createNotificationSubscription* = Call_CreateNotificationSubscription_402656730(
    name: "createNotificationSubscription", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_CreateNotificationSubscription_402656731, base: "/",
    makeUrl: url_CreateNotificationSubscription_402656732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationSubscriptions_402656713 = ref object of OpenApiRestCall_402656044
proc url_DescribeNotificationSubscriptions_402656715(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path,
         "`OrganizationId` is a required path parameter"
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

proc validate_DescribeNotificationSubscriptions_402656714(path: JsonNode;
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
  var valid_402656716 = path.getOrDefault("OrganizationId")
  valid_402656716 = validateParameter(valid_402656716, JString, required = true,
                                      default = nil)
  if valid_402656716 != nil:
    section.add "OrganizationId", valid_402656716
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
                                  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   
                                                                                                                                       ## limit: JInt
                                                                                                                                       ##        
                                                                                                                                       ## : 
                                                                                                                                       ## The 
                                                                                                                                       ## maximum 
                                                                                                                                       ## number 
                                                                                                                                       ## of 
                                                                                                                                       ## items 
                                                                                                                                       ## to 
                                                                                                                                       ## return 
                                                                                                                                       ## with 
                                                                                                                                       ## this 
                                                                                                                                       ## call.
  section = newJObject()
  var valid_402656717 = query.getOrDefault("marker")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "marker", valid_402656717
  var valid_402656718 = query.getOrDefault("limit")
  valid_402656718 = validateParameter(valid_402656718, JInt, required = false,
                                      default = nil)
  if valid_402656718 != nil:
    section.add "limit", valid_402656718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656719 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Security-Token", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Signature")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Signature", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Algorithm", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Date")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Date", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Credential")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Credential", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656726: Call_DescribeNotificationSubscriptions_402656713;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the specified notification subscriptions.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_DescribeNotificationSubscriptions_402656713;
           OrganizationId: string; marker: string = ""; limit: int = 0): Recallable =
  ## describeNotificationSubscriptions
  ## Lists the specified notification subscriptions.
  ##   OrganizationId: string (required)
                                                    ##                 : The ID of the organization.
  ##   
                                                                                                    ## marker: string
                                                                                                    ##         
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## marker 
                                                                                                    ## for 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## set 
                                                                                                    ## of 
                                                                                                    ## results. 
                                                                                                    ## (You 
                                                                                                    ## received 
                                                                                                    ## this 
                                                                                                    ## marker 
                                                                                                    ## from 
                                                                                                    ## a 
                                                                                                    ## previous 
                                                                                                    ## call.)
  ##   
                                                                                                             ## limit: int
                                                                                                             ##        
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## maximum 
                                                                                                             ## number 
                                                                                                             ## of 
                                                                                                             ## items 
                                                                                                             ## to 
                                                                                                             ## return 
                                                                                                             ## with 
                                                                                                             ## this 
                                                                                                             ## call.
  var path_402656728 = newJObject()
  var query_402656729 = newJObject()
  add(path_402656728, "OrganizationId", newJString(OrganizationId))
  add(query_402656729, "marker", newJString(marker))
  add(query_402656729, "limit", newJInt(limit))
  result = call_402656727.call(path_402656728, query_402656729, nil, nil, nil)

var describeNotificationSubscriptions* = Call_DescribeNotificationSubscriptions_402656713(
    name: "describeNotificationSubscriptions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/organizations/{OrganizationId}/subscriptions",
    validator: validate_DescribeNotificationSubscriptions_402656714, base: "/",
    makeUrl: url_DescribeNotificationSubscriptions_402656715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_402656783 = ref object of OpenApiRestCall_402656044
proc url_CreateUser_402656785(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_402656784(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656786 = header.getOrDefault("Authentication")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "Authentication", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Security-Token", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Signature")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Signature", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Algorithm", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Date")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Date", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Credential")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Credential", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656793
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

proc call*(call_402656795: Call_CreateUser_402656783; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
                                                                                         ## 
  let valid = call_402656795.validator(path, query, header, formData, body, _)
  let scheme = call_402656795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656795.makeUrl(scheme.get, call_402656795.host, call_402656795.base,
                                   call_402656795.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656795, uri, valid, _)

proc call*(call_402656796: Call_CreateUser_402656783; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user in a Simple AD or Microsoft AD directory. The status of a newly created user is "ACTIVE". New users can access Amazon WorkDocs.
  ##   
                                                                                                                                                   ## body: JObject (required)
  var body_402656797 = newJObject()
  if body != nil:
    body_402656797 = body
  result = call_402656796.call(nil, nil, nil, nil, body_402656797)

var createUser* = Call_CreateUser_402656783(name: "createUser",
    meth: HttpMethod.HttpPost, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_CreateUser_402656784, base: "/",
    makeUrl: url_CreateUser_402656785, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUsers_402656746 = ref object of OpenApiRestCall_402656044
proc url_DescribeUsers_402656748(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUsers_402656747(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
                                  ##         : A comma-separated list of values. Specify "STORAGE_METADATA" to include the user storage quota and utilization information.
  ##   
                                                                                                                                                                          ## marker: JString
                                                                                                                                                                          ##         
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## The 
                                                                                                                                                                          ## marker 
                                                                                                                                                                          ## for 
                                                                                                                                                                          ## the 
                                                                                                                                                                          ## next 
                                                                                                                                                                          ## set 
                                                                                                                                                                          ## of 
                                                                                                                                                                          ## results. 
                                                                                                                                                                          ## (You 
                                                                                                                                                                          ## received 
                                                                                                                                                                          ## this 
                                                                                                                                                                          ## marker 
                                                                                                                                                                          ## from 
                                                                                                                                                                          ## a 
                                                                                                                                                                          ## previous 
                                                                                                                                                                          ## call.)
  ##   
                                                                                                                                                                                   ## Marker: JString
                                                                                                                                                                                   ##         
                                                                                                                                                                                   ## : 
                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                   ## token
  ##   
                                                                                                                                                                                           ## query: JString
                                                                                                                                                                                           ##        
                                                                                                                                                                                           ## : 
                                                                                                                                                                                           ## A 
                                                                                                                                                                                           ## query 
                                                                                                                                                                                           ## to 
                                                                                                                                                                                           ## filter 
                                                                                                                                                                                           ## users 
                                                                                                                                                                                           ## by 
                                                                                                                                                                                           ## user 
                                                                                                                                                                                           ## name.
  ##   
                                                                                                                                                                                                   ## order: JString
                                                                                                                                                                                                   ##        
                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                   ## order 
                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## results.
  ##   
                                                                                                                                                                                                              ## organizationId: JString
                                                                                                                                                                                                              ##                 
                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                              ## organization.
  ##   
                                                                                                                                                                                                                              ## userIds: JString
                                                                                                                                                                                                                              ##          
                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                              ## IDs 
                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                              ## users.
  ##   
                                                                                                                                                                                                                                       ## sort: JString
                                                                                                                                                                                                                                       ##       
                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                       ## sorting 
                                                                                                                                                                                                                                       ## criteria.
  ##   
                                                                                                                                                                                                                                                   ## limit: JInt
                                                                                                                                                                                                                                                   ##        
                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                   ## maximum 
                                                                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                   ## items 
                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                   ## return.
  ##   
                                                                                                                                                                                                                                                             ## Limit: JString
                                                                                                                                                                                                                                                             ##        
                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                     ## include: JString
                                                                                                                                                                                                                                                                     ##          
                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                     ## state 
                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                     ## users. 
                                                                                                                                                                                                                                                                     ## Specify 
                                                                                                                                                                                                                                                                     ## "ALL" 
                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                     ## include 
                                                                                                                                                                                                                                                                     ## inactive 
                                                                                                                                                                                                                                                                     ## users.
  section = newJObject()
  var valid_402656749 = query.getOrDefault("fields")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "fields", valid_402656749
  var valid_402656750 = query.getOrDefault("marker")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "marker", valid_402656750
  var valid_402656751 = query.getOrDefault("Marker")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "Marker", valid_402656751
  var valid_402656752 = query.getOrDefault("query")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "query", valid_402656752
  var valid_402656765 = query.getOrDefault("order")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false,
                                      default = newJString("ASCENDING"))
  if valid_402656765 != nil:
    section.add "order", valid_402656765
  var valid_402656766 = query.getOrDefault("organizationId")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "organizationId", valid_402656766
  var valid_402656767 = query.getOrDefault("userIds")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "userIds", valid_402656767
  var valid_402656768 = query.getOrDefault("sort")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false,
                                      default = newJString("USER_NAME"))
  if valid_402656768 != nil:
    section.add "sort", valid_402656768
  var valid_402656769 = query.getOrDefault("limit")
  valid_402656769 = validateParameter(valid_402656769, JInt, required = false,
                                      default = nil)
  if valid_402656769 != nil:
    section.add "limit", valid_402656769
  var valid_402656770 = query.getOrDefault("Limit")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "Limit", valid_402656770
  var valid_402656771 = query.getOrDefault("include")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false,
                                      default = newJString("ALL"))
  if valid_402656771 != nil:
    section.add "include", valid_402656771
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656772 = header.getOrDefault("Authentication")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "Authentication", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Security-Token", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Signature")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Signature", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Algorithm", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Date")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Date", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Credential")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Credential", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656780: Call_DescribeUsers_402656746; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
                                                                                         ## 
  let valid = call_402656780.validator(path, query, header, formData, body, _)
  let scheme = call_402656780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656780.makeUrl(scheme.get, call_402656780.host, call_402656780.base,
                                   call_402656780.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656780, uri, valid, _)

proc call*(call_402656781: Call_DescribeUsers_402656746; fields: string = "";
           marker: string = ""; Marker: string = ""; query: string = "";
           order: string = "ASCENDING"; organizationId: string = "";
           userIds: string = ""; sort: string = "USER_NAME"; limit: int = 0;
           Limit: string = ""; `include`: string = "ALL"): Recallable =
  ## describeUsers
  ## <p>Describes the specified users. You can describe all users or filter the results (for example, by status or organization).</p> <p>By default, Amazon WorkDocs returns the first 24 active or pending users. If there are more results, the response includes a marker that you can use to request the next set of results.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                     ## fields: string
                                                                                                                                                                                                                                                                                                                                     ##         
                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                     ## comma-separated 
                                                                                                                                                                                                                                                                                                                                     ## list 
                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                     ## values. 
                                                                                                                                                                                                                                                                                                                                     ## Specify 
                                                                                                                                                                                                                                                                                                                                     ## "STORAGE_METADATA" 
                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                     ## include 
                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                     ## user 
                                                                                                                                                                                                                                                                                                                                     ## storage 
                                                                                                                                                                                                                                                                                                                                     ## quota 
                                                                                                                                                                                                                                                                                                                                     ## and 
                                                                                                                                                                                                                                                                                                                                     ## utilization 
                                                                                                                                                                                                                                                                                                                                     ## information.
  ##   
                                                                                                                                                                                                                                                                                                                                                    ## marker: string
                                                                                                                                                                                                                                                                                                                                                    ##         
                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                    ## marker 
                                                                                                                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                    ## next 
                                                                                                                                                                                                                                                                                                                                                    ## set 
                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                    ## results. 
                                                                                                                                                                                                                                                                                                                                                    ## (You 
                                                                                                                                                                                                                                                                                                                                                    ## received 
                                                                                                                                                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                                                                                                                                                    ## marker 
                                                                                                                                                                                                                                                                                                                                                    ## from 
                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                    ## previous 
                                                                                                                                                                                                                                                                                                                                                    ## call.)
  ##   
                                                                                                                                                                                                                                                                                                                                                             ## Marker: string
                                                                                                                                                                                                                                                                                                                                                             ##         
                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                             ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                     ## query: string
                                                                                                                                                                                                                                                                                                                                                                     ##        
                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                                                     ## query 
                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                     ## filter 
                                                                                                                                                                                                                                                                                                                                                                     ## users 
                                                                                                                                                                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                                                                                                                                                                     ## user 
                                                                                                                                                                                                                                                                                                                                                                     ## name.
  ##   
                                                                                                                                                                                                                                                                                                                                                                             ## order: string
                                                                                                                                                                                                                                                                                                                                                                             ##        
                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                                                                                                             ## order 
                                                                                                                                                                                                                                                                                                                                                                             ## for 
                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                             ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                        ## organizationId: string
                                                                                                                                                                                                                                                                                                                                                                                        ##                 
                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                        ## ID 
                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                        ## organization.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                        ## userIds: string
                                                                                                                                                                                                                                                                                                                                                                                                        ##          
                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                        ## IDs 
                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                        ## users.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                 ## sort: string
                                                                                                                                                                                                                                                                                                                                                                                                                 ##       
                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                 ## sorting 
                                                                                                                                                                                                                                                                                                                                                                                                                 ## criteria.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                             ## limit: int
                                                                                                                                                                                                                                                                                                                                                                                                                             ##        
                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## items 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## return.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Limit: string
                                                                                                                                                                                                                                                                                                                                                                                                                                       ##        
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## include: string
                                                                                                                                                                                                                                                                                                                                                                                                                                               ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## state 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## users. 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## "ALL" 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## include 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## inactive 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## users.
  var query_402656782 = newJObject()
  add(query_402656782, "fields", newJString(fields))
  add(query_402656782, "marker", newJString(marker))
  add(query_402656782, "Marker", newJString(Marker))
  add(query_402656782, "query", newJString(query))
  add(query_402656782, "order", newJString(order))
  add(query_402656782, "organizationId", newJString(organizationId))
  add(query_402656782, "userIds", newJString(userIds))
  add(query_402656782, "sort", newJString(sort))
  add(query_402656782, "limit", newJInt(limit))
  add(query_402656782, "Limit", newJString(Limit))
  add(query_402656782, "include", newJString(`include`))
  result = call_402656781.call(nil, query_402656782, nil, nil, nil)

var describeUsers* = Call_DescribeUsers_402656746(name: "describeUsers",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/users", validator: validate_DescribeUsers_402656747,
    base: "/", makeUrl: url_DescribeUsers_402656748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComment_402656798 = ref object of OpenApiRestCall_402656044
proc url_DeleteComment_402656800(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteComment_402656799(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified comment from the document version.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CommentId: JString (required)
                                 ##            : The ID of the comment.
  ##   
                                                                       ## VersionId: JString (required)
                                                                       ##            
                                                                       ## : 
                                                                       ## The ID of the 
                                                                       ## document 
                                                                       ## version.
  ##   
                                                                                  ## DocumentId: JString (required)
                                                                                  ##             
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## ID 
                                                                                  ## of 
                                                                                  ## the 
                                                                                  ## document.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `CommentId` field"
  var valid_402656801 = path.getOrDefault("CommentId")
  valid_402656801 = validateParameter(valid_402656801, JString, required = true,
                                      default = nil)
  if valid_402656801 != nil:
    section.add "CommentId", valid_402656801
  var valid_402656802 = path.getOrDefault("VersionId")
  valid_402656802 = validateParameter(valid_402656802, JString, required = true,
                                      default = nil)
  if valid_402656802 != nil:
    section.add "VersionId", valid_402656802
  var valid_402656803 = path.getOrDefault("DocumentId")
  valid_402656803 = validateParameter(valid_402656803, JString, required = true,
                                      default = nil)
  if valid_402656803 != nil:
    section.add "DocumentId", valid_402656803
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656804 = header.getOrDefault("Authentication")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "Authentication", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Security-Token", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Signature")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Signature", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Algorithm", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Date")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Date", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Credential")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Credential", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656812: Call_DeleteComment_402656798; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified comment from the document version.
                                                                                         ## 
  let valid = call_402656812.validator(path, query, header, formData, body, _)
  let scheme = call_402656812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656812.makeUrl(scheme.get, call_402656812.host, call_402656812.base,
                                   call_402656812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656812, uri, valid, _)

proc call*(call_402656813: Call_DeleteComment_402656798; CommentId: string;
           VersionId: string; DocumentId: string): Recallable =
  ## deleteComment
  ## Deletes the specified comment from the document version.
  ##   CommentId: string (required)
                                                             ##            : The ID of the comment.
  ##   
                                                                                                   ## VersionId: string (required)
                                                                                                   ##            
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## ID 
                                                                                                   ## of 
                                                                                                   ## the 
                                                                                                   ## document 
                                                                                                   ## version.
  ##   
                                                                                                              ## DocumentId: string (required)
                                                                                                              ##             
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## ID 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## document.
  var path_402656814 = newJObject()
  add(path_402656814, "CommentId", newJString(CommentId))
  add(path_402656814, "VersionId", newJString(VersionId))
  add(path_402656814, "DocumentId", newJString(DocumentId))
  result = call_402656813.call(path_402656814, nil, nil, nil, nil)

var deleteComment* = Call_DeleteComment_402656798(name: "deleteComment",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com", route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comment/{CommentId}",
    validator: validate_DeleteComment_402656799, base: "/",
    makeUrl: url_DeleteComment_402656800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_402656815 = ref object of OpenApiRestCall_402656044
proc url_GetDocument_402656817(protocol: Scheme; host: string; base: string;
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

proc validate_GetDocument_402656816(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656818 = path.getOrDefault("DocumentId")
  valid_402656818 = validateParameter(valid_402656818, JString, required = true,
                                      default = nil)
  if valid_402656818 != nil:
    section.add "DocumentId", valid_402656818
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
                                  ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  section = newJObject()
  var valid_402656819 = query.getOrDefault("includeCustomMetadata")
  valid_402656819 = validateParameter(valid_402656819, JBool, required = false,
                                      default = nil)
  if valid_402656819 != nil:
    section.add "includeCustomMetadata", valid_402656819
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656820 = header.getOrDefault("Authentication")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "Authentication", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Security-Token", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Signature")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Signature", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Algorithm", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Date")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Date", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Credential")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Credential", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656828: Call_GetDocument_402656815; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details of a document.
                                                                                         ## 
  let valid = call_402656828.validator(path, query, header, formData, body, _)
  let scheme = call_402656828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656828.makeUrl(scheme.get, call_402656828.host, call_402656828.base,
                                   call_402656828.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656828, uri, valid, _)

proc call*(call_402656829: Call_GetDocument_402656815; DocumentId: string;
           includeCustomMetadata: bool = false): Recallable =
  ## getDocument
  ## Retrieves details of a document.
  ##   includeCustomMetadata: bool
                                     ##                        : Set this to <code>TRUE</code> to include custom metadata in the response.
  ##   
                                                                                                                                          ## DocumentId: string (required)
                                                                                                                                          ##             
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## ID 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## document.
  var path_402656830 = newJObject()
  var query_402656831 = newJObject()
  add(query_402656831, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_402656830, "DocumentId", newJString(DocumentId))
  result = call_402656829.call(path_402656830, query_402656831, nil, nil, nil)

var getDocument* = Call_GetDocument_402656815(name: "getDocument",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_GetDocument_402656816,
    base: "/", makeUrl: url_GetDocument_402656817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_402656847 = ref object of OpenApiRestCall_402656044
proc url_UpdateDocument_402656849(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDocument_402656848(path: JsonNode; query: JsonNode;
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
  var valid_402656850 = path.getOrDefault("DocumentId")
  valid_402656850 = validateParameter(valid_402656850, JString, required = true,
                                      default = nil)
  if valid_402656850 != nil:
    section.add "DocumentId", valid_402656850
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656851 = header.getOrDefault("Authentication")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "Authentication", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Security-Token", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Signature")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Signature", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Algorithm", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Date")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Date", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Credential")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Credential", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656858
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

proc call*(call_402656860: Call_UpdateDocument_402656847; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
                                                                                         ## 
  let valid = call_402656860.validator(path, query, header, formData, body, _)
  let scheme = call_402656860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656860.makeUrl(scheme.get, call_402656860.host, call_402656860.base,
                                   call_402656860.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656860, uri, valid, _)

proc call*(call_402656861: Call_UpdateDocument_402656847; body: JsonNode;
           DocumentId: string): Recallable =
  ## updateDocument
  ## Updates the specified attributes of a document. The user must have access to both the document and its parent folder, if applicable.
  ##   
                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                    ## DocumentId: string (required)
                                                                                                                                                                    ##             
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## The 
                                                                                                                                                                    ## ID 
                                                                                                                                                                    ## of 
                                                                                                                                                                    ## the 
                                                                                                                                                                    ## document.
  var path_402656862 = newJObject()
  var body_402656863 = newJObject()
  if body != nil:
    body_402656863 = body
  add(path_402656862, "DocumentId", newJString(DocumentId))
  result = call_402656861.call(path_402656862, nil, nil, nil, body_402656863)

var updateDocument* = Call_UpdateDocument_402656847(name: "updateDocument",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_UpdateDocument_402656848,
    base: "/", makeUrl: url_UpdateDocument_402656849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_402656832 = ref object of OpenApiRestCall_402656044
proc url_DeleteDocument_402656834(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDocument_402656833(path: JsonNode; query: JsonNode;
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
  var valid_402656835 = path.getOrDefault("DocumentId")
  valid_402656835 = validateParameter(valid_402656835, JString, required = true,
                                      default = nil)
  if valid_402656835 != nil:
    section.add "DocumentId", valid_402656835
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656836 = header.getOrDefault("Authentication")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "Authentication", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Security-Token", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Signature")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Signature", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Algorithm", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Date")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Date", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Credential")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Credential", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656844: Call_DeleteDocument_402656832; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes the specified document and its associated metadata.
                                                                                         ## 
  let valid = call_402656844.validator(path, query, header, formData, body, _)
  let scheme = call_402656844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656844.makeUrl(scheme.get, call_402656844.host, call_402656844.base,
                                   call_402656844.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656844, uri, valid, _)

proc call*(call_402656845: Call_DeleteDocument_402656832; DocumentId: string): Recallable =
  ## deleteDocument
  ## Permanently deletes the specified document and its associated metadata.
  ##   
                                                                            ## DocumentId: string (required)
                                                                            ##             
                                                                            ## : 
                                                                            ## The 
                                                                            ## ID 
                                                                            ## of 
                                                                            ## the 
                                                                            ## document.
  var path_402656846 = newJObject()
  add(path_402656846, "DocumentId", newJString(DocumentId))
  result = call_402656845.call(path_402656846, nil, nil, nil, nil)

var deleteDocument* = Call_DeleteDocument_402656832(name: "deleteDocument",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}", validator: validate_DeleteDocument_402656833,
    base: "/", makeUrl: url_DeleteDocument_402656834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_402656864 = ref object of OpenApiRestCall_402656044
proc url_GetFolder_402656866(protocol: Scheme; host: string; base: string;
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

proc validate_GetFolder_402656865(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the metadata of the specified folder.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
                                 ##           : The ID of the folder.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `FolderId` field"
  var valid_402656867 = path.getOrDefault("FolderId")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true,
                                      default = nil)
  if valid_402656867 != nil:
    section.add "FolderId", valid_402656867
  result.add "path", section
  ## parameters in `query` object:
  ##   includeCustomMetadata: JBool
                                  ##                        : Set to TRUE to include custom metadata in the response.
  section = newJObject()
  var valid_402656868 = query.getOrDefault("includeCustomMetadata")
  valid_402656868 = validateParameter(valid_402656868, JBool, required = false,
                                      default = nil)
  if valid_402656868 != nil:
    section.add "includeCustomMetadata", valid_402656868
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656869 = header.getOrDefault("Authentication")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "Authentication", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Security-Token", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Signature")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Signature", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Algorithm", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Date")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Date", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Credential")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Credential", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656877: Call_GetFolder_402656864; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the metadata of the specified folder.
                                                                                         ## 
  let valid = call_402656877.validator(path, query, header, formData, body, _)
  let scheme = call_402656877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656877.makeUrl(scheme.get, call_402656877.host, call_402656877.base,
                                   call_402656877.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656877, uri, valid, _)

proc call*(call_402656878: Call_GetFolder_402656864; FolderId: string;
           includeCustomMetadata: bool = false): Recallable =
  ## getFolder
  ## Retrieves the metadata of the specified folder.
  ##   includeCustomMetadata: bool
                                                    ##                        : Set to TRUE to include custom metadata in the response.
  ##   
                                                                                                                                       ## FolderId: string (required)
                                                                                                                                       ##           
                                                                                                                                       ## : 
                                                                                                                                       ## The 
                                                                                                                                       ## ID 
                                                                                                                                       ## of 
                                                                                                                                       ## the 
                                                                                                                                       ## folder.
  var path_402656879 = newJObject()
  var query_402656880 = newJObject()
  add(query_402656880, "includeCustomMetadata", newJBool(includeCustomMetadata))
  add(path_402656879, "FolderId", newJString(FolderId))
  result = call_402656878.call(path_402656879, query_402656880, nil, nil, nil)

var getFolder* = Call_GetFolder_402656864(name: "getFolder",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_GetFolder_402656865,
    base: "/", makeUrl: url_GetFolder_402656866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFolder_402656896 = ref object of OpenApiRestCall_402656044
proc url_UpdateFolder_402656898(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFolder_402656897(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
                                 ##           : The ID of the folder.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `FolderId` field"
  var valid_402656899 = path.getOrDefault("FolderId")
  valid_402656899 = validateParameter(valid_402656899, JString, required = true,
                                      default = nil)
  if valid_402656899 != nil:
    section.add "FolderId", valid_402656899
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656900 = header.getOrDefault("Authentication")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "Authentication", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Security-Token", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Signature")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Signature", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Algorithm", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Date")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Date", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Credential")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Credential", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656907
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

proc call*(call_402656909: Call_UpdateFolder_402656896; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
                                                                                         ## 
  let valid = call_402656909.validator(path, query, header, formData, body, _)
  let scheme = call_402656909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656909.makeUrl(scheme.get, call_402656909.host, call_402656909.base,
                                   call_402656909.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656909, uri, valid, _)

proc call*(call_402656910: Call_UpdateFolder_402656896; body: JsonNode;
           FolderId: string): Recallable =
  ## updateFolder
  ## Updates the specified attributes of the specified folder. The user must have access to both the folder and its parent folder, if applicable.
  ##   
                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                            ## FolderId: string (required)
                                                                                                                                                                            ##           
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## The 
                                                                                                                                                                            ## ID 
                                                                                                                                                                            ## of 
                                                                                                                                                                            ## the 
                                                                                                                                                                            ## folder.
  var path_402656911 = newJObject()
  var body_402656912 = newJObject()
  if body != nil:
    body_402656912 = body
  add(path_402656911, "FolderId", newJString(FolderId))
  result = call_402656910.call(path_402656911, nil, nil, nil, body_402656912)

var updateFolder* = Call_UpdateFolder_402656896(name: "updateFolder",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_UpdateFolder_402656897,
    base: "/", makeUrl: url_UpdateFolder_402656898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolder_402656881 = ref object of OpenApiRestCall_402656044
proc url_DeleteFolder_402656883(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFolder_402656882(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Permanently deletes the specified folder and its contents.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
                                 ##           : The ID of the folder.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `FolderId` field"
  var valid_402656884 = path.getOrDefault("FolderId")
  valid_402656884 = validateParameter(valid_402656884, JString, required = true,
                                      default = nil)
  if valid_402656884 != nil:
    section.add "FolderId", valid_402656884
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656885 = header.getOrDefault("Authentication")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "Authentication", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Security-Token", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Signature")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Signature", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Algorithm", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Date")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Date", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Credential")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Credential", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656893: Call_DeleteFolder_402656881; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes the specified folder and its contents.
                                                                                         ## 
  let valid = call_402656893.validator(path, query, header, formData, body, _)
  let scheme = call_402656893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656893.makeUrl(scheme.get, call_402656893.host, call_402656893.base,
                                   call_402656893.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656893, uri, valid, _)

proc call*(call_402656894: Call_DeleteFolder_402656881; FolderId: string): Recallable =
  ## deleteFolder
  ## Permanently deletes the specified folder and its contents.
  ##   FolderId: string (required)
                                                               ##           : The ID of the folder.
  var path_402656895 = newJObject()
  add(path_402656895, "FolderId", newJString(FolderId))
  result = call_402656894.call(path_402656895, nil, nil, nil, nil)

var deleteFolder* = Call_DeleteFolder_402656881(name: "deleteFolder",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}", validator: validate_DeleteFolder_402656882,
    base: "/", makeUrl: url_DeleteFolder_402656883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFolderContents_402656913 = ref object of OpenApiRestCall_402656044
proc url_DescribeFolderContents_402656915(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeFolderContents_402656914(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `FolderId` field"
  var valid_402656916 = path.getOrDefault("FolderId")
  valid_402656916 = validateParameter(valid_402656916, JString, required = true,
                                      default = nil)
  if valid_402656916 != nil:
    section.add "FolderId", valid_402656916
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
                                  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   
                                                                                                                                     ## Marker: JString
                                                                                                                                     ##         
                                                                                                                                     ## : 
                                                                                                                                     ## Pagination 
                                                                                                                                     ## token
  ##   
                                                                                                                                             ## order: JString
                                                                                                                                             ##        
                                                                                                                                             ## : 
                                                                                                                                             ## The 
                                                                                                                                             ## order 
                                                                                                                                             ## for 
                                                                                                                                             ## the 
                                                                                                                                             ## contents 
                                                                                                                                             ## of 
                                                                                                                                             ## the 
                                                                                                                                             ## folder.
  ##   
                                                                                                                                                       ## limit: JInt
                                                                                                                                                       ##        
                                                                                                                                                       ## : 
                                                                                                                                                       ## The 
                                                                                                                                                       ## maximum 
                                                                                                                                                       ## number 
                                                                                                                                                       ## of 
                                                                                                                                                       ## items 
                                                                                                                                                       ## to 
                                                                                                                                                       ## return 
                                                                                                                                                       ## with 
                                                                                                                                                       ## this 
                                                                                                                                                       ## call.
  ##   
                                                                                                                                                               ## sort: JString
                                                                                                                                                               ##       
                                                                                                                                                               ## : 
                                                                                                                                                               ## The 
                                                                                                                                                               ## sorting 
                                                                                                                                                               ## criteria.
  ##   
                                                                                                                                                                           ## Limit: JString
                                                                                                                                                                           ##        
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## Pagination 
                                                                                                                                                                           ## limit
  ##   
                                                                                                                                                                                   ## include: JString
                                                                                                                                                                                   ##          
                                                                                                                                                                                   ## : 
                                                                                                                                                                                   ## The 
                                                                                                                                                                                   ## contents 
                                                                                                                                                                                   ## to 
                                                                                                                                                                                   ## include. 
                                                                                                                                                                                   ## Specify 
                                                                                                                                                                                   ## "INITIALIZED" 
                                                                                                                                                                                   ## to 
                                                                                                                                                                                   ## include 
                                                                                                                                                                                   ## initialized 
                                                                                                                                                                                   ## documents.
  ##   
                                                                                                                                                                                                ## type: JString
                                                                                                                                                                                                ##       
                                                                                                                                                                                                ## : 
                                                                                                                                                                                                ## The 
                                                                                                                                                                                                ## type 
                                                                                                                                                                                                ## of 
                                                                                                                                                                                                ## items.
  section = newJObject()
  var valid_402656917 = query.getOrDefault("marker")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "marker", valid_402656917
  var valid_402656918 = query.getOrDefault("Marker")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "Marker", valid_402656918
  var valid_402656919 = query.getOrDefault("order")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false,
                                      default = newJString("ASCENDING"))
  if valid_402656919 != nil:
    section.add "order", valid_402656919
  var valid_402656920 = query.getOrDefault("limit")
  valid_402656920 = validateParameter(valid_402656920, JInt, required = false,
                                      default = nil)
  if valid_402656920 != nil:
    section.add "limit", valid_402656920
  var valid_402656921 = query.getOrDefault("sort")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false,
                                      default = newJString("DATE"))
  if valid_402656921 != nil:
    section.add "sort", valid_402656921
  var valid_402656922 = query.getOrDefault("Limit")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "Limit", valid_402656922
  var valid_402656923 = query.getOrDefault("include")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "include", valid_402656923
  var valid_402656924 = query.getOrDefault("type")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false,
                                      default = newJString("ALL"))
  if valid_402656924 != nil:
    section.add "type", valid_402656924
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656925 = header.getOrDefault("Authentication")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "Authentication", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Security-Token", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Signature")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Signature", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Algorithm", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Date")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Date", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Credential")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Credential", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656933: Call_DescribeFolderContents_402656913;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
                                                                                         ## 
  let valid = call_402656933.validator(path, query, header, formData, body, _)
  let scheme = call_402656933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656933.makeUrl(scheme.get, call_402656933.host, call_402656933.base,
                                   call_402656933.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656933, uri, valid, _)

proc call*(call_402656934: Call_DescribeFolderContents_402656913;
           FolderId: string; marker: string = ""; Marker: string = "";
           order: string = "ASCENDING"; limit: int = 0; sort: string = "DATE";
           Limit: string = ""; `include`: string = ""; `type`: string = "ALL"): Recallable =
  ## describeFolderContents
  ## <p>Describes the contents of the specified folder, including its documents and subfolders.</p> <p>By default, Amazon WorkDocs returns the first 100 active document and folder metadata items. If there are more results, the response includes a marker that you can use to request the next set of results. You can also request initialized documents.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                  ## marker: string
                                                                                                                                                                                                                                                                                                                                                                  ##         
                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                  ## marker 
                                                                                                                                                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                  ## next 
                                                                                                                                                                                                                                                                                                                                                                  ## set 
                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                  ## results. 
                                                                                                                                                                                                                                                                                                                                                                  ## This 
                                                                                                                                                                                                                                                                                                                                                                  ## marker 
                                                                                                                                                                                                                                                                                                                                                                  ## was 
                                                                                                                                                                                                                                                                                                                                                                  ## received 
                                                                                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                                                                                  ## previous 
                                                                                                                                                                                                                                                                                                                                                                  ## call.
  ##   
                                                                                                                                                                                                                                                                                                                                                                          ## Marker: string
                                                                                                                                                                                                                                                                                                                                                                          ##         
                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                          ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                                                  ## order: string
                                                                                                                                                                                                                                                                                                                                                                                  ##        
                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                  ## order 
                                                                                                                                                                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                  ## contents 
                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                  ## folder.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                            ## limit: int
                                                                                                                                                                                                                                                                                                                                                                                            ##        
                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                            ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                            ## items 
                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                            ## return 
                                                                                                                                                                                                                                                                                                                                                                                            ## with 
                                                                                                                                                                                                                                                                                                                                                                                            ## this 
                                                                                                                                                                                                                                                                                                                                                                                            ## call.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                    ## sort: string
                                                                                                                                                                                                                                                                                                                                                                                                    ##       
                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                                                                    ## sorting 
                                                                                                                                                                                                                                                                                                                                                                                                    ## criteria.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                ## Limit: string
                                                                                                                                                                                                                                                                                                                                                                                                                ##        
                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                        ## include: string
                                                                                                                                                                                                                                                                                                                                                                                                                        ##          
                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## contents 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## include. 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## Specify 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## "INITIALIZED" 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## include 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## initialized 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## documents.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## FolderId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                     ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                     ## folder.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## type: string
                                                                                                                                                                                                                                                                                                                                                                                                                                               ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## type 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                               ## items.
  var path_402656935 = newJObject()
  var query_402656936 = newJObject()
  add(query_402656936, "marker", newJString(marker))
  add(query_402656936, "Marker", newJString(Marker))
  add(query_402656936, "order", newJString(order))
  add(query_402656936, "limit", newJInt(limit))
  add(query_402656936, "sort", newJString(sort))
  add(query_402656936, "Limit", newJString(Limit))
  add(query_402656936, "include", newJString(`include`))
  add(path_402656935, "FolderId", newJString(FolderId))
  add(query_402656936, "type", newJString(`type`))
  result = call_402656934.call(path_402656935, query_402656936, nil, nil, nil)

var describeFolderContents* = Call_DescribeFolderContents_402656913(
    name: "describeFolderContents", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DescribeFolderContents_402656914, base: "/",
    makeUrl: url_DescribeFolderContents_402656915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFolderContents_402656937 = ref object of OpenApiRestCall_402656044
proc url_DeleteFolderContents_402656939(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteFolderContents_402656938(path: JsonNode; query: JsonNode;
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
  assert path != nil,
         "path argument is necessary due to required `FolderId` field"
  var valid_402656940 = path.getOrDefault("FolderId")
  valid_402656940 = validateParameter(valid_402656940, JString, required = true,
                                      default = nil)
  if valid_402656940 != nil:
    section.add "FolderId", valid_402656940
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656941 = header.getOrDefault("Authentication")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "Authentication", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-Security-Token", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Signature")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Signature", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Algorithm", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Date")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Date", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Credential")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Credential", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656949: Call_DeleteFolderContents_402656937;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the contents of the specified folder.
                                                                                         ## 
  let valid = call_402656949.validator(path, query, header, formData, body, _)
  let scheme = call_402656949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656949.makeUrl(scheme.get, call_402656949.host, call_402656949.base,
                                   call_402656949.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656949, uri, valid, _)

proc call*(call_402656950: Call_DeleteFolderContents_402656937; FolderId: string): Recallable =
  ## deleteFolderContents
  ## Deletes the contents of the specified folder.
  ##   FolderId: string (required)
                                                  ##           : The ID of the folder.
  var path_402656951 = newJObject()
  add(path_402656951, "FolderId", newJString(FolderId))
  result = call_402656950.call(path_402656951, nil, nil, nil, nil)

var deleteFolderContents* = Call_DeleteFolderContents_402656937(
    name: "deleteFolderContents", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/contents",
    validator: validate_DeleteFolderContents_402656938, base: "/",
    makeUrl: url_DeleteFolderContents_402656939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationSubscription_402656952 = ref object of OpenApiRestCall_402656044
proc url_DeleteNotificationSubscription_402656954(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OrganizationId" in path,
         "`OrganizationId` is a required path parameter"
  assert "SubscriptionId" in path,
         "`SubscriptionId` is a required path parameter"
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

proc validate_DeleteNotificationSubscription_402656953(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the specified subscription from the specified organization.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OrganizationId: JString (required)
                                 ##                 : The ID of the organization.
  ##   
                                                                                 ## SubscriptionId: JString (required)
                                                                                 ##                 
                                                                                 ## : 
                                                                                 ## The 
                                                                                 ## ID 
                                                                                 ## of 
                                                                                 ## the 
                                                                                 ## subscription.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `OrganizationId` field"
  var valid_402656955 = path.getOrDefault("OrganizationId")
  valid_402656955 = validateParameter(valid_402656955, JString, required = true,
                                      default = nil)
  if valid_402656955 != nil:
    section.add "OrganizationId", valid_402656955
  var valid_402656956 = path.getOrDefault("SubscriptionId")
  valid_402656956 = validateParameter(valid_402656956, JString, required = true,
                                      default = nil)
  if valid_402656956 != nil:
    section.add "SubscriptionId", valid_402656956
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656957 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Security-Token", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Signature")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Signature", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Algorithm", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Date")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Date", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Credential")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Credential", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656964: Call_DeleteNotificationSubscription_402656952;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified subscription from the specified organization.
                                                                                         ## 
  let valid = call_402656964.validator(path, query, header, formData, body, _)
  let scheme = call_402656964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656964.makeUrl(scheme.get, call_402656964.host, call_402656964.base,
                                   call_402656964.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656964, uri, valid, _)

proc call*(call_402656965: Call_DeleteNotificationSubscription_402656952;
           OrganizationId: string; SubscriptionId: string): Recallable =
  ## deleteNotificationSubscription
  ## Deletes the specified subscription from the specified organization.
  ##   
                                                                        ## OrganizationId: string (required)
                                                                        ##                 
                                                                        ## : 
                                                                        ## The ID of the 
                                                                        ## organization.
  ##   
                                                                                        ## SubscriptionId: string (required)
                                                                                        ##                 
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## ID 
                                                                                        ## of 
                                                                                        ## the 
                                                                                        ## subscription.
  var path_402656966 = newJObject()
  add(path_402656966, "OrganizationId", newJString(OrganizationId))
  add(path_402656966, "SubscriptionId", newJString(SubscriptionId))
  result = call_402656965.call(path_402656966, nil, nil, nil, nil)

var deleteNotificationSubscription* = Call_DeleteNotificationSubscription_402656952(
    name: "deleteNotificationSubscription", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com", route: "/api/v1/organizations/{OrganizationId}/subscriptions/{SubscriptionId}",
    validator: validate_DeleteNotificationSubscription_402656953, base: "/",
    makeUrl: url_DeleteNotificationSubscription_402656954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_402656982 = ref object of OpenApiRestCall_402656044
proc url_UpdateUser_402656984(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUser_402656983(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
                                 ##         : The ID of the user.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `UserId` field"
  var valid_402656985 = path.getOrDefault("UserId")
  valid_402656985 = validateParameter(valid_402656985, JString, required = true,
                                      default = nil)
  if valid_402656985 != nil:
    section.add "UserId", valid_402656985
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656986 = header.getOrDefault("Authentication")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "Authentication", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Security-Token", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Signature")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Signature", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Algorithm", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Date")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Date", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Credential")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Credential", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656993
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

proc call*(call_402656995: Call_UpdateUser_402656982; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
                                                                                         ## 
  let valid = call_402656995.validator(path, query, header, formData, body, _)
  let scheme = call_402656995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656995.makeUrl(scheme.get, call_402656995.host, call_402656995.base,
                                   call_402656995.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656995, uri, valid, _)

proc call*(call_402656996: Call_UpdateUser_402656982; body: JsonNode;
           UserId: string): Recallable =
  ## updateUser
  ## Updates the specified attributes of the specified user, and grants or revokes administrative privileges to the Amazon WorkDocs site.
  ##   
                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                    ## UserId: string (required)
                                                                                                                                                                    ##         
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## The 
                                                                                                                                                                    ## ID 
                                                                                                                                                                    ## of 
                                                                                                                                                                    ## the 
                                                                                                                                                                    ## user.
  var path_402656997 = newJObject()
  var body_402656998 = newJObject()
  if body != nil:
    body_402656998 = body
  add(path_402656997, "UserId", newJString(UserId))
  result = call_402656996.call(path_402656997, nil, nil, nil, body_402656998)

var updateUser* = Call_UpdateUser_402656982(name: "updateUser",
    meth: HttpMethod.HttpPatch, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}", validator: validate_UpdateUser_402656983,
    base: "/", makeUrl: url_UpdateUser_402656984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_402656967 = ref object of OpenApiRestCall_402656044
proc url_DeleteUser_402656969(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUser_402656968(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
                                 ##         : The ID of the user.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `UserId` field"
  var valid_402656970 = path.getOrDefault("UserId")
  valid_402656970 = validateParameter(valid_402656970, JString, required = true,
                                      default = nil)
  if valid_402656970 != nil:
    section.add "UserId", valid_402656970
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656971 = header.getOrDefault("Authentication")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "Authentication", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Security-Token", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Signature")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Signature", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Algorithm", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Date")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Date", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Credential")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Credential", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656979: Call_DeleteUser_402656967; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
                                                                                         ## 
  let valid = call_402656979.validator(path, query, header, formData, body, _)
  let scheme = call_402656979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656979.makeUrl(scheme.get, call_402656979.host, call_402656979.base,
                                   call_402656979.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656979, uri, valid, _)

proc call*(call_402656980: Call_DeleteUser_402656967; UserId: string): Recallable =
  ## deleteUser
  ## Deletes the specified user from a Simple AD or Microsoft AD directory.
  ##   
                                                                           ## UserId: string (required)
                                                                           ##         
                                                                           ## : 
                                                                           ## The 
                                                                           ## ID 
                                                                           ## of 
                                                                           ## the 
                                                                           ## user.
  var path_402656981 = newJObject()
  add(path_402656981, "UserId", newJString(UserId))
  result = call_402656980.call(path_402656981, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_402656967(name: "deleteUser",
    meth: HttpMethod.HttpDelete, host: "workdocs.amazonaws.com",
    route: "/api/v1/users/{UserId}", validator: validate_DeleteUser_402656968,
    base: "/", makeUrl: url_DeleteUser_402656969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivities_402656999 = ref object of OpenApiRestCall_402656044
proc url_DescribeActivities_402657001(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivities_402657000(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the user activities in a specified time period.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceId: JString
                                  ##             : The document or folder ID for which to describe activity types.
  ##   
                                                                                                                  ## marker: JString
                                                                                                                  ##         
                                                                                                                  ## : 
                                                                                                                  ## The 
                                                                                                                  ## marker 
                                                                                                                  ## for 
                                                                                                                  ## the 
                                                                                                                  ## next 
                                                                                                                  ## set 
                                                                                                                  ## of 
                                                                                                                  ## results.
  ##   
                                                                                                                             ## userId: JString
                                                                                                                             ##         
                                                                                                                             ## : 
                                                                                                                             ## The 
                                                                                                                             ## ID 
                                                                                                                             ## of 
                                                                                                                             ## the 
                                                                                                                             ## user 
                                                                                                                             ## who 
                                                                                                                             ## performed 
                                                                                                                             ## the 
                                                                                                                             ## action. 
                                                                                                                             ## The 
                                                                                                                             ## response 
                                                                                                                             ## includes 
                                                                                                                             ## activities 
                                                                                                                             ## pertaining 
                                                                                                                             ## to 
                                                                                                                             ## this 
                                                                                                                             ## user. 
                                                                                                                             ## This 
                                                                                                                             ## is 
                                                                                                                             ## an 
                                                                                                                             ## optional 
                                                                                                                             ## parameter 
                                                                                                                             ## and 
                                                                                                                             ## is 
                                                                                                                             ## only 
                                                                                                                             ## applicable 
                                                                                                                             ## for 
                                                                                                                             ## administrative 
                                                                                                                             ## API 
                                                                                                                             ## (SigV4) 
                                                                                                                             ## requests.
  ##   
                                                                                                                                         ## organizationId: JString
                                                                                                                                         ##                 
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## ID 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## organization. 
                                                                                                                                         ## This 
                                                                                                                                         ## is 
                                                                                                                                         ## a 
                                                                                                                                         ## mandatory 
                                                                                                                                         ## parameter 
                                                                                                                                         ## when 
                                                                                                                                         ## using 
                                                                                                                                         ## administrative 
                                                                                                                                         ## API 
                                                                                                                                         ## (SigV4) 
                                                                                                                                         ## requests.
  ##   
                                                                                                                                                     ## limit: JInt
                                                                                                                                                     ##        
                                                                                                                                                     ## : 
                                                                                                                                                     ## The 
                                                                                                                                                     ## maximum 
                                                                                                                                                     ## number 
                                                                                                                                                     ## of 
                                                                                                                                                     ## items 
                                                                                                                                                     ## to 
                                                                                                                                                     ## return.
  ##   
                                                                                                                                                               ## endTime: JString
                                                                                                                                                               ##          
                                                                                                                                                               ## : 
                                                                                                                                                               ## The 
                                                                                                                                                               ## timestamp 
                                                                                                                                                               ## that 
                                                                                                                                                               ## determines 
                                                                                                                                                               ## the 
                                                                                                                                                               ## end 
                                                                                                                                                               ## time 
                                                                                                                                                               ## of 
                                                                                                                                                               ## the 
                                                                                                                                                               ## activities. 
                                                                                                                                                               ## The 
                                                                                                                                                               ## response 
                                                                                                                                                               ## includes 
                                                                                                                                                               ## the 
                                                                                                                                                               ## activities 
                                                                                                                                                               ## performed 
                                                                                                                                                               ## before 
                                                                                                                                                               ## the 
                                                                                                                                                               ## specified 
                                                                                                                                                               ## timestamp.
  ##   
                                                                                                                                                                            ## activityTypes: JString
                                                                                                                                                                            ##                
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## Specifies 
                                                                                                                                                                            ## which 
                                                                                                                                                                            ## activity 
                                                                                                                                                                            ## types 
                                                                                                                                                                            ## to 
                                                                                                                                                                            ## include 
                                                                                                                                                                            ## in 
                                                                                                                                                                            ## the 
                                                                                                                                                                            ## response. 
                                                                                                                                                                            ## If 
                                                                                                                                                                            ## this 
                                                                                                                                                                            ## field 
                                                                                                                                                                            ## is 
                                                                                                                                                                            ## left 
                                                                                                                                                                            ## empty, 
                                                                                                                                                                            ## all 
                                                                                                                                                                            ## activity 
                                                                                                                                                                            ## types 
                                                                                                                                                                            ## are 
                                                                                                                                                                            ## returned.
  ##   
                                                                                                                                                                                        ## includeIndirectActivities: JBool
                                                                                                                                                                                        ##                            
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ## Includes 
                                                                                                                                                                                        ## indirect 
                                                                                                                                                                                        ## activities. 
                                                                                                                                                                                        ## An 
                                                                                                                                                                                        ## indirect 
                                                                                                                                                                                        ## activity 
                                                                                                                                                                                        ## results 
                                                                                                                                                                                        ## from 
                                                                                                                                                                                        ## a 
                                                                                                                                                                                        ## direct 
                                                                                                                                                                                        ## activity 
                                                                                                                                                                                        ## performed 
                                                                                                                                                                                        ## on 
                                                                                                                                                                                        ## a 
                                                                                                                                                                                        ## parent 
                                                                                                                                                                                        ## resource. 
                                                                                                                                                                                        ## For 
                                                                                                                                                                                        ## example, 
                                                                                                                                                                                        ## sharing 
                                                                                                                                                                                        ## a 
                                                                                                                                                                                        ## parent 
                                                                                                                                                                                        ## folder 
                                                                                                                                                                                        ## (the 
                                                                                                                                                                                        ## direct 
                                                                                                                                                                                        ## activity) 
                                                                                                                                                                                        ## shares 
                                                                                                                                                                                        ## all 
                                                                                                                                                                                        ## of 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## subfolders 
                                                                                                                                                                                        ## and 
                                                                                                                                                                                        ## documents 
                                                                                                                                                                                        ## within 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## parent 
                                                                                                                                                                                        ## folder 
                                                                                                                                                                                        ## (the 
                                                                                                                                                                                        ## indirect 
                                                                                                                                                                                        ## activity).
  ##   
                                                                                                                                                                                                     ## startTime: JString
                                                                                                                                                                                                     ##            
                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                     ## timestamp 
                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                     ## determines 
                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                     ## starting 
                                                                                                                                                                                                     ## time 
                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                     ## activities. 
                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                     ## response 
                                                                                                                                                                                                     ## includes 
                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                     ## activities 
                                                                                                                                                                                                     ## performed 
                                                                                                                                                                                                     ## after 
                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                     ## specified 
                                                                                                                                                                                                     ## timestamp.
  section = newJObject()
  var valid_402657002 = query.getOrDefault("resourceId")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "resourceId", valid_402657002
  var valid_402657003 = query.getOrDefault("marker")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "marker", valid_402657003
  var valid_402657004 = query.getOrDefault("userId")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "userId", valid_402657004
  var valid_402657005 = query.getOrDefault("organizationId")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "organizationId", valid_402657005
  var valid_402657006 = query.getOrDefault("limit")
  valid_402657006 = validateParameter(valid_402657006, JInt, required = false,
                                      default = nil)
  if valid_402657006 != nil:
    section.add "limit", valid_402657006
  var valid_402657007 = query.getOrDefault("endTime")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "endTime", valid_402657007
  var valid_402657008 = query.getOrDefault("activityTypes")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "activityTypes", valid_402657008
  var valid_402657009 = query.getOrDefault("includeIndirectActivities")
  valid_402657009 = validateParameter(valid_402657009, JBool, required = false,
                                      default = nil)
  if valid_402657009 != nil:
    section.add "includeIndirectActivities", valid_402657009
  var valid_402657010 = query.getOrDefault("startTime")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "startTime", valid_402657010
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657011 = header.getOrDefault("Authentication")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "Authentication", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Security-Token", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Signature")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Signature", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Algorithm", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Date")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Date", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Credential")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Credential", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657019: Call_DescribeActivities_402656999;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the user activities in a specified time period.
                                                                                         ## 
  let valid = call_402657019.validator(path, query, header, formData, body, _)
  let scheme = call_402657019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657019.makeUrl(scheme.get, call_402657019.host, call_402657019.base,
                                   call_402657019.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657019, uri, valid, _)

proc call*(call_402657020: Call_DescribeActivities_402656999;
           resourceId: string = ""; marker: string = ""; userId: string = "";
           organizationId: string = ""; limit: int = 0; endTime: string = "";
           activityTypes: string = ""; includeIndirectActivities: bool = false;
           startTime: string = ""): Recallable =
  ## describeActivities
  ## Describes the user activities in a specified time period.
  ##   resourceId: string
                                                              ##             : The document or folder ID for which to describe activity types.
  ##   
                                                                                                                                              ## marker: string
                                                                                                                                              ##         
                                                                                                                                              ## : 
                                                                                                                                              ## The 
                                                                                                                                              ## marker 
                                                                                                                                              ## for 
                                                                                                                                              ## the 
                                                                                                                                              ## next 
                                                                                                                                              ## set 
                                                                                                                                              ## of 
                                                                                                                                              ## results.
  ##   
                                                                                                                                                         ## userId: string
                                                                                                                                                         ##         
                                                                                                                                                         ## : 
                                                                                                                                                         ## The 
                                                                                                                                                         ## ID 
                                                                                                                                                         ## of 
                                                                                                                                                         ## the 
                                                                                                                                                         ## user 
                                                                                                                                                         ## who 
                                                                                                                                                         ## performed 
                                                                                                                                                         ## the 
                                                                                                                                                         ## action. 
                                                                                                                                                         ## The 
                                                                                                                                                         ## response 
                                                                                                                                                         ## includes 
                                                                                                                                                         ## activities 
                                                                                                                                                         ## pertaining 
                                                                                                                                                         ## to 
                                                                                                                                                         ## this 
                                                                                                                                                         ## user. 
                                                                                                                                                         ## This 
                                                                                                                                                         ## is 
                                                                                                                                                         ## an 
                                                                                                                                                         ## optional 
                                                                                                                                                         ## parameter 
                                                                                                                                                         ## and 
                                                                                                                                                         ## is 
                                                                                                                                                         ## only 
                                                                                                                                                         ## applicable 
                                                                                                                                                         ## for 
                                                                                                                                                         ## administrative 
                                                                                                                                                         ## API 
                                                                                                                                                         ## (SigV4) 
                                                                                                                                                         ## requests.
  ##   
                                                                                                                                                                     ## organizationId: string
                                                                                                                                                                     ##                 
                                                                                                                                                                     ## : 
                                                                                                                                                                     ## The 
                                                                                                                                                                     ## ID 
                                                                                                                                                                     ## of 
                                                                                                                                                                     ## the 
                                                                                                                                                                     ## organization. 
                                                                                                                                                                     ## This 
                                                                                                                                                                     ## is 
                                                                                                                                                                     ## a 
                                                                                                                                                                     ## mandatory 
                                                                                                                                                                     ## parameter 
                                                                                                                                                                     ## when 
                                                                                                                                                                     ## using 
                                                                                                                                                                     ## administrative 
                                                                                                                                                                     ## API 
                                                                                                                                                                     ## (SigV4) 
                                                                                                                                                                     ## requests.
  ##   
                                                                                                                                                                                 ## limit: int
                                                                                                                                                                                 ##        
                                                                                                                                                                                 ## : 
                                                                                                                                                                                 ## The 
                                                                                                                                                                                 ## maximum 
                                                                                                                                                                                 ## number 
                                                                                                                                                                                 ## of 
                                                                                                                                                                                 ## items 
                                                                                                                                                                                 ## to 
                                                                                                                                                                                 ## return.
  ##   
                                                                                                                                                                                           ## endTime: string
                                                                                                                                                                                           ##          
                                                                                                                                                                                           ## : 
                                                                                                                                                                                           ## The 
                                                                                                                                                                                           ## timestamp 
                                                                                                                                                                                           ## that 
                                                                                                                                                                                           ## determines 
                                                                                                                                                                                           ## the 
                                                                                                                                                                                           ## end 
                                                                                                                                                                                           ## time 
                                                                                                                                                                                           ## of 
                                                                                                                                                                                           ## the 
                                                                                                                                                                                           ## activities. 
                                                                                                                                                                                           ## The 
                                                                                                                                                                                           ## response 
                                                                                                                                                                                           ## includes 
                                                                                                                                                                                           ## the 
                                                                                                                                                                                           ## activities 
                                                                                                                                                                                           ## performed 
                                                                                                                                                                                           ## before 
                                                                                                                                                                                           ## the 
                                                                                                                                                                                           ## specified 
                                                                                                                                                                                           ## timestamp.
  ##   
                                                                                                                                                                                                        ## activityTypes: string
                                                                                                                                                                                                        ##                
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                        ## which 
                                                                                                                                                                                                        ## activity 
                                                                                                                                                                                                        ## types 
                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                        ## include 
                                                                                                                                                                                                        ## in 
                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                        ## response. 
                                                                                                                                                                                                        ## If 
                                                                                                                                                                                                        ## this 
                                                                                                                                                                                                        ## field 
                                                                                                                                                                                                        ## is 
                                                                                                                                                                                                        ## left 
                                                                                                                                                                                                        ## empty, 
                                                                                                                                                                                                        ## all 
                                                                                                                                                                                                        ## activity 
                                                                                                                                                                                                        ## types 
                                                                                                                                                                                                        ## are 
                                                                                                                                                                                                        ## returned.
  ##   
                                                                                                                                                                                                                    ## includeIndirectActivities: bool
                                                                                                                                                                                                                    ##                            
                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                    ## Includes 
                                                                                                                                                                                                                    ## indirect 
                                                                                                                                                                                                                    ## activities. 
                                                                                                                                                                                                                    ## An 
                                                                                                                                                                                                                    ## indirect 
                                                                                                                                                                                                                    ## activity 
                                                                                                                                                                                                                    ## results 
                                                                                                                                                                                                                    ## from 
                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                    ## direct 
                                                                                                                                                                                                                    ## activity 
                                                                                                                                                                                                                    ## performed 
                                                                                                                                                                                                                    ## on 
                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                    ## parent 
                                                                                                                                                                                                                    ## resource. 
                                                                                                                                                                                                                    ## For 
                                                                                                                                                                                                                    ## example, 
                                                                                                                                                                                                                    ## sharing 
                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                    ## parent 
                                                                                                                                                                                                                    ## folder 
                                                                                                                                                                                                                    ## (the 
                                                                                                                                                                                                                    ## direct 
                                                                                                                                                                                                                    ## activity) 
                                                                                                                                                                                                                    ## shares 
                                                                                                                                                                                                                    ## all 
                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## subfolders 
                                                                                                                                                                                                                    ## and 
                                                                                                                                                                                                                    ## documents 
                                                                                                                                                                                                                    ## within 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## parent 
                                                                                                                                                                                                                    ## folder 
                                                                                                                                                                                                                    ## (the 
                                                                                                                                                                                                                    ## indirect 
                                                                                                                                                                                                                    ## activity).
  ##   
                                                                                                                                                                                                                                 ## startTime: string
                                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                 ## timestamp 
                                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                                 ## determines 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## starting 
                                                                                                                                                                                                                                 ## time 
                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## activities. 
                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                                                 ## includes 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## activities 
                                                                                                                                                                                                                                 ## performed 
                                                                                                                                                                                                                                 ## after 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## specified 
                                                                                                                                                                                                                                 ## timestamp.
  var query_402657021 = newJObject()
  add(query_402657021, "resourceId", newJString(resourceId))
  add(query_402657021, "marker", newJString(marker))
  add(query_402657021, "userId", newJString(userId))
  add(query_402657021, "organizationId", newJString(organizationId))
  add(query_402657021, "limit", newJInt(limit))
  add(query_402657021, "endTime", newJString(endTime))
  add(query_402657021, "activityTypes", newJString(activityTypes))
  add(query_402657021, "includeIndirectActivities",
      newJBool(includeIndirectActivities))
  add(query_402657021, "startTime", newJString(startTime))
  result = call_402657020.call(nil, query_402657021, nil, nil, nil)

var describeActivities* = Call_DescribeActivities_402656999(
    name: "describeActivities", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/activities",
    validator: validate_DescribeActivities_402657000, base: "/",
    makeUrl: url_DescribeActivities_402657001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComments_402657022 = ref object of OpenApiRestCall_402656044
proc url_DescribeComments_402657024(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
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
                 (kind: VariableSegment, value: "VersionId"),
                 (kind: ConstantSegment, value: "/comments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeComments_402657023(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all the comments for the specified document version.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionId: JString (required)
                                 ##            : The ID of the document version.
  ##   
                                                                                ## DocumentId: JString (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## The 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## document.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `VersionId` field"
  var valid_402657025 = path.getOrDefault("VersionId")
  valid_402657025 = validateParameter(valid_402657025, JString, required = true,
                                      default = nil)
  if valid_402657025 != nil:
    section.add "VersionId", valid_402657025
  var valid_402657026 = path.getOrDefault("DocumentId")
  valid_402657026 = validateParameter(valid_402657026, JString, required = true,
                                      default = nil)
  if valid_402657026 != nil:
    section.add "DocumentId", valid_402657026
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
                                  ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   
                                                                                                                                     ## limit: JInt
                                                                                                                                     ##        
                                                                                                                                     ## : 
                                                                                                                                     ## The 
                                                                                                                                     ## maximum 
                                                                                                                                     ## number 
                                                                                                                                     ## of 
                                                                                                                                     ## items 
                                                                                                                                     ## to 
                                                                                                                                     ## return.
  section = newJObject()
  var valid_402657027 = query.getOrDefault("marker")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "marker", valid_402657027
  var valid_402657028 = query.getOrDefault("limit")
  valid_402657028 = validateParameter(valid_402657028, JInt, required = false,
                                      default = nil)
  if valid_402657028 != nil:
    section.add "limit", valid_402657028
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657029 = header.getOrDefault("Authentication")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "Authentication", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Security-Token", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Signature")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Signature", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Algorithm", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Date")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Date", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Credential")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Credential", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657037: Call_DescribeComments_402657022;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all the comments for the specified document version.
                                                                                         ## 
  let valid = call_402657037.validator(path, query, header, formData, body, _)
  let scheme = call_402657037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657037.makeUrl(scheme.get, call_402657037.host, call_402657037.base,
                                   call_402657037.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657037, uri, valid, _)

proc call*(call_402657038: Call_DescribeComments_402657022; VersionId: string;
           DocumentId: string; marker: string = ""; limit: int = 0): Recallable =
  ## describeComments
  ## List all the comments for the specified document version.
  ##   marker: string
                                                              ##         : The marker for the next set of results. This marker was received from a previous call.
  ##   
                                                                                                                                                                 ## limit: int
                                                                                                                                                                 ##        
                                                                                                                                                                 ## : 
                                                                                                                                                                 ## The 
                                                                                                                                                                 ## maximum 
                                                                                                                                                                 ## number 
                                                                                                                                                                 ## of 
                                                                                                                                                                 ## items 
                                                                                                                                                                 ## to 
                                                                                                                                                                 ## return.
  ##   
                                                                                                                                                                           ## VersionId: string (required)
                                                                                                                                                                           ##            
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## The 
                                                                                                                                                                           ## ID 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## document 
                                                                                                                                                                           ## version.
  ##   
                                                                                                                                                                                      ## DocumentId: string (required)
                                                                                                                                                                                      ##             
                                                                                                                                                                                      ## : 
                                                                                                                                                                                      ## The 
                                                                                                                                                                                      ## ID 
                                                                                                                                                                                      ## of 
                                                                                                                                                                                      ## the 
                                                                                                                                                                                      ## document.
  var path_402657039 = newJObject()
  var query_402657040 = newJObject()
  add(query_402657040, "marker", newJString(marker))
  add(query_402657040, "limit", newJInt(limit))
  add(path_402657039, "VersionId", newJString(VersionId))
  add(path_402657039, "DocumentId", newJString(DocumentId))
  result = call_402657038.call(path_402657039, query_402657040, nil, nil, nil)

var describeComments* = Call_DescribeComments_402657022(
    name: "describeComments", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions/{VersionId}/comments",
    validator: validate_DescribeComments_402657023, base: "/",
    makeUrl: url_DescribeComments_402657024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentVersions_402657041 = ref object of OpenApiRestCall_402656044
proc url_DescribeDocumentVersions_402657043(protocol: Scheme; host: string;
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

proc validate_DescribeDocumentVersions_402657042(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657044 = path.getOrDefault("DocumentId")
  valid_402657044 = validateParameter(valid_402657044, JString, required = true,
                                      default = nil)
  if valid_402657044 != nil:
    section.add "DocumentId", valid_402657044
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
                                  ##         : Specify "SOURCE" to include initialized versions and a URL for the source document.
  ##   
                                                                                                                                  ## marker: JString
                                                                                                                                  ##         
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## marker 
                                                                                                                                  ## for 
                                                                                                                                  ## the 
                                                                                                                                  ## next 
                                                                                                                                  ## set 
                                                                                                                                  ## of 
                                                                                                                                  ## results. 
                                                                                                                                  ## (You 
                                                                                                                                  ## received 
                                                                                                                                  ## this 
                                                                                                                                  ## marker 
                                                                                                                                  ## from 
                                                                                                                                  ## a 
                                                                                                                                  ## previous 
                                                                                                                                  ## call.)
  ##   
                                                                                                                                           ## Marker: JString
                                                                                                                                           ##         
                                                                                                                                           ## : 
                                                                                                                                           ## Pagination 
                                                                                                                                           ## token
  ##   
                                                                                                                                                   ## limit: JInt
                                                                                                                                                   ##        
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## maximum 
                                                                                                                                                   ## number 
                                                                                                                                                   ## of 
                                                                                                                                                   ## versions 
                                                                                                                                                   ## to 
                                                                                                                                                   ## return 
                                                                                                                                                   ## with 
                                                                                                                                                   ## this 
                                                                                                                                                   ## call.
  ##   
                                                                                                                                                           ## Limit: JString
                                                                                                                                                           ##        
                                                                                                                                                           ## : 
                                                                                                                                                           ## Pagination 
                                                                                                                                                           ## limit
  ##   
                                                                                                                                                                   ## include: JString
                                                                                                                                                                   ##          
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## A 
                                                                                                                                                                   ## comma-separated 
                                                                                                                                                                   ## list 
                                                                                                                                                                   ## of 
                                                                                                                                                                   ## values. 
                                                                                                                                                                   ## Specify 
                                                                                                                                                                   ## "INITIALIZED" 
                                                                                                                                                                   ## to 
                                                                                                                                                                   ## include 
                                                                                                                                                                   ## incomplete 
                                                                                                                                                                   ## versions.
  section = newJObject()
  var valid_402657045 = query.getOrDefault("fields")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "fields", valid_402657045
  var valid_402657046 = query.getOrDefault("marker")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "marker", valid_402657046
  var valid_402657047 = query.getOrDefault("Marker")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "Marker", valid_402657047
  var valid_402657048 = query.getOrDefault("limit")
  valid_402657048 = validateParameter(valid_402657048, JInt, required = false,
                                      default = nil)
  if valid_402657048 != nil:
    section.add "limit", valid_402657048
  var valid_402657049 = query.getOrDefault("Limit")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "Limit", valid_402657049
  var valid_402657050 = query.getOrDefault("include")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "include", valid_402657050
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657051 = header.getOrDefault("Authentication")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "Authentication", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Security-Token", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Signature")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Signature", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Algorithm", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Date")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Date", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Credential")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Credential", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657059: Call_DescribeDocumentVersions_402657041;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
                                                                                         ## 
  let valid = call_402657059.validator(path, query, header, formData, body, _)
  let scheme = call_402657059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657059.makeUrl(scheme.get, call_402657059.host, call_402657059.base,
                                   call_402657059.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657059, uri, valid, _)

proc call*(call_402657060: Call_DescribeDocumentVersions_402657041;
           DocumentId: string; fields: string = ""; marker: string = "";
           Marker: string = ""; limit: int = 0; Limit: string = "";
           `include`: string = ""): Recallable =
  ## describeDocumentVersions
  ## <p>Retrieves the document versions for the specified document.</p> <p>By default, only active versions are returned.</p>
  ##   
                                                                                                                             ## fields: string
                                                                                                                             ##         
                                                                                                                             ## : 
                                                                                                                             ## Specify 
                                                                                                                             ## "SOURCE" 
                                                                                                                             ## to 
                                                                                                                             ## include 
                                                                                                                             ## initialized 
                                                                                                                             ## versions 
                                                                                                                             ## and 
                                                                                                                             ## a 
                                                                                                                             ## URL 
                                                                                                                             ## for 
                                                                                                                             ## the 
                                                                                                                             ## source 
                                                                                                                             ## document.
  ##   
                                                                                                                                         ## marker: string
                                                                                                                                         ##         
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## marker 
                                                                                                                                         ## for 
                                                                                                                                         ## the 
                                                                                                                                         ## next 
                                                                                                                                         ## set 
                                                                                                                                         ## of 
                                                                                                                                         ## results. 
                                                                                                                                         ## (You 
                                                                                                                                         ## received 
                                                                                                                                         ## this 
                                                                                                                                         ## marker 
                                                                                                                                         ## from 
                                                                                                                                         ## a 
                                                                                                                                         ## previous 
                                                                                                                                         ## call.)
  ##   
                                                                                                                                                  ## Marker: string
                                                                                                                                                  ##         
                                                                                                                                                  ## : 
                                                                                                                                                  ## Pagination 
                                                                                                                                                  ## token
  ##   
                                                                                                                                                          ## limit: int
                                                                                                                                                          ##        
                                                                                                                                                          ## : 
                                                                                                                                                          ## The 
                                                                                                                                                          ## maximum 
                                                                                                                                                          ## number 
                                                                                                                                                          ## of 
                                                                                                                                                          ## versions 
                                                                                                                                                          ## to 
                                                                                                                                                          ## return 
                                                                                                                                                          ## with 
                                                                                                                                                          ## this 
                                                                                                                                                          ## call.
  ##   
                                                                                                                                                                  ## Limit: string
                                                                                                                                                                  ##        
                                                                                                                                                                  ## : 
                                                                                                                                                                  ## Pagination 
                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                          ## DocumentId: string (required)
                                                                                                                                                                          ##             
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## The 
                                                                                                                                                                          ## ID 
                                                                                                                                                                          ## of 
                                                                                                                                                                          ## the 
                                                                                                                                                                          ## document.
  ##   
                                                                                                                                                                                      ## include: string
                                                                                                                                                                                      ##          
                                                                                                                                                                                      ## : 
                                                                                                                                                                                      ## A 
                                                                                                                                                                                      ## comma-separated 
                                                                                                                                                                                      ## list 
                                                                                                                                                                                      ## of 
                                                                                                                                                                                      ## values. 
                                                                                                                                                                                      ## Specify 
                                                                                                                                                                                      ## "INITIALIZED" 
                                                                                                                                                                                      ## to 
                                                                                                                                                                                      ## include 
                                                                                                                                                                                      ## incomplete 
                                                                                                                                                                                      ## versions.
  var path_402657061 = newJObject()
  var query_402657062 = newJObject()
  add(query_402657062, "fields", newJString(fields))
  add(query_402657062, "marker", newJString(marker))
  add(query_402657062, "Marker", newJString(Marker))
  add(query_402657062, "limit", newJInt(limit))
  add(query_402657062, "Limit", newJString(Limit))
  add(path_402657061, "DocumentId", newJString(DocumentId))
  add(query_402657062, "include", newJString(`include`))
  result = call_402657060.call(path_402657061, query_402657062, nil, nil, nil)

var describeDocumentVersions* = Call_DescribeDocumentVersions_402657041(
    name: "describeDocumentVersions", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/versions",
    validator: validate_DescribeDocumentVersions_402657042, base: "/",
    makeUrl: url_DescribeDocumentVersions_402657043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroups_402657063 = ref object of OpenApiRestCall_402656044
proc url_DescribeGroups_402657065(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGroups_402657064(path: JsonNode; query: JsonNode;
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
  ##   marker: JString
                                  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   
                                                                                                                                       ## searchQuery: JString (required)
                                                                                                                                       ##              
                                                                                                                                       ## : 
                                                                                                                                       ## A 
                                                                                                                                       ## query 
                                                                                                                                       ## to 
                                                                                                                                       ## describe 
                                                                                                                                       ## groups 
                                                                                                                                       ## by 
                                                                                                                                       ## group 
                                                                                                                                       ## name.
  ##   
                                                                                                                                               ## organizationId: JString
                                                                                                                                               ##                 
                                                                                                                                               ## : 
                                                                                                                                               ## The 
                                                                                                                                               ## ID 
                                                                                                                                               ## of 
                                                                                                                                               ## the 
                                                                                                                                               ## organization.
  ##   
                                                                                                                                                               ## limit: JInt
                                                                                                                                                               ##        
                                                                                                                                                               ## : 
                                                                                                                                                               ## The 
                                                                                                                                                               ## maximum 
                                                                                                                                                               ## number 
                                                                                                                                                               ## of 
                                                                                                                                                               ## items 
                                                                                                                                                               ## to 
                                                                                                                                                               ## return 
                                                                                                                                                               ## with 
                                                                                                                                                               ## this 
                                                                                                                                                               ## call.
  section = newJObject()
  var valid_402657066 = query.getOrDefault("marker")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "marker", valid_402657066
  assert query != nil,
         "query argument is necessary due to required `searchQuery` field"
  var valid_402657067 = query.getOrDefault("searchQuery")
  valid_402657067 = validateParameter(valid_402657067, JString, required = true,
                                      default = nil)
  if valid_402657067 != nil:
    section.add "searchQuery", valid_402657067
  var valid_402657068 = query.getOrDefault("organizationId")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "organizationId", valid_402657068
  var valid_402657069 = query.getOrDefault("limit")
  valid_402657069 = validateParameter(valid_402657069, JInt, required = false,
                                      default = nil)
  if valid_402657069 != nil:
    section.add "limit", valid_402657069
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657070 = header.getOrDefault("Authentication")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "Authentication", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Security-Token", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Signature")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Signature", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Algorithm", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Date")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Date", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-Credential")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Credential", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657078: Call_DescribeGroups_402657063; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
                                                                                         ## 
  let valid = call_402657078.validator(path, query, header, formData, body, _)
  let scheme = call_402657078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657078.makeUrl(scheme.get, call_402657078.host, call_402657078.base,
                                   call_402657078.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657078, uri, valid, _)

proc call*(call_402657079: Call_DescribeGroups_402657063; searchQuery: string;
           marker: string = ""; organizationId: string = ""; limit: int = 0): Recallable =
  ## describeGroups
  ## Describes the groups specified by the query. Groups are defined by the underlying Active Directory.
  ##   
                                                                                                        ## marker: string
                                                                                                        ##         
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## marker 
                                                                                                        ## for 
                                                                                                        ## the 
                                                                                                        ## next 
                                                                                                        ## set 
                                                                                                        ## of 
                                                                                                        ## results. 
                                                                                                        ## (You 
                                                                                                        ## received 
                                                                                                        ## this 
                                                                                                        ## marker 
                                                                                                        ## from 
                                                                                                        ## a 
                                                                                                        ## previous 
                                                                                                        ## call.)
  ##   
                                                                                                                 ## searchQuery: string (required)
                                                                                                                 ##              
                                                                                                                 ## : 
                                                                                                                 ## A 
                                                                                                                 ## query 
                                                                                                                 ## to 
                                                                                                                 ## describe 
                                                                                                                 ## groups 
                                                                                                                 ## by 
                                                                                                                 ## group 
                                                                                                                 ## name.
  ##   
                                                                                                                         ## organizationId: string
                                                                                                                         ##                 
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## ID 
                                                                                                                         ## of 
                                                                                                                         ## the 
                                                                                                                         ## organization.
  ##   
                                                                                                                                         ## limit: int
                                                                                                                                         ##        
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## maximum 
                                                                                                                                         ## number 
                                                                                                                                         ## of 
                                                                                                                                         ## items 
                                                                                                                                         ## to 
                                                                                                                                         ## return 
                                                                                                                                         ## with 
                                                                                                                                         ## this 
                                                                                                                                         ## call.
  var query_402657080 = newJObject()
  add(query_402657080, "marker", newJString(marker))
  add(query_402657080, "searchQuery", newJString(searchQuery))
  add(query_402657080, "organizationId", newJString(organizationId))
  add(query_402657080, "limit", newJInt(limit))
  result = call_402657079.call(nil, query_402657080, nil, nil, nil)

var describeGroups* = Call_DescribeGroups_402657063(name: "describeGroups",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/groups#searchQuery", validator: validate_DescribeGroups_402657064,
    base: "/", makeUrl: url_DescribeGroups_402657065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRootFolders_402657081 = ref object of OpenApiRestCall_402656044
proc url_DescribeRootFolders_402657083(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRootFolders_402657082(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                                                       ## limit: JInt
                                                                                                                                       ##        
                                                                                                                                       ## : 
                                                                                                                                       ## The 
                                                                                                                                       ## maximum 
                                                                                                                                       ## number 
                                                                                                                                       ## of 
                                                                                                                                       ## items 
                                                                                                                                       ## to 
                                                                                                                                       ## return.
  section = newJObject()
  var valid_402657084 = query.getOrDefault("marker")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "marker", valid_402657084
  var valid_402657085 = query.getOrDefault("limit")
  valid_402657085 = validateParameter(valid_402657085, JInt, required = false,
                                      default = nil)
  if valid_402657085 != nil:
    section.add "limit", valid_402657085
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString (required)
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
         "header argument is necessary due to required `Authentication` field"
  var valid_402657086 = header.getOrDefault("Authentication")
  valid_402657086 = validateParameter(valid_402657086, JString, required = true,
                                      default = nil)
  if valid_402657086 != nil:
    section.add "Authentication", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Security-Token", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Signature")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Signature", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Algorithm", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-Date")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-Date", valid_402657091
  var valid_402657092 = header.getOrDefault("X-Amz-Credential")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "X-Amz-Credential", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657094: Call_DescribeRootFolders_402657081;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657094.validator(path, query, header, formData, body, _)
  let scheme = call_402657094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657094.makeUrl(scheme.get, call_402657094.host, call_402657094.base,
                                   call_402657094.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657094, uri, valid, _)

proc call*(call_402657095: Call_DescribeRootFolders_402657081;
           marker: string = ""; limit: int = 0): Recallable =
  ## describeRootFolders
  ## <p>Describes the current user's special folders; the <code>RootFolder</code> and the <code>RecycleBin</code>. <code>RootFolder</code> is the root of user's files and folders and <code>RecycleBin</code> is the root of recycled items. This is not a valid action for SigV4 (administrative API) clients.</p> <p>This action requires an authentication token. To get an authentication token, register an application with Amazon WorkDocs. For more information, see <a href="https://docs.aws.amazon.com/workdocs/latest/developerguide/wd-auth-user.html">Authentication and Access Control for User Applications</a> in the <i>Amazon WorkDocs Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## marker: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## marker 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## results. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## (You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## received 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## marker 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## call.)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## limit: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## items 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## return.
  var query_402657096 = newJObject()
  add(query_402657096, "marker", newJString(marker))
  add(query_402657096, "limit", newJInt(limit))
  result = call_402657095.call(nil, query_402657096, nil, nil, nil)

var describeRootFolders* = Call_DescribeRootFolders_402657081(
    name: "describeRootFolders", meth: HttpMethod.HttpGet,
    host: "workdocs.amazonaws.com", route: "/api/v1/me/root#Authentication",
    validator: validate_DescribeRootFolders_402657082, base: "/",
    makeUrl: url_DescribeRootFolders_402657083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentUser_402657097 = ref object of OpenApiRestCall_402656044
proc url_GetCurrentUser_402657099(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCurrentUser_402657098(path: JsonNode; query: JsonNode;
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
  ##   Authentication: JString (required)
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
         "header argument is necessary due to required `Authentication` field"
  var valid_402657100 = header.getOrDefault("Authentication")
  valid_402657100 = validateParameter(valid_402657100, JString, required = true,
                                      default = nil)
  if valid_402657100 != nil:
    section.add "Authentication", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Security-Token", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-Signature")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-Signature", valid_402657102
  var valid_402657103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657103 = validateParameter(valid_402657103, JString,
                                      required = false, default = nil)
  if valid_402657103 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657103
  var valid_402657104 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657104 = validateParameter(valid_402657104, JString,
                                      required = false, default = nil)
  if valid_402657104 != nil:
    section.add "X-Amz-Algorithm", valid_402657104
  var valid_402657105 = header.getOrDefault("X-Amz-Date")
  valid_402657105 = validateParameter(valid_402657105, JString,
                                      required = false, default = nil)
  if valid_402657105 != nil:
    section.add "X-Amz-Date", valid_402657105
  var valid_402657106 = header.getOrDefault("X-Amz-Credential")
  valid_402657106 = validateParameter(valid_402657106, JString,
                                      required = false, default = nil)
  if valid_402657106 != nil:
    section.add "X-Amz-Credential", valid_402657106
  var valid_402657107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657107 = validateParameter(valid_402657107, JString,
                                      required = false, default = nil)
  if valid_402657107 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657108: Call_GetCurrentUser_402657097; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
                                                                                         ## 
  let valid = call_402657108.validator(path, query, header, formData, body, _)
  let scheme = call_402657108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657108.makeUrl(scheme.get, call_402657108.host, call_402657108.base,
                                   call_402657108.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657108, uri, valid, _)

proc call*(call_402657109: Call_GetCurrentUser_402657097): Recallable =
  ## getCurrentUser
  ## Retrieves details of the current user for whom the authentication token was generated. This is not a valid action for SigV4 (administrative API) clients.
  result = call_402657109.call(nil, nil, nil, nil, nil)

var getCurrentUser* = Call_GetCurrentUser_402657097(name: "getCurrentUser",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/me#Authentication", validator: validate_GetCurrentUser_402657098,
    base: "/", makeUrl: url_GetCurrentUser_402657099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocumentPath_402657110 = ref object of OpenApiRestCall_402656044
proc url_GetDocumentPath_402657112(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_GetDocumentPath_402657111(path: JsonNode; query: JsonNode;
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
  var valid_402657113 = path.getOrDefault("DocumentId")
  valid_402657113 = validateParameter(valid_402657113, JString, required = true,
                                      default = nil)
  if valid_402657113 != nil:
    section.add "DocumentId", valid_402657113
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
                                  ##         : A comma-separated list of values. Specify <code>NAME</code> to include the names of the parent folders.
  ##   
                                                                                                                                                      ## marker: JString
                                                                                                                                                      ##         
                                                                                                                                                      ## : 
                                                                                                                                                      ## This 
                                                                                                                                                      ## value 
                                                                                                                                                      ## is 
                                                                                                                                                      ## not 
                                                                                                                                                      ## supported.
  ##   
                                                                                                                                                                   ## limit: JInt
                                                                                                                                                                   ##        
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## The 
                                                                                                                                                                   ## maximum 
                                                                                                                                                                   ## number 
                                                                                                                                                                   ## of 
                                                                                                                                                                   ## levels 
                                                                                                                                                                   ## in 
                                                                                                                                                                   ## the 
                                                                                                                                                                   ## hierarchy 
                                                                                                                                                                   ## to 
                                                                                                                                                                   ## return.
  section = newJObject()
  var valid_402657114 = query.getOrDefault("fields")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "fields", valid_402657114
  var valid_402657115 = query.getOrDefault("marker")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "marker", valid_402657115
  var valid_402657116 = query.getOrDefault("limit")
  valid_402657116 = validateParameter(valid_402657116, JInt, required = false,
                                      default = nil)
  if valid_402657116 != nil:
    section.add "limit", valid_402657116
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657117 = header.getOrDefault("Authentication")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "Authentication", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Security-Token", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-Signature")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-Signature", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657120
  var valid_402657121 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657121 = validateParameter(valid_402657121, JString,
                                      required = false, default = nil)
  if valid_402657121 != nil:
    section.add "X-Amz-Algorithm", valid_402657121
  var valid_402657122 = header.getOrDefault("X-Amz-Date")
  valid_402657122 = validateParameter(valid_402657122, JString,
                                      required = false, default = nil)
  if valid_402657122 != nil:
    section.add "X-Amz-Date", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Credential")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Credential", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657125: Call_GetDocumentPath_402657110; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
                                                                                         ## 
  let valid = call_402657125.validator(path, query, header, formData, body, _)
  let scheme = call_402657125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657125.makeUrl(scheme.get, call_402657125.host, call_402657125.base,
                                   call_402657125.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657125, uri, valid, _)

proc call*(call_402657126: Call_GetDocumentPath_402657110; DocumentId: string;
           fields: string = ""; marker: string = ""; limit: int = 0): Recallable =
  ## getDocumentPath
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the requested document.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested document and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the names of the parent folders.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## fields: string
                                                                                                                                                                                                                                                                                                                                                                                 ##         
                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                 ## A 
                                                                                                                                                                                                                                                                                                                                                                                 ## comma-separated 
                                                                                                                                                                                                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                 ## values. 
                                                                                                                                                                                                                                                                                                                                                                                 ## Specify 
                                                                                                                                                                                                                                                                                                                                                                                 ## <code>NAME</code> 
                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                 ## include 
                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                 ## names 
                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                 ## parent 
                                                                                                                                                                                                                                                                                                                                                                                 ## folders.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                            ## marker: string
                                                                                                                                                                                                                                                                                                                                                                                            ##         
                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                            ## This 
                                                                                                                                                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                            ## not 
                                                                                                                                                                                                                                                                                                                                                                                            ## supported.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                         ## limit: int
                                                                                                                                                                                                                                                                                                                                                                                                         ##        
                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                                         ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                         ## levels 
                                                                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                         ## hierarchy 
                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                         ## return.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                   ## DocumentId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## document.
  var path_402657127 = newJObject()
  var query_402657128 = newJObject()
  add(query_402657128, "fields", newJString(fields))
  add(query_402657128, "marker", newJString(marker))
  add(query_402657128, "limit", newJInt(limit))
  add(path_402657127, "DocumentId", newJString(DocumentId))
  result = call_402657126.call(path_402657127, query_402657128, nil, nil, nil)

var getDocumentPath* = Call_GetDocumentPath_402657110(name: "getDocumentPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/documents/{DocumentId}/path",
    validator: validate_GetDocumentPath_402657111, base: "/",
    makeUrl: url_GetDocumentPath_402657112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolderPath_402657129 = ref object of OpenApiRestCall_402656044
proc url_GetFolderPath_402657131(protocol: Scheme; host: string; base: string;
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

proc validate_GetFolderPath_402657130(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FolderId: JString (required)
                                 ##           : The ID of the folder.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `FolderId` field"
  var valid_402657132 = path.getOrDefault("FolderId")
  valid_402657132 = validateParameter(valid_402657132, JString, required = true,
                                      default = nil)
  if valid_402657132 != nil:
    section.add "FolderId", valid_402657132
  result.add "path", section
  ## parameters in `query` object:
  ##   fields: JString
                                  ##         : A comma-separated list of values. Specify "NAME" to include the names of the parent folders.
  ##   
                                                                                                                                           ## marker: JString
                                                                                                                                           ##         
                                                                                                                                           ## : 
                                                                                                                                           ## This 
                                                                                                                                           ## value 
                                                                                                                                           ## is 
                                                                                                                                           ## not 
                                                                                                                                           ## supported.
  ##   
                                                                                                                                                        ## limit: JInt
                                                                                                                                                        ##        
                                                                                                                                                        ## : 
                                                                                                                                                        ## The 
                                                                                                                                                        ## maximum 
                                                                                                                                                        ## number 
                                                                                                                                                        ## of 
                                                                                                                                                        ## levels 
                                                                                                                                                        ## in 
                                                                                                                                                        ## the 
                                                                                                                                                        ## hierarchy 
                                                                                                                                                        ## to 
                                                                                                                                                        ## return.
  section = newJObject()
  var valid_402657133 = query.getOrDefault("fields")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "fields", valid_402657133
  var valid_402657134 = query.getOrDefault("marker")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "marker", valid_402657134
  var valid_402657135 = query.getOrDefault("limit")
  valid_402657135 = validateParameter(valid_402657135, JInt, required = false,
                                      default = nil)
  if valid_402657135 != nil:
    section.add "limit", valid_402657135
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657136 = header.getOrDefault("Authentication")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "Authentication", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-Security-Token", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Signature")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Signature", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Algorithm", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Date")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Date", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-Credential")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-Credential", valid_402657142
  var valid_402657143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657143 = validateParameter(valid_402657143, JString,
                                      required = false, default = nil)
  if valid_402657143 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657144: Call_GetFolderPath_402657129; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
                                                                                         ## 
  let valid = call_402657144.validator(path, query, header, formData, body, _)
  let scheme = call_402657144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657144.makeUrl(scheme.get, call_402657144.host, call_402657144.base,
                                   call_402657144.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657144, uri, valid, _)

proc call*(call_402657145: Call_GetFolderPath_402657129; FolderId: string;
           fields: string = ""; marker: string = ""; limit: int = 0): Recallable =
  ## getFolderPath
  ## <p>Retrieves the path information (the hierarchy from the root folder) for the specified folder.</p> <p>By default, Amazon WorkDocs returns a maximum of 100 levels upwards from the requested folder and only includes the IDs of the parent folders in the path. You can limit the maximum number of levels. You can also request the parent folder names.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                     ## fields: string
                                                                                                                                                                                                                                                                                                                                                                     ##         
                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                                                     ## comma-separated 
                                                                                                                                                                                                                                                                                                                                                                     ## list 
                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                     ## values. 
                                                                                                                                                                                                                                                                                                                                                                     ## Specify 
                                                                                                                                                                                                                                                                                                                                                                     ## "NAME" 
                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                     ## include 
                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                     ## names 
                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                     ## parent 
                                                                                                                                                                                                                                                                                                                                                                     ## folders.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                ## marker: string
                                                                                                                                                                                                                                                                                                                                                                                ##         
                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                ## This 
                                                                                                                                                                                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                                                                ## not 
                                                                                                                                                                                                                                                                                                                                                                                ## supported.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                             ## limit: int
                                                                                                                                                                                                                                                                                                                                                                                             ##        
                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                                                                                                                             ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                             ## number 
                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                             ## levels 
                                                                                                                                                                                                                                                                                                                                                                                             ## in 
                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                             ## hierarchy 
                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                             ## return.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                       ## FolderId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                       ##           
                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                       ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                       ## folder.
  var path_402657146 = newJObject()
  var query_402657147 = newJObject()
  add(query_402657147, "fields", newJString(fields))
  add(query_402657147, "marker", newJString(marker))
  add(query_402657147, "limit", newJInt(limit))
  add(path_402657146, "FolderId", newJString(FolderId))
  result = call_402657145.call(path_402657146, query_402657147, nil, nil, nil)

var getFolderPath* = Call_GetFolderPath_402657129(name: "getFolderPath",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/folders/{FolderId}/path", validator: validate_GetFolderPath_402657130,
    base: "/", makeUrl: url_GetFolderPath_402657131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResources_402657148 = ref object of OpenApiRestCall_402656044
proc url_GetResources_402657150(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResources_402657149(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   collectionType: JString
                                  ##                 : The collection type.
  ##   
                                                                           ## marker: JString
                                                                           ##         
                                                                           ## : 
                                                                           ## The 
                                                                           ## marker 
                                                                           ## for 
                                                                           ## the 
                                                                           ## next 
                                                                           ## set 
                                                                           ## of 
                                                                           ## results. 
                                                                           ## This 
                                                                           ## marker 
                                                                           ## was 
                                                                           ## received 
                                                                           ## from 
                                                                           ## a 
                                                                           ## previous 
                                                                           ## call.
  ##   
                                                                                   ## userId: JString
                                                                                   ##         
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## user 
                                                                                   ## ID 
                                                                                   ## for 
                                                                                   ## the 
                                                                                   ## resource 
                                                                                   ## collection. 
                                                                                   ## This 
                                                                                   ## is 
                                                                                   ## a 
                                                                                   ## required 
                                                                                   ## field 
                                                                                   ## for 
                                                                                   ## accessing 
                                                                                   ## the 
                                                                                   ## API 
                                                                                   ## operation 
                                                                                   ## using 
                                                                                   ## IAM 
                                                                                   ## credentials.
  ##   
                                                                                                  ## limit: JInt
                                                                                                  ##        
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## maximum 
                                                                                                  ## number 
                                                                                                  ## of 
                                                                                                  ## resources 
                                                                                                  ## to 
                                                                                                  ## return.
  section = newJObject()
  var valid_402657151 = query.getOrDefault("collectionType")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false,
                                      default = newJString("SHARED_WITH_ME"))
  if valid_402657151 != nil:
    section.add "collectionType", valid_402657151
  var valid_402657152 = query.getOrDefault("marker")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "marker", valid_402657152
  var valid_402657153 = query.getOrDefault("userId")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "userId", valid_402657153
  var valid_402657154 = query.getOrDefault("limit")
  valid_402657154 = validateParameter(valid_402657154, JInt, required = false,
                                      default = nil)
  if valid_402657154 != nil:
    section.add "limit", valid_402657154
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : The Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API operation using AWS credentials.
  ##   
                                                                                                                                                                                                                       ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                                       ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                                  ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                                  ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                                             ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                   ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657155 = header.getOrDefault("Authentication")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "Authentication", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Security-Token", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-Signature")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-Signature", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-Algorithm", valid_402657159
  var valid_402657160 = header.getOrDefault("X-Amz-Date")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-Date", valid_402657160
  var valid_402657161 = header.getOrDefault("X-Amz-Credential")
  valid_402657161 = validateParameter(valid_402657161, JString,
                                      required = false, default = nil)
  if valid_402657161 != nil:
    section.add "X-Amz-Credential", valid_402657161
  var valid_402657162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657163: Call_GetResources_402657148; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
                                                                                         ## 
  let valid = call_402657163.validator(path, query, header, formData, body, _)
  let scheme = call_402657163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657163.makeUrl(scheme.get, call_402657163.host, call_402657163.base,
                                   call_402657163.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657163, uri, valid, _)

proc call*(call_402657164: Call_GetResources_402657148;
           collectionType: string = "SHARED_WITH_ME"; marker: string = "";
           userId: string = ""; limit: int = 0): Recallable =
  ## getResources
  ## Retrieves a collection of resources, including folders and documents. The only <code>CollectionType</code> supported is <code>SHARED_WITH_ME</code>.
  ##   
                                                                                                                                                         ## collectionType: string
                                                                                                                                                         ##                 
                                                                                                                                                         ## : 
                                                                                                                                                         ## The 
                                                                                                                                                         ## collection 
                                                                                                                                                         ## type.
  ##   
                                                                                                                                                                 ## marker: string
                                                                                                                                                                 ##         
                                                                                                                                                                 ## : 
                                                                                                                                                                 ## The 
                                                                                                                                                                 ## marker 
                                                                                                                                                                 ## for 
                                                                                                                                                                 ## the 
                                                                                                                                                                 ## next 
                                                                                                                                                                 ## set 
                                                                                                                                                                 ## of 
                                                                                                                                                                 ## results. 
                                                                                                                                                                 ## This 
                                                                                                                                                                 ## marker 
                                                                                                                                                                 ## was 
                                                                                                                                                                 ## received 
                                                                                                                                                                 ## from 
                                                                                                                                                                 ## a 
                                                                                                                                                                 ## previous 
                                                                                                                                                                 ## call.
  ##   
                                                                                                                                                                         ## userId: string
                                                                                                                                                                         ##         
                                                                                                                                                                         ## : 
                                                                                                                                                                         ## The 
                                                                                                                                                                         ## user 
                                                                                                                                                                         ## ID 
                                                                                                                                                                         ## for 
                                                                                                                                                                         ## the 
                                                                                                                                                                         ## resource 
                                                                                                                                                                         ## collection. 
                                                                                                                                                                         ## This 
                                                                                                                                                                         ## is 
                                                                                                                                                                         ## a 
                                                                                                                                                                         ## required 
                                                                                                                                                                         ## field 
                                                                                                                                                                         ## for 
                                                                                                                                                                         ## accessing 
                                                                                                                                                                         ## the 
                                                                                                                                                                         ## API 
                                                                                                                                                                         ## operation 
                                                                                                                                                                         ## using 
                                                                                                                                                                         ## IAM 
                                                                                                                                                                         ## credentials.
  ##   
                                                                                                                                                                                        ## limit: int
                                                                                                                                                                                        ##        
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ## The 
                                                                                                                                                                                        ## maximum 
                                                                                                                                                                                        ## number 
                                                                                                                                                                                        ## of 
                                                                                                                                                                                        ## resources 
                                                                                                                                                                                        ## to 
                                                                                                                                                                                        ## return.
  var query_402657165 = newJObject()
  add(query_402657165, "collectionType", newJString(collectionType))
  add(query_402657165, "marker", newJString(marker))
  add(query_402657165, "userId", newJString(userId))
  add(query_402657165, "limit", newJInt(limit))
  result = call_402657164.call(nil, query_402657165, nil, nil, nil)

var getResources* = Call_GetResources_402657148(name: "getResources",
    meth: HttpMethod.HttpGet, host: "workdocs.amazonaws.com",
    route: "/api/v1/resources", validator: validate_GetResources_402657149,
    base: "/", makeUrl: url_GetResources_402657150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateDocumentVersionUpload_402657166 = ref object of OpenApiRestCall_402656044
proc url_InitiateDocumentVersionUpload_402657168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InitiateDocumentVersionUpload_402657167(path: JsonNode;
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
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657169 = header.getOrDefault("Authentication")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "Authentication", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-Security-Token", valid_402657170
  var valid_402657171 = header.getOrDefault("X-Amz-Signature")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false, default = nil)
  if valid_402657171 != nil:
    section.add "X-Amz-Signature", valid_402657171
  var valid_402657172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657172 = validateParameter(valid_402657172, JString,
                                      required = false, default = nil)
  if valid_402657172 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657172
  var valid_402657173 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Algorithm", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Date")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Date", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Credential")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Credential", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657176
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

proc call*(call_402657178: Call_InitiateDocumentVersionUpload_402657166;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
                                                                                         ## 
  let valid = call_402657178.validator(path, query, header, formData, body, _)
  let scheme = call_402657178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657178.makeUrl(scheme.get, call_402657178.host, call_402657178.base,
                                   call_402657178.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657178, uri, valid, _)

proc call*(call_402657179: Call_InitiateDocumentVersionUpload_402657166;
           body: JsonNode): Recallable =
  ## initiateDocumentVersionUpload
  ## <p>Creates a new document object and version object.</p> <p>The client specifies the parent folder ID and name of the document to upload. The ID is optionally specified when creating a new version of an existing document. This is the first step to upload a document. Next, upload the document to the URL returned from the call, and then call <a>UpdateDocumentVersion</a>.</p> <p>To cancel the document upload, call <a>AbortDocumentVersionUpload</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657180 = newJObject()
  if body != nil:
    body_402657180 = body
  result = call_402657179.call(nil, nil, nil, nil, body_402657180)

var initiateDocumentVersionUpload* = Call_InitiateDocumentVersionUpload_402657166(
    name: "initiateDocumentVersionUpload", meth: HttpMethod.HttpPost,
    host: "workdocs.amazonaws.com", route: "/api/v1/documents",
    validator: validate_InitiateDocumentVersionUpload_402657167, base: "/",
    makeUrl: url_InitiateDocumentVersionUpload_402657168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveResourcePermission_402657181 = ref object of OpenApiRestCall_402656044
proc url_RemoveResourcePermission_402657183(protocol: Scheme; host: string;
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

proc validate_RemoveResourcePermission_402657182(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes the permission for the specified principal from the specified resource.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
                                 ##             : The ID of the resource.
  ##   
                                                                         ## PrincipalId: JString (required)
                                                                         ##              
                                                                         ## : 
                                                                         ## The 
                                                                         ## principal 
                                                                         ## ID 
                                                                         ## of 
                                                                         ## the 
                                                                         ## resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ResourceId` field"
  var valid_402657184 = path.getOrDefault("ResourceId")
  valid_402657184 = validateParameter(valid_402657184, JString, required = true,
                                      default = nil)
  if valid_402657184 != nil:
    section.add "ResourceId", valid_402657184
  var valid_402657185 = path.getOrDefault("PrincipalId")
  valid_402657185 = validateParameter(valid_402657185, JString, required = true,
                                      default = nil)
  if valid_402657185 != nil:
    section.add "PrincipalId", valid_402657185
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
                                  ##       : The principal type of the resource.
  section = newJObject()
  var valid_402657186 = query.getOrDefault("type")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false,
                                      default = newJString("USER"))
  if valid_402657186 != nil:
    section.add "type", valid_402657186
  result.add "query", section
  ## parameters in `header` object:
  ##   Authentication: JString
                                   ##                 : Amazon WorkDocs authentication token. Do not set this field when using administrative API actions, as in accessing the API using AWS credentials.
  ##   
                                                                                                                                                                                                         ## X-Amz-Security-Token: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Signature: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                                                                 ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657187 = header.getOrDefault("Authentication")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "Authentication", valid_402657187
  var valid_402657188 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Security-Token", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Signature")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Signature", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657190
  var valid_402657191 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657191 = validateParameter(valid_402657191, JString,
                                      required = false, default = nil)
  if valid_402657191 != nil:
    section.add "X-Amz-Algorithm", valid_402657191
  var valid_402657192 = header.getOrDefault("X-Amz-Date")
  valid_402657192 = validateParameter(valid_402657192, JString,
                                      required = false, default = nil)
  if valid_402657192 != nil:
    section.add "X-Amz-Date", valid_402657192
  var valid_402657193 = header.getOrDefault("X-Amz-Credential")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-Credential", valid_402657193
  var valid_402657194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657195: Call_RemoveResourcePermission_402657181;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the permission for the specified principal from the specified resource.
                                                                                         ## 
  let valid = call_402657195.validator(path, query, header, formData, body, _)
  let scheme = call_402657195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657195.makeUrl(scheme.get, call_402657195.host, call_402657195.base,
                                   call_402657195.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657195, uri, valid, _)

proc call*(call_402657196: Call_RemoveResourcePermission_402657181;
           ResourceId: string; PrincipalId: string; `type`: string = "USER"): Recallable =
  ## removeResourcePermission
  ## Removes the permission for the specified principal from the specified resource.
  ##   
                                                                                    ## ResourceId: string (required)
                                                                                    ##             
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## resource.
  ##   
                                                                                                ## PrincipalId: string (required)
                                                                                                ##              
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## principal 
                                                                                                ## ID 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## resource.
  ##   
                                                                                                            ## type: string
                                                                                                            ##       
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## principal 
                                                                                                            ## type 
                                                                                                            ## of 
                                                                                                            ## the 
                                                                                                            ## resource.
  var path_402657197 = newJObject()
  var query_402657198 = newJObject()
  add(path_402657197, "ResourceId", newJString(ResourceId))
  add(path_402657197, "PrincipalId", newJString(PrincipalId))
  add(query_402657198, "type", newJString(`type`))
  result = call_402657196.call(path_402657197, query_402657198, nil, nil, nil)

var removeResourcePermission* = Call_RemoveResourcePermission_402657181(
    name: "removeResourcePermission", meth: HttpMethod.HttpDelete,
    host: "workdocs.amazonaws.com",
    route: "/api/v1/resources/{ResourceId}/permissions/{PrincipalId}",
    validator: validate_RemoveResourcePermission_402657182, base: "/",
    makeUrl: url_RemoveResourcePermission_402657183,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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