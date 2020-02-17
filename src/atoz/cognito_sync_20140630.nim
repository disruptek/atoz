
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BulkPublish_610996 = ref object of OpenApiRestCall_610658
proc url_BulkPublish_610998(protocol: Scheme; host: string; base: string;
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

proc validate_BulkPublish_610997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611124 = path.getOrDefault("IdentityPoolId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "IdentityPoolId", valid_611124
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
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_BulkPublish_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_BulkPublish_610996; IdentityPoolId: string): Recallable =
  ## bulkPublish
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_611226 = newJObject()
  add(path_611226, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611225.call(path_611226, nil, nil, nil, nil)

var bulkPublish* = Call_BulkPublish_610996(name: "bulkPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/bulkpublish",
                                        validator: validate_BulkPublish_610997,
                                        base: "/", url: url_BulkPublish_610998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecords_611282 = ref object of OpenApiRestCall_610658
proc url_UpdateRecords_611284(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRecords_611283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611285 = path.getOrDefault("IdentityId")
  valid_611285 = validateParameter(valid_611285, JString, required = true,
                                 default = nil)
  if valid_611285 != nil:
    section.add "IdentityId", valid_611285
  var valid_611286 = path.getOrDefault("IdentityPoolId")
  valid_611286 = validateParameter(valid_611286, JString, required = true,
                                 default = nil)
  if valid_611286 != nil:
    section.add "IdentityPoolId", valid_611286
  var valid_611287 = path.getOrDefault("DatasetName")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "DatasetName", valid_611287
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
  var valid_611288 = header.getOrDefault("x-amz-Client-Context")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "x-amz-Client-Context", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Signature")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Signature", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Content-Sha256", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Date")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Date", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Credential")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Credential", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Security-Token")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Security-Token", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Algorithm")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Algorithm", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-SignedHeaders", valid_611295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611297: Call_UpdateRecords_611282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_611297.validator(path, query, header, formData, body)
  let scheme = call_611297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611297.url(scheme.get, call_611297.host, call_611297.base,
                         call_611297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611297, url, valid)

