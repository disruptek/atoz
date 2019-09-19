
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS AppSync
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS AppSync provides API actions for creating and interacting with data sources using GraphQL from your application.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appsync/
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "appsync.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appsync.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appsync.us-west-2.amazonaws.com",
                           "eu-west-2": "appsync.eu-west-2.amazonaws.com", "ap-northeast-3": "appsync.ap-northeast-3.amazonaws.com", "eu-central-1": "appsync.eu-central-1.amazonaws.com",
                           "us-east-2": "appsync.us-east-2.amazonaws.com",
                           "us-east-1": "appsync.us-east-1.amazonaws.com", "cn-northwest-1": "appsync.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appsync.ap-south-1.amazonaws.com",
                           "eu-north-1": "appsync.eu-north-1.amazonaws.com", "ap-northeast-2": "appsync.ap-northeast-2.amazonaws.com",
                           "us-west-1": "appsync.us-west-1.amazonaws.com", "us-gov-east-1": "appsync.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appsync.eu-west-3.amazonaws.com",
                           "cn-north-1": "appsync.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appsync.sa-east-1.amazonaws.com",
                           "eu-west-1": "appsync.eu-west-1.amazonaws.com", "us-gov-west-1": "appsync.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appsync.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "appsync.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "appsync.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appsync.ap-southeast-1.amazonaws.com",
      "us-west-2": "appsync.us-west-2.amazonaws.com",
      "eu-west-2": "appsync.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appsync.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appsync.eu-central-1.amazonaws.com",
      "us-east-2": "appsync.us-east-2.amazonaws.com",
      "us-east-1": "appsync.us-east-1.amazonaws.com",
      "cn-northwest-1": "appsync.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appsync.ap-south-1.amazonaws.com",
      "eu-north-1": "appsync.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appsync.ap-northeast-2.amazonaws.com",
      "us-west-1": "appsync.us-west-1.amazonaws.com",
      "us-gov-east-1": "appsync.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appsync.eu-west-3.amazonaws.com",
      "cn-north-1": "appsync.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appsync.sa-east-1.amazonaws.com",
      "eu-west-1": "appsync.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appsync.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appsync.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appsync.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appsync"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_773206 = ref object of OpenApiRestCall_772597
proc url_CreateApiKey_773208(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateApiKey_773207(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The ID for your GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773209 = path.getOrDefault("apiId")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = nil)
  if valid_773209 != nil:
    section.add "apiId", valid_773209
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
  var valid_773210 = header.getOrDefault("X-Amz-Date")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Date", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Security-Token")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Security-Token", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Content-Sha256", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Algorithm")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Algorithm", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Signature")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Signature", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-SignedHeaders", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Credential")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Credential", valid_773216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773218: Call_CreateApiKey_773206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_773218.validator(path, query, header, formData, body)
  let scheme = call_773218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773218.url(scheme.get, call_773218.host, call_773218.base,
                         call_773218.route, valid.getOrDefault("path"))
  result = hook(call_773218, url, valid)

