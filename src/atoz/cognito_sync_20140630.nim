
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
  Call_BulkPublish_605927 = ref object of OpenApiRestCall_605589
proc url_BulkPublish_605929(protocol: Scheme; host: string; base: string;
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

proc validate_BulkPublish_605928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606055 = path.getOrDefault("IdentityPoolId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "IdentityPoolId", valid_606055
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
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_BulkPublish_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_BulkPublish_605927; IdentityPoolId: string): Recallable =
  ## bulkPublish
  ## <p>Initiates a bulk publish of all existing datasets for an Identity Pool to the configured stream. Customers are limited to one successful bulk publish per 24 hours. Bulk publish is an asynchronous request, customers can see the status of the request via the GetBulkPublishDetails operation.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_606157 = newJObject()
  add(path_606157, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606156.call(path_606157, nil, nil, nil, nil)

var bulkPublish* = Call_BulkPublish_605927(name: "bulkPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/bulkpublish",
                                        validator: validate_BulkPublish_605928,
                                        base: "/", url: url_BulkPublish_605929,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecords_606213 = ref object of OpenApiRestCall_605589
proc url_UpdateRecords_606215(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRecords_606214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606216 = path.getOrDefault("IdentityId")
  valid_606216 = validateParameter(valid_606216, JString, required = true,
                                 default = nil)
  if valid_606216 != nil:
    section.add "IdentityId", valid_606216
  var valid_606217 = path.getOrDefault("IdentityPoolId")
  valid_606217 = validateParameter(valid_606217, JString, required = true,
                                 default = nil)
  if valid_606217 != nil:
    section.add "IdentityPoolId", valid_606217
  var valid_606218 = path.getOrDefault("DatasetName")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "DatasetName", valid_606218
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
  var valid_606219 = header.getOrDefault("x-amz-Client-Context")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "x-amz-Client-Context", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Signature")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Signature", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Content-Sha256", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Date")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Date", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Credential")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Credential", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Security-Token")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Security-Token", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Algorithm")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Algorithm", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-SignedHeaders", valid_606226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606228: Call_UpdateRecords_606213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Posts updates to records and adds and deletes records for a dataset and user.</p> <p>The sync count in the record patch is your last known sync count for that record. The server will reject an UpdateRecords request with a ResourceConflictException if you try to patch a record with a new value but a stale sync count.</p> <p>For example, if the sync count on the server is 5 for a key called highScore and you try and submit a new highScore with sync count of 4, the request will be rejected. To obtain the current sync count for a record, call ListRecords. On a successful update of the record, the response returns the new sync count for that record. You should present that sync count the next time you try to update that same record. When the record does not exist, specify the sync count as 0.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_606228.validator(path, query, header, formData, body)
  let scheme = call_606228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606228.url(scheme.get, call_606228.host, call_606228.base,
                         call_606228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606228, url, valid)

