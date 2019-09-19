
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BulkPublish_600768 = ref object of OpenApiRestCall_600426
proc url_BulkPublish_600770(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
               (kind: VariableSegment, value: "IdentityPoolId"),
               (kind: ConstantSegment, value: "/bulkpublish")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_BulkPublish_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600896 = path.getOrDefault("IdentityPoolId")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "IdentityPoolId", valid_600896
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
  var valid_600897 = header.getOrDefault("X-Amz-Date")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Date", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Security-Token")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Security-Token", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Content-Sha256", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Algorithm")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Algorithm", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Signature")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Signature", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-SignedHeaders", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Credential")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Credential", valid_600903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_BulkPublish_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_BulkPublish_600768; IdentityPoolId: string): Recallable =
  ## bulkPublish
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_600998 = newJObject()
  add(path_600998, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_600997.call(path_600998, nil, nil, nil, nil)

var bulkPublish* = Call_BulkPublish_600768(name: "bulkPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/bulkpublish",
                                        validator: validate_BulkPublish_600769,
                                        base: "/", url: url_BulkPublish_600770,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecords_601054 = ref object of OpenApiRestCall_600426
proc url_UpdateRecords_601056(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateRecords_601055(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601057 = path.getOrDefault("IdentityId")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "IdentityId", valid_601057
  var valid_601058 = path.getOrDefault("IdentityPoolId")
  valid_601058 = validateParameter(valid_601058, JString, required = true,
                                 default = nil)
  if valid_601058 != nil:
    section.add "IdentityPoolId", valid_601058
  var valid_601059 = path.getOrDefault("DatasetName")
  valid_601059 = validateParameter(valid_601059, JString, required = true,
                                 default = nil)
  if valid_601059 != nil:
    section.add "DatasetName", valid_601059
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
  var valid_601060 = header.getOrDefault("X-Amz-Date")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Date", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Security-Token")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Security-Token", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Content-Sha256", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Algorithm")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Algorithm", valid_601063
  var valid_601064 = header.getOrDefault("x-amz-Client-Context")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "x-amz-Client-Context", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Signature")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Signature", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-SignedHeaders", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Credential")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Credential", valid_601067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601069: Call_UpdateRecords_601054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_601069.validator(path, query, header, formData, body)
  let scheme = call_601069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601069.url(scheme.get, call_601069.host, call_601069.base,
                         call_601069.route, valid.getOrDefault("path"))
  result = hook(call_601069, url, valid)

proc call*(call_601070: Call_UpdateRecords_601054; IdentityId: string;
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
  var path_601071 = newJObject()
  var body_601072 = newJObject()
  add(path_601071, "IdentityId", newJString(IdentityId))
  add(path_601071, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_601071, "DatasetName", newJString(DatasetName))
  if body != nil:
    body_601072 = body
  result = call_601070.call(path_601071, nil, nil, nil, body_601072)

var updateRecords* = Call_UpdateRecords_601054(name: "updateRecords",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_UpdateRecords_601055, base: "/", url: url_UpdateRecords_601056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_601038 = ref object of OpenApiRestCall_600426
proc url_DescribeDataset_601040(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeDataset_601039(path: JsonNode; query: JsonNode;
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
  var valid_601041 = path.getOrDefault("IdentityId")
  valid_601041 = validateParameter(valid_601041, JString, required = true,
                                 default = nil)
  if valid_601041 != nil:
    section.add "IdentityId", valid_601041
  var valid_601042 = path.getOrDefault("IdentityPoolId")
  valid_601042 = validateParameter(valid_601042, JString, required = true,
                                 default = nil)
  if valid_601042 != nil:
    section.add "IdentityPoolId", valid_601042
  var valid_601043 = path.getOrDefault("DatasetName")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = nil)
  if valid_601043 != nil:
    section.add "DatasetName", valid_601043
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
  var valid_601044 = header.getOrDefault("X-Amz-Date")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Date", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Security-Token")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Security-Token", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_DescribeDataset_601038; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"))
  result = hook(call_601051, url, valid)

proc call*(call_601052: Call_DescribeDataset_601038; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## describeDataset
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_601053 = newJObject()
  add(path_601053, "IdentityId", newJString(IdentityId))
  add(path_601053, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_601053, "DatasetName", newJString(DatasetName))
  result = call_601052.call(path_601053, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_601038(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DescribeDataset_601039, base: "/", url: url_DescribeDataset_601040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_601073 = ref object of OpenApiRestCall_600426
proc url_DeleteDataset_601075(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDataset_601074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601076 = path.getOrDefault("IdentityId")
  valid_601076 = validateParameter(valid_601076, JString, required = true,
                                 default = nil)
  if valid_601076 != nil:
    section.add "IdentityId", valid_601076
  var valid_601077 = path.getOrDefault("IdentityPoolId")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = nil)
  if valid_601077 != nil:
    section.add "IdentityPoolId", valid_601077
  var valid_601078 = path.getOrDefault("DatasetName")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = nil)
  if valid_601078 != nil:
    section.add "DatasetName", valid_601078
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
  var valid_601079 = header.getOrDefault("X-Amz-Date")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Date", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Security-Token")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Security-Token", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Content-Sha256", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Algorithm")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Algorithm", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Signature")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Signature", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-SignedHeaders", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Credential")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Credential", valid_601085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601086: Call_DeleteDataset_601073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"))
  result = hook(call_601086, url, valid)

