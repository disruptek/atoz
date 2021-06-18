
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Cognito Sync
## version: 2014-06-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Cognito Sync</fullname> <p>Amazon Cognito Sync provides an AWS service and client library that enable cross-device syncing of application-related user data. High-level client libraries are available for both iOS and Android. You can use these libraries to persist data locally so that it's available even if the device is offline. Developer credentials don't need to be stored on the mobile device to access the service. You can use Amazon Cognito to obtain a normalized user ID and credentials. User data is persisted in a dataset that can store up to 1 MB of key-value pairs, and you can have up to 20 datasets per user identity.</p> <p>With Amazon Cognito Sync, the data stored for each identity is accessible only to credentials assigned to that identity. In order to use the Cognito Sync service, you need to make API calls using credentials retrieved with <a href="http://docs.aws.amazon.com/cognitoidentity/latest/APIReference/Welcome.html">Amazon Cognito Identity service</a>.</p> <p>If you want to use Cognito Sync in an Android or iOS application, you will probably want to make API calls via the AWS Mobile SDK. To learn more, see the <a href="http://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-sync.html">Developer Guide for Android</a> and the <a href="http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-sync.html">Developer Guide for iOS</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cognito-sync/
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "cognito-sync.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cognito-sync.ap-southeast-1.amazonaws.com", "us-west-2": "cognito-sync.us-west-2.amazonaws.com", "eu-west-2": "cognito-sync.eu-west-2.amazonaws.com", "ap-northeast-3": "cognito-sync.ap-northeast-3.amazonaws.com", "eu-central-1": "cognito-sync.eu-central-1.amazonaws.com", "us-east-2": "cognito-sync.us-east-2.amazonaws.com", "us-east-1": "cognito-sync.us-east-1.amazonaws.com", "cn-northwest-1": "cognito-sync.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cognito-sync.ap-south-1.amazonaws.com", "eu-north-1": "cognito-sync.eu-north-1.amazonaws.com", "ap-northeast-2": "cognito-sync.ap-northeast-2.amazonaws.com", "us-west-1": "cognito-sync.us-west-1.amazonaws.com", "us-gov-east-1": "cognito-sync.us-gov-east-1.amazonaws.com", "eu-west-3": "cognito-sync.eu-west-3.amazonaws.com", "cn-north-1": "cognito-sync.cn-north-1.amazonaws.com.cn", "sa-east-1": "cognito-sync.sa-east-1.amazonaws.com", "eu-west-1": "cognito-sync.eu-west-1.amazonaws.com", "us-gov-west-1": "cognito-sync.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cognito-sync.ap-southeast-2.amazonaws.com", "ca-central-1": "cognito-sync.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "cognito-sync.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cognito-sync.ap-southeast-1.amazonaws.com",
      "us-west-2": "cognito-sync.us-west-2.amazonaws.com",
      "eu-west-2": "cognito-sync.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cognito-sync.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cognito-sync.eu-central-1.amazonaws.com",
      "us-east-2": "cognito-sync.us-east-2.amazonaws.com",
      "us-east-1": "cognito-sync.us-east-1.amazonaws.com",
      "cn-northwest-1": "cognito-sync.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cognito-sync.ap-south-1.amazonaws.com",
      "eu-north-1": "cognito-sync.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cognito-sync.ap-northeast-2.amazonaws.com",
      "us-west-1": "cognito-sync.us-west-1.amazonaws.com",
      "us-gov-east-1": "cognito-sync.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cognito-sync.eu-west-3.amazonaws.com",
      "cn-north-1": "cognito-sync.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cognito-sync.sa-east-1.amazonaws.com",
      "eu-west-1": "cognito-sync.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cognito-sync.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cognito-sync.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cognito-sync.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cognito-sync"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BulkPublish_402656288 = ref object of OpenApiRestCall_402656038
proc url_BulkPublish_402656290(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/bulkpublish")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BulkPublish_402656289(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
                                 ##                 : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityPoolId` field"
  var valid_402656380 = path.getOrDefault("IdentityPoolId")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "IdentityPoolId", valid_402656380
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
  var valid_402656381 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Security-Token", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Signature")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Signature", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Algorithm", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Date")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Date", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Credential")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Credential", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656401: Call_BulkPublish_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656401.validator(path, query, header, formData, body, _)
  let scheme = call_402656401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656401.makeUrl(scheme.get, call_402656401.host, call_402656401.base,
                                   call_402656401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656401, uri, valid, _)

proc call*(call_402656450: Call_BulkPublish_402656288; IdentityPoolId: string): Recallable =
  ## bulkPublish
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## region.
  var path_402656451 = newJObject()
  add(path_402656451, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656450.call(path_402656451, nil, nil, nil, nil)

var bulkPublish* = Call_BulkPublish_402656288(name: "bulkPublish",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/bulkpublish",
    validator: validate_BulkPublish_402656289, base: "/",
    makeUrl: url_BulkPublish_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecords_402656497 = ref object of OpenApiRestCall_402656038
proc url_UpdateRecords_402656499(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  assert "DatasetName" in path, "`DatasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/datasets/"),
                 (kind: VariableSegment, value: "DatasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRecords_402656498(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  ##   
                                                                                                 ## DatasetName: JString (required)
                                                                                                 ##              
                                                                                                 ## : 
                                                                                                 ## A 
                                                                                                 ## string 
                                                                                                 ## of 
                                                                                                 ## up 
                                                                                                 ## to 
                                                                                                 ## 128 
                                                                                                 ## characters. 
                                                                                                 ## Allowed 
                                                                                                 ## characters 
                                                                                                 ## are 
                                                                                                 ## a-z, 
                                                                                                 ## A-Z, 
                                                                                                 ## 0-9, 
                                                                                                 ## '_' 
                                                                                                 ## (underscore), 
                                                                                                 ## '-' 
                                                                                                 ## (dash), 
                                                                                                 ## and 
                                                                                                 ## '.' 
                                                                                                 ## (dot).
  ##   
                                                                                                          ## IdentityPoolId: JString (required)
                                                                                                          ##                 
                                                                                                          ## : 
                                                                                                          ## A 
                                                                                                          ## name-spaced 
                                                                                                          ## GUID 
                                                                                                          ## (for 
                                                                                                          ## example, 
                                                                                                          ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                          ## created 
                                                                                                          ## by 
                                                                                                          ## Amazon 
                                                                                                          ## Cognito. 
                                                                                                          ## GUID 
                                                                                                          ## generation 
                                                                                                          ## is 
                                                                                                          ## unique 
                                                                                                          ## within 
                                                                                                          ## a 
                                                                                                          ## region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656500 = path.getOrDefault("IdentityId")
  valid_402656500 = validateParameter(valid_402656500, JString, required = true,
                                      default = nil)
  if valid_402656500 != nil:
    section.add "IdentityId", valid_402656500
  var valid_402656501 = path.getOrDefault("DatasetName")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true,
                                      default = nil)
  if valid_402656501 != nil:
    section.add "DatasetName", valid_402656501
  var valid_402656502 = path.getOrDefault("IdentityPoolId")
  valid_402656502 = validateParameter(valid_402656502, JString, required = true,
                                      default = nil)
  if valid_402656502 != nil:
    section.add "IdentityPoolId", valid_402656502
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-Client-Context: JString
                               ##                       : Intended to supply a device ID that will populate the lastModifiedBy field referenced in other methods. The ClientContext field is not yet implemented.
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
  var valid_402656503 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Security-Token", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Signature")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Signature", valid_402656504
  var valid_402656505 = header.getOrDefault("x-amz-Client-Context")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "x-amz-Client-Context", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Algorithm", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Date")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Date", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Credential")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Credential", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656510
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

