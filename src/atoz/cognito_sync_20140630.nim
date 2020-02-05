
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BulkPublish_612996 = ref object of OpenApiRestCall_612658
proc url_BulkPublish_612998(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BulkPublish_612997(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613124 = path.getOrDefault("IdentityPoolId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "IdentityPoolId", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_BulkPublish_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_BulkPublish_612996; IdentityPoolId: string): Recallable =
  ## bulkPublish
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_613226 = newJObject()
  add(path_613226, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613225.call(path_613226, nil, nil, nil, nil)

var bulkPublish* = Call_BulkPublish_612996(name: "bulkPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/bulkpublish",
                                        validator: validate_BulkPublish_612997,
                                        base: "/", url: url_BulkPublish_612998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecords_613282 = ref object of OpenApiRestCall_612658
proc url_UpdateRecords_613284(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRecords_613283(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613285 = path.getOrDefault("IdentityId")
  valid_613285 = validateParameter(valid_613285, JString, required = true,
                                 default = nil)
  if valid_613285 != nil:
    section.add "IdentityId", valid_613285
  var valid_613286 = path.getOrDefault("IdentityPoolId")
  valid_613286 = validateParameter(valid_613286, JString, required = true,
                                 default = nil)
  if valid_613286 != nil:
    section.add "IdentityPoolId", valid_613286
  var valid_613287 = path.getOrDefault("DatasetName")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "DatasetName", valid_613287
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-Client-Context: JString
  ##                       : Intended to supply a device ID that will populate the lastModifiedBy field referenced in other methods. The ClientContext field is not yet implemented.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613288 = header.getOrDefault("x-amz-Client-Context")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "x-amz-Client-Context", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Signature")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Signature", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Content-Sha256", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Date")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Date", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Credential")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Credential", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Security-Token")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Security-Token", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Algorithm")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Algorithm", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-SignedHeaders", valid_613295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613297: Call_UpdateRecords_613282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_613297.validator(path, query, header, formData, body)
  let scheme = call_613297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613297.url(scheme.get, call_613297.host, call_613297.base,
                         call_613297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613297, url, valid)

proc call*(call_613298: Call_UpdateRecords_613282; IdentityId: string;
          body: JsonNode; IdentityPoolId: string; DatasetName: string): Recallable =
  ## updateRecords
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_613299 = newJObject()
  var body_613300 = newJObject()
  add(path_613299, "IdentityId", newJString(IdentityId))
  if body != nil:
    body_613300 = body
  add(path_613299, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_613299, "DatasetName", newJString(DatasetName))
  result = call_613298.call(path_613299, nil, nil, nil, body_613300)

var updateRecords* = Call_UpdateRecords_613282(name: "updateRecords",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_UpdateRecords_613283, base: "/", url: url_UpdateRecords_613284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_613266 = ref object of OpenApiRestCall_612658
proc url_DescribeDataset_613268(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataset_613267(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_613269 = path.getOrDefault("IdentityId")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "IdentityId", valid_613269
  var valid_613270 = path.getOrDefault("IdentityPoolId")
  valid_613270 = validateParameter(valid_613270, JString, required = true,
                                 default = nil)
  if valid_613270 != nil:
    section.add "IdentityPoolId", valid_613270
  var valid_613271 = path.getOrDefault("DatasetName")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "DatasetName", valid_613271
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
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_DescribeDataset_613266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

proc call*(call_613280: Call_DescribeDataset_613266; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## describeDataset
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_613281 = newJObject()
  add(path_613281, "IdentityId", newJString(IdentityId))
  add(path_613281, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_613281, "DatasetName", newJString(DatasetName))
  result = call_613280.call(path_613281, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_613266(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DescribeDataset_613267, base: "/", url: url_DescribeDataset_613268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_613301 = ref object of OpenApiRestCall_612658
proc url_DeleteDataset_613303(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataset_613302(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613304 = path.getOrDefault("IdentityId")
  valid_613304 = validateParameter(valid_613304, JString, required = true,
                                 default = nil)
  if valid_613304 != nil:
    section.add "IdentityId", valid_613304
  var valid_613305 = path.getOrDefault("IdentityPoolId")
  valid_613305 = validateParameter(valid_613305, JString, required = true,
                                 default = nil)
  if valid_613305 != nil:
    section.add "IdentityPoolId", valid_613305
  var valid_613306 = path.getOrDefault("DatasetName")
  valid_613306 = validateParameter(valid_613306, JString, required = true,
                                 default = nil)
  if valid_613306 != nil:
    section.add "DatasetName", valid_613306
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
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613314: Call_DeleteDataset_613301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_613314.validator(path, query, header, formData, body)
  let scheme = call_613314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613314.url(scheme.get, call_613314.host, call_613314.base,
                         call_613314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613314, url, valid)

proc call*(call_613315: Call_DeleteDataset_613301; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_613316 = newJObject()
  add(path_613316, "IdentityId", newJString(IdentityId))
  add(path_613316, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_613316, "DatasetName", newJString(DatasetName))
  result = call_613315.call(path_613316, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_613301(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DeleteDataset_613302, base: "/", url: url_DeleteDataset_613303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPoolUsage_613317 = ref object of OpenApiRestCall_612658
proc url_DescribeIdentityPoolUsage_613319(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIdentityPoolUsage_613318(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613320 = path.getOrDefault("IdentityPoolId")
  valid_613320 = validateParameter(valid_613320, JString, required = true,
                                 default = nil)
  if valid_613320 != nil:
    section.add "IdentityPoolId", valid_613320
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
  var valid_613321 = header.getOrDefault("X-Amz-Signature")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Signature", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Content-Sha256", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Date")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Date", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Credential")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Credential", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Security-Token")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Security-Token", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Algorithm")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Algorithm", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-SignedHeaders", valid_613327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613328: Call_DescribeIdentityPoolUsage_613317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613328.validator(path, query, header, formData, body)
  let scheme = call_613328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613328.url(scheme.get, call_613328.host, call_613328.base,
                         call_613328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613328, url, valid)

proc call*(call_613329: Call_DescribeIdentityPoolUsage_613317;
          IdentityPoolId: string): Recallable =
  ## describeIdentityPoolUsage
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_613330 = newJObject()
  add(path_613330, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613329.call(path_613330, nil, nil, nil, nil)

var describeIdentityPoolUsage* = Call_DescribeIdentityPoolUsage_613317(
    name: "describeIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}",
    validator: validate_DescribeIdentityPoolUsage_613318, base: "/",
    url: url_DescribeIdentityPoolUsage_613319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityUsage_613331 = ref object of OpenApiRestCall_612658
proc url_DescribeIdentityUsage_613333(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "IdentityId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIdentityUsage_613332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613334 = path.getOrDefault("IdentityId")
  valid_613334 = validateParameter(valid_613334, JString, required = true,
                                 default = nil)
  if valid_613334 != nil:
    section.add "IdentityId", valid_613334
  var valid_613335 = path.getOrDefault("IdentityPoolId")
  valid_613335 = validateParameter(valid_613335, JString, required = true,
                                 default = nil)
  if valid_613335 != nil:
    section.add "IdentityPoolId", valid_613335
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
  var valid_613336 = header.getOrDefault("X-Amz-Signature")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Signature", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Content-Sha256", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Date")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Date", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Credential")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Credential", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Security-Token")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Security-Token", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Algorithm")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Algorithm", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-SignedHeaders", valid_613342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613343: Call_DescribeIdentityUsage_613331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_613343.validator(path, query, header, formData, body)
  let scheme = call_613343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613343.url(scheme.get, call_613343.host, call_613343.base,
                         call_613343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613343, url, valid)

proc call*(call_613344: Call_DescribeIdentityUsage_613331; IdentityId: string;
          IdentityPoolId: string): Recallable =
  ## describeIdentityUsage
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_613345 = newJObject()
  add(path_613345, "IdentityId", newJString(IdentityId))
  add(path_613345, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613344.call(path_613345, nil, nil, nil, nil)

var describeIdentityUsage* = Call_DescribeIdentityUsage_613331(
    name: "describeIdentityUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}",
    validator: validate_DescribeIdentityUsage_613332, base: "/",
    url: url_DescribeIdentityUsage_613333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkPublishDetails_613346 = ref object of OpenApiRestCall_612658
proc url_GetBulkPublishDetails_613348(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBulkPublishDetails_613347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613349 = path.getOrDefault("IdentityPoolId")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "IdentityPoolId", valid_613349
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
  var valid_613350 = header.getOrDefault("X-Amz-Signature")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Signature", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Content-Sha256", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Date")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Date", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Credential")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Credential", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Security-Token")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Security-Token", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Algorithm")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Algorithm", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-SignedHeaders", valid_613356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613357: Call_GetBulkPublishDetails_613346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613357.validator(path, query, header, formData, body)
  let scheme = call_613357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613357.url(scheme.get, call_613357.host, call_613357.base,
                         call_613357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613357, url, valid)

proc call*(call_613358: Call_GetBulkPublishDetails_613346; IdentityPoolId: string): Recallable =
  ## getBulkPublishDetails
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_613359 = newJObject()
  add(path_613359, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613358.call(path_613359, nil, nil, nil, nil)

var getBulkPublishDetails* = Call_GetBulkPublishDetails_613346(
    name: "getBulkPublishDetails", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/getBulkPublishDetails",
    validator: validate_GetBulkPublishDetails_613347, base: "/",
    url: url_GetBulkPublishDetails_613348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetCognitoEvents_613374 = ref object of OpenApiRestCall_612658
proc url_SetCognitoEvents_613376(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SetCognitoEvents_613375(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_613377 = path.getOrDefault("IdentityPoolId")
  valid_613377 = validateParameter(valid_613377, JString, required = true,
                                 default = nil)
  if valid_613377 != nil:
    section.add "IdentityPoolId", valid_613377
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
  var valid_613378 = header.getOrDefault("X-Amz-Signature")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Signature", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Content-Sha256", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Date")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Date", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Credential")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Credential", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Security-Token")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Security-Token", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Algorithm")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Algorithm", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-SignedHeaders", valid_613384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613386: Call_SetCognitoEvents_613374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613386.validator(path, query, header, formData, body)
  let scheme = call_613386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613386.url(scheme.get, call_613386.host, call_613386.base,
                         call_613386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613386, url, valid)

proc call*(call_613387: Call_SetCognitoEvents_613374; body: JsonNode;
          IdentityPoolId: string): Recallable =
  ## setCognitoEvents
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool to use when configuring Cognito Events
  var path_613388 = newJObject()
  var body_613389 = newJObject()
  if body != nil:
    body_613389 = body
  add(path_613388, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613387.call(path_613388, nil, nil, nil, body_613389)

var setCognitoEvents* = Call_SetCognitoEvents_613374(name: "setCognitoEvents",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_SetCognitoEvents_613375, base: "/",
    url: url_SetCognitoEvents_613376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCognitoEvents_613360 = ref object of OpenApiRestCall_612658
proc url_GetCognitoEvents_613362(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCognitoEvents_613361(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_613363 = path.getOrDefault("IdentityPoolId")
  valid_613363 = validateParameter(valid_613363, JString, required = true,
                                 default = nil)
  if valid_613363 != nil:
    section.add "IdentityPoolId", valid_613363
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
  var valid_613364 = header.getOrDefault("X-Amz-Signature")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Signature", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Content-Sha256", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Date")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Date", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Credential")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Credential", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Security-Token")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Security-Token", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Algorithm")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Algorithm", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-SignedHeaders", valid_613370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613371: Call_GetCognitoEvents_613360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613371.validator(path, query, header, formData, body)
  let scheme = call_613371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613371.url(scheme.get, call_613371.host, call_613371.base,
                         call_613371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613371, url, valid)

proc call*(call_613372: Call_GetCognitoEvents_613360; IdentityPoolId: string): Recallable =
  ## getCognitoEvents
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool ID for the request
  var path_613373 = newJObject()
  add(path_613373, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613372.call(path_613373, nil, nil, nil, nil)

var getCognitoEvents* = Call_GetCognitoEvents_613360(name: "getCognitoEvents",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_GetCognitoEvents_613361, base: "/",
    url: url_GetCognitoEvents_613362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolConfiguration_613404 = ref object of OpenApiRestCall_612658
proc url_SetIdentityPoolConfiguration_613406(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SetIdentityPoolConfiguration_613405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613407 = path.getOrDefault("IdentityPoolId")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = nil)
  if valid_613407 != nil:
    section.add "IdentityPoolId", valid_613407
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
  var valid_613408 = header.getOrDefault("X-Amz-Signature")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Signature", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Content-Sha256", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Date")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Date", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Credential")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Credential", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Security-Token")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Security-Token", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Algorithm")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Algorithm", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-SignedHeaders", valid_613414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613416: Call_SetIdentityPoolConfiguration_613404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613416.validator(path, query, header, formData, body)
  let scheme = call_613416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613416.url(scheme.get, call_613416.host, call_613416.base,
                         call_613416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613416, url, valid)

proc call*(call_613417: Call_SetIdentityPoolConfiguration_613404; body: JsonNode;
          IdentityPoolId: string): Recallable =
  ## setIdentityPoolConfiguration
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool to modify.
  var path_613418 = newJObject()
  var body_613419 = newJObject()
  if body != nil:
    body_613419 = body
  add(path_613418, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613417.call(path_613418, nil, nil, nil, body_613419)

var setIdentityPoolConfiguration* = Call_SetIdentityPoolConfiguration_613404(
    name: "setIdentityPoolConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_SetIdentityPoolConfiguration_613405, base: "/",
    url: url_SetIdentityPoolConfiguration_613406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolConfiguration_613390 = ref object of OpenApiRestCall_612658
proc url_GetIdentityPoolConfiguration_613392(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIdentityPoolConfiguration_613391(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613393 = path.getOrDefault("IdentityPoolId")
  valid_613393 = validateParameter(valid_613393, JString, required = true,
                                 default = nil)
  if valid_613393 != nil:
    section.add "IdentityPoolId", valid_613393
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
  var valid_613394 = header.getOrDefault("X-Amz-Signature")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Signature", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Content-Sha256", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Date")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Date", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Credential")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Credential", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Security-Token")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Security-Token", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Algorithm")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Algorithm", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-SignedHeaders", valid_613400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613401: Call_GetIdentityPoolConfiguration_613390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613401.validator(path, query, header, formData, body)
  let scheme = call_613401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613401.url(scheme.get, call_613401.host, call_613401.base,
                         call_613401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613401, url, valid)

proc call*(call_613402: Call_GetIdentityPoolConfiguration_613390;
          IdentityPoolId: string): Recallable =
  ## getIdentityPoolConfiguration
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool for which to return a configuration.
  var path_613403 = newJObject()
  add(path_613403, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613402.call(path_613403, nil, nil, nil, nil)

var getIdentityPoolConfiguration* = Call_GetIdentityPoolConfiguration_613390(
    name: "getIdentityPoolConfiguration", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_GetIdentityPoolConfiguration_613391, base: "/",
    url: url_GetIdentityPoolConfiguration_613392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_613420 = ref object of OpenApiRestCall_612658
proc url_ListDatasets_613422(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDatasets_613421(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613423 = path.getOrDefault("IdentityId")
  valid_613423 = validateParameter(valid_613423, JString, required = true,
                                 default = nil)
  if valid_613423 != nil:
    section.add "IdentityId", valid_613423
  var valid_613424 = path.getOrDefault("IdentityPoolId")
  valid_613424 = validateParameter(valid_613424, JString, required = true,
                                 default = nil)
  if valid_613424 != nil:
    section.add "IdentityPoolId", valid_613424
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  section = newJObject()
  var valid_613425 = query.getOrDefault("nextToken")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "nextToken", valid_613425
  var valid_613426 = query.getOrDefault("maxResults")
  valid_613426 = validateParameter(valid_613426, JInt, required = false, default = nil)
  if valid_613426 != nil:
    section.add "maxResults", valid_613426
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
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613434: Call_ListDatasets_613420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_613434.validator(path, query, header, formData, body)
  let scheme = call_613434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613434.url(scheme.get, call_613434.host, call_613434.base,
                         call_613434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613434, url, valid)

proc call*(call_613435: Call_ListDatasets_613420; IdentityId: string;
          IdentityPoolId: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDatasets
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  var path_613436 = newJObject()
  var query_613437 = newJObject()
  add(query_613437, "nextToken", newJString(nextToken))
  add(path_613436, "IdentityId", newJString(IdentityId))
  add(path_613436, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_613437, "maxResults", newJInt(maxResults))
  result = call_613435.call(path_613436, query_613437, nil, nil, nil)

var listDatasets* = Call_ListDatasets_613420(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets",
    validator: validate_ListDatasets_613421, base: "/", url: url_ListDatasets_613422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPoolUsage_613438 = ref object of OpenApiRestCall_612658
proc url_ListIdentityPoolUsage_613440(protocol: Scheme; host: string; base: string;
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

proc validate_ListIdentityPoolUsage_613439(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  section = newJObject()
  var valid_613441 = query.getOrDefault("nextToken")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "nextToken", valid_613441
  var valid_613442 = query.getOrDefault("maxResults")
  valid_613442 = validateParameter(valid_613442, JInt, required = false, default = nil)
  if valid_613442 != nil:
    section.add "maxResults", valid_613442
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
  var valid_613443 = header.getOrDefault("X-Amz-Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Signature", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Content-Sha256", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Date")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Date", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Credential")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Credential", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Security-Token")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Security-Token", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Algorithm")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Algorithm", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-SignedHeaders", valid_613449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613450: Call_ListIdentityPoolUsage_613438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_613450.validator(path, query, header, formData, body)
  let scheme = call_613450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613450.url(scheme.get, call_613450.host, call_613450.base,
                         call_613450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613450, url, valid)

proc call*(call_613451: Call_ListIdentityPoolUsage_613438; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listIdentityPoolUsage
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  var query_613452 = newJObject()
  add(query_613452, "nextToken", newJString(nextToken))
  add(query_613452, "maxResults", newJInt(maxResults))
  result = call_613451.call(nil, query_613452, nil, nil, nil)

var listIdentityPoolUsage* = Call_ListIdentityPoolUsage_613438(
    name: "listIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools",
    validator: validate_ListIdentityPoolUsage_613439, base: "/",
    url: url_ListIdentityPoolUsage_613440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecords_613453 = ref object of OpenApiRestCall_612658
proc url_ListRecords_613455(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecords_613454(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613456 = path.getOrDefault("IdentityId")
  valid_613456 = validateParameter(valid_613456, JString, required = true,
                                 default = nil)
  if valid_613456 != nil:
    section.add "IdentityId", valid_613456
  var valid_613457 = path.getOrDefault("IdentityPoolId")
  valid_613457 = validateParameter(valid_613457, JString, required = true,
                                 default = nil)
  if valid_613457 != nil:
    section.add "IdentityPoolId", valid_613457
  var valid_613458 = path.getOrDefault("DatasetName")
  valid_613458 = validateParameter(valid_613458, JString, required = true,
                                 default = nil)
  if valid_613458 != nil:
    section.add "DatasetName", valid_613458
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  ##   lastSyncCount: JInt
  ##                : The last server sync count for this record.
  ##   syncSessionToken: JString
  ##                   : A token containing a session ID, identity ID, and expiration.
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  section = newJObject()
  var valid_613459 = query.getOrDefault("nextToken")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "nextToken", valid_613459
  var valid_613460 = query.getOrDefault("lastSyncCount")
  valid_613460 = validateParameter(valid_613460, JInt, required = false, default = nil)
  if valid_613460 != nil:
    section.add "lastSyncCount", valid_613460
  var valid_613461 = query.getOrDefault("syncSessionToken")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "syncSessionToken", valid_613461
  var valid_613462 = query.getOrDefault("maxResults")
  valid_613462 = validateParameter(valid_613462, JInt, required = false, default = nil)
  if valid_613462 != nil:
    section.add "maxResults", valid_613462
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
  var valid_613463 = header.getOrDefault("X-Amz-Signature")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Signature", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Content-Sha256", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Date")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Date", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Credential")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Credential", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Security-Token")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Security-Token", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Algorithm")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Algorithm", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-SignedHeaders", valid_613469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613470: Call_ListRecords_613453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_613470.validator(path, query, header, formData, body)
  let scheme = call_613470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613470.url(scheme.get, call_613470.host, call_613470.base,
                         call_613470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613470, url, valid)

proc call*(call_613471: Call_ListRecords_613453; IdentityId: string;
          IdentityPoolId: string; DatasetName: string; nextToken: string = "";
          lastSyncCount: int = 0; syncSessionToken: string = ""; maxResults: int = 0): Recallable =
  ## listRecords
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   lastSyncCount: int
  ##                : The last server sync count for this record.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  ##   syncSessionToken: string
  ##                   : A token containing a session ID, identity ID, and expiration.
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  var path_613472 = newJObject()
  var query_613473 = newJObject()
  add(query_613473, "nextToken", newJString(nextToken))
  add(path_613472, "IdentityId", newJString(IdentityId))
  add(query_613473, "lastSyncCount", newJInt(lastSyncCount))
  add(path_613472, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_613472, "DatasetName", newJString(DatasetName))
  add(query_613473, "syncSessionToken", newJString(syncSessionToken))
  add(query_613473, "maxResults", newJInt(maxResults))
  result = call_613471.call(path_613472, query_613473, nil, nil, nil)

var listRecords* = Call_ListRecords_613453(name: "listRecords",
                                        meth: HttpMethod.HttpGet,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/records",
                                        validator: validate_ListRecords_613454,
                                        base: "/", url: url_ListRecords_613455,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDevice_613474 = ref object of OpenApiRestCall_612658
proc url_RegisterDevice_613476(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterDevice_613475(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_613477 = path.getOrDefault("IdentityId")
  valid_613477 = validateParameter(valid_613477, JString, required = true,
                                 default = nil)
  if valid_613477 != nil:
    section.add "IdentityId", valid_613477
  var valid_613478 = path.getOrDefault("IdentityPoolId")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = nil)
  if valid_613478 != nil:
    section.add "IdentityPoolId", valid_613478
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
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_RegisterDevice_613474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_RegisterDevice_613474; IdentityId: string;
          body: JsonNode; IdentityPoolId: string): Recallable =
  ## registerDevice
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : The unique ID for this identity.
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. Here, the ID of the pool that the identity belongs to.
  var path_613489 = newJObject()
  var body_613490 = newJObject()
  add(path_613489, "IdentityId", newJString(IdentityId))
  if body != nil:
    body_613490 = body
  add(path_613489, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_613488.call(path_613489, nil, nil, nil, body_613490)

var registerDevice* = Call_RegisterDevice_613474(name: "registerDevice",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identity/{IdentityId}/device",
    validator: validate_RegisterDevice_613475, base: "/", url: url_RegisterDevice_613476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToDataset_613491 = ref object of OpenApiRestCall_612658
proc url_SubscribeToDataset_613493(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SubscribeToDataset_613492(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_613494 = path.getOrDefault("IdentityId")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = nil)
  if valid_613494 != nil:
    section.add "IdentityId", valid_613494
  var valid_613495 = path.getOrDefault("DeviceId")
  valid_613495 = validateParameter(valid_613495, JString, required = true,
                                 default = nil)
  if valid_613495 != nil:
    section.add "DeviceId", valid_613495
  var valid_613496 = path.getOrDefault("IdentityPoolId")
  valid_613496 = validateParameter(valid_613496, JString, required = true,
                                 default = nil)
  if valid_613496 != nil:
    section.add "IdentityPoolId", valid_613496
  var valid_613497 = path.getOrDefault("DatasetName")
  valid_613497 = validateParameter(valid_613497, JString, required = true,
                                 default = nil)
  if valid_613497 != nil:
    section.add "DatasetName", valid_613497
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
  var valid_613498 = header.getOrDefault("X-Amz-Signature")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Signature", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Content-Sha256", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Date")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Date", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Credential")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Credential", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Security-Token")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Security-Token", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Algorithm")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Algorithm", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-SignedHeaders", valid_613504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613505: Call_SubscribeToDataset_613491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_613505.validator(path, query, header, formData, body)
  let scheme = call_613505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613505.url(scheme.get, call_613505.host, call_613505.base,
                         call_613505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613505, url, valid)

proc call*(call_613506: Call_SubscribeToDataset_613491; IdentityId: string;
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
  var path_613507 = newJObject()
  add(path_613507, "IdentityId", newJString(IdentityId))
  add(path_613507, "DeviceId", newJString(DeviceId))
  add(path_613507, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_613507, "DatasetName", newJString(DatasetName))
  result = call_613506.call(path_613507, nil, nil, nil, nil)

var subscribeToDataset* = Call_SubscribeToDataset_613491(
    name: "subscribeToDataset", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_SubscribeToDataset_613492, base: "/",
    url: url_SubscribeToDataset_613493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromDataset_613508 = ref object of OpenApiRestCall_612658
proc url_UnsubscribeFromDataset_613510(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UnsubscribeFromDataset_613509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613511 = path.getOrDefault("IdentityId")
  valid_613511 = validateParameter(valid_613511, JString, required = true,
                                 default = nil)
  if valid_613511 != nil:
    section.add "IdentityId", valid_613511
  var valid_613512 = path.getOrDefault("DeviceId")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "DeviceId", valid_613512
  var valid_613513 = path.getOrDefault("IdentityPoolId")
  valid_613513 = validateParameter(valid_613513, JString, required = true,
                                 default = nil)
  if valid_613513 != nil:
    section.add "IdentityPoolId", valid_613513
  var valid_613514 = path.getOrDefault("DatasetName")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = nil)
  if valid_613514 != nil:
    section.add "DatasetName", valid_613514
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
  var valid_613515 = header.getOrDefault("X-Amz-Signature")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Signature", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Content-Sha256", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Date")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Date", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Credential")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Credential", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Security-Token")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Security-Token", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Algorithm")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Algorithm", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-SignedHeaders", valid_613521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613522: Call_UnsubscribeFromDataset_613508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_613522.validator(path, query, header, formData, body)
  let scheme = call_613522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613522.url(scheme.get, call_613522.host, call_613522.base,
                         call_613522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613522, url, valid)

proc call*(call_613523: Call_UnsubscribeFromDataset_613508; IdentityId: string;
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
  var path_613524 = newJObject()
  add(path_613524, "IdentityId", newJString(IdentityId))
  add(path_613524, "DeviceId", newJString(DeviceId))
  add(path_613524, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_613524, "DatasetName", newJString(DatasetName))
  result = call_613523.call(path_613524, nil, nil, nil, nil)

var unsubscribeFromDataset* = Call_UnsubscribeFromDataset_613508(
    name: "unsubscribeFromDataset", meth: HttpMethod.HttpDelete,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_UnsubscribeFromDataset_613509, base: "/",
    url: url_UnsubscribeFromDataset_613510, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