proc call*(call_606229: Call_UpdateRecords_606213; IdentityId: string;
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
  var path_606230 = newJObject()
  var body_606231 = newJObject()
  add(path_606230, "IdentityId", newJString(IdentityId))
  if body != nil:
    body_606231 = body
  add(path_606230, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_606230, "DatasetName", newJString(DatasetName))
  result = call_606229.call(path_606230, nil, nil, nil, body_606231)

var updateRecords* = Call_UpdateRecords_606213(name: "updateRecords",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_UpdateRecords_606214, base: "/", url: url_UpdateRecords_606215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_606197 = ref object of OpenApiRestCall_605589
proc url_DescribeDataset_606199(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataset_606198(path: JsonNode; query: JsonNode;
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
  var valid_606200 = path.getOrDefault("IdentityId")
  valid_606200 = validateParameter(valid_606200, JString, required = true,
                                 default = nil)
  if valid_606200 != nil:
    section.add "IdentityId", valid_606200
  var valid_606201 = path.getOrDefault("IdentityPoolId")
  valid_606201 = validateParameter(valid_606201, JString, required = true,
                                 default = nil)
  if valid_606201 != nil:
    section.add "IdentityPoolId", valid_606201
  var valid_606202 = path.getOrDefault("DatasetName")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "DatasetName", valid_606202
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
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606210: Call_DescribeDataset_606197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_606210.validator(path, query, header, formData, body)
  let scheme = call_606210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606210.url(scheme.get, call_606210.host, call_606210.base,
                         call_606210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606210, url, valid)

proc call*(call_606211: Call_DescribeDataset_606197; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## describeDataset
  ## <p>Gets meta data about a dataset by identity and dataset name. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_606212 = newJObject()
  add(path_606212, "IdentityId", newJString(IdentityId))
  add(path_606212, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_606212, "DatasetName", newJString(DatasetName))
  result = call_606211.call(path_606212, nil, nil, nil, nil)

var describeDataset* = Call_DescribeDataset_606197(name: "describeDataset",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DescribeDataset_606198, base: "/", url: url_DescribeDataset_606199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_606232 = ref object of OpenApiRestCall_605589
proc url_DeleteDataset_606234(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataset_606233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606235 = path.getOrDefault("IdentityId")
  valid_606235 = validateParameter(valid_606235, JString, required = true,
                                 default = nil)
  if valid_606235 != nil:
    section.add "IdentityId", valid_606235
  var valid_606236 = path.getOrDefault("IdentityPoolId")
  valid_606236 = validateParameter(valid_606236, JString, required = true,
                                 default = nil)
  if valid_606236 != nil:
    section.add "IdentityPoolId", valid_606236
  var valid_606237 = path.getOrDefault("DatasetName")
  valid_606237 = validateParameter(valid_606237, JString, required = true,
                                 default = nil)
  if valid_606237 != nil:
    section.add "DatasetName", valid_606237
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
  var valid_606238 = header.getOrDefault("X-Amz-Signature")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Signature", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Content-Sha256", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Date")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Date", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Credential")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Credential", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Security-Token")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Security-Token", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Algorithm")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Algorithm", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-SignedHeaders", valid_606244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606245: Call_DeleteDataset_606232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_606245.validator(path, query, header, formData, body)
  let scheme = call_606245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606245.url(scheme.get, call_606245.host, call_606245.base,
                         call_606245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606245, url, valid)

proc call*(call_606246: Call_DeleteDataset_606232; IdentityId: string;
          IdentityPoolId: string; DatasetName: string): Recallable =
  ## deleteDataset
  ## <p>Deletes the specific dataset. The dataset will be deleted permanently, and the action can't be undone. Datasets that this dataset was merged with will no longer report the merge. Any subsequent operation on this dataset will result in a ResourceNotFoundException.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   DatasetName: string (required)
  ##              : A string of up to 128 characters. Allowed characters are a-z, A-Z, 0-9, '_' (underscore), '-' (dash), and '.' (dot).
  var path_606247 = newJObject()
  add(path_606247, "IdentityId", newJString(IdentityId))
  add(path_606247, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_606247, "DatasetName", newJString(DatasetName))
  result = call_606246.call(path_606247, nil, nil, nil, nil)

var deleteDataset* = Call_DeleteDataset_606232(name: "deleteDataset",
    meth: HttpMethod.HttpDelete, host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}",
    validator: validate_DeleteDataset_606233, base: "/", url: url_DeleteDataset_606234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityPoolUsage_606248 = ref object of OpenApiRestCall_605589
proc url_DescribeIdentityPoolUsage_606250(protocol: Scheme; host: string;
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

proc validate_DescribeIdentityPoolUsage_606249(path: JsonNode; query: JsonNode;
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
  var valid_606251 = path.getOrDefault("IdentityPoolId")
  valid_606251 = validateParameter(valid_606251, JString, required = true,
                                 default = nil)
  if valid_606251 != nil:
    section.add "IdentityPoolId", valid_606251
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
  var valid_606252 = header.getOrDefault("X-Amz-Signature")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Signature", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Content-Sha256", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Date")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Date", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Credential")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Credential", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Security-Token")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Security-Token", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Algorithm")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Algorithm", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-SignedHeaders", valid_606258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606259: Call_DescribeIdentityPoolUsage_606248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606259.validator(path, query, header, formData, body)
  let scheme = call_606259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606259.url(scheme.get, call_606259.host, call_606259.base,
                         call_606259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606259, url, valid)

proc call*(call_606260: Call_DescribeIdentityPoolUsage_606248;
          IdentityPoolId: string): Recallable =
  ## describeIdentityPoolUsage
  ## <p>Gets usage details (for example, data storage) about a particular identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_606261 = newJObject()
  add(path_606261, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606260.call(path_606261, nil, nil, nil, nil)

var describeIdentityPoolUsage* = Call_DescribeIdentityPoolUsage_606248(
    name: "describeIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}",
    validator: validate_DescribeIdentityPoolUsage_606249, base: "/",
    url: url_DescribeIdentityPoolUsage_606250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIdentityUsage_606262 = ref object of OpenApiRestCall_605589
proc url_DescribeIdentityUsage_606264(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIdentityUsage_606263(path: JsonNode; query: JsonNode;
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
  var valid_606265 = path.getOrDefault("IdentityId")
  valid_606265 = validateParameter(valid_606265, JString, required = true,
                                 default = nil)
  if valid_606265 != nil:
    section.add "IdentityId", valid_606265
  var valid_606266 = path.getOrDefault("IdentityPoolId")
  valid_606266 = validateParameter(valid_606266, JString, required = true,
                                 default = nil)
  if valid_606266 != nil:
    section.add "IdentityPoolId", valid_606266
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
  var valid_606267 = header.getOrDefault("X-Amz-Signature")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Signature", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Content-Sha256", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Date")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Date", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Credential")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Credential", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Security-Token")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Security-Token", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Algorithm")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Algorithm", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-SignedHeaders", valid_606273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606274: Call_DescribeIdentityUsage_606262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ## 
  let valid = call_606274.validator(path, query, header, formData, body)
  let scheme = call_606274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606274.url(scheme.get, call_606274.host, call_606274.base,
                         call_606274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606274, url, valid)

proc call*(call_606275: Call_DescribeIdentityUsage_606262; IdentityId: string;
          IdentityPoolId: string): Recallable =
  ## describeIdentityUsage
  ## <p>Gets usage information for an identity, including number of datasets and data usage.</p> <p>This API can be called with temporary user credentials provided by Cognito Identity or with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_606276 = newJObject()
  add(path_606276, "IdentityId", newJString(IdentityId))
  add(path_606276, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606275.call(path_606276, nil, nil, nil, nil)

var describeIdentityUsage* = Call_DescribeIdentityUsage_606262(
    name: "describeIdentityUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}",
    validator: validate_DescribeIdentityUsage_606263, base: "/",
    url: url_DescribeIdentityUsage_606264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBulkPublishDetails_606277 = ref object of OpenApiRestCall_605589
proc url_GetBulkPublishDetails_606279(protocol: Scheme; host: string; base: string;
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

proc validate_GetBulkPublishDetails_606278(path: JsonNode; query: JsonNode;
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
  var valid_606280 = path.getOrDefault("IdentityPoolId")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "IdentityPoolId", valid_606280
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
  var valid_606281 = header.getOrDefault("X-Amz-Signature")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Signature", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Content-Sha256", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Date")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Date", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Credential")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Credential", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Security-Token")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Security-Token", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Algorithm")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Algorithm", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-SignedHeaders", valid_606287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606288: Call_GetBulkPublishDetails_606277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606288.validator(path, query, header, formData, body)
  let scheme = call_606288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606288.url(scheme.get, call_606288.host, call_606288.base,
                         call_606288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606288, url, valid)

proc call*(call_606289: Call_GetBulkPublishDetails_606277; IdentityPoolId: string): Recallable =
  ## getBulkPublishDetails
  ## <p>Get the status of the last BulkPublish operation for an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. GUID generation is unique within a region.
  var path_606290 = newJObject()
  add(path_606290, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606289.call(path_606290, nil, nil, nil, nil)

var getBulkPublishDetails* = Call_GetBulkPublishDetails_606277(
    name: "getBulkPublishDetails", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/getBulkPublishDetails",
    validator: validate_GetBulkPublishDetails_606278, base: "/",
    url: url_GetBulkPublishDetails_606279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetCognitoEvents_606305 = ref object of OpenApiRestCall_605589
proc url_SetCognitoEvents_606307(protocol: Scheme; host: string; base: string;
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

proc validate_SetCognitoEvents_606306(path: JsonNode; query: JsonNode;
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
  var valid_606308 = path.getOrDefault("IdentityPoolId")
  valid_606308 = validateParameter(valid_606308, JString, required = true,
                                 default = nil)
  if valid_606308 != nil:
    section.add "IdentityPoolId", valid_606308
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
  var valid_606309 = header.getOrDefault("X-Amz-Signature")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Signature", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Content-Sha256", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Date")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Date", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Credential")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Credential", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Security-Token")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Security-Token", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Algorithm")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Algorithm", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-SignedHeaders", valid_606315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606317: Call_SetCognitoEvents_606305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606317.validator(path, query, header, formData, body)
  let scheme = call_606317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606317.url(scheme.get, call_606317.host, call_606317.base,
                         call_606317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606317, url, valid)

proc call*(call_606318: Call_SetCognitoEvents_606305; body: JsonNode;
          IdentityPoolId: string): Recallable =
  ## setCognitoEvents
  ## <p>Sets the AWS Lambda function for a given event type for an identity pool. This request only updates the key/value pair specified. Other key/values pairs are not updated. To remove a key value pair, pass a empty value for the particular key.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool to use when configuring Cognito Events
  var path_606319 = newJObject()
  var body_606320 = newJObject()
  if body != nil:
    body_606320 = body
  add(path_606319, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606318.call(path_606319, nil, nil, nil, body_606320)

var setCognitoEvents* = Call_SetCognitoEvents_606305(name: "setCognitoEvents",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_SetCognitoEvents_606306, base: "/",
    url: url_SetCognitoEvents_606307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCognitoEvents_606291 = ref object of OpenApiRestCall_605589
proc url_GetCognitoEvents_606293(protocol: Scheme; host: string; base: string;
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

proc validate_GetCognitoEvents_606292(path: JsonNode; query: JsonNode;
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
  var valid_606294 = path.getOrDefault("IdentityPoolId")
  valid_606294 = validateParameter(valid_606294, JString, required = true,
                                 default = nil)
  if valid_606294 != nil:
    section.add "IdentityPoolId", valid_606294
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
  var valid_606295 = header.getOrDefault("X-Amz-Signature")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Signature", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Content-Sha256", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Date")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Date", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Credential")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Credential", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Security-Token")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Security-Token", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Algorithm")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Algorithm", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-SignedHeaders", valid_606301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606302: Call_GetCognitoEvents_606291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606302.validator(path, query, header, formData, body)
  let scheme = call_606302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606302.url(scheme.get, call_606302.host, call_606302.base,
                         call_606302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606302, url, valid)

proc call*(call_606303: Call_GetCognitoEvents_606291; IdentityPoolId: string): Recallable =
  ## getCognitoEvents
  ## <p>Gets the events and the corresponding Lambda functions associated with an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : The Cognito Identity Pool ID for the request
  var path_606304 = newJObject()
  add(path_606304, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606303.call(path_606304, nil, nil, nil, nil)

var getCognitoEvents* = Call_GetCognitoEvents_606291(name: "getCognitoEvents",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/events",
    validator: validate_GetCognitoEvents_606292, base: "/",
    url: url_GetCognitoEvents_606293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetIdentityPoolConfiguration_606335 = ref object of OpenApiRestCall_605589
proc url_SetIdentityPoolConfiguration_606337(protocol: Scheme; host: string;
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

proc validate_SetIdentityPoolConfiguration_606336(path: JsonNode; query: JsonNode;
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
  var valid_606338 = path.getOrDefault("IdentityPoolId")
  valid_606338 = validateParameter(valid_606338, JString, required = true,
                                 default = nil)
  if valid_606338 != nil:
    section.add "IdentityPoolId", valid_606338
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
  var valid_606339 = header.getOrDefault("X-Amz-Signature")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Signature", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Content-Sha256", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Date")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Date", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Credential")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Credential", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Security-Token")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Security-Token", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Algorithm")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Algorithm", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-SignedHeaders", valid_606345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606347: Call_SetIdentityPoolConfiguration_606335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606347.validator(path, query, header, formData, body)
  let scheme = call_606347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606347.url(scheme.get, call_606347.host, call_606347.base,
                         call_606347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606347, url, valid)

proc call*(call_606348: Call_SetIdentityPoolConfiguration_606335; body: JsonNode;
          IdentityPoolId: string): Recallable =
  ## setIdentityPoolConfiguration
  ## <p>Sets the necessary configuration for push sync.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool to modify.
  var path_606349 = newJObject()
  var body_606350 = newJObject()
  if body != nil:
    body_606350 = body
  add(path_606349, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606348.call(path_606349, nil, nil, nil, body_606350)

var setIdentityPoolConfiguration* = Call_SetIdentityPoolConfiguration_606335(
    name: "setIdentityPoolConfiguration", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_SetIdentityPoolConfiguration_606336, base: "/",
    url: url_SetIdentityPoolConfiguration_606337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIdentityPoolConfiguration_606321 = ref object of OpenApiRestCall_605589
proc url_GetIdentityPoolConfiguration_606323(protocol: Scheme; host: string;
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

proc validate_GetIdentityPoolConfiguration_606322(path: JsonNode; query: JsonNode;
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
  var valid_606324 = path.getOrDefault("IdentityPoolId")
  valid_606324 = validateParameter(valid_606324, JString, required = true,
                                 default = nil)
  if valid_606324 != nil:
    section.add "IdentityPoolId", valid_606324
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
  var valid_606325 = header.getOrDefault("X-Amz-Signature")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Signature", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Content-Sha256", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Date")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Date", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Credential")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Credential", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Security-Token")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Security-Token", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Algorithm")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Algorithm", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-SignedHeaders", valid_606331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606332: Call_GetIdentityPoolConfiguration_606321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606332.validator(path, query, header, formData, body)
  let scheme = call_606332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606332.url(scheme.get, call_606332.host, call_606332.base,
                         call_606332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606332, url, valid)

proc call*(call_606333: Call_GetIdentityPoolConfiguration_606321;
          IdentityPoolId: string): Recallable =
  ## getIdentityPoolConfiguration
  ## <p>Gets the configuration settings of an identity pool.</p> <p>This API can only be called with developer credentials. You cannot call this API with the temporary user credentials provided by Cognito Identity.</p>
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. This is the ID of the pool for which to return a configuration.
  var path_606334 = newJObject()
  add(path_606334, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606333.call(path_606334, nil, nil, nil, nil)

var getIdentityPoolConfiguration* = Call_GetIdentityPoolConfiguration_606321(
    name: "getIdentityPoolConfiguration", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/configuration",
    validator: validate_GetIdentityPoolConfiguration_606322, base: "/",
    url: url_GetIdentityPoolConfiguration_606323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_606351 = ref object of OpenApiRestCall_605589
proc url_ListDatasets_606353(protocol: Scheme; host: string; base: string;
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

proc validate_ListDatasets_606352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606354 = path.getOrDefault("IdentityId")
  valid_606354 = validateParameter(valid_606354, JString, required = true,
                                 default = nil)
  if valid_606354 != nil:
    section.add "IdentityId", valid_606354
  var valid_606355 = path.getOrDefault("IdentityPoolId")
  valid_606355 = validateParameter(valid_606355, JString, required = true,
                                 default = nil)
  if valid_606355 != nil:
    section.add "IdentityPoolId", valid_606355
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for obtaining the next page of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to be returned.
  section = newJObject()
  var valid_606356 = query.getOrDefault("nextToken")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "nextToken", valid_606356
  var valid_606357 = query.getOrDefault("maxResults")
  valid_606357 = validateParameter(valid_606357, JInt, required = false, default = nil)
  if valid_606357 != nil:
    section.add "maxResults", valid_606357
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
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606365: Call_ListDatasets_606351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists datasets for an identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListDatasets can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use the Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_606365.validator(path, query, header, formData, body)
  let scheme = call_606365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606365.url(scheme.get, call_606365.host, call_606365.base,
                         call_606365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606365, url, valid)

proc call*(call_606366: Call_ListDatasets_606351; IdentityId: string;
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
  var path_606367 = newJObject()
  var query_606368 = newJObject()
  add(query_606368, "nextToken", newJString(nextToken))
  add(path_606367, "IdentityId", newJString(IdentityId))
  add(path_606367, "IdentityPoolId", newJString(IdentityPoolId))
  add(query_606368, "maxResults", newJInt(maxResults))
  result = call_606366.call(path_606367, query_606368, nil, nil, nil)

var listDatasets* = Call_ListDatasets_606351(name: "listDatasets",
    meth: HttpMethod.HttpGet, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets",
    validator: validate_ListDatasets_606352, base: "/", url: url_ListDatasets_606353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIdentityPoolUsage_606369 = ref object of OpenApiRestCall_605589
proc url_ListIdentityPoolUsage_606371(protocol: Scheme; host: string; base: string;
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

proc validate_ListIdentityPoolUsage_606370(path: JsonNode; query: JsonNode;
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
  var valid_606372 = query.getOrDefault("nextToken")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "nextToken", valid_606372
  var valid_606373 = query.getOrDefault("maxResults")
  valid_606373 = validateParameter(valid_606373, JInt, required = false, default = nil)
  if valid_606373 != nil:
    section.add "maxResults", valid_606373
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
  var valid_606374 = header.getOrDefault("X-Amz-Signature")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Signature", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Content-Sha256", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Date")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Date", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Credential")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Credential", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Security-Token")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Security-Token", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Algorithm")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Algorithm", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-SignedHeaders", valid_606380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606381: Call_ListIdentityPoolUsage_606369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ## 
  let valid = call_606381.validator(path, query, header, formData, body)
  let scheme = call_606381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606381.url(scheme.get, call_606381.host, call_606381.base,
                         call_606381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606381, url, valid)

proc call*(call_606382: Call_ListIdentityPoolUsage_606369; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listIdentityPoolUsage
  ## <p>Gets a list of identity pools registered with Cognito.</p> <p>ListIdentityPoolUsage can only be called with developer credentials. You cannot make this API call with the temporary user credentials provided by Cognito Identity.</p>
  ##   nextToken: string
  ##            : A pagination token for obtaining the next page of results.
  ##   maxResults: int
  ##             : The maximum number of results to be returned.
  var query_606383 = newJObject()
  add(query_606383, "nextToken", newJString(nextToken))
  add(query_606383, "maxResults", newJInt(maxResults))
  result = call_606382.call(nil, query_606383, nil, nil, nil)

var listIdentityPoolUsage* = Call_ListIdentityPoolUsage_606369(
    name: "listIdentityPoolUsage", meth: HttpMethod.HttpGet,
    host: "cognito-sync.amazonaws.com", route: "/identitypools",
    validator: validate_ListIdentityPoolUsage_606370, base: "/",
    url: url_ListIdentityPoolUsage_606371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecords_606384 = ref object of OpenApiRestCall_605589
proc url_ListRecords_606386(protocol: Scheme; host: string; base: string;
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

proc validate_ListRecords_606385(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606387 = path.getOrDefault("IdentityId")
  valid_606387 = validateParameter(valid_606387, JString, required = true,
                                 default = nil)
  if valid_606387 != nil:
    section.add "IdentityId", valid_606387
  var valid_606388 = path.getOrDefault("IdentityPoolId")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = nil)
  if valid_606388 != nil:
    section.add "IdentityPoolId", valid_606388
  var valid_606389 = path.getOrDefault("DatasetName")
  valid_606389 = validateParameter(valid_606389, JString, required = true,
                                 default = nil)
  if valid_606389 != nil:
    section.add "DatasetName", valid_606389
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
  var valid_606390 = query.getOrDefault("nextToken")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "nextToken", valid_606390
  var valid_606391 = query.getOrDefault("lastSyncCount")
  valid_606391 = validateParameter(valid_606391, JInt, required = false, default = nil)
  if valid_606391 != nil:
    section.add "lastSyncCount", valid_606391
  var valid_606392 = query.getOrDefault("syncSessionToken")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "syncSessionToken", valid_606392
  var valid_606393 = query.getOrDefault("maxResults")
  valid_606393 = validateParameter(valid_606393, JInt, required = false, default = nil)
  if valid_606393 != nil:
    section.add "maxResults", valid_606393
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
  var valid_606394 = header.getOrDefault("X-Amz-Signature")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Signature", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Content-Sha256", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Date")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Date", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Credential")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Credential", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Security-Token")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Security-Token", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Algorithm")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Algorithm", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-SignedHeaders", valid_606400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606401: Call_ListRecords_606384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets paginated records, optionally changed after a particular sync count for a dataset and identity. With Amazon Cognito Sync, each identity has access only to its own data. Thus, the credentials used to make this API call need to have access to the identity data.</p> <p>ListRecords can be called with temporary user credentials provided by Cognito Identity or with developer credentials. You should use Cognito Identity credentials to make this API call.</p>
  ## 
  let valid = call_606401.validator(path, query, header, formData, body)
  let scheme = call_606401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606401.url(scheme.get, call_606401.host, call_606401.base,
                         call_606401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606401, url, valid)

proc call*(call_606402: Call_ListRecords_606384; IdentityId: string;
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
  var path_606403 = newJObject()
  var query_606404 = newJObject()
  add(query_606404, "nextToken", newJString(nextToken))
  add(path_606403, "IdentityId", newJString(IdentityId))
  add(query_606404, "lastSyncCount", newJInt(lastSyncCount))
  add(path_606403, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_606403, "DatasetName", newJString(DatasetName))
  add(query_606404, "syncSessionToken", newJString(syncSessionToken))
  add(query_606404, "maxResults", newJInt(maxResults))
  result = call_606402.call(path_606403, query_606404, nil, nil, nil)

var listRecords* = Call_ListRecords_606384(name: "listRecords",
                                        meth: HttpMethod.HttpGet,
                                        host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/records",
                                        validator: validate_ListRecords_606385,
                                        base: "/", url: url_ListRecords_606386,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDevice_606405 = ref object of OpenApiRestCall_605589
proc url_RegisterDevice_606407(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterDevice_606406(path: JsonNode; query: JsonNode;
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
  var valid_606408 = path.getOrDefault("IdentityId")
  valid_606408 = validateParameter(valid_606408, JString, required = true,
                                 default = nil)
  if valid_606408 != nil:
    section.add "IdentityId", valid_606408
  var valid_606409 = path.getOrDefault("IdentityPoolId")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = nil)
  if valid_606409 != nil:
    section.add "IdentityPoolId", valid_606409
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
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_RegisterDevice_606405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_RegisterDevice_606405; IdentityId: string;
          body: JsonNode; IdentityPoolId: string): Recallable =
  ## registerDevice
  ## <p>Registers a device to receive push sync notifications.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ##   IdentityId: string (required)
  ##             : The unique ID for this identity.
  ##   body: JObject (required)
  ##   IdentityPoolId: string (required)
  ##                 : A name-spaced GUID (for example, us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon Cognito. Here, the ID of the pool that the identity belongs to.
  var path_606420 = newJObject()
  var body_606421 = newJObject()
  add(path_606420, "IdentityId", newJString(IdentityId))
  if body != nil:
    body_606421 = body
  add(path_606420, "IdentityPoolId", newJString(IdentityPoolId))
  result = call_606419.call(path_606420, nil, nil, nil, body_606421)

var registerDevice* = Call_RegisterDevice_606405(name: "registerDevice",
    meth: HttpMethod.HttpPost, host: "cognito-sync.amazonaws.com",
    route: "/identitypools/{IdentityPoolId}/identity/{IdentityId}/device",
    validator: validate_RegisterDevice_606406, base: "/", url: url_RegisterDevice_606407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToDataset_606422 = ref object of OpenApiRestCall_605589
proc url_SubscribeToDataset_606424(protocol: Scheme; host: string; base: string;
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

proc validate_SubscribeToDataset_606423(path: JsonNode; query: JsonNode;
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
  var valid_606425 = path.getOrDefault("IdentityId")
  valid_606425 = validateParameter(valid_606425, JString, required = true,
                                 default = nil)
  if valid_606425 != nil:
    section.add "IdentityId", valid_606425
  var valid_606426 = path.getOrDefault("DeviceId")
  valid_606426 = validateParameter(valid_606426, JString, required = true,
                                 default = nil)
  if valid_606426 != nil:
    section.add "DeviceId", valid_606426
  var valid_606427 = path.getOrDefault("IdentityPoolId")
  valid_606427 = validateParameter(valid_606427, JString, required = true,
                                 default = nil)
  if valid_606427 != nil:
    section.add "IdentityPoolId", valid_606427
  var valid_606428 = path.getOrDefault("DatasetName")
  valid_606428 = validateParameter(valid_606428, JString, required = true,
                                 default = nil)
  if valid_606428 != nil:
    section.add "DatasetName", valid_606428
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

proc call*(call_606436: Call_SubscribeToDataset_606422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Subscribes to receive notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_606436.validator(path, query, header, formData, body)
  let scheme = call_606436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606436.url(scheme.get, call_606436.host, call_606436.base,
                         call_606436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606436, url, valid)

proc call*(call_606437: Call_SubscribeToDataset_606422; IdentityId: string;
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
  var path_606438 = newJObject()
  add(path_606438, "IdentityId", newJString(IdentityId))
  add(path_606438, "DeviceId", newJString(DeviceId))
  add(path_606438, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_606438, "DatasetName", newJString(DatasetName))
  result = call_606437.call(path_606438, nil, nil, nil, nil)

var subscribeToDataset* = Call_SubscribeToDataset_606422(
    name: "subscribeToDataset", meth: HttpMethod.HttpPost,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_SubscribeToDataset_606423, base: "/",
    url: url_SubscribeToDataset_606424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromDataset_606439 = ref object of OpenApiRestCall_605589
proc url_UnsubscribeFromDataset_606441(protocol: Scheme; host: string; base: string;
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

proc validate_UnsubscribeFromDataset_606440(path: JsonNode; query: JsonNode;
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
  var valid_606442 = path.getOrDefault("IdentityId")
  valid_606442 = validateParameter(valid_606442, JString, required = true,
                                 default = nil)
  if valid_606442 != nil:
    section.add "IdentityId", valid_606442
  var valid_606443 = path.getOrDefault("DeviceId")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "DeviceId", valid_606443
  var valid_606444 = path.getOrDefault("IdentityPoolId")
  valid_606444 = validateParameter(valid_606444, JString, required = true,
                                 default = nil)
  if valid_606444 != nil:
    section.add "IdentityPoolId", valid_606444
  var valid_606445 = path.getOrDefault("DatasetName")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = nil)
  if valid_606445 != nil:
    section.add "DatasetName", valid_606445
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
  var valid_606446 = header.getOrDefault("X-Amz-Signature")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Signature", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Content-Sha256", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Date")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Date", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Credential")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Credential", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Security-Token")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Security-Token", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Algorithm")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Algorithm", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-SignedHeaders", valid_606452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606453: Call_UnsubscribeFromDataset_606439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Unsubscribes from receiving notifications when a dataset is modified by another device.</p> <p>This API can only be called with temporary credentials provided by Cognito Identity. You cannot call this API with developer credentials.</p>
  ## 
  let valid = call_606453.validator(path, query, header, formData, body)
  let scheme = call_606453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606453.url(scheme.get, call_606453.host, call_606453.base,
                         call_606453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606453, url, valid)

proc call*(call_606454: Call_UnsubscribeFromDataset_606439; IdentityId: string;
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
  var path_606455 = newJObject()
  add(path_606455, "IdentityId", newJString(IdentityId))
  add(path_606455, "DeviceId", newJString(DeviceId))
  add(path_606455, "IdentityPoolId", newJString(IdentityPoolId))
  add(path_606455, "DatasetName", newJString(DatasetName))
  result = call_606454.call(path_606455, nil, nil, nil, nil)

var unsubscribeFromDataset* = Call_UnsubscribeFromDataset_606439(
    name: "unsubscribeFromDataset", meth: HttpMethod.HttpDelete,
    host: "cognito-sync.amazonaws.com", route: "/identitypools/{IdentityPoolId}/identities/{IdentityId}/datasets/{DatasetName}/subscriptions/{DeviceId}",
    validator: validate_UnsubscribeFromDataset_606440, base: "/",
    url: url_UnsubscribeFromDataset_606441, schemes: {Scheme.Https, Scheme.Http})
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