proc call*(call_611298: Call_UpdateRecords_611282; IdentityId: string;
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
  var path_611299 = newJObject()
  var body_611300 = newJObject()
  add(path_611299, "IdentityId", newJString(IdentityId))
  if body != nil:
    body_611300 = body
  add(path_611299, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_611299, "DatasetName", newJString(DatasetName))
  result = call_611298.call(path_611299, nil, nil, nil, body_611300)

var updateRecords* = Call_UpdateRecords_611282(name: "updateRecords",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_UpdateRecords_611283, base: "/", url: url_UpdateRecords_611284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_611266 = ref object of OpenApiRestCall_610658
proc url_DescribeDataset_611268(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataset_611267(path: JsonNode; query: JsonNode;
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
  var valid_611269 = path.getOrDefault("IdentityId")
  valid_611269 = validateParameter(valid_611269, JString, required = true,
                                 default = nil)
  if valid_611269 != nil:
    section.add "IdentityId", valid_611269
  var valid_611270 = path.getOrDefault("IdentityPoolId")
  valid_611270 = validateParameter(valid_611270, JString, required = true,
                                 default = nil)
  if valid_611270 != nil:
    section.add "IdentityPoolId", valid_611270
  var valid_611271 = path.getOrDefault("DatasetName")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = nil)
  if valid_611271 != nil:
    section.add "DatasetName", valid_611271
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
  var valid_611272 = header.getOrDefault("X-Amz-Signature")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Signature", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Content-Sha256", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Date")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Date", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Credential")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Credential", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Security-Token")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Security-Token", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Algorithm")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Algorithm", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-SignedHeaders", valid_611278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611279: Call_DescribeDataset_611266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_611279.validator(path, query, header, formData, body)
  let scheme = call_611279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611279.url(scheme.get, call_611279.host, call_611279.base,
                         call_611279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611279, url, valid)

proc call*(call_611280: Call_DescribeDataset_611266; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## describeDataset
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_611281 = newJObject()
  add(path_611281, "IdentityId", newJString(IdentityId))
  add(path_611281, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_611281, "DatasetName", newJString(DatasetName))
  result = call_611280.call(path_611281, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_611266(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DescribeDataset_611267, base: "/", url: url_DescribeDataset_611268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_611301 = ref object of OpenApiRestCall_610658
proc url_DeleteDataset_611303(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataset_611302(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611304 = path.getOrDefault("IdentityId")
  valid_611304 = validateParameter(valid_611304, JString, required = true,
                                 default = nil)
  if valid_611304 != nil:
    section.add "IdentityId", valid_611304
  var valid_611305 = path.getOrDefault("IdentityPoolId")
  valid_611305 = validateParameter(valid_611305, JString, required = true,
                                 default = nil)
  if valid_611305 != nil:
    section.add "IdentityPoolId", valid_611305
  var valid_611306 = path.getOrDefault("DatasetName")
  valid_611306 = validateParameter(valid_611306, JString, required = true,
                                 default = nil)
  if valid_611306 != nil:
    section.add "DatasetName", valid_611306
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
  var valid_611307 = header.getOrDefault("X-Amz-Signature")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Signature", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Content-Sha256", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Date")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Date", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Credential")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Credential", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Security-Token")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Security-Token", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Algorithm")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Algorithm", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-SignedHeaders", valid_611313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611314: Call_DeleteDataset_611301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_611314.validator(path, query, header, formData, body)
  let scheme = call_611314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611314.url(scheme.get, call_611314.host, call_611314.base,
                         call_611314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611314, url, valid)

proc call*(call_611315: Call_DeleteDataset_611301; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_611316 = newJObject()
  add(path_611316, "IdentityId", newJString(IdentityId))
  add(path_611316, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_611316, "DatasetName", newJString(DatasetName))
  result = call_611315.call(path_611316, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_611301(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DeleteDataset_611302, base: "/", url: url_DeleteDataset_611303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPoolUsage_611317 = ref object of OpenApiRestCall_610658
proc url_DescribeIdentityPoolUsage_611319(protocol: Scheme; host: string;
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

proc validate_DescribeIdentityPoolUsage_611318(path: JsonNode; query: JsonNode;
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
  var valid_611320 = path.getOrDefault("IdentityPoolId")
  valid_611320 = validateParameter(valid_611320, JString, required = true,
                                 default = nil)
  if valid_611320 != nil:
    section.add "IdentityPoolId", valid_611320
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
  var valid_611321 = header.getOrDefault("X-Amz-Signature")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Signature", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Content-Sha256", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Date")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Date", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Credential")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Credential", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Security-Token")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Security-Token", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Algorithm")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Algorithm", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-SignedHeaders", valid_611327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611328: Call_DescribeIdentityPoolUsage_611317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611328.validator(path, query, header, formData, body)
  let scheme = call_611328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611328.url(scheme.get, call_611328.host, call_611328.base,
                         call_611328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611328, url, valid)

proc call*(call_611329: Call_DescribeIdentityPoolUsage_611317;
          IdentityPoolId: string): Recallable =
  ## describeIdentityPoolUsage
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_611330 = newJObject()
  add(path_611330, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611329.call(path_611330, nil, nil, nil, nil)

var describeIdentityPoolUsage* = Call_DescribeIdentityPoolUsage_611317(
    name: "describeIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}",
    validator: validate_DescribeIdentityPoolUsage_611318, base: "/",
    url: url_DescribeIdentityPoolUsage_611319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityUsage_611331 = ref object of OpenApiRestCall_610658
proc url_DescribeIdentityUsage_611333(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIdentityUsage_611332(path: JsonNode; query: JsonNode;
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
  var valid_611334 = path.getOrDefault("IdentityId")
  valid_611334 = validateParameter(valid_611334, JString, required = true,
                                 default = nil)
  if valid_611334 != nil:
    section.add "IdentityId", valid_611334
  var valid_611335 = path.getOrDefault("IdentityPoolId")
  valid_611335 = validateParameter(valid_611335, JString, required = true,
                                 default = nil)
  if valid_611335 != nil:
    section.add "IdentityPoolId", valid_611335
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
  var valid_611336 = header.getOrDefault("X-Amz-Signature")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Signature", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Content-Sha256", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Date")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Date", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Credential")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Credential", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Security-Token")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Security-Token", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Algorithm")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Algorithm", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-SignedHeaders", valid_611342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611343: Call_DescribeIdentityUsage_611331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_611343.validator(path, query, header, formData, body)
  let scheme = call_611343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611343.url(scheme.get, call_611343.host, call_611343.base,
                         call_611343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611343, url, valid)

proc call*(call_611344: Call_DescribeIdentityUsage_611331; IdentityId: string;
          IdentityPoolId: string): Recallable =
  ## describeIdentityUsage
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_611345 = newJObject()
  add(path_611345, "IdentityId", newJString(IdentityId))
  add(path_611345, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611344.call(path_611345, nil, nil, nil, nil)

var describeIdentityUsage* = Call_DescribeIdentityUsage_611331(
    name: "describeIdentityUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}",
    validator: validate_DescribeIdentityUsage_611332, base: "/",
    url: url_DescribeIdentityUsage_611333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkPublishDetails_611346 = ref object of OpenApiRestCall_610658
proc url_GetBulkPublishDetails_611348(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBulkPublishDetails_611347(path: JsonNode; query: JsonNode;
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
  var valid_611349 = path.getOrDefault("IdentityPoolId")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "IdentityPoolId", valid_611349
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
  var valid_611350 = header.getOrDefault("X-Amz-Signature")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Signature", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Content-Sha256", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Date")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Date", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Credential")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Credential", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Security-Token")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Security-Token", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Algorithm")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Algorithm", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-SignedHeaders", valid_611356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611357: Call_GetBulkPublishDetails_611346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611357.validator(path, query, header, formData, body)
  let scheme = call_611357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611357.url(scheme.get, call_611357.host, call_611357.base,
                         call_611357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611357, url, valid)

proc call*(call_611358: Call_GetBulkPublishDetails_611346; IdentityPoolId: string): Recallable =
  ## getBulkPublishDetails
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_611359 = newJObject()
  add(path_611359, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611358.call(path_611359, nil, nil, nil, nil)

var getBulkPublishDetails* = Call_GetBulkPublishDetails_611346(
    name: "getBulkPublishDetails", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/getBulkPublishDetails",
    validator: validate_GetBulkPublishDetails_611347, base: "/",
    url: url_GetBulkPublishDetails_611348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetCognitoEvents_611374 = ref object of OpenApiRestCall_610658
proc url_SetCognitoEvents_611376(protocol: Scheme; host: string; base: string;
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

proc validate_SetCognitoEvents_611375(path: JsonNode; query: JsonNode;
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
  var valid_611377 = path.getOrDefault("IdentityPoolId")
  valid_611377 = validateParameter(valid_611377, JString, required = true,
                                 default = nil)
  if valid_611377 != nil:
    section.add "IdentityPoolId", valid_611377
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
  var valid_611378 = header.getOrDefault("X-Amz-Signature")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Signature", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Content-Sha256", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Date")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Date", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Credential")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Credential", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Security-Token")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Security-Token", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Algorithm")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Algorithm", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-SignedHeaders", valid_611384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611386: Call_SetCognitoEvents_611374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611386.validator(path, query, header, formData, body)
  let scheme = call_611386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611386.url(scheme.get, call_611386.host, call_611386.base,
                         call_611386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611386, url, valid)

proc call*(call_611387: Call_SetCognitoEvents_611374; body: JsonNode;
          IdentityPoolId: string): Recallable =
  ## setCognitoEvents
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool to use when configuring Cognito Events
  var path_611388 = newJObject()
  var body_611389 = newJObject()
  if body != nil:
    body_611389 = body
  add(path_611388, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611387.call(path_611388, nil, nil, nil, body_611389)

var setCognitoEvents* = Call_SetCognitoEvents_611374(name: "setCognitoEvents",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_SetCognitoEvents_611375, base: "/",
    url: url_SetCognitoEvents_611376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCognitoEvents_611360 = ref object of OpenApiRestCall_610658
proc url_GetCognitoEvents_611362(protocol: Scheme; host: string; base: string;
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

proc validate_GetCognitoEvents_611361(path: JsonNode; query: JsonNode;
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
  var valid_611363 = path.getOrDefault("IdentityPoolId")
  valid_611363 = validateParameter(valid_611363, JString, required = true,
                                 default = nil)
  if valid_611363 != nil:
    section.add "IdentityPoolId", valid_611363
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
  var valid_611364 = header.getOrDefault("X-Amz-Signature")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Signature", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Content-Sha256", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Date")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Date", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Credential")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Credential", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Security-Token")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Security-Token", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Algorithm")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Algorithm", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-SignedHeaders", valid_611370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611371: Call_GetCognitoEvents_611360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611371.validator(path, query, header, formData, body)
  let scheme = call_611371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611371.url(scheme.get, call_611371.host, call_611371.base,
                         call_611371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611371, url, valid)

proc call*(call_611372: Call_GetCognitoEvents_611360; IdentityPoolId: string): Recallable =
  ## getCognitoEvents
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool ID for the request
  var path_611373 = newJObject()
  add(path_611373, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611372.call(path_611373, nil, nil, nil, nil)

var getCognitoEvents* = Call_GetCognitoEvents_611360(name: "getCognitoEvents",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_GetCognitoEvents_611361, base: "/",
    url: url_GetCognitoEvents_611362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolConfiguration_611404 = ref object of OpenApiRestCall_610658
proc url_SetIdentityPoolConfiguration_611406(protocol: Scheme; host: string;
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

proc validate_SetIdentityPoolConfiguration_611405(path: JsonNode; query: JsonNode;
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
  var valid_611407 = path.getOrDefault("IdentityPoolId")
  valid_611407 = validateParameter(valid_611407, JString, required = true,
                                 default = nil)
  if valid_611407 != nil:
    section.add "IdentityPoolId", valid_611407
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
  var valid_611408 = header.getOrDefault("X-Amz-Signature")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Signature", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Content-Sha256", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Date")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Date", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Credential")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Credential", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Security-Token")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Security-Token", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Algorithm")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Algorithm", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-SignedHeaders", valid_611414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611416: Call_SetIdentityPoolConfiguration_611404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611416.validator(path, query, header, formData, body)
  let scheme = call_611416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611416.url(scheme.get, call_611416.host, call_611416.base,
                         call_611416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611416, url, valid)

proc call*(call_611417: Call_SetIdentityPoolConfiguration_611404; body: JsonNode;
          IdentityPoolId: string): Recallable =
  ## setIdentityPoolConfiguration
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool to modify.
  var path_611418 = newJObject()
  var body_611419 = newJObject()
  if body != nil:
    body_611419 = body
  add(path_611418, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611417.call(path_611418, nil, nil, nil, body_611419)

var setIdentityPoolConfiguration* = Call_SetIdentityPoolConfiguration_611404(
    name: "setIdentityPoolConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_SetIdentityPoolConfiguration_611405, base: "/",
    url: url_SetIdentityPoolConfiguration_611406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolConfiguration_611390 = ref object of OpenApiRestCall_610658
proc url_GetIdentityPoolConfiguration_611392(protocol: Scheme; host: string;
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

proc validate_GetIdentityPoolConfiguration_611391(path: JsonNode; query: JsonNode;
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
  var valid_611393 = path.getOrDefault("IdentityPoolId")
  valid_611393 = validateParameter(valid_611393, JString, required = true,
                                 default = nil)
  if valid_611393 != nil:
    section.add "IdentityPoolId", valid_611393
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
  var valid_611394 = header.getOrDefault("X-Amz-Signature")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Signature", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Content-Sha256", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Date")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Date", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Credential")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Credential", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Security-Token")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Security-Token", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Algorithm")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Algorithm", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-SignedHeaders", valid_611400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611401: Call_GetIdentityPoolConfiguration_611390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611401.validator(path, query, header, formData, body)
  let scheme = call_611401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611401.url(scheme.get, call_611401.host, call_611401.base,
                         call_611401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611401, url, valid)

proc call*(call_611402: Call_GetIdentityPoolConfiguration_611390;
          IdentityPoolId: string): Recallable =
  ## getIdentityPoolConfiguration
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool for which to return a configuration.
  var path_611403 = newJObject()
  add(path_611403, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611402.call(path_611403, nil, nil, nil, nil)

var getIdentityPoolConfiguration* = Call_GetIdentityPoolConfiguration_611390(
    name: "getIdentityPoolConfiguration", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_GetIdentityPoolConfiguration_611391, base: "/",
    url: url_GetIdentityPoolConfiguration_611392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_611420 = ref object of OpenApiRestCall_610658
proc url_ListDatasets_611422(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasets_611421(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611423 = path.getOrDefault("IdentityId")
  valid_611423 = validateParameter(valid_611423, JString, required = true,
                                 default = nil)
  if valid_611423 != nil:
    section.add "IdentityId", valid_611423
  var valid_611424 = path.getOrDefault("IdentityPoolId")
  valid_611424 = validateParameter(valid_611424, JString, required = true,
                                 default = nil)
  if valid_611424 != nil:
    section.add "IdentityPoolId", valid_611424
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  section = newJObject()
  var valid_611425 = query.getOrDefault("nextToken")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "nextToken", valid_611425
  var valid_611426 = query.getOrDefault("maxResults")
  valid_611426 = validateParameter(valid_611426, JInt, required = false, default = nil)
  if valid_611426 != nil:
    section.add "maxResults", valid_611426
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
  var valid_611427 = header.getOrDefault("X-Amz-Signature")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Signature", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Content-Sha256", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Date")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Date", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Credential")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Credential", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Security-Token")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Security-Token", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Algorithm")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Algorithm", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-SignedHeaders", valid_611433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611434: Call_ListDatasets_611420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_611434.validator(path, query, header, formData, body)
  let scheme = call_611434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611434.url(scheme.get, call_611434.host, call_611434.base,
                         call_611434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611434, url, valid)

proc call*(call_611435: Call_ListDatasets_611420; IdentityId: string;
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
  var path_611436 = newJObject()
  var query_611437 = newJObject()
  add(query_611437, "nextToken", newJString(nextToken))
  add(path_611436, "IdentityId", newJString(IdentityId))
  add(path_611436, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_611437, "maxResults", newJInt(maxResults))
  result = call_611435.call(path_611436, query_611437, nil, nil, nil)

var listDatasets* = Call_ListDatasets_611420(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets",
    validator: validate_ListDatasets_611421, base: "/", url: url_ListDatasets_611422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPoolUsage_611438 = ref object of OpenApiRestCall_610658
proc url_ListIdentityPoolUsage_611440(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIdentityPoolUsage_611439(path: JsonNode; query: JsonNode;
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
  var valid_611441 = query.getOrDefault("nextToken")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "nextToken", valid_611441
  var valid_611442 = query.getOrDefault("maxResults")
  valid_611442 = validateParameter(valid_611442, JInt, required = false, default = nil)
  if valid_611442 != nil:
    section.add "maxResults", valid_611442
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
  var valid_611443 = header.getOrDefault("X-Amz-Signature")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Signature", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Content-Sha256", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Date")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Date", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Credential")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Credential", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Security-Token")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Security-Token", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Algorithm")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Algorithm", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-SignedHeaders", valid_611449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611450: Call_ListIdentityPoolUsage_611438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_611450.validator(path, query, header, formData, body)
  let scheme = call_611450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611450.url(scheme.get, call_611450.host, call_611450.base,
                         call_611450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611450, url, valid)

proc call*(call_611451: Call_ListIdentityPoolUsage_611438; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listIdentityPoolUsage
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  var query_611452 = newJObject()
  add(query_611452, "nextToken", newJString(nextToken))
  add(query_611452, "maxResults", newJInt(maxResults))
  result = call_611451.call(nil, query_611452, nil, nil, nil)

var listIdentityPoolUsage* = Call_ListIdentityPoolUsage_611438(
    name: "listIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools",
    validator: validate_ListIdentityPoolUsage_611439, base: "/",
    url: url_ListIdentityPoolUsage_611440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecords_611453 = ref object of OpenApiRestCall_610658
proc url_ListRecords_611455(protocol: Scheme; host: string; base: string;
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

proc validate_ListRecords_611454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611456 = path.getOrDefault("IdentityId")
  valid_611456 = validateParameter(valid_611456, JString, required = true,
                                 default = nil)
  if valid_611456 != nil:
    section.add "IdentityId", valid_611456
  var valid_611457 = path.getOrDefault("IdentityPoolId")
  valid_611457 = validateParameter(valid_611457, JString, required = true,
                                 default = nil)
  if valid_611457 != nil:
    section.add "IdentityPoolId", valid_611457
  var valid_611458 = path.getOrDefault("DatasetName")
  valid_611458 = validateParameter(valid_611458, JString, required = true,
                                 default = nil)
  if valid_611458 != nil:
    section.add "DatasetName", valid_611458
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
  var valid_611459 = query.getOrDefault("nextToken")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "nextToken", valid_611459
  var valid_611460 = query.getOrDefault("lastSyncCount")
  valid_611460 = validateParameter(valid_611460, JInt, required = false, default = nil)
  if valid_611460 != nil:
    section.add "lastSyncCount", valid_611460
  var valid_611461 = query.getOrDefault("syncSessionToken")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "syncSessionToken", valid_611461
  var valid_611462 = query.getOrDefault("maxResults")
  valid_611462 = validateParameter(valid_611462, JInt, required = false, default = nil)
  if valid_611462 != nil:
    section.add "maxResults", valid_611462
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
  var valid_611463 = header.getOrDefault("X-Amz-Signature")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Signature", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Content-Sha256", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Date")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Date", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Credential")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Credential", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Security-Token")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Security-Token", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Algorithm")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Algorithm", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-SignedHeaders", valid_611469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611470: Call_ListRecords_611453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_611470.validator(path, query, header, formData, body)
  let scheme = call_611470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611470.url(scheme.get, call_611470.host, call_611470.base,
                         call_611470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611470, url, valid)

proc call*(call_611471: Call_ListRecords_611453; IdentityId: string;
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
  var path_611472 = newJObject()
  var query_611473 = newJObject()
  add(query_611473, "nextToken", newJString(nextToken))
  add(path_611472, "IdentityId", newJString(IdentityId))
  add(query_611473, "lastSyncCount", newJInt(lastSyncCount))
  add(path_611472, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_611472, "DatasetName", newJString(DatasetName))
  add(query_611473, "syncSessionToken", newJString(syncSessionToken))
  add(query_611473, "maxResults", newJInt(maxResults))
  result = call_611471.call(path_611472, query_611473, nil, nil, nil)

var listRecords* = Call_ListRecords_611453(name: "listRecords",
                                        meth: HttpMethod.HttpGet,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/records",
                                        validator: validate_ListRecords_611454,
                                        base: "/", url: url_ListRecords_611455,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDevice_611474 = ref object of OpenApiRestCall_610658
proc url_RegisterDevice_611476(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterDevice_611475(path: JsonNode; query: JsonNode;
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
  var valid_611477 = path.getOrDefault("IdentityId")
  valid_611477 = validateParameter(valid_611477, JString, required = true,
                                 default = nil)
  if valid_611477 != nil:
    section.add "IdentityId", valid_611477
  var valid_611478 = path.getOrDefault("IdentityPoolId")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = nil)
  if valid_611478 != nil:
    section.add "IdentityPoolId", valid_611478
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
  var valid_611479 = header.getOrDefault("X-Amz-Signature")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Signature", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Content-Sha256", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Date")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Date", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Credential")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Credential", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Security-Token")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Security-Token", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Algorithm")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Algorithm", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-SignedHeaders", valid_611485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_RegisterDevice_611474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_RegisterDevice_611474; IdentityId: string;
          body: JsonNode; IdentityPoolId: string): Recallable =
  ## registerDevice
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : The unique ID for this identity.
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. Here, the ID of the pool that the identity belongs to.
  var path_611489 = newJObject()
  var body_611490 = newJObject()
  add(path_611489, "IdentityId", newJString(IdentityId))
  if body != nil:
    body_611490 = body
  add(path_611489, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_611488.call(path_611489, nil, nil, nil, body_611490)

var registerDevice* = Call_RegisterDevice_611474(name: "registerDevice",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identity/{IdentityId}/device",
    validator: validate_RegisterDevice_611475, base: "/", url: url_RegisterDevice_611476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToDataset_611491 = ref object of OpenApiRestCall_610658
proc url_SubscribeToDataset_611493(protocol: Scheme; host: string; base: string;
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

proc validate_SubscribeToDataset_611492(path: JsonNode; query: JsonNode;
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
  var valid_611494 = path.getOrDefault("IdentityId")
  valid_611494 = validateParameter(valid_611494, JString, required = true,
                                 default = nil)
  if valid_611494 != nil:
    section.add "IdentityId", valid_611494
  var valid_611495 = path.getOrDefault("DeviceId")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = nil)
  if valid_611495 != nil:
    section.add "DeviceId", valid_611495
  var valid_611496 = path.getOrDefault("IdentityPoolId")
  valid_611496 = validateParameter(valid_611496, JString, required = true,
                                 default = nil)
  if valid_611496 != nil:
    section.add "IdentityPoolId", valid_611496
  var valid_611497 = path.getOrDefault("DatasetName")
  valid_611497 = validateParameter(valid_611497, JString, required = true,
                                 default = nil)
  if valid_611497 != nil:
    section.add "DatasetName", valid_611497
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
  var valid_611498 = header.getOrDefault("X-Amz-Signature")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Signature", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Content-Sha256", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Date")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Date", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Credential")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Credential", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Security-Token")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Security-Token", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Algorithm")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Algorithm", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-SignedHeaders", valid_611504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611505: Call_SubscribeToDataset_611491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_611505.validator(path, query, header, formData, body)
  let scheme = call_611505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611505.url(scheme.get, call_611505.host, call_611505.base,
                         call_611505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611505, url, valid)

proc call*(call_611506: Call_SubscribeToDataset_611491; IdentityId: string;
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
  var path_611507 = newJObject()
  add(path_611507, "IdentityId", newJString(IdentityId))
  add(path_611507, "DeviceId", newJString(DeviceId))
  add(path_611507, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_611507, "DatasetName", newJString(DatasetName))
  result = call_611506.call(path_611507, nil, nil, nil, nil)

var subscribeToDataset* = Call_SubscribeToDataset_611491(
    name: "subscribeToDataset", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_SubscribeToDataset_611492, base: "/",
    url: url_SubscribeToDataset_611493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromDataset_611508 = ref object of OpenApiRestCall_610658
proc url_UnsubscribeFromDataset_611510(protocol: Scheme; host: string; base: string;
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

proc validate_UnsubscribeFromDataset_611509(path: JsonNode; query: JsonNode;
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
  var valid_611511 = path.getOrDefault("IdentityId")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "IdentityId", valid_611511
  var valid_611512 = path.getOrDefault("DeviceId")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "DeviceId", valid_611512
  var valid_611513 = path.getOrDefault("IdentityPoolId")
  valid_611513 = validateParameter(valid_611513, JString, required = true,
                                 default = nil)
  if valid_611513 != nil:
    section.add "IdentityPoolId", valid_611513
  var valid_611514 = path.getOrDefault("DatasetName")
  valid_611514 = validateParameter(valid_611514, JString, required = true,
                                 default = nil)
  if valid_611514 != nil:
    section.add "DatasetName", valid_611514
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
  var valid_611515 = header.getOrDefault("X-Amz-Signature")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Signature", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Content-Sha256", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Date")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Date", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Credential")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Credential", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Security-Token")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Security-Token", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Algorithm")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Algorithm", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-SignedHeaders", valid_611521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611522: Call_UnsubscribeFromDataset_611508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_611522.validator(path, query, header, formData, body)
  let scheme = call_611522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611522.url(scheme.get, call_611522.host, call_611522.base,
                         call_611522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611522, url, valid)

proc call*(call_611523: Call_UnsubscribeFromDataset_611508; IdentityId: string;
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
  var path_611524 = newJObject()
  add(path_611524, "IdentityId", newJString(IdentityId))
  add(path_611524, "DeviceId", newJString(DeviceId))
  add(path_611524, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_611524, "DatasetName", newJString(DatasetName))
  result = call_611523.call(path_611524, nil, nil, nil, nil)

var unsubscribeFromDataset* = Call_UnsubscribeFromDataset_611508(
    name: "unsubscribeFromDataset", meth: HttpMethod.HttpDelete,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_UnsubscribeFromDataset_611509, base: "/",
    url: url_UnsubscribeFromDataset_611510, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
