
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cognito-sync.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cognito-sync.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cognito-sync.us-west-2.amazonaws.com",
                           "eu-west-2": "cognito-sync.eu-west-2.amazonaws.com", "ap-northeast-3": "cognito-sync.ap-northeast-3.amazonaws.com", "eu-central-1": "cognito-sync.eu-central-1.amazonaws.com",
                           "us-east-2": "cognito-sync.us-east-2.amazonaws.com",
                           "us-east-1": "cognito-sync.us-east-1.amazonaws.com", "cn-northwest-1": "cognito-sync.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cognito-sync.ap-south-1.amazonaws.com", "eu-north-1": "cognito-sync.eu-north-1.amazonaws.com", "ap-northeast-2": "cognito-sync.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cognito-sync.us-west-1.amazonaws.com", "us-gov-east-1": "cognito-sync.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cognito-sync.eu-west-3.amazonaws.com", "cn-north-1": "cognito-sync.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cognito-sync.sa-east-1.amazonaws.com",
                           "eu-west-1": "cognito-sync.eu-west-1.amazonaws.com", "us-gov-west-1": "cognito-sync.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cognito-sync.ap-southeast-2.amazonaws.com", "ca-central-1": "cognito-sync.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BulkPublish_21625779 = ref object of OpenApiRestCall_21625435