proc call*(call_601087: Call_DeleteDataset_601073; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_601088 = newJObject()
  add(path_601088, "IdentityId", newJString(IdentityId))
  add(path_601088, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_601088, "DatasetName", newJString(DatasetName))
  result = call_601087.call(path_601088, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_601073(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DeleteDataset_601074, base: "/", url: url_DeleteDataset_601075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPoolUsage_601089 = ref object of OpenApiRestCall_600426
proc url_DescribeIdentityPoolUsage_601091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
               (kind: VariableSegment, value: "IdentityPoolId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeIdentityPoolUsage_601090(path: JsonNode; query: JsonNode;
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
  var valid_601092 = path.getOrDefault("IdentityPoolId")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = nil)
  if valid_601092 != nil:
    section.add "IdentityPoolId", valid_601092
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
  var valid_601093 = header.getOrDefault("X-Amz-Date")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Date", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Security-Token")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Security-Token", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_DescribeIdentityPoolUsage_601089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_DescribeIdentityPoolUsage_601089;
          IdentityPoolId: string): Recallable =
  ## describeIdentityPoolUsage
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_601102 = newJObject()
  add(path_601102, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_601101.call(path_601102, nil, nil, nil, nil)

var describeIdentityPoolUsage* = Call_DescribeIdentityPoolUsage_601089(
    name: "describeIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}",
    validator: validate_DescribeIdentityPoolUsage_601090, base: "/",
    url: url_DescribeIdentityPoolUsage_601091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityUsage_601103 = ref object of OpenApiRestCall_600426
proc url_DescribeIdentityUsage_601105(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeIdentityUsage_601104(path: JsonNode; query: JsonNode;
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
  var valid_601106 = path.getOrDefault("IdentityId")
  valid_601106 = validateParameter(valid_601106, JString, required = true,
                                 default = nil)
  if valid_601106 != nil:
    section.add "IdentityId", valid_601106
  var valid_601107 = path.getOrDefault("IdentityPoolId")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = nil)
  if valid_601107 != nil:
    section.add "IdentityPoolId", valid_601107
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
  var valid_601108 = header.getOrDefault("X-Amz-Date")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Date", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Security-Token")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Security-Token", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Content-Sha256", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Algorithm")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Algorithm", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Signature")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Signature", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-SignedHeaders", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Credential")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Credential", valid_601114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_DescribeIdentityUsage_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_DescribeIdentityUsage_601103; IdentityId: string;
          IdentityPoolId: string): Recallable =
  ## describeIdentityUsage
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_601117 = newJObject()
  add(path_601117, "IdentityId", newJString(IdentityId))
  add(path_601117, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_601116.call(path_601117, nil, nil, nil, nil)

var describeIdentityUsage* = Call_DescribeIdentityUsage_601103(
    name: "describeIdentityUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}",
    validator: validate_DescribeIdentityUsage_601104, base: "/",
    url: url_DescribeIdentityUsage_601105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkPublishDetails_601118 = ref object of OpenApiRestCall_600426
proc url_GetBulkPublishDetails_601120(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
               (kind: VariableSegment, value: "IdentityPoolId"),
               (kind: ConstantSegment, value: "/getBulkPublishDetails")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBulkPublishDetails_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = path.getOrDefault("IdentityPoolId")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = nil)
  if valid_601121 != nil:
    section.add "IdentityPoolId", valid_601121
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
  var valid_601122 = header.getOrDefault("X-Amz-Date")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Date", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Security-Token")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Security-Token", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601129: Call_GetBulkPublishDetails_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_601129.validator(path, query, header, formData, body)
  let scheme = call_601129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601129.url(scheme.get, call_601129.host, call_601129.base,
                         call_601129.route, valid.getOrDefault("path"))
  result = hook(call_601129, url, valid)

proc call*(call_601130: Call_GetBulkPublishDetails_601118; IdentityPoolId: string): Recallable =
  ## getBulkPublishDetails
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_601131 = newJObject()
  add(path_601131, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_601130.call(path_601131, nil, nil, nil, nil)

var getBulkPublishDetails* = Call_GetBulkPublishDetails_601118(
    name: "getBulkPublishDetails", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/getBulkPublishDetails",
    validator: validate_GetBulkPublishDetails_601119, base: "/",
    url: url_GetBulkPublishDetails_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetCognitoEvents_601146 = ref object of OpenApiRestCall_600426
proc url_SetCognitoEvents_601148(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
               (kind: VariableSegment, value: "IdentityPoolId"),
               (kind: ConstantSegment, value: "/events")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_SetCognitoEvents_601147(path: JsonNode; query: JsonNode;
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
  var valid_601149 = path.getOrDefault("IdentityPoolId")
  valid_601149 = validateParameter(valid_601149, JString, required = true,
                                 default = nil)
  if valid_601149 != nil:
    section.add "IdentityPoolId", valid_601149
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
  var valid_601150 = header.getOrDefault("X-Amz-Date")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Date", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Security-Token")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Security-Token", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Content-Sha256", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Algorithm")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Algorithm", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Signature")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Signature", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-SignedHeaders", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Credential")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Credential", valid_601156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601158: Call_SetCognitoEvents_601146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_601158.validator(path, query, header, formData, body)
  let scheme = call_601158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601158.url(scheme.get, call_601158.host, call_601158.base,
                         call_601158.route, valid.getOrDefault("path"))
  result = hook(call_601158, url, valid)

proc call*(call_601159: Call_SetCognitoEvents_601146; IdentityPoolId: string;
          body: JsonNode): Recallable =
  ## setCognitoEvents
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool to use when configuring Cognito Events
  ##   body: JObject (required)
  var path_601160 = newJObject()
  var body_601161 = newJObject()
  add(path_601160, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_601161 = body
  result = call_601159.call(path_601160, nil, nil, nil, body_601161)

var setCognitoEvents* = Call_SetCognitoEvents_601146(name: "setCognitoEvents",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_SetCognitoEvents_601147, base: "/",
    url: url_SetCognitoEvents_601148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCognitoEvents_601132 = ref object of OpenApiRestCall_600426
proc url_GetCognitoEvents_601134(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
               (kind: VariableSegment, value: "IdentityPoolId"),
               (kind: ConstantSegment, value: "/events")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCognitoEvents_601133(path: JsonNode; query: JsonNode;
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
  var valid_601135 = path.getOrDefault("IdentityPoolId")
  valid_601135 = validateParameter(valid_601135, JString, required = true,
                                 default = nil)
  if valid_601135 != nil:
    section.add "IdentityPoolId", valid_601135
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
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Content-Sha256", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Algorithm")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Algorithm", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Signature")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Signature", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-SignedHeaders", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Credential")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Credential", valid_601142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601143: Call_GetCognitoEvents_601132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_601143.validator(path, query, header, formData, body)
  let scheme = call_601143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601143.url(scheme.get, call_601143.host, call_601143.base,
                         call_601143.route, valid.getOrDefault("path"))
  result = hook(call_601143, url, valid)

proc call*(call_601144: Call_GetCognitoEvents_601132; IdentityPoolId: string): Recallable =
  ## getCognitoEvents
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool ID for the request
  var path_601145 = newJObject()
  add(path_601145, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_601144.call(path_601145, nil, nil, nil, nil)

var getCognitoEvents* = Call_GetCognitoEvents_601132(name: "getCognitoEvents",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_GetCognitoEvents_601133, base: "/",
    url: url_GetCognitoEvents_601134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolConfiguration_601176 = ref object of OpenApiRestCall_600426
proc url_SetIdentityPoolConfiguration_601178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
               (kind: VariableSegment, value: "IdentityPoolId"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_SetIdentityPoolConfiguration_601177(path: JsonNode; query: JsonNode;
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
  var valid_601179 = path.getOrDefault("IdentityPoolId")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = nil)
  if valid_601179 != nil:
    section.add "IdentityPoolId", valid_601179
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
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601188: Call_SetIdentityPoolConfiguration_601176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_601188.validator(path, query, header, formData, body)
  let scheme = call_601188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601188.url(scheme.get, call_601188.host, call_601188.base,
                         call_601188.route, valid.getOrDefault("path"))
  result = hook(call_601188, url, valid)

proc call*(call_601189: Call_SetIdentityPoolConfiguration_601176;
          IdentityPoolId: string; body: JsonNode): Recallable =
  ## setIdentityPoolConfiguration
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool to modify.
  ##   body: JObject (required)
  var path_601190 = newJObject()
  var body_601191 = newJObject()
  add(path_601190, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_601191 = body
  result = call_601189.call(path_601190, nil, nil, nil, body_601191)

var setIdentityPoolConfiguration* = Call_SetIdentityPoolConfiguration_601176(
    name: "setIdentityPoolConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_SetIdentityPoolConfiguration_601177, base: "/",
    url: url_SetIdentityPoolConfiguration_601178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolConfiguration_601162 = ref object of OpenApiRestCall_600426
proc url_GetIdentityPoolConfiguration_601164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "IdentityPoolId" in path, "`IdentityPoolId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/identitypools/"),
               (kind: VariableSegment, value: "IdentityPoolId"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIdentityPoolConfiguration_601163(path: JsonNode; query: JsonNode;
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
  var valid_601165 = path.getOrDefault("IdentityPoolId")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = nil)
  if valid_601165 != nil:
    section.add "IdentityPoolId", valid_601165
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
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601173: Call_GetIdentityPoolConfiguration_601162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_601173.validator(path, query, header, formData, body)
  let scheme = call_601173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601173.url(scheme.get, call_601173.host, call_601173.base,
                         call_601173.route, valid.getOrDefault("path"))
  result = hook(call_601173, url, valid)

proc call*(call_601174: Call_GetIdentityPoolConfiguration_601162;
          IdentityPoolId: string): Recallable =
  ## getIdentityPoolConfiguration
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool for which to return a configuration.
  var path_601175 = newJObject()
  add(path_601175, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_601174.call(path_601175, nil, nil, nil, nil)

var getIdentityPoolConfiguration* = Call_GetIdentityPoolConfiguration_601162(
    name: "getIdentityPoolConfiguration", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_GetIdentityPoolConfiguration_601163, base: "/",
    url: url_GetIdentityPoolConfiguration_601164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_601192 = ref object of OpenApiRestCall_600426
proc url_ListDatasets_601194(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDatasets_601193(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601195 = path.getOrDefault("IdentityId")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = nil)
  if valid_601195 != nil:
    section.add "IdentityId", valid_601195
  var valid_601196 = path.getOrDefault("IdentityPoolId")
  valid_601196 = validateParameter(valid_601196, JString, required = true,
                                 default = nil)
  if valid_601196 != nil:
    section.add "IdentityPoolId", valid_601196
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  section = newJObject()
  var valid_601197 = query.getOrDefault("maxResults")
  valid_601197 = validateParameter(valid_601197, JInt, required = false, default = nil)
  if valid_601197 != nil:
    section.add "maxResults", valid_601197
  var valid_601198 = query.getOrDefault("nextToken")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "nextToken", valid_601198
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
  var valid_601199 = header.getOrDefault("X-Amz-Date")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Date", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Security-Token")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Security-Token", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Content-Sha256", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Algorithm")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Algorithm", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Signature")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Signature", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-SignedHeaders", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Credential")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Credential", valid_601205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601206: Call_ListDatasets_601192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_601206.validator(path, query, header, formData, body)
  let scheme = call_601206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601206.url(scheme.get, call_601206.host, call_601206.base,
                         call_601206.route, valid.getOrDefault("path"))
  result = hook(call_601206, url, valid)

proc call*(call_601207: Call_ListDatasets_601192; IdentityId: string;
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
  var path_601208 = newJObject()
  var query_601209 = newJObject()
  add(path_601208, "IdentityId", newJString(IdentityId))
  add(path_601208, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_601209, "maxResults", newJInt(maxResults))
  add(query_601209, "nextToken", newJString(nextToken))
  result = call_601207.call(path_601208, query_601209, nil, nil, nil)

var listDatasets* = Call_ListDatasets_601192(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets",
    validator: validate_ListDatasets_601193, base: "/", url: url_ListDatasets_601194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPoolUsage_601210 = ref object of OpenApiRestCall_600426
proc url_ListIdentityPoolUsage_601212(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIdentityPoolUsage_601211(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601213 = query.getOrDefault("maxResults")
  valid_601213 = validateParameter(valid_601213, JInt, required = false, default = nil)
  if valid_601213 != nil:
    section.add "maxResults", valid_601213
  var valid_601214 = query.getOrDefault("nextToken")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "nextToken", valid_601214
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
  var valid_601215 = header.getOrDefault("X-Amz-Date")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Date", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Security-Token")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Security-Token", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Content-Sha256", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Algorithm")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Algorithm", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Signature")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Signature", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-SignedHeaders", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Credential")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Credential", valid_601221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601222: Call_ListIdentityPoolUsage_601210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_601222.validator(path, query, header, formData, body)
  let scheme = call_601222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601222.url(scheme.get, call_601222.host, call_601222.base,
                         call_601222.route, valid.getOrDefault("path"))
  result = hook(call_601222, url, valid)

proc call*(call_601223: Call_ListIdentityPoolUsage_601210; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listIdentityPoolUsage
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  var query_601224 = newJObject()
  add(query_601224, "maxResults", newJInt(maxResults))
  add(query_601224, "nextToken", newJString(nextToken))
  result = call_601223.call(nil, query_601224, nil, nil, nil)

var listIdentityPoolUsage* = Call_ListIdentityPoolUsage_601210(
    name: "listIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools",
    validator: validate_ListIdentityPoolUsage_601211, base: "/",
    url: url_ListIdentityPoolUsage_601212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecords_601225 = ref object of OpenApiRestCall_600426
proc url_ListRecords_601227(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListRecords_601226(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601228 = path.getOrDefault("IdentityId")
  valid_601228 = validateParameter(valid_601228, JString, required = true,
                                 default = nil)
  if valid_601228 != nil:
    section.add "IdentityId", valid_601228
  var valid_601229 = path.getOrDefault("IdentityPoolId")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = nil)
  if valid_601229 != nil:
    section.add "IdentityPoolId", valid_601229
  var valid_601230 = path.getOrDefault("DatasetName")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = nil)
  if valid_601230 != nil:
    section.add "DatasetName", valid_601230
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
  var valid_601231 = query.getOrDefault("maxResults")
  valid_601231 = validateParameter(valid_601231, JInt, required = false, default = nil)
  if valid_601231 != nil:
    section.add "maxResults", valid_601231
  var valid_601232 = query.getOrDefault("nextToken")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "nextToken", valid_601232
  var valid_601233 = query.getOrDefault("lastSyncCount")
  valid_601233 = validateParameter(valid_601233, JInt, required = false, default = nil)
  if valid_601233 != nil:
    section.add "lastSyncCount", valid_601233
  var valid_601234 = query.getOrDefault("syncSessionToken")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "syncSessionToken", valid_601234
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
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Content-Sha256", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Algorithm")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Algorithm", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Signature")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Signature", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-SignedHeaders", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Credential")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Credential", valid_601241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601242: Call_ListRecords_601225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_601242.validator(path, query, header, formData, body)
  let scheme = call_601242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601242.url(scheme.get, call_601242.host, call_601242.base,
                         call_601242.route, valid.getOrDefault("path"))
  result = hook(call_601242, url, valid)

proc call*(call_601243: Call_ListRecords_601225; IdentityId: string;
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
  var path_601244 = newJObject()
  var query_601245 = newJObject()
  add(path_601244, "IdentityId", newJString(IdentityId))
  add(path_601244, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_601245, "maxResults", newJInt(maxResults))
  add(query_601245, "nextToken", newJString(nextToken))
  add(query_601245, "lastSyncCount", newJInt(lastSyncCount))
  add(path_601244, "DatasetName", newJString(DatasetName))
  add(query_601245, "syncSessionToken", newJString(syncSessionToken))
  result = call_601243.call(path_601244, query_601245, nil, nil, nil)

var listRecords* = Call_ListRecords_601225(name: "listRecords",
                                        meth: HttpMethod.HttpGet,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/records",
                                        validator: validate_ListRecords_601226,
                                        base: "/", url: url_ListRecords_601227,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDevice_601246 = ref object of OpenApiRestCall_600426
proc url_RegisterDevice_601248(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RegisterDevice_601247(path: JsonNode; query: JsonNode;
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
  var valid_601249 = path.getOrDefault("IdentityId")
  valid_601249 = validateParameter(valid_601249, JString, required = true,
                                 default = nil)
  if valid_601249 != nil:
    section.add "IdentityId", valid_601249
  var valid_601250 = path.getOrDefault("IdentityPoolId")
  valid_601250 = validateParameter(valid_601250, JString, required = true,
                                 default = nil)
  if valid_601250 != nil:
    section.add "IdentityPoolId", valid_601250
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
  var valid_601251 = header.getOrDefault("X-Amz-Date")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Date", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Security-Token")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Security-Token", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_RegisterDevice_601246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_RegisterDevice_601246; IdentityId: string;
          IdentityPoolId: string; body: JsonNode): Recallable =
  ## registerDevice
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : The unique ID for this identity.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. Here, the ID of the pool that the identity belongs to.
  ##   body: JObject (required)
  var path_601261 = newJObject()
  var body_601262 = newJObject()
  add(path_601261, "IdentityId", newJString(IdentityId))
  add(path_601261, "IdentityPoolId", newJString(IdentityPoolId))
  if body != nil:
    body_601262 = body
  result = call_601260.call(path_601261, nil, nil, nil, body_601262)

var registerDevice* = Call_RegisterDevice_601246(name: "registerDevice",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identity/{IdentityId}/device",
    validator: validate_RegisterDevice_601247, base: "/", url: url_RegisterDevice_601248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToDataset_601263 = ref object of OpenApiRestCall_600426
proc url_SubscribeToDataset_601265(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_SubscribeToDataset_601264(path: JsonNode; query: JsonNode;
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
  var valid_601266 = path.getOrDefault("IdentityId")
  valid_601266 = validateParameter(valid_601266, JString, required = true,
                                 default = nil)
  if valid_601266 != nil:
    section.add "IdentityId", valid_601266
  var valid_601267 = path.getOrDefault("DeviceId")
  valid_601267 = validateParameter(valid_601267, JString, required = true,
                                 default = nil)
  if valid_601267 != nil:
    section.add "DeviceId", valid_601267
  var valid_601268 = path.getOrDefault("IdentityPoolId")
  valid_601268 = validateParameter(valid_601268, JString, required = true,
                                 default = nil)
  if valid_601268 != nil:
    section.add "IdentityPoolId", valid_601268
  var valid_601269 = path.getOrDefault("DatasetName")
  valid_601269 = validateParameter(valid_601269, JString, required = true,
                                 default = nil)
  if valid_601269 != nil:
    section.add "DatasetName", valid_601269
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
  var valid_601270 = header.getOrDefault("X-Amz-Date")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Date", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Security-Token")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Security-Token", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Content-Sha256", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Algorithm")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Algorithm", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Signature")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Signature", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-SignedHeaders", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Credential")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Credential", valid_601276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601277: Call_SubscribeToDataset_601263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_601277.validator(path, query, header, formData, body)
  let scheme = call_601277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601277.url(scheme.get, call_601277.host, call_601277.base,
                         call_601277.route, valid.getOrDefault("path"))
  result = hook(call_601277, url, valid)

proc call*(call_601278: Call_SubscribeToDataset_601263; IdentityId: string;
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
  var path_601279 = newJObject()
  add(path_601279, "IdentityId", newJString(IdentityId))
  add(path_601279, "DeviceId", newJString(DeviceId))
  add(path_601279, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_601279, "DatasetName", newJString(DatasetName))
  result = call_601278.call(path_601279, nil, nil, nil, nil)

var subscribeToDataset* = Call_SubscribeToDataset_601263(
    name: "subscribeToDataset", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_SubscribeToDataset_601264, base: "/",
    url: url_SubscribeToDataset_601265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromDataset_601280 = ref object of OpenApiRestCall_600426
proc url_UnsubscribeFromDataset_601282(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UnsubscribeFromDataset_601281(path: JsonNode; query: JsonNode;
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
  var valid_601283 = path.getOrDefault("IdentityId")
  valid_601283 = validateParameter(valid_601283, JString, required = true,
                                 default = nil)
  if valid_601283 != nil:
    section.add "IdentityId", valid_601283
  var valid_601284 = path.getOrDefault("DeviceId")
  valid_601284 = validateParameter(valid_601284, JString, required = true,
                                 default = nil)
  if valid_601284 != nil:
    section.add "DeviceId", valid_601284
  var valid_601285 = path.getOrDefault("IdentityPoolId")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = nil)
  if valid_601285 != nil:
    section.add "IdentityPoolId", valid_601285
  var valid_601286 = path.getOrDefault("DatasetName")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = nil)
  if valid_601286 != nil:
    section.add "DatasetName", valid_601286
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
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Content-Sha256", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Algorithm")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Algorithm", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Signature")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Signature", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-SignedHeaders", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Credential")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Credential", valid_601293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601294: Call_UnsubscribeFromDataset_601280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_601294.validator(path, query, header, formData, body)
  let scheme = call_601294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601294.url(scheme.get, call_601294.host, call_601294.base,
                         call_601294.route, valid.getOrDefault("path"))
  result = hook(call_601294, url, valid)

proc call*(call_601295: Call_UnsubscribeFromDataset_601280; IdentityId: string;
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
  var path_601296 = newJObject()
  add(path_601296, "IdentityId", newJString(IdentityId))
  add(path_601296, "DeviceId", newJString(DeviceId))
  add(path_601296, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_601296, "DatasetName", newJString(DatasetName))
  result = call_601295.call(path_601296, nil, nil, nil, nil)

var unsubscribeFromDataset* = Call_UnsubscribeFromDataset_601280(
    name: "unsubscribeFromDataset", meth: HttpMethod.HttpDelete,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_UnsubscribeFromDataset_601281, base: "/",
    url: url_UnsubscribeFromDataset_601282, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