proc call*(call_773219: Call_CreateApiKey_773206; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_773220 = newJObject()
  var body_773221 = newJObject()
  add(path_773220, "apiId", newJString(apiId))
  if body != nil:
    body_773221 = body
  result = call_773219.call(path_773220, nil, nil, nil, body_773221)

var createApiKey* = Call_CreateApiKey_773206(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_773207,
    base: "/", url: url_CreateApiKey_773208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_772933 = ref object of OpenApiRestCall_772597
proc url_ListApiKeys_772935(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListApiKeys_772934(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773061 = path.getOrDefault("apiId")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "apiId", valid_773061
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_773062 = query.getOrDefault("maxResults")
  valid_773062 = validateParameter(valid_773062, JInt, required = false, default = nil)
  if valid_773062 != nil:
    section.add "maxResults", valid_773062
  var valid_773063 = query.getOrDefault("nextToken")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "nextToken", valid_773063
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
  var valid_773064 = header.getOrDefault("X-Amz-Date")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Date", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Security-Token")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Security-Token", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Content-Sha256", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Algorithm")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Algorithm", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Signature")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Signature", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-SignedHeaders", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-Credential")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-Credential", valid_773070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773093: Call_ListApiKeys_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_773093.validator(path, query, header, formData, body)
  let scheme = call_773093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773093.url(scheme.get, call_773093.host, call_773093.base,
                         call_773093.route, valid.getOrDefault("path"))
  result = hook(call_773093, url, valid)

proc call*(call_773164: Call_ListApiKeys_772933; apiId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_773165 = newJObject()
  var query_773167 = newJObject()
  add(path_773165, "apiId", newJString(apiId))
  add(query_773167, "maxResults", newJInt(maxResults))
  add(query_773167, "nextToken", newJString(nextToken))
  result = call_773164.call(path_773165, query_773167, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_772933(name: "listApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/apikeys",
                                        validator: validate_ListApiKeys_772934,
                                        base: "/", url: url_ListApiKeys_772935,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_773239 = ref object of OpenApiRestCall_772597
proc url_CreateDataSource_773241(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateDataSource_773240(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773242 = path.getOrDefault("apiId")
  valid_773242 = validateParameter(valid_773242, JString, required = true,
                                 default = nil)
  if valid_773242 != nil:
    section.add "apiId", valid_773242
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
  var valid_773243 = header.getOrDefault("X-Amz-Date")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Date", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Security-Token")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Security-Token", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Content-Sha256", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Algorithm")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Algorithm", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Signature")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Signature", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-SignedHeaders", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Credential")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Credential", valid_773249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773251: Call_CreateDataSource_773239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_773251.validator(path, query, header, formData, body)
  let scheme = call_773251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773251.url(scheme.get, call_773251.host, call_773251.base,
                         call_773251.route, valid.getOrDefault("path"))
  result = hook(call_773251, url, valid)

proc call*(call_773252: Call_CreateDataSource_773239; apiId: string; body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_773253 = newJObject()
  var body_773254 = newJObject()
  add(path_773253, "apiId", newJString(apiId))
  if body != nil:
    body_773254 = body
  result = call_773252.call(path_773253, nil, nil, nil, body_773254)

var createDataSource* = Call_CreateDataSource_773239(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_773240,
    base: "/", url: url_CreateDataSource_773241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_773222 = ref object of OpenApiRestCall_772597
proc url_ListDataSources_773224(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDataSources_773223(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the data sources for a given API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773225 = path.getOrDefault("apiId")
  valid_773225 = validateParameter(valid_773225, JString, required = true,
                                 default = nil)
  if valid_773225 != nil:
    section.add "apiId", valid_773225
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_773226 = query.getOrDefault("maxResults")
  valid_773226 = validateParameter(valid_773226, JInt, required = false, default = nil)
  if valid_773226 != nil:
    section.add "maxResults", valid_773226
  var valid_773227 = query.getOrDefault("nextToken")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "nextToken", valid_773227
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
  var valid_773228 = header.getOrDefault("X-Amz-Date")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Date", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Security-Token")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Security-Token", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Content-Sha256", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Algorithm")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Algorithm", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Signature")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Signature", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-SignedHeaders", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Credential")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Credential", valid_773234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773235: Call_ListDataSources_773222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_773235.validator(path, query, header, formData, body)
  let scheme = call_773235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773235.url(scheme.get, call_773235.host, call_773235.base,
                         call_773235.route, valid.getOrDefault("path"))
  result = hook(call_773235, url, valid)

proc call*(call_773236: Call_ListDataSources_773222; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var path_773237 = newJObject()
  var query_773238 = newJObject()
  add(path_773237, "apiId", newJString(apiId))
  add(query_773238, "maxResults", newJInt(maxResults))
  add(query_773238, "nextToken", newJString(nextToken))
  result = call_773236.call(path_773237, query_773238, nil, nil, nil)

var listDataSources* = Call_ListDataSources_773222(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_773223,
    base: "/", url: url_ListDataSources_773224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_773272 = ref object of OpenApiRestCall_772597
proc url_CreateFunction_773274(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateFunction_773273(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773275 = path.getOrDefault("apiId")
  valid_773275 = validateParameter(valid_773275, JString, required = true,
                                 default = nil)
  if valid_773275 != nil:
    section.add "apiId", valid_773275
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
  var valid_773276 = header.getOrDefault("X-Amz-Date")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Date", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Security-Token")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Security-Token", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Content-Sha256", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-Algorithm")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Algorithm", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Signature")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Signature", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-SignedHeaders", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Credential")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Credential", valid_773282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773284: Call_CreateFunction_773272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_773284.validator(path, query, header, formData, body)
  let scheme = call_773284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773284.url(scheme.get, call_773284.host, call_773284.base,
                         call_773284.route, valid.getOrDefault("path"))
  result = hook(call_773284, url, valid)

proc call*(call_773285: Call_CreateFunction_773272; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_773286 = newJObject()
  var body_773287 = newJObject()
  add(path_773286, "apiId", newJString(apiId))
  if body != nil:
    body_773287 = body
  result = call_773285.call(path_773286, nil, nil, nil, body_773287)

var createFunction* = Call_CreateFunction_773272(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_773273,
    base: "/", url: url_CreateFunction_773274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_773255 = ref object of OpenApiRestCall_772597
proc url_ListFunctions_773257(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListFunctions_773256(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## List multiple functions.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773258 = path.getOrDefault("apiId")
  valid_773258 = validateParameter(valid_773258, JString, required = true,
                                 default = nil)
  if valid_773258 != nil:
    section.add "apiId", valid_773258
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_773259 = query.getOrDefault("maxResults")
  valid_773259 = validateParameter(valid_773259, JInt, required = false, default = nil)
  if valid_773259 != nil:
    section.add "maxResults", valid_773259
  var valid_773260 = query.getOrDefault("nextToken")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "nextToken", valid_773260
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
  var valid_773261 = header.getOrDefault("X-Amz-Date")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Date", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Security-Token")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Security-Token", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Content-Sha256", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Algorithm")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Algorithm", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Signature")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Signature", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-SignedHeaders", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Credential")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Credential", valid_773267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773268: Call_ListFunctions_773255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_773268.validator(path, query, header, formData, body)
  let scheme = call_773268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773268.url(scheme.get, call_773268.host, call_773268.base,
                         call_773268.route, valid.getOrDefault("path"))
  result = hook(call_773268, url, valid)

proc call*(call_773269: Call_ListFunctions_773255; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_773270 = newJObject()
  var query_773271 = newJObject()
  add(path_773270, "apiId", newJString(apiId))
  add(query_773271, "maxResults", newJInt(maxResults))
  add(query_773271, "nextToken", newJString(nextToken))
  result = call_773269.call(path_773270, query_773271, nil, nil, nil)

var listFunctions* = Call_ListFunctions_773255(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_773256,
    base: "/", url: url_ListFunctions_773257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_773303 = ref object of OpenApiRestCall_772597
proc url_CreateGraphqlApi_773305(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGraphqlApi_773304(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a <code>GraphqlApi</code> object.
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773306 = header.getOrDefault("X-Amz-Date")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Date", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Security-Token")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Security-Token", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Content-Sha256", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-Algorithm")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Algorithm", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Signature")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Signature", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-SignedHeaders", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Credential")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Credential", valid_773312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773314: Call_CreateGraphqlApi_773303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_773314.validator(path, query, header, formData, body)
  let scheme = call_773314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773314.url(scheme.get, call_773314.host, call_773314.base,
                         call_773314.route, valid.getOrDefault("path"))
  result = hook(call_773314, url, valid)

proc call*(call_773315: Call_CreateGraphqlApi_773303; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_773316 = newJObject()
  if body != nil:
    body_773316 = body
  result = call_773315.call(nil, nil, nil, nil, body_773316)

var createGraphqlApi* = Call_CreateGraphqlApi_773303(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_773304, base: "/",
    url: url_CreateGraphqlApi_773305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_773288 = ref object of OpenApiRestCall_772597
proc url_ListGraphqlApis_773290(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGraphqlApis_773289(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists your GraphQL APIs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_773291 = query.getOrDefault("maxResults")
  valid_773291 = validateParameter(valid_773291, JInt, required = false, default = nil)
  if valid_773291 != nil:
    section.add "maxResults", valid_773291
  var valid_773292 = query.getOrDefault("nextToken")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "nextToken", valid_773292
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
  var valid_773293 = header.getOrDefault("X-Amz-Date")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Date", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Security-Token")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Security-Token", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Content-Sha256", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Algorithm")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Algorithm", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Signature")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Signature", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-SignedHeaders", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Credential")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Credential", valid_773299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773300: Call_ListGraphqlApis_773288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_773300.validator(path, query, header, formData, body)
  let scheme = call_773300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773300.url(scheme.get, call_773300.host, call_773300.base,
                         call_773300.route, valid.getOrDefault("path"))
  result = hook(call_773300, url, valid)

proc call*(call_773301: Call_ListGraphqlApis_773288; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var query_773302 = newJObject()
  add(query_773302, "maxResults", newJInt(maxResults))
  add(query_773302, "nextToken", newJString(nextToken))
  result = call_773301.call(nil, query_773302, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_773288(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_773289, base: "/", url: url_ListGraphqlApis_773290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_773335 = ref object of OpenApiRestCall_772597
proc url_CreateResolver_773337(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateResolver_773336(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: JString (required)
  ##           : The name of the <code>Type</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773338 = path.getOrDefault("apiId")
  valid_773338 = validateParameter(valid_773338, JString, required = true,
                                 default = nil)
  if valid_773338 != nil:
    section.add "apiId", valid_773338
  var valid_773339 = path.getOrDefault("typeName")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = nil)
  if valid_773339 != nil:
    section.add "typeName", valid_773339
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Content-Sha256", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Algorithm")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Algorithm", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Signature")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Signature", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-SignedHeaders", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Credential")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Credential", valid_773346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773348: Call_CreateResolver_773335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_773348.validator(path, query, header, formData, body)
  let scheme = call_773348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773348.url(scheme.get, call_773348.host, call_773348.base,
                         call_773348.route, valid.getOrDefault("path"))
  result = hook(call_773348, url, valid)

proc call*(call_773349: Call_CreateResolver_773335; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_773350 = newJObject()
  var body_773351 = newJObject()
  add(path_773350, "apiId", newJString(apiId))
  add(path_773350, "typeName", newJString(typeName))
  if body != nil:
    body_773351 = body
  result = call_773349.call(path_773350, nil, nil, nil, body_773351)

var createResolver* = Call_CreateResolver_773335(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_773336, base: "/", url: url_CreateResolver_773337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_773317 = ref object of OpenApiRestCall_772597
proc url_ListResolvers_773319(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListResolvers_773318(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resolvers for a given API and type.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773320 = path.getOrDefault("apiId")
  valid_773320 = validateParameter(valid_773320, JString, required = true,
                                 default = nil)
  if valid_773320 != nil:
    section.add "apiId", valid_773320
  var valid_773321 = path.getOrDefault("typeName")
  valid_773321 = validateParameter(valid_773321, JString, required = true,
                                 default = nil)
  if valid_773321 != nil:
    section.add "typeName", valid_773321
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_773322 = query.getOrDefault("maxResults")
  valid_773322 = validateParameter(valid_773322, JInt, required = false, default = nil)
  if valid_773322 != nil:
    section.add "maxResults", valid_773322
  var valid_773323 = query.getOrDefault("nextToken")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "nextToken", valid_773323
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
  var valid_773324 = header.getOrDefault("X-Amz-Date")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Date", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Security-Token")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Security-Token", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Content-Sha256", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Algorithm")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Algorithm", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Signature")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Signature", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-SignedHeaders", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Credential")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Credential", valid_773330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773331: Call_ListResolvers_773317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_773331.validator(path, query, header, formData, body)
  let scheme = call_773331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773331.url(scheme.get, call_773331.host, call_773331.base,
                         call_773331.route, valid.getOrDefault("path"))
  result = hook(call_773331, url, valid)

proc call*(call_773332: Call_ListResolvers_773317; apiId: string; typeName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listResolvers
  ## Lists the resolvers for a given API and type.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var path_773333 = newJObject()
  var query_773334 = newJObject()
  add(path_773333, "apiId", newJString(apiId))
  add(path_773333, "typeName", newJString(typeName))
  add(query_773334, "maxResults", newJInt(maxResults))
  add(query_773334, "nextToken", newJString(nextToken))
  result = call_773332.call(path_773333, query_773334, nil, nil, nil)

var listResolvers* = Call_ListResolvers_773317(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_773318, base: "/", url: url_ListResolvers_773319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_773352 = ref object of OpenApiRestCall_772597
proc url_CreateType_773354(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateType_773353(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773355 = path.getOrDefault("apiId")
  valid_773355 = validateParameter(valid_773355, JString, required = true,
                                 default = nil)
  if valid_773355 != nil:
    section.add "apiId", valid_773355
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
  var valid_773356 = header.getOrDefault("X-Amz-Date")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Date", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Security-Token")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Security-Token", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_CreateType_773352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_CreateType_773352; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_773366 = newJObject()
  var body_773367 = newJObject()
  add(path_773366, "apiId", newJString(apiId))
  if body != nil:
    body_773367 = body
  result = call_773365.call(path_773366, nil, nil, nil, body_773367)

var createType* = Call_CreateType_773352(name: "createType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types",
                                      validator: validate_CreateType_773353,
                                      base: "/", url: url_CreateType_773354,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_773368 = ref object of OpenApiRestCall_772597
proc url_UpdateApiKey_773370(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateApiKey_773369(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The ID for the GraphQL API.
  ##   id: JString (required)
  ##     : The API key ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773371 = path.getOrDefault("apiId")
  valid_773371 = validateParameter(valid_773371, JString, required = true,
                                 default = nil)
  if valid_773371 != nil:
    section.add "apiId", valid_773371
  var valid_773372 = path.getOrDefault("id")
  valid_773372 = validateParameter(valid_773372, JString, required = true,
                                 default = nil)
  if valid_773372 != nil:
    section.add "id", valid_773372
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
  var valid_773373 = header.getOrDefault("X-Amz-Date")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Date", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Security-Token")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Security-Token", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Content-Sha256", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Algorithm")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Algorithm", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Signature")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Signature", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-SignedHeaders", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Credential")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Credential", valid_773379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773381: Call_UpdateApiKey_773368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_773381.validator(path, query, header, formData, body)
  let scheme = call_773381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773381.url(scheme.get, call_773381.host, call_773381.base,
                         call_773381.route, valid.getOrDefault("path"))
  result = hook(call_773381, url, valid)

proc call*(call_773382: Call_UpdateApiKey_773368; apiId: string; id: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   id: string (required)
  ##     : The API key ID.
  ##   body: JObject (required)
  var path_773383 = newJObject()
  var body_773384 = newJObject()
  add(path_773383, "apiId", newJString(apiId))
  add(path_773383, "id", newJString(id))
  if body != nil:
    body_773384 = body
  result = call_773382.call(path_773383, nil, nil, nil, body_773384)

var updateApiKey* = Call_UpdateApiKey_773368(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_773369,
    base: "/", url: url_UpdateApiKey_773370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_773385 = ref object of OpenApiRestCall_772597
proc url_DeleteApiKey_773387(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteApiKey_773386(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   id: JString (required)
  ##     : The ID for the API key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773388 = path.getOrDefault("apiId")
  valid_773388 = validateParameter(valid_773388, JString, required = true,
                                 default = nil)
  if valid_773388 != nil:
    section.add "apiId", valid_773388
  var valid_773389 = path.getOrDefault("id")
  valid_773389 = validateParameter(valid_773389, JString, required = true,
                                 default = nil)
  if valid_773389 != nil:
    section.add "id", valid_773389
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
  var valid_773390 = header.getOrDefault("X-Amz-Date")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Date", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Security-Token")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Security-Token", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Content-Sha256", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Algorithm")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Algorithm", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Signature")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Signature", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-SignedHeaders", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Credential")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Credential", valid_773396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773397: Call_DeleteApiKey_773385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_773397.validator(path, query, header, formData, body)
  let scheme = call_773397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773397.url(scheme.get, call_773397.host, call_773397.base,
                         call_773397.route, valid.getOrDefault("path"))
  result = hook(call_773397, url, valid)

proc call*(call_773398: Call_DeleteApiKey_773385; apiId: string; id: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   id: string (required)
  ##     : The ID for the API key.
  var path_773399 = newJObject()
  add(path_773399, "apiId", newJString(apiId))
  add(path_773399, "id", newJString(id))
  result = call_773398.call(path_773399, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_773385(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_773386,
    base: "/", url: url_DeleteApiKey_773387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_773415 = ref object of OpenApiRestCall_772597
proc url_UpdateDataSource_773417(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDataSource_773416(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   name: JString (required)
  ##       : The new name for the data source.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773418 = path.getOrDefault("apiId")
  valid_773418 = validateParameter(valid_773418, JString, required = true,
                                 default = nil)
  if valid_773418 != nil:
    section.add "apiId", valid_773418
  var valid_773419 = path.getOrDefault("name")
  valid_773419 = validateParameter(valid_773419, JString, required = true,
                                 default = nil)
  if valid_773419 != nil:
    section.add "name", valid_773419
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
  var valid_773420 = header.getOrDefault("X-Amz-Date")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Date", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-Security-Token")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Security-Token", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Content-Sha256", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Algorithm")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Algorithm", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Signature")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Signature", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-SignedHeaders", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Credential")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Credential", valid_773426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773428: Call_UpdateDataSource_773415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_773428.validator(path, query, header, formData, body)
  let scheme = call_773428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773428.url(scheme.get, call_773428.host, call_773428.base,
                         call_773428.route, valid.getOrDefault("path"))
  result = hook(call_773428, url, valid)

proc call*(call_773429: Call_UpdateDataSource_773415; apiId: string; name: string;
          body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_773430 = newJObject()
  var body_773431 = newJObject()
  add(path_773430, "apiId", newJString(apiId))
  add(path_773430, "name", newJString(name))
  if body != nil:
    body_773431 = body
  result = call_773429.call(path_773430, nil, nil, nil, body_773431)

var updateDataSource* = Call_UpdateDataSource_773415(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_773416, base: "/",
    url: url_UpdateDataSource_773417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_773400 = ref object of OpenApiRestCall_772597
proc url_GetDataSource_773402(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDataSource_773401(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   name: JString (required)
  ##       : The name of the data source.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773403 = path.getOrDefault("apiId")
  valid_773403 = validateParameter(valid_773403, JString, required = true,
                                 default = nil)
  if valid_773403 != nil:
    section.add "apiId", valid_773403
  var valid_773404 = path.getOrDefault("name")
  valid_773404 = validateParameter(valid_773404, JString, required = true,
                                 default = nil)
  if valid_773404 != nil:
    section.add "name", valid_773404
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
  var valid_773405 = header.getOrDefault("X-Amz-Date")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Date", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Security-Token")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Security-Token", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Content-Sha256", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Algorithm")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Algorithm", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Signature")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Signature", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-SignedHeaders", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Credential")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Credential", valid_773411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773412: Call_GetDataSource_773400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_773412.validator(path, query, header, formData, body)
  let scheme = call_773412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773412.url(scheme.get, call_773412.host, call_773412.base,
                         call_773412.route, valid.getOrDefault("path"))
  result = hook(call_773412, url, valid)

proc call*(call_773413: Call_GetDataSource_773400; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_773414 = newJObject()
  add(path_773414, "apiId", newJString(apiId))
  add(path_773414, "name", newJString(name))
  result = call_773413.call(path_773414, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_773400(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_773401, base: "/", url: url_GetDataSource_773402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_773432 = ref object of OpenApiRestCall_772597
proc url_DeleteDataSource_773434(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDataSource_773433(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   name: JString (required)
  ##       : The name of the data source.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773435 = path.getOrDefault("apiId")
  valid_773435 = validateParameter(valid_773435, JString, required = true,
                                 default = nil)
  if valid_773435 != nil:
    section.add "apiId", valid_773435
  var valid_773436 = path.getOrDefault("name")
  valid_773436 = validateParameter(valid_773436, JString, required = true,
                                 default = nil)
  if valid_773436 != nil:
    section.add "name", valid_773436
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
  var valid_773437 = header.getOrDefault("X-Amz-Date")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Date", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Security-Token")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Security-Token", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Content-Sha256", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Algorithm")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Algorithm", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Signature")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Signature", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-SignedHeaders", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Credential")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Credential", valid_773443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773444: Call_DeleteDataSource_773432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_773444.validator(path, query, header, formData, body)
  let scheme = call_773444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773444.url(scheme.get, call_773444.host, call_773444.base,
                         call_773444.route, valid.getOrDefault("path"))
  result = hook(call_773444, url, valid)

proc call*(call_773445: Call_DeleteDataSource_773432; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_773446 = newJObject()
  add(path_773446, "apiId", newJString(apiId))
  add(path_773446, "name", newJString(name))
  result = call_773445.call(path_773446, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_773432(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_773433, base: "/",
    url: url_DeleteDataSource_773434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_773462 = ref object of OpenApiRestCall_772597
proc url_UpdateFunction_773464(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFunction_773463(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a <code>Function</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  ##   functionId: JString (required)
  ##             : The function ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773465 = path.getOrDefault("apiId")
  valid_773465 = validateParameter(valid_773465, JString, required = true,
                                 default = nil)
  if valid_773465 != nil:
    section.add "apiId", valid_773465
  var valid_773466 = path.getOrDefault("functionId")
  valid_773466 = validateParameter(valid_773466, JString, required = true,
                                 default = nil)
  if valid_773466 != nil:
    section.add "functionId", valid_773466
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
  var valid_773467 = header.getOrDefault("X-Amz-Date")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Date", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Security-Token")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Security-Token", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Content-Sha256", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Algorithm")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Algorithm", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Signature")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Signature", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-SignedHeaders", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Credential")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Credential", valid_773473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773475: Call_UpdateFunction_773462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_773475.validator(path, query, header, formData, body)
  let scheme = call_773475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773475.url(scheme.get, call_773475.host, call_773475.base,
                         call_773475.route, valid.getOrDefault("path"))
  result = hook(call_773475, url, valid)

proc call*(call_773476: Call_UpdateFunction_773462; apiId: string;
          functionId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   body: JObject (required)
  var path_773477 = newJObject()
  var body_773478 = newJObject()
  add(path_773477, "apiId", newJString(apiId))
  add(path_773477, "functionId", newJString(functionId))
  if body != nil:
    body_773478 = body
  result = call_773476.call(path_773477, nil, nil, nil, body_773478)

var updateFunction* = Call_UpdateFunction_773462(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_773463, base: "/", url: url_UpdateFunction_773464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_773447 = ref object of OpenApiRestCall_772597
proc url_GetFunction_773449(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFunction_773448(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Get a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773450 = path.getOrDefault("apiId")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = nil)
  if valid_773450 != nil:
    section.add "apiId", valid_773450
  var valid_773451 = path.getOrDefault("functionId")
  valid_773451 = validateParameter(valid_773451, JString, required = true,
                                 default = nil)
  if valid_773451 != nil:
    section.add "functionId", valid_773451
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
  var valid_773452 = header.getOrDefault("X-Amz-Date")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Date", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Security-Token")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Security-Token", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Content-Sha256", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Algorithm")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Algorithm", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Signature")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Signature", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-SignedHeaders", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Credential")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Credential", valid_773458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773459: Call_GetFunction_773447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_773459.validator(path, query, header, formData, body)
  let scheme = call_773459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773459.url(scheme.get, call_773459.host, call_773459.base,
                         call_773459.route, valid.getOrDefault("path"))
  result = hook(call_773459, url, valid)

proc call*(call_773460: Call_GetFunction_773447; apiId: string; functionId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_773461 = newJObject()
  add(path_773461, "apiId", newJString(apiId))
  add(path_773461, "functionId", newJString(functionId))
  result = call_773460.call(path_773461, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_773447(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/functions/{functionId}",
                                        validator: validate_GetFunction_773448,
                                        base: "/", url: url_GetFunction_773449,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_773479 = ref object of OpenApiRestCall_772597
proc url_DeleteFunction_773481(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFunction_773480(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773482 = path.getOrDefault("apiId")
  valid_773482 = validateParameter(valid_773482, JString, required = true,
                                 default = nil)
  if valid_773482 != nil:
    section.add "apiId", valid_773482
  var valid_773483 = path.getOrDefault("functionId")
  valid_773483 = validateParameter(valid_773483, JString, required = true,
                                 default = nil)
  if valid_773483 != nil:
    section.add "functionId", valid_773483
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
  var valid_773484 = header.getOrDefault("X-Amz-Date")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Date", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Security-Token")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Security-Token", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Content-Sha256", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Algorithm")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Algorithm", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Signature")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Signature", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-SignedHeaders", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Credential")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Credential", valid_773490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773491: Call_DeleteFunction_773479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_773491.validator(path, query, header, formData, body)
  let scheme = call_773491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773491.url(scheme.get, call_773491.host, call_773491.base,
                         call_773491.route, valid.getOrDefault("path"))
  result = hook(call_773491, url, valid)

proc call*(call_773492: Call_DeleteFunction_773479; apiId: string; functionId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_773493 = newJObject()
  add(path_773493, "apiId", newJString(apiId))
  add(path_773493, "functionId", newJString(functionId))
  result = call_773492.call(path_773493, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_773479(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_773480, base: "/", url: url_DeleteFunction_773481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_773508 = ref object of OpenApiRestCall_772597
proc url_UpdateGraphqlApi_773510(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateGraphqlApi_773509(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773511 = path.getOrDefault("apiId")
  valid_773511 = validateParameter(valid_773511, JString, required = true,
                                 default = nil)
  if valid_773511 != nil:
    section.add "apiId", valid_773511
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
  var valid_773512 = header.getOrDefault("X-Amz-Date")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Date", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Security-Token")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Security-Token", valid_773513
  var valid_773514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Content-Sha256", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Algorithm")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Algorithm", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Signature")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Signature", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-SignedHeaders", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Credential")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Credential", valid_773518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773520: Call_UpdateGraphqlApi_773508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_773520.validator(path, query, header, formData, body)
  let scheme = call_773520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773520.url(scheme.get, call_773520.host, call_773520.base,
                         call_773520.route, valid.getOrDefault("path"))
  result = hook(call_773520, url, valid)

proc call*(call_773521: Call_UpdateGraphqlApi_773508; apiId: string; body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_773522 = newJObject()
  var body_773523 = newJObject()
  add(path_773522, "apiId", newJString(apiId))
  if body != nil:
    body_773523 = body
  result = call_773521.call(path_773522, nil, nil, nil, body_773523)

var updateGraphqlApi* = Call_UpdateGraphqlApi_773508(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_773509,
    base: "/", url: url_UpdateGraphqlApi_773510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_773494 = ref object of OpenApiRestCall_772597
proc url_GetGraphqlApi_773496(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetGraphqlApi_773495(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID for the GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773497 = path.getOrDefault("apiId")
  valid_773497 = validateParameter(valid_773497, JString, required = true,
                                 default = nil)
  if valid_773497 != nil:
    section.add "apiId", valid_773497
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
  var valid_773498 = header.getOrDefault("X-Amz-Date")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Date", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Security-Token")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Security-Token", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Content-Sha256", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Algorithm")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Algorithm", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Signature")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Signature", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-SignedHeaders", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Credential")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Credential", valid_773504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773505: Call_GetGraphqlApi_773494; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_773505.validator(path, query, header, formData, body)
  let scheme = call_773505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773505.url(scheme.get, call_773505.host, call_773505.base,
                         call_773505.route, valid.getOrDefault("path"))
  result = hook(call_773505, url, valid)

proc call*(call_773506: Call_GetGraphqlApi_773494; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_773507 = newJObject()
  add(path_773507, "apiId", newJString(apiId))
  result = call_773506.call(path_773507, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_773494(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_773495, base: "/",
    url: url_GetGraphqlApi_773496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_773524 = ref object of OpenApiRestCall_772597
proc url_DeleteGraphqlApi_773526(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteGraphqlApi_773525(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773527 = path.getOrDefault("apiId")
  valid_773527 = validateParameter(valid_773527, JString, required = true,
                                 default = nil)
  if valid_773527 != nil:
    section.add "apiId", valid_773527
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
  var valid_773528 = header.getOrDefault("X-Amz-Date")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Date", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Security-Token")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Security-Token", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Content-Sha256", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Algorithm")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Algorithm", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Signature")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Signature", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-SignedHeaders", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Credential")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Credential", valid_773534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773535: Call_DeleteGraphqlApi_773524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_773535.validator(path, query, header, formData, body)
  let scheme = call_773535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773535.url(scheme.get, call_773535.host, call_773535.base,
                         call_773535.route, valid.getOrDefault("path"))
  result = hook(call_773535, url, valid)

proc call*(call_773536: Call_DeleteGraphqlApi_773524; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_773537 = newJObject()
  add(path_773537, "apiId", newJString(apiId))
  result = call_773536.call(path_773537, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_773524(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_773525,
    base: "/", url: url_DeleteGraphqlApi_773526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_773554 = ref object of OpenApiRestCall_772597
proc url_UpdateResolver_773556(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  assert "fieldName" in path, "`fieldName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers/"),
               (kind: VariableSegment, value: "fieldName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateResolver_773555(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   fieldName: JString (required)
  ##            : The new field name.
  ##   typeName: JString (required)
  ##           : The new type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773557 = path.getOrDefault("apiId")
  valid_773557 = validateParameter(valid_773557, JString, required = true,
                                 default = nil)
  if valid_773557 != nil:
    section.add "apiId", valid_773557
  var valid_773558 = path.getOrDefault("fieldName")
  valid_773558 = validateParameter(valid_773558, JString, required = true,
                                 default = nil)
  if valid_773558 != nil:
    section.add "fieldName", valid_773558
  var valid_773559 = path.getOrDefault("typeName")
  valid_773559 = validateParameter(valid_773559, JString, required = true,
                                 default = nil)
  if valid_773559 != nil:
    section.add "typeName", valid_773559
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
  var valid_773560 = header.getOrDefault("X-Amz-Date")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Date", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Security-Token")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Security-Token", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Content-Sha256", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Algorithm")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Algorithm", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Signature")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Signature", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-SignedHeaders", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Credential")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Credential", valid_773566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773568: Call_UpdateResolver_773554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_773568.validator(path, query, header, formData, body)
  let scheme = call_773568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773568.url(scheme.get, call_773568.host, call_773568.base,
                         call_773568.route, valid.getOrDefault("path"))
  result = hook(call_773568, url, valid)

proc call*(call_773569: Call_UpdateResolver_773554; apiId: string; fieldName: string;
          typeName: string; body: JsonNode): Recallable =
  ## updateResolver
  ## Updates a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The new field name.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_773570 = newJObject()
  var body_773571 = newJObject()
  add(path_773570, "apiId", newJString(apiId))
  add(path_773570, "fieldName", newJString(fieldName))
  add(path_773570, "typeName", newJString(typeName))
  if body != nil:
    body_773571 = body
  result = call_773569.call(path_773570, nil, nil, nil, body_773571)

var updateResolver* = Call_UpdateResolver_773554(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_773555, base: "/", url: url_UpdateResolver_773556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_773538 = ref object of OpenApiRestCall_772597
proc url_GetResolver_773540(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  assert "fieldName" in path, "`fieldName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers/"),
               (kind: VariableSegment, value: "fieldName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetResolver_773539(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  ##   typeName: JString (required)
  ##           : The resolver type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773541 = path.getOrDefault("apiId")
  valid_773541 = validateParameter(valid_773541, JString, required = true,
                                 default = nil)
  if valid_773541 != nil:
    section.add "apiId", valid_773541
  var valid_773542 = path.getOrDefault("fieldName")
  valid_773542 = validateParameter(valid_773542, JString, required = true,
                                 default = nil)
  if valid_773542 != nil:
    section.add "fieldName", valid_773542
  var valid_773543 = path.getOrDefault("typeName")
  valid_773543 = validateParameter(valid_773543, JString, required = true,
                                 default = nil)
  if valid_773543 != nil:
    section.add "typeName", valid_773543
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
  var valid_773544 = header.getOrDefault("X-Amz-Date")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Date", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Security-Token")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Security-Token", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Content-Sha256", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Algorithm")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Algorithm", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Signature")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Signature", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-SignedHeaders", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Credential")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Credential", valid_773550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773551: Call_GetResolver_773538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_773551.validator(path, query, header, formData, body)
  let scheme = call_773551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773551.url(scheme.get, call_773551.host, call_773551.base,
                         call_773551.route, valid.getOrDefault("path"))
  result = hook(call_773551, url, valid)

proc call*(call_773552: Call_GetResolver_773538; apiId: string; fieldName: string;
          typeName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The resolver type name.
  var path_773553 = newJObject()
  add(path_773553, "apiId", newJString(apiId))
  add(path_773553, "fieldName", newJString(fieldName))
  add(path_773553, "typeName", newJString(typeName))
  result = call_773552.call(path_773553, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_773538(name: "getResolver",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
                                        validator: validate_GetResolver_773539,
                                        base: "/", url: url_GetResolver_773540,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_773572 = ref object of OpenApiRestCall_772597
proc url_DeleteResolver_773574(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  assert "fieldName" in path, "`fieldName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers/"),
               (kind: VariableSegment, value: "fieldName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteResolver_773573(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  ##   typeName: JString (required)
  ##           : The name of the resolver type.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773575 = path.getOrDefault("apiId")
  valid_773575 = validateParameter(valid_773575, JString, required = true,
                                 default = nil)
  if valid_773575 != nil:
    section.add "apiId", valid_773575
  var valid_773576 = path.getOrDefault("fieldName")
  valid_773576 = validateParameter(valid_773576, JString, required = true,
                                 default = nil)
  if valid_773576 != nil:
    section.add "fieldName", valid_773576
  var valid_773577 = path.getOrDefault("typeName")
  valid_773577 = validateParameter(valid_773577, JString, required = true,
                                 default = nil)
  if valid_773577 != nil:
    section.add "typeName", valid_773577
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
  var valid_773578 = header.getOrDefault("X-Amz-Date")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Date", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Security-Token")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Security-Token", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Content-Sha256", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Algorithm")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Algorithm", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Signature")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Signature", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-SignedHeaders", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Credential")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Credential", valid_773584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773585: Call_DeleteResolver_773572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_773585.validator(path, query, header, formData, body)
  let scheme = call_773585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773585.url(scheme.get, call_773585.host, call_773585.base,
                         call_773585.route, valid.getOrDefault("path"))
  result = hook(call_773585, url, valid)

proc call*(call_773586: Call_DeleteResolver_773572; apiId: string; fieldName: string;
          typeName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  var path_773587 = newJObject()
  add(path_773587, "apiId", newJString(apiId))
  add(path_773587, "fieldName", newJString(fieldName))
  add(path_773587, "typeName", newJString(typeName))
  result = call_773586.call(path_773587, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_773572(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_773573, base: "/", url: url_DeleteResolver_773574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_773588 = ref object of OpenApiRestCall_772597
proc url_UpdateType_773590(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateType_773589(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The new type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773591 = path.getOrDefault("apiId")
  valid_773591 = validateParameter(valid_773591, JString, required = true,
                                 default = nil)
  if valid_773591 != nil:
    section.add "apiId", valid_773591
  var valid_773592 = path.getOrDefault("typeName")
  valid_773592 = validateParameter(valid_773592, JString, required = true,
                                 default = nil)
  if valid_773592 != nil:
    section.add "typeName", valid_773592
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
  var valid_773593 = header.getOrDefault("X-Amz-Date")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Date", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Security-Token")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Security-Token", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Content-Sha256", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Algorithm")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Algorithm", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Signature")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Signature", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-SignedHeaders", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Credential")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Credential", valid_773599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773601: Call_UpdateType_773588; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_773601.validator(path, query, header, formData, body)
  let scheme = call_773601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773601.url(scheme.get, call_773601.host, call_773601.base,
                         call_773601.route, valid.getOrDefault("path"))
  result = hook(call_773601, url, valid)

proc call*(call_773602: Call_UpdateType_773588; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_773603 = newJObject()
  var body_773604 = newJObject()
  add(path_773603, "apiId", newJString(apiId))
  add(path_773603, "typeName", newJString(typeName))
  if body != nil:
    body_773604 = body
  result = call_773602.call(path_773603, nil, nil, nil, body_773604)

var updateType* = Call_UpdateType_773588(name: "updateType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_UpdateType_773589,
                                      base: "/", url: url_UpdateType_773590,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_773605 = ref object of OpenApiRestCall_772597
proc url_DeleteType_773607(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteType_773606(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773608 = path.getOrDefault("apiId")
  valid_773608 = validateParameter(valid_773608, JString, required = true,
                                 default = nil)
  if valid_773608 != nil:
    section.add "apiId", valid_773608
  var valid_773609 = path.getOrDefault("typeName")
  valid_773609 = validateParameter(valid_773609, JString, required = true,
                                 default = nil)
  if valid_773609 != nil:
    section.add "typeName", valid_773609
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
  var valid_773610 = header.getOrDefault("X-Amz-Date")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Date", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Security-Token")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Security-Token", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Content-Sha256", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Algorithm")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Algorithm", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Signature")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Signature", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-SignedHeaders", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Credential")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Credential", valid_773616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773617: Call_DeleteType_773605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_773617.validator(path, query, header, formData, body)
  let scheme = call_773617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773617.url(scheme.get, call_773617.host, call_773617.base,
                         call_773617.route, valid.getOrDefault("path"))
  result = hook(call_773617, url, valid)

proc call*(call_773618: Call_DeleteType_773605; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_773619 = newJObject()
  add(path_773619, "apiId", newJString(apiId))
  add(path_773619, "typeName", newJString(typeName))
  result = call_773618.call(path_773619, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_773605(name: "deleteType",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_DeleteType_773606,
                                      base: "/", url: url_DeleteType_773607,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_773620 = ref object of OpenApiRestCall_772597
proc url_GetIntrospectionSchema_773622(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schema#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIntrospectionSchema_773621(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773623 = path.getOrDefault("apiId")
  valid_773623 = validateParameter(valid_773623, JString, required = true,
                                 default = nil)
  if valid_773623 != nil:
    section.add "apiId", valid_773623
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_773624 = query.getOrDefault("includeDirectives")
  valid_773624 = validateParameter(valid_773624, JBool, required = false, default = nil)
  if valid_773624 != nil:
    section.add "includeDirectives", valid_773624
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_773638 = query.getOrDefault("format")
  valid_773638 = validateParameter(valid_773638, JString, required = true,
                                 default = newJString("SDL"))
  if valid_773638 != nil:
    section.add "format", valid_773638
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
  var valid_773639 = header.getOrDefault("X-Amz-Date")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Date", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Security-Token")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Security-Token", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Content-Sha256", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-Algorithm")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Algorithm", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Signature")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Signature", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-SignedHeaders", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Credential")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Credential", valid_773645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773646: Call_GetIntrospectionSchema_773620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_773646.validator(path, query, header, formData, body)
  let scheme = call_773646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773646.url(scheme.get, call_773646.host, call_773646.base,
                         call_773646.route, valid.getOrDefault("path"))
  result = hook(call_773646, url, valid)

proc call*(call_773647: Call_GetIntrospectionSchema_773620; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_773648 = newJObject()
  var query_773649 = newJObject()
  add(query_773649, "includeDirectives", newJBool(includeDirectives))
  add(path_773648, "apiId", newJString(apiId))
  add(query_773649, "format", newJString(format))
  result = call_773647.call(path_773648, query_773649, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_773620(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_773621, base: "/",
    url: url_GetIntrospectionSchema_773622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_773664 = ref object of OpenApiRestCall_772597
proc url_StartSchemaCreation_773666(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schemacreation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StartSchemaCreation_773665(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773667 = path.getOrDefault("apiId")
  valid_773667 = validateParameter(valid_773667, JString, required = true,
                                 default = nil)
  if valid_773667 != nil:
    section.add "apiId", valid_773667
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
  var valid_773668 = header.getOrDefault("X-Amz-Date")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Date", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Security-Token")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Security-Token", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Content-Sha256", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Algorithm")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Algorithm", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Signature")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Signature", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-SignedHeaders", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Credential")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Credential", valid_773674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773676: Call_StartSchemaCreation_773664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_773676.validator(path, query, header, formData, body)
  let scheme = call_773676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773676.url(scheme.get, call_773676.host, call_773676.base,
                         call_773676.route, valid.getOrDefault("path"))
  result = hook(call_773676, url, valid)

proc call*(call_773677: Call_StartSchemaCreation_773664; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_773678 = newJObject()
  var body_773679 = newJObject()
  add(path_773678, "apiId", newJString(apiId))
  if body != nil:
    body_773679 = body
  result = call_773677.call(path_773678, nil, nil, nil, body_773679)

var startSchemaCreation* = Call_StartSchemaCreation_773664(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_773665, base: "/",
    url: url_StartSchemaCreation_773666, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_773650 = ref object of OpenApiRestCall_772597
proc url_GetSchemaCreationStatus_773652(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schemacreation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetSchemaCreationStatus_773651(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current status of a schema creation operation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773653 = path.getOrDefault("apiId")
  valid_773653 = validateParameter(valid_773653, JString, required = true,
                                 default = nil)
  if valid_773653 != nil:
    section.add "apiId", valid_773653
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
  var valid_773654 = header.getOrDefault("X-Amz-Date")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Date", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-Security-Token")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Security-Token", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Content-Sha256", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-Algorithm")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Algorithm", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Signature")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Signature", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-SignedHeaders", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Credential")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Credential", valid_773660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773661: Call_GetSchemaCreationStatus_773650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_773661.validator(path, query, header, formData, body)
  let scheme = call_773661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773661.url(scheme.get, call_773661.host, call_773661.base,
                         call_773661.route, valid.getOrDefault("path"))
  result = hook(call_773661, url, valid)

proc call*(call_773662: Call_GetSchemaCreationStatus_773650; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_773663 = newJObject()
  add(path_773663, "apiId", newJString(apiId))
  result = call_773662.call(path_773663, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_773650(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_773651, base: "/",
    url: url_GetSchemaCreationStatus_773652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_773680 = ref object of OpenApiRestCall_772597
proc url_GetType_773682(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetType_773681(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773683 = path.getOrDefault("apiId")
  valid_773683 = validateParameter(valid_773683, JString, required = true,
                                 default = nil)
  if valid_773683 != nil:
    section.add "apiId", valid_773683
  var valid_773684 = path.getOrDefault("typeName")
  valid_773684 = validateParameter(valid_773684, JString, required = true,
                                 default = nil)
  if valid_773684 != nil:
    section.add "typeName", valid_773684
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_773685 = query.getOrDefault("format")
  valid_773685 = validateParameter(valid_773685, JString, required = true,
                                 default = newJString("SDL"))
  if valid_773685 != nil:
    section.add "format", valid_773685
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
  var valid_773686 = header.getOrDefault("X-Amz-Date")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Date", valid_773686
  var valid_773687 = header.getOrDefault("X-Amz-Security-Token")
  valid_773687 = validateParameter(valid_773687, JString, required = false,
                                 default = nil)
  if valid_773687 != nil:
    section.add "X-Amz-Security-Token", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Content-Sha256", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Algorithm")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Algorithm", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Signature")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Signature", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-SignedHeaders", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Credential")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Credential", valid_773692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773693: Call_GetType_773680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_773693.validator(path, query, header, formData, body)
  let scheme = call_773693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773693.url(scheme.get, call_773693.host, call_773693.base,
                         call_773693.route, valid.getOrDefault("path"))
  result = hook(call_773693, url, valid)

proc call*(call_773694: Call_GetType_773680; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_773695 = newJObject()
  var query_773696 = newJObject()
  add(path_773695, "apiId", newJString(apiId))
  add(path_773695, "typeName", newJString(typeName))
  add(query_773696, "format", newJString(format))
  result = call_773694.call(path_773695, query_773696, nil, nil, nil)

var getType* = Call_GetType_773680(name: "getType", meth: HttpMethod.HttpGet,
                                host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                validator: validate_GetType_773681, base: "/",
                                url: url_GetType_773682,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_773697 = ref object of OpenApiRestCall_772597
proc url_ListResolversByFunction_773699(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId"),
               (kind: ConstantSegment, value: "/resolvers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListResolversByFunction_773698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the resolvers that are associated with a specific function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   functionId: JString (required)
  ##             : The Function ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773700 = path.getOrDefault("apiId")
  valid_773700 = validateParameter(valid_773700, JString, required = true,
                                 default = nil)
  if valid_773700 != nil:
    section.add "apiId", valid_773700
  var valid_773701 = path.getOrDefault("functionId")
  valid_773701 = validateParameter(valid_773701, JString, required = true,
                                 default = nil)
  if valid_773701 != nil:
    section.add "functionId", valid_773701
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  section = newJObject()
  var valid_773702 = query.getOrDefault("maxResults")
  valid_773702 = validateParameter(valid_773702, JInt, required = false, default = nil)
  if valid_773702 != nil:
    section.add "maxResults", valid_773702
  var valid_773703 = query.getOrDefault("nextToken")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "nextToken", valid_773703
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
  var valid_773704 = header.getOrDefault("X-Amz-Date")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Date", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Security-Token")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Security-Token", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Content-Sha256", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Algorithm")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Algorithm", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Signature")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Signature", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-SignedHeaders", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Credential")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Credential", valid_773710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773711: Call_ListResolversByFunction_773697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_773711.validator(path, query, header, formData, body)
  let scheme = call_773711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773711.url(scheme.get, call_773711.host, call_773711.base,
                         call_773711.route, valid.getOrDefault("path"))
  result = hook(call_773711, url, valid)

proc call*(call_773712: Call_ListResolversByFunction_773697; apiId: string;
          functionId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listResolversByFunction
  ## List the resolvers that are associated with a specific function.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   functionId: string (required)
  ##             : The Function ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  var path_773713 = newJObject()
  var query_773714 = newJObject()
  add(path_773713, "apiId", newJString(apiId))
  add(path_773713, "functionId", newJString(functionId))
  add(query_773714, "maxResults", newJInt(maxResults))
  add(query_773714, "nextToken", newJString(nextToken))
  result = call_773712.call(path_773713, query_773714, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_773697(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_773698, base: "/",
    url: url_ListResolversByFunction_773699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773729 = ref object of OpenApiRestCall_772597
proc url_TagResource_773731(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_773730(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Tags a resource with user-supplied tags.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The <code>GraphqlApi</code> ARN.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_773732 = path.getOrDefault("resourceArn")
  valid_773732 = validateParameter(valid_773732, JString, required = true,
                                 default = nil)
  if valid_773732 != nil:
    section.add "resourceArn", valid_773732
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
  var valid_773733 = header.getOrDefault("X-Amz-Date")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Date", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Security-Token")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Security-Token", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Content-Sha256", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-Algorithm")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Algorithm", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Signature")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Signature", valid_773737
  var valid_773738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-SignedHeaders", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Credential")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Credential", valid_773739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773741: Call_TagResource_773729; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_773741.validator(path, query, header, formData, body)
  let scheme = call_773741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773741.url(scheme.get, call_773741.host, call_773741.base,
                         call_773741.route, valid.getOrDefault("path"))
  result = hook(call_773741, url, valid)

proc call*(call_773742: Call_TagResource_773729; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_773743 = newJObject()
  var body_773744 = newJObject()
  if body != nil:
    body_773744 = body
  add(path_773743, "resourceArn", newJString(resourceArn))
  result = call_773742.call(path_773743, nil, nil, nil, body_773744)

var tagResource* = Call_TagResource_773729(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_773730,
                                        base: "/", url: url_TagResource_773731,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773715 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773717(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_773716(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The <code>GraphqlApi</code> ARN.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_773718 = path.getOrDefault("resourceArn")
  valid_773718 = validateParameter(valid_773718, JString, required = true,
                                 default = nil)
  if valid_773718 != nil:
    section.add "resourceArn", valid_773718
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
  var valid_773719 = header.getOrDefault("X-Amz-Date")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Date", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Security-Token")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Security-Token", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-Content-Sha256", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Algorithm")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Algorithm", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Signature")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Signature", valid_773723
  var valid_773724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-SignedHeaders", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Credential")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Credential", valid_773725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773726: Call_ListTagsForResource_773715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_773726.validator(path, query, header, formData, body)
  let scheme = call_773726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773726.url(scheme.get, call_773726.host, call_773726.base,
                         call_773726.route, valid.getOrDefault("path"))
  result = hook(call_773726, url, valid)

proc call*(call_773727: Call_ListTagsForResource_773715; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_773728 = newJObject()
  add(path_773728, "resourceArn", newJString(resourceArn))
  result = call_773727.call(path_773728, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773715(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_773716, base: "/",
    url: url_ListTagsForResource_773717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_773745 = ref object of OpenApiRestCall_772597
proc url_ListTypes_773747(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTypes_773746(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the types for a given API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_773748 = path.getOrDefault("apiId")
  valid_773748 = validateParameter(valid_773748, JString, required = true,
                                 default = nil)
  if valid_773748 != nil:
    section.add "apiId", valid_773748
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_773749 = query.getOrDefault("maxResults")
  valid_773749 = validateParameter(valid_773749, JInt, required = false, default = nil)
  if valid_773749 != nil:
    section.add "maxResults", valid_773749
  var valid_773750 = query.getOrDefault("nextToken")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "nextToken", valid_773750
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_773751 = query.getOrDefault("format")
  valid_773751 = validateParameter(valid_773751, JString, required = true,
                                 default = newJString("SDL"))
  if valid_773751 != nil:
    section.add "format", valid_773751
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
  var valid_773752 = header.getOrDefault("X-Amz-Date")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Date", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Security-Token")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Security-Token", valid_773753
  var valid_773754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-Content-Sha256", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Algorithm")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Algorithm", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-Signature")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-Signature", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-SignedHeaders", valid_773757
  var valid_773758 = header.getOrDefault("X-Amz-Credential")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-Credential", valid_773758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773759: Call_ListTypes_773745; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_773759.validator(path, query, header, formData, body)
  let scheme = call_773759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773759.url(scheme.get, call_773759.host, call_773759.base,
                         call_773759.route, valid.getOrDefault("path"))
  result = hook(call_773759, url, valid)

proc call*(call_773760: Call_ListTypes_773745; apiId: string; maxResults: int = 0;
          nextToken: string = ""; format: string = "SDL"): Recallable =
  ## listTypes
  ## Lists the types for a given API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_773761 = newJObject()
  var query_773762 = newJObject()
  add(path_773761, "apiId", newJString(apiId))
  add(query_773762, "maxResults", newJInt(maxResults))
  add(query_773762, "nextToken", newJString(nextToken))
  add(query_773762, "format", newJString(format))
  result = call_773760.call(path_773761, query_773762, nil, nil, nil)

var listTypes* = Call_ListTypes_773745(name: "listTypes", meth: HttpMethod.HttpGet,
                                    host: "appsync.amazonaws.com",
                                    route: "/v1/apis/{apiId}/types#format",
                                    validator: validate_ListTypes_773746,
                                    base: "/", url: url_ListTypes_773747,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773763 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773765(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_773764(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Untags a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The <code>GraphqlApi</code> ARN.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_773766 = path.getOrDefault("resourceArn")
  valid_773766 = validateParameter(valid_773766, JString, required = true,
                                 default = nil)
  if valid_773766 != nil:
    section.add "resourceArn", valid_773766
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_773767 = query.getOrDefault("tagKeys")
  valid_773767 = validateParameter(valid_773767, JArray, required = true, default = nil)
  if valid_773767 != nil:
    section.add "tagKeys", valid_773767
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
  var valid_773768 = header.getOrDefault("X-Amz-Date")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Date", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-Security-Token")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-Security-Token", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Content-Sha256", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Algorithm")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Algorithm", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Signature")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Signature", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-SignedHeaders", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Credential")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Credential", valid_773774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773775: Call_UntagResource_773763; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_773775.validator(path, query, header, formData, body)
  let scheme = call_773775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773775.url(scheme.get, call_773775.host, call_773775.base,
                         call_773775.route, valid.getOrDefault("path"))
  result = hook(call_773775, url, valid)

proc call*(call_773776: Call_UntagResource_773763; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_773777 = newJObject()
  var query_773778 = newJObject()
  if tagKeys != nil:
    query_773778.add "tagKeys", tagKeys
  add(path_773777, "resourceArn", newJString(resourceArn))
  result = call_773776.call(path_773777, query_773778, nil, nil, nil)

var untagResource* = Call_UntagResource_773763(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_773764,
    base: "/", url: url_UntagResource_773765, schemes: {Scheme.Https, Scheme.Http})
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