proc url_BulkPublish_21625781(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_BulkPublish_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityPoolId` field"
  var valid_21625895 = path.getOrDefault("IdentityPoolId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "IdentityPoolId", valid_21625895
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
  var valid_21625896 = header.getOrDefault("X-Amz-Date")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Date", valid_21625896
  var valid_21625897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Security-Token", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Algorithm", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Signature")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Signature", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Credential")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Credential", valid_21625902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625927: Call_BulkPublish_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21625927.validator(path, query, header, formData, body, _)
  let scheme = call_21625927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625927.makeUrl(scheme.get, call_21625927.host, call_21625927.base,
                               call_21625927.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625927, uri, valid, _)

proc call*(call_21625990: Call_BulkPublish_21625779; IdentityPoolId: string): Recallable =
  ## bulkPublish
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_21625992 = newJObject()
  add(path_21625992, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_21625990.call(path_21625992, nil, nil, nil, nil)

var bulkPublish* = Call_BulkPublish_21625779(name: "bulkPublish",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/bulkpublish",
    validator: validate_BulkPublish_21625780, base: "/", makeUrl: url_BulkPublish_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecords_21626046 = ref object of OpenApiRestCall_21625435
proc url_UpdateRecords_21626048(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_UpdateRecords_21626047(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: JString (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626049 = path.getOrDefault("IdentityId")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "IdentityId", valid_21626049
  var valid_21626050 = path.getOrDefault("IdentityPoolId")
  valid_21626050 = validateParameter(valid_21626050, JString, required = true,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "IdentityPoolId", valid_21626050
  var valid_21626051 = path.getOrDefault("DatasetName")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "DatasetName", valid_21626051
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   x-amz-Client-Context: JString
  ##                       : Intended to supply a device ID that will populate the lastModifiedBy field referenced in other methods. The ClientContext field is not yet implemented.
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626052 = header.getOrDefault("X-Amz-Date")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Date", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Security-Token", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Algorithm", valid_21626055
  var valid_21626056 = header.getOrDefault("x-amz-Client-Context")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "x-amz-Client-Context", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Signature")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Signature", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Credential")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Credential", valid_21626059
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

proc call*(call_21626061: Call_UpdateRecords_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_UpdateRecords_21626046; IdentityId: string;
          IdentityPoolId: string; DatasetName: string; body: JsonNode): Recallable =
  ## updateRecords
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  ##   body: JObject (required)
  var path_21626063 = newJObject()
  var body_21626064 = newJObject()
  add(path_21626063, "IdentityId", newJString(IdentityId))
  add(path_21626063, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_21626063, "DatasetName", newJString(DatasetName))
  if body != nil:
    body_21626064 = body
  result = call_21626062.call(path_21626063, nil, nil, nil, body_21626064)

var updateRecords* = Call_UpdateRecords_21626046(name: "updateRecords",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_UpdateRecords_21626047, base: "/",
    makeUrl: url_UpdateRecords_21626048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_21626030 = ref object of OpenApiRestCall_21625435
proc url_DescribeDataset_21626032(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_DescribeDataset_21626031(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: JString (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626033 = path.getOrDefault("IdentityId")
  valid_21626033 = validateParameter(valid_21626033, JString, required = true,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "IdentityId", valid_21626033
  var valid_21626034 = path.getOrDefault("IdentityPoolId")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "IdentityPoolId", valid_21626034
  var valid_21626035 = path.getOrDefault("DatasetName")
  valid_21626035 = validateParameter(valid_21626035, JString, required = true,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "DatasetName", valid_21626035
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
  var valid_21626036 = header.getOrDefault("X-Amz-Date")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Date", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Security-Token", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Algorithm", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Signature")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Signature", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Credential")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Credential", valid_21626042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626043: Call_DescribeDataset_21626030; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_21626043.validator(path, query, header, formData, body, _)
  let scheme = call_21626043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626043.makeUrl(scheme.get, call_21626043.host, call_21626043.base,
                               call_21626043.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626043, uri, valid, _)

proc call*(call_21626044: Call_DescribeDataset_21626030; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## describeDataset
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_21626045 = newJObject()
  add(path_21626045, "IdentityId", newJString(IdentityId))
  add(path_21626045, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_21626045, "DatasetName", newJString(DatasetName))
  result = call_21626044.call(path_21626045, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_21626030(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DescribeDataset_21626031, base: "/",
    makeUrl: url_DescribeDataset_21626032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_21626065 = ref object of OpenApiRestCall_21625435
proc url_DeleteDataset_21626067(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_DeleteDataset_21626066(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: JString (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626068 = path.getOrDefault("IdentityId")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "IdentityId", valid_21626068
  var valid_21626069 = path.getOrDefault("IdentityPoolId")
  valid_21626069 = validateParameter(valid_21626069, JString, required = true,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "IdentityPoolId", valid_21626069
  var valid_21626070 = path.getOrDefault("DatasetName")
  valid_21626070 = validateParameter(valid_21626070, JString, required = true,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "DatasetName", valid_21626070
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
  var valid_21626071 = header.getOrDefault("X-Amz-Date")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Date", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Security-Token", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Algorithm", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Signature")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Signature", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Credential")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Credential", valid_21626077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626078: Call_DeleteDataset_21626065; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_21626078.validator(path, query, header, formData, body, _)
  let scheme = call_21626078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626078.makeUrl(scheme.get, call_21626078.host, call_21626078.base,
                               call_21626078.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626078, uri, valid, _)

proc call*(call_21626079: Call_DeleteDataset_21626065; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_21626080 = newJObject()
  add(path_21626080, "IdentityId", newJString(IdentityId))
  add(path_21626080, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_21626080, "DatasetName", newJString(DatasetName))
  result = call_21626079.call(path_21626080, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_21626065(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DeleteDataset_21626066, base: "/",
    makeUrl: url_DeleteDataset_21626067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPoolUsage_21626081 = ref object of OpenApiRestCall_21625435
proc url_DescribeIdentityPoolUsage_21626083(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_DescribeIdentityPoolUsage_21626082(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityPoolId` field"
  var valid_21626084 = path.getOrDefault("IdentityPoolId")
  valid_21626084 = validateParameter(valid_21626084, JString, required = true,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "IdentityPoolId", valid_21626084
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
  var valid_21626085 = header.getOrDefault("X-Amz-Date")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Date", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Security-Token", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Algorithm", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Signature")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Signature", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Credential")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Credential", valid_21626091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626092: Call_DescribeIdentityPoolUsage_21626081;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_DescribeIdentityPoolUsage_21626081;
          IdentityPoolId: string): Recallable =
  ## describeIdentityPoolUsage
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_21626094 = newJObject()
  add(path_21626094, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_21626093.call(path_21626094, nil, nil, nil, nil)

var describeIdentityPoolUsage* = Call_DescribeIdentityPoolUsage_21626081(
    name: "describeIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}",
    validator: validate_DescribeIdentityPoolUsage_21626082, base: "/",
    makeUrl: url_DescribeIdentityPoolUsage_21626083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityUsage_21626095 = ref object of OpenApiRestCall_21625435
proc url_DescribeIdentityUsage_21626097(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_DescribeIdentityUsage_21626096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626098 = path.getOrDefault("IdentityId")
  valid_21626098 = validateParameter(valid_21626098, JString, required = true,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "IdentityId", valid_21626098
  var valid_21626099 = path.getOrDefault("IdentityPoolId")
  valid_21626099 = validateParameter(valid_21626099, JString, required = true,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "IdentityPoolId", valid_21626099
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
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Signature", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Credential")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Credential", valid_21626106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626107: Call_DescribeIdentityUsage_21626095;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_DescribeIdentityUsage_21626095; IdentityId: string;
          IdentityPoolId: string): Recallable =
  ## describeIdentityUsage
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_21626109 = newJObject()
  add(path_21626109, "IdentityId", newJString(IdentityId))
  add(path_21626109, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_21626108.call(path_21626109, nil, nil, nil, nil)

var describeIdentityUsage* = Call_DescribeIdentityUsage_21626095(
    name: "describeIdentityUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}",
    validator: validate_DescribeIdentityUsage_21626096, base: "/",
    makeUrl: url_DescribeIdentityUsage_21626097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkPublishDetails_21626110 = ref object of OpenApiRestCall_21625435
proc url_GetBulkPublishDetails_21626112(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_GetBulkPublishDetails_21626111(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityPoolId` field"
  var valid_21626113 = path.getOrDefault("IdentityPoolId")
  valid_21626113 = validateParameter(valid_21626113, JString, required = true,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "IdentityPoolId", valid_21626113
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
  var valid_21626114 = header.getOrDefault("X-Amz-Date")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Date", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Security-Token", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Algorithm", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Signature")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Signature", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Credential")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Credential", valid_21626120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626121: Call_GetBulkPublishDetails_21626110;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21626121.validator(path, query, header, formData, body, _)
  let scheme = call_21626121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626121.makeUrl(scheme.get, call_21626121.host, call_21626121.base,
                               call_21626121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626121, uri, valid, _)

proc call*(call_21626122: Call_GetBulkPublishDetails_21626110;
          IdentityPoolId: string): Recallable =
  ## getBulkPublishDetails
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_21626123 = newJObject()
  add(path_21626123, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_21626122.call(path_21626123, nil, nil, nil, nil)

var getBulkPublishDetails* = Call_GetBulkPublishDetails_21626110(
    name: "getBulkPublishDetails", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/getBulkPublishDetails",
    validator: validate_GetBulkPublishDetails_21626111, base: "/",
    makeUrl: url_GetBulkPublishDetails_21626112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetCognitoEvents_21626138 = ref object of OpenApiRestCall_21625435
proc url_SetCognitoEvents_21626140(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_SetCognitoEvents_21626139(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626141 = path.getOrDefault("IdentityPoolId")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "IdentityPoolId", valid_21626141
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
  var valid_21626142 = header.getOrDefault("X-Amz-Date")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Date", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Security-Token", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Algorithm", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Signature")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Signature", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Credential")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Credential", valid_21626148
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

proc call*(call_21626150: Call_SetCognitoEvents_21626138; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21626150.validator(path, query, header, formData, body, _)
  let scheme = call_21626150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626150.makeUrl(scheme.get, call_21626150.host, call_21626150.base,
                               call_21626150.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626150, uri, valid, _)

proc call*(call_21626151: Call_SetCognitoEvents_21626138; IdentityPoolId: string;
          body: JsonNode): Recallable =
  ## setCognitoEvents
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool to use when configuring Cognito Events
  ##   body: JObject (required)
  var path_21626152 = newJObject()
  var body_21626153 = newJObject()
  add(path_21626152, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_21626153 = body
  result = call_21626151.call(path_21626152, nil, nil, nil, body_21626153)

var setCognitoEvents* = Call_SetCognitoEvents_21626138(name: "setCognitoEvents",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_SetCognitoEvents_21626139, base: "/",
    makeUrl: url_SetCognitoEvents_21626140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCognitoEvents_21626124 = ref object of OpenApiRestCall_21625435
proc url_GetCognitoEvents_21626126(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_GetCognitoEvents_21626125(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626127 = path.getOrDefault("IdentityPoolId")
  valid_21626127 = validateParameter(valid_21626127, JString, required = true,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "IdentityPoolId", valid_21626127
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
  var valid_21626128 = header.getOrDefault("X-Amz-Date")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Date", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Security-Token", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Algorithm", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Signature")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Signature", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Credential")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Credential", valid_21626134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626135: Call_GetCognitoEvents_21626124; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21626135.validator(path, query, header, formData, body, _)
  let scheme = call_21626135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626135.makeUrl(scheme.get, call_21626135.host, call_21626135.base,
                               call_21626135.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626135, uri, valid, _)

proc call*(call_21626136: Call_GetCognitoEvents_21626124; IdentityPoolId: string): Recallable =
  ## getCognitoEvents
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool ID for the request
  var path_21626137 = newJObject()
  add(path_21626137, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_21626136.call(path_21626137, nil, nil, nil, nil)

var getCognitoEvents* = Call_GetCognitoEvents_21626124(name: "getCognitoEvents",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_GetCognitoEvents_21626125, base: "/",
    makeUrl: url_GetCognitoEvents_21626126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolConfiguration_21626168 = ref object of OpenApiRestCall_21625435
proc url_SetIdentityPoolConfiguration_21626170(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_SetIdentityPoolConfiguration_21626169(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool to modify.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityPoolId` field"
  var valid_21626171 = path.getOrDefault("IdentityPoolId")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "IdentityPoolId", valid_21626171
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
  var valid_21626172 = header.getOrDefault("X-Amz-Date")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Date", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Security-Token", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Algorithm", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Signature")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Signature", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Credential")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Credential", valid_21626178
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

proc call*(call_21626180: Call_SetIdentityPoolConfiguration_21626168;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21626180.validator(path, query, header, formData, body, _)
  let scheme = call_21626180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626180.makeUrl(scheme.get, call_21626180.host, call_21626180.base,
                               call_21626180.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626180, uri, valid, _)

proc call*(call_21626181: Call_SetIdentityPoolConfiguration_21626168;
          IdentityPoolId: string; body: JsonNode): Recallable =
  ## setIdentityPoolConfiguration
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool to modify.
  ##   body: JObject (required)
  var path_21626182 = newJObject()
  var body_21626183 = newJObject()
  add(path_21626182, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_21626183 = body
  result = call_21626181.call(path_21626182, nil, nil, nil, body_21626183)

var setIdentityPoolConfiguration* = Call_SetIdentityPoolConfiguration_21626168(
    name: "setIdentityPoolConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_SetIdentityPoolConfiguration_21626169, base: "/",
    makeUrl: url_SetIdentityPoolConfiguration_21626170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolConfiguration_21626154 = ref object of OpenApiRestCall_21625435
proc url_GetIdentityPoolConfiguration_21626156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_GetIdentityPoolConfiguration_21626155(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool for which to return a configuration.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityPoolId` field"
  var valid_21626157 = path.getOrDefault("IdentityPoolId")
  valid_21626157 = validateParameter(valid_21626157, JString, required = true,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "IdentityPoolId", valid_21626157
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
  var valid_21626158 = header.getOrDefault("X-Amz-Date")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Date", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Security-Token", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Algorithm", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Signature")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Signature", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Credential")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Credential", valid_21626164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626165: Call_GetIdentityPoolConfiguration_21626154;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21626165.validator(path, query, header, formData, body, _)
  let scheme = call_21626165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626165.makeUrl(scheme.get, call_21626165.host, call_21626165.base,
                               call_21626165.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626165, uri, valid, _)

proc call*(call_21626166: Call_GetIdentityPoolConfiguration_21626154;
          IdentityPoolId: string): Recallable =
  ## getIdentityPoolConfiguration
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool for which to return a configuration.
  var path_21626167 = newJObject()
  add(path_21626167, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_21626166.call(path_21626167, nil, nil, nil, nil)

var getIdentityPoolConfiguration* = Call_GetIdentityPoolConfiguration_21626154(
    name: "getIdentityPoolConfiguration", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_GetIdentityPoolConfiguration_21626155, base: "/",
    makeUrl: url_GetIdentityPoolConfiguration_21626156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_21626184 = ref object of OpenApiRestCall_21625435
proc url_ListDatasets_21626186(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_ListDatasets_21626185(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626187 = path.getOrDefault("IdentityId")
  valid_21626187 = validateParameter(valid_21626187, JString, required = true,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "IdentityId", valid_21626187
  var valid_21626188 = path.getOrDefault("IdentityPoolId")
  valid_21626188 = validateParameter(valid_21626188, JString, required = true,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "IdentityPoolId", valid_21626188
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  section = newJObject()
  var valid_21626189 = query.getOrDefault("maxResults")
  valid_21626189 = validateParameter(valid_21626189, JInt, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "maxResults", valid_21626189
  var valid_21626190 = query.getOrDefault("nextToken")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "nextToken", valid_21626190
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
  var valid_21626191 = header.getOrDefault("X-Amz-Date")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Date", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Security-Token", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Algorithm", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Signature")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Signature", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Credential")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Credential", valid_21626197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626198: Call_ListDatasets_21626184; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_21626198.validator(path, query, header, formData, body, _)
  let scheme = call_21626198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626198.makeUrl(scheme.get, call_21626198.host, call_21626198.base,
                               call_21626198.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626198, uri, valid, _)

proc call*(call_21626199: Call_ListDatasets_21626184; IdentityId: string;
          IdentityPoolId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDatasets
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  var path_21626200 = newJObject()
  var query_21626201 = newJObject()
  add(path_21626200, "IdentityId", newJString(IdentityId))
  add(path_21626200, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_21626201, "maxResults", newJInt(maxResults))
  add(query_21626201, "nextToken", newJString(nextToken))
  result = call_21626199.call(path_21626200, query_21626201, nil, nil, nil)

var listDatasets* = Call_ListDatasets_21626184(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets",
    validator: validate_ListDatasets_21626185, base: "/", makeUrl: url_ListDatasets_21626186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPoolUsage_21626203 = ref object of OpenApiRestCall_21625435
proc url_ListIdentityPoolUsage_21626205(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIdentityPoolUsage_21626204(path: JsonNode; query: JsonNode;
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
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  section = newJObject()
  var valid_21626206 = query.getOrDefault("maxResults")
  valid_21626206 = validateParameter(valid_21626206, JInt, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "maxResults", valid_21626206
  var valid_21626207 = query.getOrDefault("nextToken")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "nextToken", valid_21626207
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
  var valid_21626208 = header.getOrDefault("X-Amz-Date")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Date", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Security-Token", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Algorithm", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Signature")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Signature", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Credential")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Credential", valid_21626214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626215: Call_ListIdentityPoolUsage_21626203;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_21626215.validator(path, query, header, formData, body, _)
  let scheme = call_21626215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626215.makeUrl(scheme.get, call_21626215.host, call_21626215.base,
                               call_21626215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626215, uri, valid, _)

proc call*(call_21626216: Call_ListIdentityPoolUsage_21626203; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listIdentityPoolUsage
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  var query_21626217 = newJObject()
  add(query_21626217, "maxResults", newJInt(maxResults))
  add(query_21626217, "nextToken", newJString(nextToken))
  result = call_21626216.call(nil, query_21626217, nil, nil, nil)

var listIdentityPoolUsage* = Call_ListIdentityPoolUsage_21626203(
    name: "listIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools",
    validator: validate_ListIdentityPoolUsage_21626204, base: "/",
    makeUrl: url_ListIdentityPoolUsage_21626205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecords_21626218 = ref object of OpenApiRestCall_21625435
proc url_ListRecords_21626220(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_ListRecords_21626219(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: JString (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626221 = path.getOrDefault("IdentityId")
  valid_21626221 = validateParameter(valid_21626221, JString, required = true,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "IdentityId", valid_21626221
  var valid_21626222 = path.getOrDefault("IdentityPoolId")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "IdentityPoolId", valid_21626222
  var valid_21626223 = path.getOrDefault("DatasetName")
  valid_21626223 = validateParameter(valid_21626223, JString, required = true,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "DatasetName", valid_21626223
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  ##   lastSyncCount: JInt
  ##                : The last server sync count for this record.
  ##   syncSessionToken: JString
  ##                   : A token containing a session ID, identity ID, and expiration.
  section = newJObject()
  var valid_21626224 = query.getOrDefault("maxResults")
  valid_21626224 = validateParameter(valid_21626224, JInt, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "maxResults", valid_21626224
  var valid_21626225 = query.getOrDefault("nextToken")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "nextToken", valid_21626225
  var valid_21626226 = query.getOrDefault("lastSyncCount")
  valid_21626226 = validateParameter(valid_21626226, JInt, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "lastSyncCount", valid_21626226
  var valid_21626227 = query.getOrDefault("syncSessionToken")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "syncSessionToken", valid_21626227
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
  var valid_21626228 = header.getOrDefault("X-Amz-Date")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Date", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Security-Token", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626235: Call_ListRecords_21626218; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_21626235.validator(path, query, header, formData, body, _)
  let scheme = call_21626235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626235.makeUrl(scheme.get, call_21626235.host, call_21626235.base,
                               call_21626235.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626235, uri, valid, _)

proc call*(call_21626236: Call_ListRecords_21626218; IdentityId: string;
          IdentityPoolId: string; DatasetName: string; maxResults: int = 0;
          nextToken: string = ""; lastSyncCount: int = 0; syncSessionToken: string = ""): Recallable =
  ## listRecords
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  ##   lastSyncCount: int
  ##                : The last server sync count for this record.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  ##   syncSessionToken: string
  ##                   : A token containing a session ID, identity ID, and expiration.
  var path_21626237 = newJObject()
  var query_21626238 = newJObject()
  add(path_21626237, "IdentityId", newJString(IdentityId))
  add(path_21626237, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_21626238, "maxResults", newJInt(maxResults))
  add(query_21626238, "nextToken", newJString(nextToken))
  add(query_21626238, "lastSyncCount", newJInt(lastSyncCount))
  add(path_21626237, "DatasetName", newJString(DatasetName))
  add(query_21626238, "syncSessionToken", newJString(syncSessionToken))
  result = call_21626236.call(path_21626237, query_21626238, nil, nil, nil)

var listRecords* = Call_ListRecords_21626218(name: "listRecords",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/records",
    validator: validate_ListRecords_21626219, base: "/", makeUrl: url_ListRecords_21626220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDevice_21626239 = ref object of OpenApiRestCall_21625435
proc url_RegisterDevice_21626241(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_RegisterDevice_21626240(path: JsonNode; query: JsonNode;
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
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. Here, the ID of the pool that the identity belongs to.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626242 = path.getOrDefault("IdentityId")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "IdentityId", valid_21626242
  var valid_21626243 = path.getOrDefault("IdentityPoolId")
  valid_21626243 = validateParameter(valid_21626243, JString, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "IdentityPoolId", valid_21626243
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
  var valid_21626244 = header.getOrDefault("X-Amz-Date")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Date", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Security-Token", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Algorithm", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Signature")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Signature", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Credential")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Credential", valid_21626250
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

proc call*(call_21626252: Call_RegisterDevice_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_21626252.validator(path, query, header, formData, body, _)
  let scheme = call_21626252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626252.makeUrl(scheme.get, call_21626252.host, call_21626252.base,
                               call_21626252.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626252, uri, valid, _)

proc call*(call_21626253: Call_RegisterDevice_21626239; IdentityId: string;
          IdentityPoolId: string; body: JsonNode): Recallable =
  ## registerDevice
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : The unique ID for this identity.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. Here, the ID of the pool that the identity belongs to.
  ##   body: JObject (required)
  var path_21626254 = newJObject()
  var body_21626255 = newJObject()
  add(path_21626254, "IdentityId", newJString(IdentityId))
  add(path_21626254, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_21626255 = body
  result = call_21626253.call(path_21626254, nil, nil, nil, body_21626255)

var registerDevice* = Call_RegisterDevice_21626239(name: "registerDevice",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identity/{IdentityId}/device",
    validator: validate_RegisterDevice_21626240, base: "/",
    makeUrl: url_RegisterDevice_21626241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToDataset_21626256 = ref object of OpenApiRestCall_21625435
proc url_SubscribeToDataset_21626258(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_SubscribeToDataset_21626257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : Unique ID for this identity.
  ##   DeviceId: JString (required)
  ##           : The unique ID generated for this device by Cognito.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. The ID of the pool to which the identity belongs.
  ##   DatasetName: JString (required)
  ##              : The name of the dataset to subcribe to.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626259 = path.getOrDefault("IdentityId")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "IdentityId", valid_21626259
  var valid_21626260 = path.getOrDefault("DeviceId")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "DeviceId", valid_21626260
  var valid_21626261 = path.getOrDefault("IdentityPoolId")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "IdentityPoolId", valid_21626261
  var valid_21626262 = path.getOrDefault("DatasetName")
  valid_21626262 = validateParameter(valid_21626262, JString, required = true,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "DatasetName", valid_21626262
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

proc call*(call_21626270: Call_SubscribeToDataset_21626256; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_21626270.validator(path, query, header, formData, body, _)
  let scheme = call_21626270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626270.makeUrl(scheme.get, call_21626270.host, call_21626270.base,
                               call_21626270.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626270, uri, valid, _)

proc call*(call_21626271: Call_SubscribeToDataset_21626256; IdentityId: string;
          DeviceId: string; IdentityPoolId: string; DatasetName: string): Recallable =
  ## subscribeToDataset
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : Unique ID for this identity.
  ##   DeviceId: string (required)
  ##           : The unique ID generated for this device by Cognito.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. The ID of the pool to which the identity belongs.
  ##   DatasetName: string (required)
  ##              : The name of the dataset to subcribe to.
  var path_21626272 = newJObject()
  add(path_21626272, "IdentityId", newJString(IdentityId))
  add(path_21626272, "DeviceId", newJString(DeviceId))
  add(path_21626272, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_21626272, "DatasetName", newJString(DatasetName))
  result = call_21626271.call(path_21626272, nil, nil, nil, nil)

var subscribeToDataset* = Call_SubscribeToDataset_21626256(
    name: "subscribeToDataset", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_SubscribeToDataset_21626257, base: "/",
    makeUrl: url_SubscribeToDataset_21626258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromDataset_21626273 = ref object of OpenApiRestCall_21625435
proc url_UnsubscribeFromDataset_21626275(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
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

proc validate_UnsubscribeFromDataset_21626274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IdentityId: JString (required)
  ##             : Unique ID for this identity.
  ##   DeviceId: JString (required)
  ##           : The unique ID generated for this device by Cognito.
  ##   IdentityPoolId: JString (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. The ID of the pool to which this identity belongs.
  ##   DatasetName: JString (required)
  ##              : The name of the dataset from which to unsubcribe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `IdentityId` field"
  var valid_21626276 = path.getOrDefault("IdentityId")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "IdentityId", valid_21626276
  var valid_21626277 = path.getOrDefault("DeviceId")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "DeviceId", valid_21626277
  var valid_21626278 = path.getOrDefault("IdentityPoolId")
  valid_21626278 = validateParameter(valid_21626278, JString, required = true,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "IdentityPoolId", valid_21626278
  var valid_21626279 = path.getOrDefault("DatasetName")
  valid_21626279 = validateParameter(valid_21626279, JString, required = true,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "DatasetName", valid_21626279
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
  var valid_21626280 = header.getOrDefault("X-Amz-Date")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Date", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Security-Token", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Algorithm", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Signature")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Signature", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Credential")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Credential", valid_21626286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626287: Call_UnsubscribeFromDataset_21626273;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_21626287.validator(path, query, header, formData, body, _)
  let scheme = call_21626287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626287.makeUrl(scheme.get, call_21626287.host, call_21626287.base,
                               call_21626287.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626287, uri, valid, _)

proc call*(call_21626288: Call_UnsubscribeFromDataset_21626273; IdentityId: string;
          DeviceId: string; IdentityPoolId: string; DatasetName: string): Recallable =
  ## unsubscribeFromDataset
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : Unique ID for this identity.
  ##   DeviceId: string (required)
  ##           : The unique ID generated for this device by Cognito.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. The ID of the pool to which this identity belongs.
  ##   DatasetName: string (required)
  ##              : The name of the dataset from which to unsubcribe.
  var path_21626289 = newJObject()
  add(path_21626289, "IdentityId", newJString(IdentityId))
  add(path_21626289, "DeviceId", newJString(DeviceId))
  add(path_21626289, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_21626289, "DatasetName", newJString(DatasetName))
  result = call_21626288.call(path_21626289, nil, nil, nil, nil)

var unsubscribeFromDataset* = Call_UnsubscribeFromDataset_21626273(
    name: "unsubscribeFromDataset", meth: HttpMethod.HttpDelete,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_UnsubscribeFromDataset_21626274, base: "/",
    makeUrl: url_UnsubscribeFromDataset_21626275,
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