proc call*(call_402656512: Call_UpdateRecords_402656497; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
                                                                                         ## 
  let valid = call_402656512.validator(path, query, header, formData, body, _)
  let scheme = call_402656512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656512.makeUrl(scheme.get, call_402656512.host, call_402656512.base,
                                   call_402656512.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656512, uri, valid, _)

proc call*(call_402656513: Call_UpdateRecords_402656497; IdentityId: string;
           DatasetName: string; IdentityPoolId: string; body: JsonNode): Recallable =
  ## updateRecords
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## IdentityId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## DatasetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## string 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## up 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## 128 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## characters. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Allowed 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## characters 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a-z, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## A-Z, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## 0-9, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## '_' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## (underscore), 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## '-' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## (dash), 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## '.' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## (dot).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var path_402656514 = newJObject()
  var body_402656515 = newJObject()
  add(path_402656514, "IdentityId", newJString(IdentityId))
  add(path_402656514, "DatasetName", newJString(DatasetName))
  add(path_402656514, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_402656515 = body
  result = call_402656513.call(path_402656514, nil, nil, nil, body_402656515)

var updateRecords* = Call_UpdateRecords_402656497(name: "updateRecords",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_UpdateRecords_402656498, base: "/",
    makeUrl: url_UpdateRecords_402656499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_402656481 = ref object of OpenApiRestCall_402656038
proc url_DescribeDataset_402656483(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  assert "DatasetName" in path, "`DatasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/datasets/"),
                 (kind: VariableSegment, value: "DatasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataset_402656482(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  ##   
                                                                                                 ## DatasetName: JString (required)
                                                                                                 ##              
                                                                                                 ## : 
                                                                                                 ## A 
                                                                                                 ## string 
                                                                                                 ## of 
                                                                                                 ## up 
                                                                                                 ## to 
                                                                                                 ## 128 
                                                                                                 ## characters. 
                                                                                                 ## Allowed 
                                                                                                 ## characters 
                                                                                                 ## are 
                                                                                                 ## a-z, 
                                                                                                 ## A-Z, 
                                                                                                 ## 0-9, 
                                                                                                 ## '_' 
                                                                                                 ## (underscore), 
                                                                                                 ## '-' 
                                                                                                 ## (dash), 
                                                                                                 ## and 
                                                                                                 ## '.' 
                                                                                                 ## (dot).
  ##   
                                                                                                          ## IdentityPoolId: JString (required)
                                                                                                          ##                 
                                                                                                          ## : 
                                                                                                          ## A 
                                                                                                          ## name-spaced 
                                                                                                          ## GUID 
                                                                                                          ## (for 
                                                                                                          ## example, 
                                                                                                          ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                          ## created 
                                                                                                          ## by 
                                                                                                          ## Amazon 
                                                                                                          ## Cognito. 
                                                                                                          ## GUID 
                                                                                                          ## generation 
                                                                                                          ## is 
                                                                                                          ## unique 
                                                                                                          ## within 
                                                                                                          ## a 
                                                                                                          ## region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656484 = path.getOrDefault("IdentityId")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "IdentityId", valid_402656484
  var valid_402656485 = path.getOrDefault("DatasetName")
  valid_402656485 = validateParameter(valid_402656485, JString, required = true,
                                      default = nil)
  if valid_402656485 != nil:
    section.add "DatasetName", valid_402656485
  var valid_402656486 = path.getOrDefault("IdentityPoolId")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true,
                                      default = nil)
  if valid_402656486 != nil:
    section.add "IdentityPoolId", valid_402656486
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
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656494: Call_DescribeDataset_402656481; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
                                                                                         ## 
  let valid = call_402656494.validator(path, query, header, formData, body, _)
  let scheme = call_402656494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656494.makeUrl(scheme.get, call_402656494.host, call_402656494.base,
                                   call_402656494.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656494, uri, valid, _)

proc call*(call_402656495: Call_DescribeDataset_402656481; IdentityId: string;
           DatasetName: string; IdentityPoolId: string): Recallable =
  ## describeDataset
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## IdentityId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                         ## region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## DatasetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## string 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## up 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## 128 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## characters. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Allowed 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## characters 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## a-z, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## A-Z, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## 0-9, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## '_' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## (underscore), 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## '-' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## (dash), 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## '.' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## (dot).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## region.
  var path_402656496 = newJObject()
  add(path_402656496, "IdentityId", newJString(IdentityId))
  add(path_402656496, "DatasetName", newJString(DatasetName))
  add(path_402656496, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656495.call(path_402656496, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_402656481(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DescribeDataset_402656482, base: "/",
    makeUrl: url_DescribeDataset_402656483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_402656516 = ref object of OpenApiRestCall_402656038
proc url_DeleteDataset_402656518(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  assert "DatasetName" in path, "`DatasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/datasets/"),
                 (kind: VariableSegment, value: "DatasetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataset_402656517(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  ##   
                                                                                                 ## DatasetName: JString (required)
                                                                                                 ##              
                                                                                                 ## : 
                                                                                                 ## A 
                                                                                                 ## string 
                                                                                                 ## of 
                                                                                                 ## up 
                                                                                                 ## to 
                                                                                                 ## 128 
                                                                                                 ## characters. 
                                                                                                 ## Allowed 
                                                                                                 ## characters 
                                                                                                 ## are 
                                                                                                 ## a-z, 
                                                                                                 ## A-Z, 
                                                                                                 ## 0-9, 
                                                                                                 ## '_' 
                                                                                                 ## (underscore), 
                                                                                                 ## '-' 
                                                                                                 ## (dash), 
                                                                                                 ## and 
                                                                                                 ## '.' 
                                                                                                 ## (dot).
  ##   
                                                                                                          ## IdentityPoolId: JString (required)
                                                                                                          ##                 
                                                                                                          ## : 
                                                                                                          ## A 
                                                                                                          ## name-spaced 
                                                                                                          ## GUID 
                                                                                                          ## (for 
                                                                                                          ## example, 
                                                                                                          ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                          ## created 
                                                                                                          ## by 
                                                                                                          ## Amazon 
                                                                                                          ## Cognito. 
                                                                                                          ## GUID 
                                                                                                          ## generation 
                                                                                                          ## is 
                                                                                                          ## unique 
                                                                                                          ## within 
                                                                                                          ## a 
                                                                                                          ## region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656519 = path.getOrDefault("IdentityId")
  valid_402656519 = validateParameter(valid_402656519, JString, required = true,
                                      default = nil)
  if valid_402656519 != nil:
    section.add "IdentityId", valid_402656519
  var valid_402656520 = path.getOrDefault("DatasetName")
  valid_402656520 = validateParameter(valid_402656520, JString, required = true,
                                      default = nil)
  if valid_402656520 != nil:
    section.add "DatasetName", valid_402656520
  var valid_402656521 = path.getOrDefault("IdentityPoolId")
  valid_402656521 = validateParameter(valid_402656521, JString, required = true,
                                      default = nil)
  if valid_402656521 != nil:
    section.add "IdentityPoolId", valid_402656521
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
  var valid_402656522 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Security-Token", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Signature")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Signature", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Algorithm", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Date")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Date", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Credential")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Credential", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656529: Call_DeleteDataset_402656516; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
                                                                                         ## 
  let valid = call_402656529.validator(path, query, header, formData, body, _)
  let scheme = call_402656529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656529.makeUrl(scheme.get, call_402656529.host, call_402656529.base,
                                   call_402656529.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656529, uri, valid, _)

proc call*(call_402656530: Call_DeleteDataset_402656516; IdentityId: string;
           DatasetName: string; IdentityPoolId: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                             ## IdentityId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                             ## A 
                                                                                                                                                                                                                                                                                                                                                                                                             ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                             ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                             ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                             ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                             ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                             ## created 
                                                                                                                                                                                                                                                                                                                                                                                                             ## by 
                                                                                                                                                                                                                                                                                                                                                                                                             ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                             ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                             ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                             ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                             ## is 
                                                                                                                                                                                                                                                                                                                                                                                                             ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                             ## within 
                                                                                                                                                                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                                                                                                                                                                             ## region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                       ## DatasetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                       ##              
                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## string 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## up 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## 128 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## characters. 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## Allowed 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## characters 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## a-z, 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## A-Z, 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## 0-9, 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## '_' 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## (underscore), 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## '-' 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## (dash), 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## '.' 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## (dot).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                ##                 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## region.
  var path_402656531 = newJObject()
  add(path_402656531, "IdentityId", newJString(IdentityId))
  add(path_402656531, "DatasetName", newJString(DatasetName))
  add(path_402656531, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656530.call(path_402656531, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_402656516(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DeleteDataset_402656517, base: "/",
    makeUrl: url_DeleteDataset_402656518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPoolUsage_402656532 = ref object of OpenApiRestCall_402656038
proc url_DescribeIdentityPoolUsage_402656534(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIdentityPoolUsage_402656533(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
                                 ##                 : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityPoolId` field"
  var valid_402656535 = path.getOrDefault("IdentityPoolId")
  valid_402656535 = validateParameter(valid_402656535, JString, required = true,
                                      default = nil)
  if valid_402656535 != nil:
    section.add "IdentityPoolId", valid_402656535
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
  var valid_402656536 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Security-Token", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Signature")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Signature", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Algorithm", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Date")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Date", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Credential")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Credential", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656543: Call_DescribeIdentityPoolUsage_402656532;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656543.validator(path, query, header, formData, body, _)
  let scheme = call_402656543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656543.makeUrl(scheme.get, call_402656543.host, call_402656543.base,
                                   call_402656543.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656543, uri, valid, _)

proc call*(call_402656544: Call_DescribeIdentityPoolUsage_402656532;
           IdentityPoolId: string): Recallable =
  ## describeIdentityPoolUsage
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                                                      ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                      ##                 
                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                      ## A 
                                                                                                                                                                                                                                                      ## name-spaced 
                                                                                                                                                                                                                                                      ## GUID 
                                                                                                                                                                                                                                                      ## (for 
                                                                                                                                                                                                                                                      ## example, 
                                                                                                                                                                                                                                                      ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                      ## created 
                                                                                                                                                                                                                                                      ## by 
                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                      ## Cognito. 
                                                                                                                                                                                                                                                      ## GUID 
                                                                                                                                                                                                                                                      ## generation 
                                                                                                                                                                                                                                                      ## is 
                                                                                                                                                                                                                                                      ## unique 
                                                                                                                                                                                                                                                      ## within 
                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                      ## region.
  var path_402656545 = newJObject()
  add(path_402656545, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656544.call(path_402656545, nil, nil, nil, nil)

var describeIdentityPoolUsage* = Call_DescribeIdentityPoolUsage_402656532(
    name: "describeIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}",
    validator: validate_DescribeIdentityPoolUsage_402656533, base: "/",
    makeUrl: url_DescribeIdentityPoolUsage_402656534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityUsage_402656546 = ref object of OpenApiRestCall_402656038
proc url_DescribeIdentityUsage_402656548(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIdentityUsage_402656547(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  ##   
                                                                                                 ## IdentityPoolId: JString (required)
                                                                                                 ##                 
                                                                                                 ## : 
                                                                                                 ## A 
                                                                                                 ## name-spaced 
                                                                                                 ## GUID 
                                                                                                 ## (for 
                                                                                                 ## example, 
                                                                                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                 ## created 
                                                                                                 ## by 
                                                                                                 ## Amazon 
                                                                                                 ## Cognito. 
                                                                                                 ## GUID 
                                                                                                 ## generation 
                                                                                                 ## is 
                                                                                                 ## unique 
                                                                                                 ## within 
                                                                                                 ## a 
                                                                                                 ## region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656549 = path.getOrDefault("IdentityId")
  valid_402656549 = validateParameter(valid_402656549, JString, required = true,
                                      default = nil)
  if valid_402656549 != nil:
    section.add "IdentityId", valid_402656549
  var valid_402656550 = path.getOrDefault("IdentityPoolId")
  valid_402656550 = validateParameter(valid_402656550, JString, required = true,
                                      default = nil)
  if valid_402656550 != nil:
    section.add "IdentityPoolId", valid_402656550
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
  var valid_402656551 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Security-Token", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Signature")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Signature", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Algorithm", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Date")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Date", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Credential")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Credential", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656558: Call_DescribeIdentityUsage_402656546;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
                                                                                         ## 
  let valid = call_402656558.validator(path, query, header, formData, body, _)
  let scheme = call_402656558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656558.makeUrl(scheme.get, call_402656558.host, call_402656558.base,
                                   call_402656558.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656558, uri, valid, _)

proc call*(call_402656559: Call_DescribeIdentityUsage_402656546;
           IdentityId: string; IdentityPoolId: string): Recallable =
  ## describeIdentityUsage
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   
                                                                                                                                                                                                                          ## IdentityId: string (required)
                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## A 
                                                                                                                                                                                                                          ## name-spaced 
                                                                                                                                                                                                                          ## GUID 
                                                                                                                                                                                                                          ## (for 
                                                                                                                                                                                                                          ## example, 
                                                                                                                                                                                                                          ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                          ## created 
                                                                                                                                                                                                                          ## by 
                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                          ## Cognito. 
                                                                                                                                                                                                                          ## GUID 
                                                                                                                                                                                                                          ## generation 
                                                                                                                                                                                                                          ## is 
                                                                                                                                                                                                                          ## unique 
                                                                                                                                                                                                                          ## within 
                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                          ## region.
  ##   
                                                                                                                                                                                                                                    ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                    ##                 
                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                    ## A 
                                                                                                                                                                                                                                    ## name-spaced 
                                                                                                                                                                                                                                    ## GUID 
                                                                                                                                                                                                                                    ## (for 
                                                                                                                                                                                                                                    ## example, 
                                                                                                                                                                                                                                    ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                    ## created 
                                                                                                                                                                                                                                    ## by 
                                                                                                                                                                                                                                    ## Amazon 
                                                                                                                                                                                                                                    ## Cognito. 
                                                                                                                                                                                                                                    ## GUID 
                                                                                                                                                                                                                                    ## generation 
                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                    ## unique 
                                                                                                                                                                                                                                    ## within 
                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                    ## region.
  var path_402656560 = newJObject()
  add(path_402656560, "IdentityId", newJString(IdentityId))
  add(path_402656560, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656559.call(path_402656560, nil, nil, nil, nil)

var describeIdentityUsage* = Call_DescribeIdentityUsage_402656546(
    name: "describeIdentityUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}",
    validator: validate_DescribeIdentityUsage_402656547, base: "/",
    makeUrl: url_DescribeIdentityUsage_402656548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkPublishDetails_402656561 = ref object of OpenApiRestCall_402656038
proc url_GetBulkPublishDetails_402656563(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/getBulkPublishDetails")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBulkPublishDetails_402656562(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
                                 ##                 : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityPoolId` field"
  var valid_402656564 = path.getOrDefault("IdentityPoolId")
  valid_402656564 = validateParameter(valid_402656564, JString, required = true,
                                      default = nil)
  if valid_402656564 != nil:
    section.add "IdentityPoolId", valid_402656564
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
  var valid_402656565 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Security-Token", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Signature")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Signature", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Algorithm", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Date")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Date", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Credential")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Credential", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656572: Call_GetBulkPublishDetails_402656561;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656572.validator(path, query, header, formData, body, _)
  let scheme = call_402656572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656572.makeUrl(scheme.get, call_402656572.host, call_402656572.base,
                                   call_402656572.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656572, uri, valid, _)

proc call*(call_402656573: Call_GetBulkPublishDetails_402656561;
           IdentityPoolId: string): Recallable =
  ## getBulkPublishDetails
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                                            ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                            ##                 
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## A 
                                                                                                                                                                                                                                            ## name-spaced 
                                                                                                                                                                                                                                            ## GUID 
                                                                                                                                                                                                                                            ## (for 
                                                                                                                                                                                                                                            ## example, 
                                                                                                                                                                                                                                            ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                            ## created 
                                                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                                                            ## Amazon 
                                                                                                                                                                                                                                            ## Cognito. 
                                                                                                                                                                                                                                            ## GUID 
                                                                                                                                                                                                                                            ## generation 
                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                            ## unique 
                                                                                                                                                                                                                                            ## within 
                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                            ## region.
  var path_402656574 = newJObject()
  add(path_402656574, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656573.call(path_402656574, nil, nil, nil, nil)

var getBulkPublishDetails* = Call_GetBulkPublishDetails_402656561(
    name: "getBulkPublishDetails", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/getBulkPublishDetails",
    validator: validate_GetBulkPublishDetails_402656562, base: "/",
    makeUrl: url_GetBulkPublishDetails_402656563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetCognitoEvents_402656589 = ref object of OpenApiRestCall_402656038
proc url_SetCognitoEvents_402656591(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/events")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SetCognitoEvents_402656590(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
                                 ##                 : The Cognito Identity Pool to use when configuring Cognito Events
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityPoolId` field"
  var valid_402656592 = path.getOrDefault("IdentityPoolId")
  valid_402656592 = validateParameter(valid_402656592, JString, required = true,
                                      default = nil)
  if valid_402656592 != nil:
    section.add "IdentityPoolId", valid_402656592
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
  var valid_402656593 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Security-Token", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Signature")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Signature", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Algorithm", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Date")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Date", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Credential")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Credential", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656599
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

proc call*(call_402656601: Call_SetCognitoEvents_402656589;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656601.validator(path, query, header, formData, body, _)
  let scheme = call_402656601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656601.makeUrl(scheme.get, call_402656601.host, call_402656601.base,
                                   call_402656601.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656601, uri, valid, _)

proc call*(call_402656602: Call_SetCognitoEvents_402656589;
           IdentityPoolId: string; body: JsonNode): Recallable =
  ## setCognitoEvents
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                      ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                      ##                 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## Cognito 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## Identity 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## Pool 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## configuring 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## Cognito 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## Events
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var path_402656603 = newJObject()
  var body_402656604 = newJObject()
  add(path_402656603, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_402656604 = body
  result = call_402656602.call(path_402656603, nil, nil, nil, body_402656604)

var setCognitoEvents* = Call_SetCognitoEvents_402656589(
    name: "setCognitoEvents", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_SetCognitoEvents_402656590, base: "/",
    makeUrl: url_SetCognitoEvents_402656591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCognitoEvents_402656575 = ref object of OpenApiRestCall_402656038
proc url_GetCognitoEvents_402656577(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/events")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCognitoEvents_402656576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
                                 ##                 : The Cognito Identity Pool ID for the request
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityPoolId` field"
  var valid_402656578 = path.getOrDefault("IdentityPoolId")
  valid_402656578 = validateParameter(valid_402656578, JString, required = true,
                                      default = nil)
  if valid_402656578 != nil:
    section.add "IdentityPoolId", valid_402656578
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
  var valid_402656579 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Security-Token", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Signature")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Signature", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Algorithm", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Date")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Date", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Credential")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Credential", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656586: Call_GetCognitoEvents_402656575;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656586.validator(path, query, header, formData, body, _)
  let scheme = call_402656586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656586.makeUrl(scheme.get, call_402656586.host, call_402656586.base,
                                   call_402656586.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656586, uri, valid, _)

proc call*(call_402656587: Call_GetCognitoEvents_402656575;
           IdentityPoolId: string): Recallable =
  ## getCognitoEvents
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                                                              ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                              ##                 
                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                              ## Cognito 
                                                                                                                                                                                                                                                              ## Identity 
                                                                                                                                                                                                                                                              ## Pool 
                                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                                              ## for 
                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                              ## request
  var path_402656588 = newJObject()
  add(path_402656588, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656587.call(path_402656588, nil, nil, nil, nil)

var getCognitoEvents* = Call_GetCognitoEvents_402656575(
    name: "getCognitoEvents", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_GetCognitoEvents_402656576, base: "/",
    makeUrl: url_GetCognitoEvents_402656577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolConfiguration_402656619 = ref object of OpenApiRestCall_402656038
proc url_SetIdentityPoolConfiguration_402656621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SetIdentityPoolConfiguration_402656620(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
                                 ##                 : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. This is the ID of the pool to modify.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityPoolId` field"
  var valid_402656622 = path.getOrDefault("IdentityPoolId")
  valid_402656622 = validateParameter(valid_402656622, JString, required = true,
                                      default = nil)
  if valid_402656622 != nil:
    section.add "IdentityPoolId", valid_402656622
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
  var valid_402656623 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Security-Token", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Signature")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Signature", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Algorithm", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Date")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Date", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Credential")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Credential", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656629
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

proc call*(call_402656631: Call_SetIdentityPoolConfiguration_402656619;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656631.validator(path, query, header, formData, body, _)
  let scheme = call_402656631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656631.makeUrl(scheme.get, call_402656631.host, call_402656631.base,
                                   call_402656631.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656631, uri, valid, _)

proc call*(call_402656632: Call_SetIdentityPoolConfiguration_402656619;
           IdentityPoolId: string; body: JsonNode): Recallable =
  ## setIdentityPoolConfiguration
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                     ## IdentityPoolId: string (required)
                                                                                                                                                                                                                     ##                 
                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                     ## name-spaced 
                                                                                                                                                                                                                     ## GUID 
                                                                                                                                                                                                                     ## (for 
                                                                                                                                                                                                                     ## example, 
                                                                                                                                                                                                                     ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                     ## created 
                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                     ## Cognito. 
                                                                                                                                                                                                                     ## This 
                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## ID 
                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## pool 
                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                     ## modify.
  ##   
                                                                                                                                                                                                                               ## body: JObject (required)
  var path_402656633 = newJObject()
  var body_402656634 = newJObject()
  add(path_402656633, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_402656634 = body
  result = call_402656632.call(path_402656633, nil, nil, nil, body_402656634)

var setIdentityPoolConfiguration* = Call_SetIdentityPoolConfiguration_402656619(
    name: "setIdentityPoolConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_SetIdentityPoolConfiguration_402656620, base: "/",
    makeUrl: url_SetIdentityPoolConfiguration_402656621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolConfiguration_402656605 = ref object of OpenApiRestCall_402656038
proc url_GetIdentityPoolConfiguration_402656607(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIdentityPoolConfiguration_402656606(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
                                 ##                 : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. This is the ID of the pool for which to return a configuration.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityPoolId` field"
  var valid_402656608 = path.getOrDefault("IdentityPoolId")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "IdentityPoolId", valid_402656608
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
  var valid_402656609 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Security-Token", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Signature")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Signature", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Algorithm", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Date")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Date", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Credential")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Credential", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656616: Call_GetIdentityPoolConfiguration_402656605;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656616.validator(path, query, header, formData, body, _)
  let scheme = call_402656616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656616.makeUrl(scheme.get, call_402656616.host, call_402656616.base,
                                   call_402656616.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656616, uri, valid, _)

proc call*(call_402656617: Call_GetIdentityPoolConfiguration_402656605;
           IdentityPoolId: string): Recallable =
  ## getIdentityPoolConfiguration
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                          ## IdentityPoolId: string (required)
                                                                                                                                                                                                                          ##                 
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## A 
                                                                                                                                                                                                                          ## name-spaced 
                                                                                                                                                                                                                          ## GUID 
                                                                                                                                                                                                                          ## (for 
                                                                                                                                                                                                                          ## example, 
                                                                                                                                                                                                                          ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                          ## created 
                                                                                                                                                                                                                          ## by 
                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                          ## Cognito. 
                                                                                                                                                                                                                          ## This 
                                                                                                                                                                                                                          ## is 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## ID 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## pool 
                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                          ## which 
                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                          ## return 
                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                          ## configuration.
  var path_402656618 = newJObject()
  add(path_402656618, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656617.call(path_402656618, nil, nil, nil, nil)

var getIdentityPoolConfiguration* = Call_GetIdentityPoolConfiguration_402656605(
    name: "getIdentityPoolConfiguration", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_GetIdentityPoolConfiguration_402656606, base: "/",
    makeUrl: url_GetIdentityPoolConfiguration_402656607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_402656635 = ref object of OpenApiRestCall_402656038
proc url_ListDatasets_402656637(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/datasets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDatasets_402656636(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  ##   
                                                                                                 ## IdentityPoolId: JString (required)
                                                                                                 ##                 
                                                                                                 ## : 
                                                                                                 ## A 
                                                                                                 ## name-spaced 
                                                                                                 ## GUID 
                                                                                                 ## (for 
                                                                                                 ## example, 
                                                                                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                 ## created 
                                                                                                 ## by 
                                                                                                 ## Amazon 
                                                                                                 ## Cognito. 
                                                                                                 ## GUID 
                                                                                                 ## generation 
                                                                                                 ## is 
                                                                                                 ## unique 
                                                                                                 ## within 
                                                                                                 ## a 
                                                                                                 ## region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656638 = path.getOrDefault("IdentityId")
  valid_402656638 = validateParameter(valid_402656638, JString, required = true,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "IdentityId", valid_402656638
  var valid_402656639 = path.getOrDefault("IdentityPoolId")
  valid_402656639 = validateParameter(valid_402656639, JString, required = true,
                                      default = nil)
  if valid_402656639 != nil:
    section.add "IdentityPoolId", valid_402656639
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to be returned.
  ##   
                                                                                                ## nextToken: JString
                                                                                                ##            
                                                                                                ## : 
                                                                                                ## A 
                                                                                                ## pagination 
                                                                                                ## token 
                                                                                                ## for 
                                                                                                ## obtaining 
                                                                                                ## the 
                                                                                                ## next 
                                                                                                ## page 
                                                                                                ## of 
                                                                                                ## results.
  section = newJObject()
  var valid_402656640 = query.getOrDefault("maxResults")
  valid_402656640 = validateParameter(valid_402656640, JInt, required = false,
                                      default = nil)
  if valid_402656640 != nil:
    section.add "maxResults", valid_402656640
  var valid_402656641 = query.getOrDefault("nextToken")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "nextToken", valid_402656641
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
  var valid_402656642 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Security-Token", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Signature")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Signature", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Algorithm", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Date")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Date", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Credential")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Credential", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656649: Call_ListDatasets_402656635; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
                                                                                         ## 
  let valid = call_402656649.validator(path, query, header, formData, body, _)
  let scheme = call_402656649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656649.makeUrl(scheme.get, call_402656649.host, call_402656649.base,
                                   call_402656649.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656649, uri, valid, _)

proc call*(call_402656650: Call_ListDatasets_402656635; IdentityId: string;
           IdentityPoolId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDatasets
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                    ## IdentityId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                    ## region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                              ## maxResults: int
                                                                                                                                                                                                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## returned.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## obtaining 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## page 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                          ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## region.
  var path_402656651 = newJObject()
  var query_402656652 = newJObject()
  add(path_402656651, "IdentityId", newJString(IdentityId))
  add(query_402656652, "maxResults", newJInt(maxResults))
  add(query_402656652, "nextToken", newJString(nextToken))
  add(path_402656651, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_402656650.call(path_402656651, query_402656652, nil, nil, nil)

var listDatasets* = Call_ListDatasets_402656635(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets",
    validator: validate_ListDatasets_402656636, base: "/",
    makeUrl: url_ListDatasets_402656637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPoolUsage_402656653 = ref object of OpenApiRestCall_402656038
proc url_ListIdentityPoolUsage_402656655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIdentityPoolUsage_402656654(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to be returned.
  ##   
                                                                                                ## nextToken: JString
                                                                                                ##            
                                                                                                ## : 
                                                                                                ## A 
                                                                                                ## pagination 
                                                                                                ## token 
                                                                                                ## for 
                                                                                                ## obtaining 
                                                                                                ## the 
                                                                                                ## next 
                                                                                                ## page 
                                                                                                ## of 
                                                                                                ## results.
  section = newJObject()
  var valid_402656656 = query.getOrDefault("maxResults")
  valid_402656656 = validateParameter(valid_402656656, JInt, required = false,
                                      default = nil)
  if valid_402656656 != nil:
    section.add "maxResults", valid_402656656
  var valid_402656657 = query.getOrDefault("nextToken")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "nextToken", valid_402656657
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
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656665: Call_ListIdentityPoolUsage_402656653;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
                                                                                         ## 
  let valid = call_402656665.validator(path, query, header, formData, body, _)
  let scheme = call_402656665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656665.makeUrl(scheme.get, call_402656665.host, call_402656665.base,
                                   call_402656665.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656665, uri, valid, _)

proc call*(call_402656666: Call_ListIdentityPoolUsage_402656653;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIdentityPoolUsage
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ##   
                                                                                                                                                                                                                                              ## maxResults: int
                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                              ## maximum 
                                                                                                                                                                                                                                              ## number 
                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                              ## results 
                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                              ## be 
                                                                                                                                                                                                                                              ## returned.
  ##   
                                                                                                                                                                                                                                                          ## nextToken: string
                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                          ## A 
                                                                                                                                                                                                                                                          ## pagination 
                                                                                                                                                                                                                                                          ## token 
                                                                                                                                                                                                                                                          ## for 
                                                                                                                                                                                                                                                          ## obtaining 
                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                          ## next 
                                                                                                                                                                                                                                                          ## page 
                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                          ## results.
  var query_402656667 = newJObject()
  add(query_402656667, "maxResults", newJInt(maxResults))
  add(query_402656667, "nextToken", newJString(nextToken))
  result = call_402656666.call(nil, query_402656667, nil, nil, nil)

var listIdentityPoolUsage* = Call_ListIdentityPoolUsage_402656653(
    name: "listIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools",
    validator: validate_ListIdentityPoolUsage_402656654, base: "/",
    makeUrl: url_ListIdentityPoolUsage_402656655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecords_402656668 = ref object of OpenApiRestCall_402656038
proc url_ListRecords_402656670(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  assert "DatasetName" in path, "`DatasetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/datasets/"),
                 (kind: VariableSegment, value: "DatasetName"),
                 (kind: ConstantSegment, value: "/records")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecords_402656669(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : A name-spaced GUID (for example, 
                                 ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                 ## created 
                                 ## by Amazon Cognito. GUID generation is unique within a region.
  ##   
                                                                                                 ## DatasetName: JString (required)
                                                                                                 ##              
                                                                                                 ## : 
                                                                                                 ## A 
                                                                                                 ## string 
                                                                                                 ## of 
                                                                                                 ## up 
                                                                                                 ## to 
                                                                                                 ## 128 
                                                                                                 ## characters. 
                                                                                                 ## Allowed 
                                                                                                 ## characters 
                                                                                                 ## are 
                                                                                                 ## a-z, 
                                                                                                 ## A-Z, 
                                                                                                 ## 0-9, 
                                                                                                 ## '_' 
                                                                                                 ## (underscore), 
                                                                                                 ## '-' 
                                                                                                 ## (dash), 
                                                                                                 ## and 
                                                                                                 ## '.' 
                                                                                                 ## (dot).
  ##   
                                                                                                          ## IdentityPoolId: JString (required)
                                                                                                          ##                 
                                                                                                          ## : 
                                                                                                          ## A 
                                                                                                          ## name-spaced 
                                                                                                          ## GUID 
                                                                                                          ## (for 
                                                                                                          ## example, 
                                                                                                          ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                          ## created 
                                                                                                          ## by 
                                                                                                          ## Amazon 
                                                                                                          ## Cognito. 
                                                                                                          ## GUID 
                                                                                                          ## generation 
                                                                                                          ## is 
                                                                                                          ## unique 
                                                                                                          ## within 
                                                                                                          ## a 
                                                                                                          ## region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656671 = path.getOrDefault("IdentityId")
  valid_402656671 = validateParameter(valid_402656671, JString, required = true,
                                      default = nil)
  if valid_402656671 != nil:
    section.add "IdentityId", valid_402656671
  var valid_402656672 = path.getOrDefault("DatasetName")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true,
                                      default = nil)
  if valid_402656672 != nil:
    section.add "DatasetName", valid_402656672
  var valid_402656673 = path.getOrDefault("IdentityPoolId")
  valid_402656673 = validateParameter(valid_402656673, JString, required = true,
                                      default = nil)
  if valid_402656673 != nil:
    section.add "IdentityPoolId", valid_402656673
  result.add "path", section
  ## parameters in `query` object:
  ##   syncSessionToken: JString
                                  ##                   : A token containing a session ID, identity ID, and expiration.
  ##   
                                                                                                                      ## maxResults: JInt
                                                                                                                      ##             
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## maximum 
                                                                                                                      ## number 
                                                                                                                      ## of 
                                                                                                                      ## results 
                                                                                                                      ## to 
                                                                                                                      ## be 
                                                                                                                      ## returned.
  ##   
                                                                                                                                  ## nextToken: JString
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## A 
                                                                                                                                  ## pagination 
                                                                                                                                  ## token 
                                                                                                                                  ## for 
                                                                                                                                  ## obtaining 
                                                                                                                                  ## the 
                                                                                                                                  ## next 
                                                                                                                                  ## page 
                                                                                                                                  ## of 
                                                                                                                                  ## results.
  ##   
                                                                                                                                             ## lastSyncCount: JInt
                                                                                                                                             ##                
                                                                                                                                             ## : 
                                                                                                                                             ## The 
                                                                                                                                             ## last 
                                                                                                                                             ## server 
                                                                                                                                             ## sync 
                                                                                                                                             ## count 
                                                                                                                                             ## for 
                                                                                                                                             ## this 
                                                                                                                                             ## record.
  section = newJObject()
  var valid_402656674 = query.getOrDefault("syncSessionToken")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "syncSessionToken", valid_402656674
  var valid_402656675 = query.getOrDefault("maxResults")
  valid_402656675 = validateParameter(valid_402656675, JInt, required = false,
                                      default = nil)
  if valid_402656675 != nil:
    section.add "maxResults", valid_402656675
  var valid_402656676 = query.getOrDefault("nextToken")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "nextToken", valid_402656676
  var valid_402656677 = query.getOrDefault("lastSyncCount")
  valid_402656677 = validateParameter(valid_402656677, JInt, required = false,
                                      default = nil)
  if valid_402656677 != nil:
    section.add "lastSyncCount", valid_402656677
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
  var valid_402656678 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Security-Token", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Signature")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Signature", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Algorithm", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Date")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Date", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Credential")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Credential", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656685: Call_ListRecords_402656668; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
                                                                                         ## 
  let valid = call_402656685.validator(path, query, header, formData, body, _)
  let scheme = call_402656685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656685.makeUrl(scheme.get, call_402656685.host, call_402656685.base,
                                   call_402656685.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656685, uri, valid, _)

proc call*(call_402656686: Call_ListRecords_402656668; IdentityId: string;
           DatasetName: string; IdentityPoolId: string;
           syncSessionToken: string = ""; maxResults: int = 0;
           nextToken: string = ""; lastSyncCount: int = 0): Recallable =
  ## listRecords
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## syncSessionToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##                   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## containing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## session 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## ID, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## identity 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## ID, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## expiration.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## IdentityId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## DatasetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## string 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## up 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## 128 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## characters. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Allowed 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## characters 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## a-z, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## A-Z, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## 0-9, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## '_' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## (underscore), 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## '-' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## (dash), 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## '.' 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## (dot).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## maxResults: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## returned.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## obtaining 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## page 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## name-spaced 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## (for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## created 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Cognito. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## GUID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## generation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## unique 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## within 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## lastSyncCount: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## last 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## server 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## sync 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## count 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## record.
  var path_402656687 = newJObject()
  var query_402656688 = newJObject()
  add(query_402656688, "syncSessionToken", newJString(syncSessionToken))
  add(path_402656687, "IdentityId", newJString(IdentityId))
  add(path_402656687, "DatasetName", newJString(DatasetName))
  add(query_402656688, "maxResults", newJInt(maxResults))
  add(query_402656688, "nextToken", newJString(nextToken))
  add(path_402656687, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_402656688, "lastSyncCount", newJInt(lastSyncCount))
  result = call_402656686.call(path_402656687, query_402656688, nil, nil, nil)

var listRecords* = Call_ListRecords_402656668(name: "listRecords",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/records",
    validator: validate_ListRecords_402656669, base: "/",
    makeUrl: url_ListRecords_402656670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDevice_402656689 = ref object of OpenApiRestCall_402656038
proc url_RegisterDevice_402656691(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identity/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/device")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterDevice_402656690(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : The unique ID for this identity.
  ##   
                                                                                  ## IdentityPoolId: JString (required)
                                                                                  ##                 
                                                                                  ## : 
                                                                                  ## A 
                                                                                  ## name-spaced 
                                                                                  ## GUID 
                                                                                  ## (for 
                                                                                  ## example, 
                                                                                  ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                  ## created 
                                                                                  ## by 
                                                                                  ## Amazon 
                                                                                  ## Cognito. 
                                                                                  ## Here, 
                                                                                  ## the 
                                                                                  ## ID 
                                                                                  ## of 
                                                                                  ## the 
                                                                                  ## pool 
                                                                                  ## that 
                                                                                  ## the 
                                                                                  ## identity 
                                                                                  ## belongs 
                                                                                  ## to.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656692 = path.getOrDefault("IdentityId")
  valid_402656692 = validateParameter(valid_402656692, JString, required = true,
                                      default = nil)
  if valid_402656692 != nil:
    section.add "IdentityId", valid_402656692
  var valid_402656693 = path.getOrDefault("IdentityPoolId")
  valid_402656693 = validateParameter(valid_402656693, JString, required = true,
                                      default = nil)
  if valid_402656693 != nil:
    section.add "IdentityPoolId", valid_402656693
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
  var valid_402656694 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Security-Token", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Signature")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Signature", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Algorithm", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Date")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Date", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Credential")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Credential", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656700
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

proc call*(call_402656702: Call_RegisterDevice_402656689; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
                                                                                         ## 
  let valid = call_402656702.validator(path, query, header, formData, body, _)
  let scheme = call_402656702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656702.makeUrl(scheme.get, call_402656702.host, call_402656702.base,
                                   call_402656702.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656702, uri, valid, _)

proc call*(call_402656703: Call_RegisterDevice_402656689; IdentityId: string;
           IdentityPoolId: string; body: JsonNode): Recallable =
  ## registerDevice
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   
                                                                                                                                                                                                                   ## IdentityId: string (required)
                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                   ## unique 
                                                                                                                                                                                                                   ## ID 
                                                                                                                                                                                                                   ## for 
                                                                                                                                                                                                                   ## this 
                                                                                                                                                                                                                   ## identity.
  ##   
                                                                                                                                                                                                                               ## IdentityPoolId: string (required)
                                                                                                                                                                                                                               ##                 
                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                               ## A 
                                                                                                                                                                                                                               ## name-spaced 
                                                                                                                                                                                                                               ## GUID 
                                                                                                                                                                                                                               ## (for 
                                                                                                                                                                                                                               ## example, 
                                                                                                                                                                                                                               ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                               ## created 
                                                                                                                                                                                                                               ## by 
                                                                                                                                                                                                                               ## Amazon 
                                                                                                                                                                                                                               ## Cognito. 
                                                                                                                                                                                                                               ## Here, 
                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                               ## ID 
                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                               ## pool 
                                                                                                                                                                                                                               ## that 
                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                               ## identity 
                                                                                                                                                                                                                               ## belongs 
                                                                                                                                                                                                                               ## to.
  ##   
                                                                                                                                                                                                                                     ## body: JObject (required)
  var path_402656704 = newJObject()
  var body_402656705 = newJObject()
  add(path_402656704, "IdentityId", newJString(IdentityId))
  add(path_402656704, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_402656705 = body
  result = call_402656703.call(path_402656704, nil, nil, nil, body_402656705)

var registerDevice* = Call_RegisterDevice_402656689(name: "registerDevice",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identity/{IdentityId}/device",
    validator: validate_RegisterDevice_402656690, base: "/",
    makeUrl: url_RegisterDevice_402656691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToDataset_402656706 = ref object of OpenApiRestCall_402656038
proc url_SubscribeToDataset_402656708(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  assert "DatasetName" in path, "`DatasetName` is a required path parameter"
  assert "DeviceId" in path, "`DeviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/datasets/"),
                 (kind: VariableSegment, value: "DatasetName"),
                 (kind: ConstantSegment, value: "/subscriptions/"),
                 (kind: VariableSegment, value: "DeviceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SubscribeToDataset_402656707(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : Unique ID for this identity.
  ##   
                                                                              ## DatasetName: JString (required)
                                                                              ##              
                                                                              ## : 
                                                                              ## The 
                                                                              ## name 
                                                                              ## of 
                                                                              ## the 
                                                                              ## dataset 
                                                                              ## to 
                                                                              ## subcribe 
                                                                              ## to.
  ##   
                                                                                    ## IdentityPoolId: JString (required)
                                                                                    ##                 
                                                                                    ## : 
                                                                                    ## A 
                                                                                    ## name-spaced 
                                                                                    ## GUID 
                                                                                    ## (for 
                                                                                    ## example, 
                                                                                    ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                    ## created 
                                                                                    ## by 
                                                                                    ## Amazon 
                                                                                    ## Cognito. 
                                                                                    ## The 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## pool 
                                                                                    ## to 
                                                                                    ## which 
                                                                                    ## the 
                                                                                    ## identity 
                                                                                    ## belongs.
  ##   
                                                                                               ## DeviceId: JString (required)
                                                                                               ##           
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## unique 
                                                                                               ## ID 
                                                                                               ## generated 
                                                                                               ## for 
                                                                                               ## this 
                                                                                               ## device 
                                                                                               ## by 
                                                                                               ## Cognito.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656709 = path.getOrDefault("IdentityId")
  valid_402656709 = validateParameter(valid_402656709, JString, required = true,
                                      default = nil)
  if valid_402656709 != nil:
    section.add "IdentityId", valid_402656709
  var valid_402656710 = path.getOrDefault("DatasetName")
  valid_402656710 = validateParameter(valid_402656710, JString, required = true,
                                      default = nil)
  if valid_402656710 != nil:
    section.add "DatasetName", valid_402656710
  var valid_402656711 = path.getOrDefault("IdentityPoolId")
  valid_402656711 = validateParameter(valid_402656711, JString, required = true,
                                      default = nil)
  if valid_402656711 != nil:
    section.add "IdentityPoolId", valid_402656711
  var valid_402656712 = path.getOrDefault("DeviceId")
  valid_402656712 = validateParameter(valid_402656712, JString, required = true,
                                      default = nil)
  if valid_402656712 != nil:
    section.add "DeviceId", valid_402656712
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
  var valid_402656713 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Security-Token", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Signature")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Signature", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Algorithm", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Date")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Date", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Credential")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Credential", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656720: Call_SubscribeToDataset_402656706;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
                                                                                         ## 
  let valid = call_402656720.validator(path, query, header, formData, body, _)
  let scheme = call_402656720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656720.makeUrl(scheme.get, call_402656720.host, call_402656720.base,
                                   call_402656720.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656720, uri, valid, _)

proc call*(call_402656721: Call_SubscribeToDataset_402656706;
           IdentityId: string; DatasetName: string; IdentityPoolId: string;
           DeviceId: string): Recallable =
  ## subscribeToDataset
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   
                                                                                                                                                                                                                                              ## IdentityId: string (required)
                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                              ## Unique 
                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                              ## for 
                                                                                                                                                                                                                                              ## this 
                                                                                                                                                                                                                                              ## identity.
  ##   
                                                                                                                                                                                                                                                          ## DatasetName: string (required)
                                                                                                                                                                                                                                                          ##              
                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                          ## name 
                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                          ## dataset 
                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                          ## subcribe 
                                                                                                                                                                                                                                                          ## to.
  ##   
                                                                                                                                                                                                                                                                ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                ##                 
                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                                                ## name-spaced 
                                                                                                                                                                                                                                                                ## GUID 
                                                                                                                                                                                                                                                                ## (for 
                                                                                                                                                                                                                                                                ## example, 
                                                                                                                                                                                                                                                                ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                ## created 
                                                                                                                                                                                                                                                                ## by 
                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                ## Cognito. 
                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                ## ID 
                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                ## pool 
                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                ## which 
                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                ## identity 
                                                                                                                                                                                                                                                                ## belongs.
  ##   
                                                                                                                                                                                                                                                                           ## DeviceId: string (required)
                                                                                                                                                                                                                                                                           ##           
                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                           ## unique 
                                                                                                                                                                                                                                                                           ## ID 
                                                                                                                                                                                                                                                                           ## generated 
                                                                                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                                                                                           ## this 
                                                                                                                                                                                                                                                                           ## device 
                                                                                                                                                                                                                                                                           ## by 
                                                                                                                                                                                                                                                                           ## Cognito.
  var path_402656722 = newJObject()
  add(path_402656722, "IdentityId", newJString(IdentityId))
  add(path_402656722, "DatasetName", newJString(DatasetName))
  add(path_402656722, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_402656722, "DeviceId", newJString(DeviceId))
  result = call_402656721.call(path_402656722, nil, nil, nil, nil)

var subscribeToDataset* = Call_SubscribeToDataset_402656706(
    name: "subscribeToDataset", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_SubscribeToDataset_402656707, base: "/",
    makeUrl: url_SubscribeToDataset_402656708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromDataset_402656723 = ref object of OpenApiRestCall_402656038
proc url_UnsubscribeFromDataset_402656725(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path,
         "`IdentityPoolId` is a required path parameter"
  assert "IdentityId" in path, "`IdentityId` is a required path parameter"
  assert "DatasetName" in path, "`DatasetName` is a required path parameter"
  assert "DeviceId" in path, "`DeviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
                 (kind: VariableSegment, value: "IdentityPoolId"),
                 (kind: ConstantSegment, value: "/identities/"),
                 (kind: VariableSegment, value: "IdentityId"),
                 (kind: ConstantSegment, value: "/datasets/"),
                 (kind: VariableSegment, value: "DatasetName"),
                 (kind: ConstantSegment, value: "/subscriptions/"),
                 (kind: VariableSegment, value: "DeviceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UnsubscribeFromDataset_402656724(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
                                 ##             : Unique ID for this identity.
  ##   
                                                                              ## DatasetName: JString (required)
                                                                              ##              
                                                                              ## : 
                                                                              ## The 
                                                                              ## name 
                                                                              ## of 
                                                                              ## the 
                                                                              ## dataset 
                                                                              ## from 
                                                                              ## which 
                                                                              ## to 
                                                                              ## unsubcribe.
  ##   
                                                                                            ## IdentityPoolId: JString (required)
                                                                                            ##                 
                                                                                            ## : 
                                                                                            ## A 
                                                                                            ## name-spaced 
                                                                                            ## GUID 
                                                                                            ## (for 
                                                                                            ## example, 
                                                                                            ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                            ## created 
                                                                                            ## by 
                                                                                            ## Amazon 
                                                                                            ## Cognito. 
                                                                                            ## The 
                                                                                            ## ID 
                                                                                            ## of 
                                                                                            ## the 
                                                                                            ## pool 
                                                                                            ## to 
                                                                                            ## which 
                                                                                            ## this 
                                                                                            ## identity 
                                                                                            ## belongs.
  ##   
                                                                                                       ## DeviceId: JString (required)
                                                                                                       ##           
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## unique 
                                                                                                       ## ID 
                                                                                                       ## generated 
                                                                                                       ## for 
                                                                                                       ## this 
                                                                                                       ## device 
                                                                                                       ## by 
                                                                                                       ## Cognito.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `IdentityId` field"
  var valid_402656726 = path.getOrDefault("IdentityId")
  valid_402656726 = validateParameter(valid_402656726, JString, required = true,
                                      default = nil)
  if valid_402656726 != nil:
    section.add "IdentityId", valid_402656726
  var valid_402656727 = path.getOrDefault("DatasetName")
  valid_402656727 = validateParameter(valid_402656727, JString, required = true,
                                      default = nil)
  if valid_402656727 != nil:
    section.add "DatasetName", valid_402656727
  var valid_402656728 = path.getOrDefault("IdentityPoolId")
  valid_402656728 = validateParameter(valid_402656728, JString, required = true,
                                      default = nil)
  if valid_402656728 != nil:
    section.add "IdentityPoolId", valid_402656728
  var valid_402656729 = path.getOrDefault("DeviceId")
  valid_402656729 = validateParameter(valid_402656729, JString, required = true,
                                      default = nil)
  if valid_402656729 != nil:
    section.add "DeviceId", valid_402656729
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
  var valid_402656730 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Security-Token", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Signature")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Signature", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Algorithm", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Date")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Date", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Credential")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Credential", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656737: Call_UnsubscribeFromDataset_402656723;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
                                                                                         ## 
  let valid = call_402656737.validator(path, query, header, formData, body, _)
  let scheme = call_402656737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656737.makeUrl(scheme.get, call_402656737.host, call_402656737.base,
                                   call_402656737.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656737, uri, valid, _)

proc call*(call_402656738: Call_UnsubscribeFromDataset_402656723;
           IdentityId: string; DatasetName: string; IdentityPoolId: string;
           DeviceId: string): Recallable =
  ## unsubscribeFromDataset
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   
                                                                                                                                                                                                                                                    ## IdentityId: string (required)
                                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                    ## Unique 
                                                                                                                                                                                                                                                    ## ID 
                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                                                    ## identity.
  ##   
                                                                                                                                                                                                                                                                ## DatasetName: string (required)
                                                                                                                                                                                                                                                                ##              
                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                ## name 
                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                ## dataset 
                                                                                                                                                                                                                                                                ## from 
                                                                                                                                                                                                                                                                ## which 
                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                ## unsubcribe.
  ##   
                                                                                                                                                                                                                                                                              ## IdentityPoolId: string (required)
                                                                                                                                                                                                                                                                              ##                 
                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                              ## A 
                                                                                                                                                                                                                                                                              ## name-spaced 
                                                                                                                                                                                                                                                                              ## GUID 
                                                                                                                                                                                                                                                                              ## (for 
                                                                                                                                                                                                                                                                              ## example, 
                                                                                                                                                                                                                                                                              ## us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) 
                                                                                                                                                                                                                                                                              ## created 
                                                                                                                                                                                                                                                                              ## by 
                                                                                                                                                                                                                                                                              ## Amazon 
                                                                                                                                                                                                                                                                              ## Cognito. 
                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                              ## pool 
                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                              ## which 
                                                                                                                                                                                                                                                                              ## this 
                                                                                                                                                                                                                                                                              ## identity 
                                                                                                                                                                                                                                                                              ## belongs.
  ##   
                                                                                                                                                                                                                                                                                         ## DeviceId: string (required)
                                                                                                                                                                                                                                                                                         ##           
                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                         ## unique 
                                                                                                                                                                                                                                                                                         ## ID 
                                                                                                                                                                                                                                                                                         ## generated 
                                                                                                                                                                                                                                                                                         ## for 
                                                                                                                                                                                                                                                                                         ## this 
                                                                                                                                                                                                                                                                                         ## device 
                                                                                                                                                                                                                                                                                         ## by 
                                                                                                                                                                                                                                                                                         ## Cognito.
  var path_402656739 = newJObject()
  add(path_402656739, "IdentityId", newJString(IdentityId))
  add(path_402656739, "DatasetName", newJString(DatasetName))
  add(path_402656739, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_402656739, "DeviceId", newJString(DeviceId))
  result = call_402656738.call(path_402656739, nil, nil, nil, nil)

var unsubscribeFromDataset* = Call_UnsubscribeFromDataset_402656723(
    name: "unsubscribeFromDataset", meth: HttpMethod.HttpDelete,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_UnsubscribeFromDataset_402656724, base: "/",
    makeUrl: url_UnsubscribeFromDataset_402656725,
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