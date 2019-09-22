
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

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
  Call_CreateApiKey_603043 = ref object of OpenApiRestCall_602433
proc url_CreateApiKey_603045(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateApiKey_603044(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603046 = path.getOrDefault("apiId")
  valid_603046 = validateParameter(valid_603046, JString, required = true,
                                 default = nil)
  if valid_603046 != nil:
    section.add "apiId", valid_603046
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
  var valid_603047 = header.getOrDefault("X-Amz-Date")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Date", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Security-Token")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Security-Token", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Content-Sha256", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Algorithm")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Algorithm", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Signature")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Signature", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-SignedHeaders", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Credential")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Credential", valid_603053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603055: Call_CreateApiKey_603043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_603055.validator(path, query, header, formData, body)
  let scheme = call_603055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603055.url(scheme.get, call_603055.host, call_603055.base,
                         call_603055.route, valid.getOrDefault("path"))
  result = hook(call_603055, url, valid)

proc call*(call_603056: Call_CreateApiKey_603043; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_603057 = newJObject()
  var body_603058 = newJObject()
  add(path_603057, "apiId", newJString(apiId))
  if body != nil:
    body_603058 = body
  result = call_603056.call(path_603057, nil, nil, nil, body_603058)

var createApiKey* = Call_CreateApiKey_603043(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_603044,
    base: "/", url: url_CreateApiKey_603045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_602770 = ref object of OpenApiRestCall_602433
proc url_ListApiKeys_602772(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListApiKeys_602771(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602898 = path.getOrDefault("apiId")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "apiId", valid_602898
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_602899 = query.getOrDefault("maxResults")
  valid_602899 = validateParameter(valid_602899, JInt, required = false, default = nil)
  if valid_602899 != nil:
    section.add "maxResults", valid_602899
  var valid_602900 = query.getOrDefault("nextToken")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "nextToken", valid_602900
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
  var valid_602901 = header.getOrDefault("X-Amz-Date")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Date", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Security-Token")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Security-Token", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Content-Sha256", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Algorithm")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Algorithm", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Signature")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Signature", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-SignedHeaders", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Credential")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Credential", valid_602907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602930: Call_ListApiKeys_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_602930.validator(path, query, header, formData, body)
  let scheme = call_602930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602930.url(scheme.get, call_602930.host, call_602930.base,
                         call_602930.route, valid.getOrDefault("path"))
  result = hook(call_602930, url, valid)

proc call*(call_603001: Call_ListApiKeys_602770; apiId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_603002 = newJObject()
  var query_603004 = newJObject()
  add(path_603002, "apiId", newJString(apiId))
  add(query_603004, "maxResults", newJInt(maxResults))
  add(query_603004, "nextToken", newJString(nextToken))
  result = call_603001.call(path_603002, query_603004, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_602770(name: "listApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/apikeys",
                                        validator: validate_ListApiKeys_602771,
                                        base: "/", url: url_ListApiKeys_602772,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_603076 = ref object of OpenApiRestCall_602433
proc url_CreateDataSource_603078(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateDataSource_603077(path: JsonNode; query: JsonNode;
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
  var valid_603079 = path.getOrDefault("apiId")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = nil)
  if valid_603079 != nil:
    section.add "apiId", valid_603079
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
  var valid_603080 = header.getOrDefault("X-Amz-Date")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Date", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Security-Token")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Security-Token", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Content-Sha256", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Algorithm")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Algorithm", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Signature")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Signature", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-SignedHeaders", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Credential")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Credential", valid_603086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_CreateDataSource_603076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"))
  result = hook(call_603088, url, valid)

proc call*(call_603089: Call_CreateDataSource_603076; apiId: string; body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_603090 = newJObject()
  var body_603091 = newJObject()
  add(path_603090, "apiId", newJString(apiId))
  if body != nil:
    body_603091 = body
  result = call_603089.call(path_603090, nil, nil, nil, body_603091)

var createDataSource* = Call_CreateDataSource_603076(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_603077,
    base: "/", url: url_CreateDataSource_603078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_603059 = ref object of OpenApiRestCall_602433
proc url_ListDataSources_603061(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListDataSources_603060(path: JsonNode; query: JsonNode;
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
  var valid_603062 = path.getOrDefault("apiId")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = nil)
  if valid_603062 != nil:
    section.add "apiId", valid_603062
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_603063 = query.getOrDefault("maxResults")
  valid_603063 = validateParameter(valid_603063, JInt, required = false, default = nil)
  if valid_603063 != nil:
    section.add "maxResults", valid_603063
  var valid_603064 = query.getOrDefault("nextToken")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "nextToken", valid_603064
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
  var valid_603065 = header.getOrDefault("X-Amz-Date")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Date", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Security-Token")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Security-Token", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Content-Sha256", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Algorithm")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Algorithm", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Signature")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Signature", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-SignedHeaders", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Credential")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Credential", valid_603071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603072: Call_ListDataSources_603059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_603072.validator(path, query, header, formData, body)
  let scheme = call_603072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603072.url(scheme.get, call_603072.host, call_603072.base,
                         call_603072.route, valid.getOrDefault("path"))
  result = hook(call_603072, url, valid)

proc call*(call_603073: Call_ListDataSources_603059; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var path_603074 = newJObject()
  var query_603075 = newJObject()
  add(path_603074, "apiId", newJString(apiId))
  add(query_603075, "maxResults", newJInt(maxResults))
  add(query_603075, "nextToken", newJString(nextToken))
  result = call_603073.call(path_603074, query_603075, nil, nil, nil)

var listDataSources* = Call_ListDataSources_603059(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_603060,
    base: "/", url: url_ListDataSources_603061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_603109 = ref object of OpenApiRestCall_602433
proc url_CreateFunction_603111(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateFunction_603110(path: JsonNode; query: JsonNode;
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
  var valid_603112 = path.getOrDefault("apiId")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = nil)
  if valid_603112 != nil:
    section.add "apiId", valid_603112
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
  var valid_603113 = header.getOrDefault("X-Amz-Date")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Date", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Content-Sha256", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Algorithm")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Algorithm", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Signature")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Signature", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-SignedHeaders", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603121: Call_CreateFunction_603109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_603121.validator(path, query, header, formData, body)
  let scheme = call_603121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603121.url(scheme.get, call_603121.host, call_603121.base,
                         call_603121.route, valid.getOrDefault("path"))
  result = hook(call_603121, url, valid)

proc call*(call_603122: Call_CreateFunction_603109; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_603123 = newJObject()
  var body_603124 = newJObject()
  add(path_603123, "apiId", newJString(apiId))
  if body != nil:
    body_603124 = body
  result = call_603122.call(path_603123, nil, nil, nil, body_603124)

var createFunction* = Call_CreateFunction_603109(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_603110,
    base: "/", url: url_CreateFunction_603111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_603092 = ref object of OpenApiRestCall_602433
proc url_ListFunctions_603094(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListFunctions_603093(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603095 = path.getOrDefault("apiId")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "apiId", valid_603095
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_603096 = query.getOrDefault("maxResults")
  valid_603096 = validateParameter(valid_603096, JInt, required = false, default = nil)
  if valid_603096 != nil:
    section.add "maxResults", valid_603096
  var valid_603097 = query.getOrDefault("nextToken")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "nextToken", valid_603097
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
  var valid_603098 = header.getOrDefault("X-Amz-Date")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Date", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Security-Token")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Security-Token", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Content-Sha256", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Algorithm")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Algorithm", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Signature")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Signature", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-SignedHeaders", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Credential")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Credential", valid_603104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603105: Call_ListFunctions_603092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_603105.validator(path, query, header, formData, body)
  let scheme = call_603105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603105.url(scheme.get, call_603105.host, call_603105.base,
                         call_603105.route, valid.getOrDefault("path"))
  result = hook(call_603105, url, valid)

proc call*(call_603106: Call_ListFunctions_603092; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_603107 = newJObject()
  var query_603108 = newJObject()
  add(path_603107, "apiId", newJString(apiId))
  add(query_603108, "maxResults", newJInt(maxResults))
  add(query_603108, "nextToken", newJString(nextToken))
  result = call_603106.call(path_603107, query_603108, nil, nil, nil)

var listFunctions* = Call_ListFunctions_603092(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_603093,
    base: "/", url: url_ListFunctions_603094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_603140 = ref object of OpenApiRestCall_602433
proc url_CreateGraphqlApi_603142(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateGraphqlApi_603141(path: JsonNode; query: JsonNode;
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
  var valid_603143 = header.getOrDefault("X-Amz-Date")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Date", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Security-Token")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Security-Token", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Content-Sha256", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Algorithm")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Algorithm", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Signature")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Signature", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-SignedHeaders", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Credential")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Credential", valid_603149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603151: Call_CreateGraphqlApi_603140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_603151.validator(path, query, header, formData, body)
  let scheme = call_603151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603151.url(scheme.get, call_603151.host, call_603151.base,
                         call_603151.route, valid.getOrDefault("path"))
  result = hook(call_603151, url, valid)

proc call*(call_603152: Call_CreateGraphqlApi_603140; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_603153 = newJObject()
  if body != nil:
    body_603153 = body
  result = call_603152.call(nil, nil, nil, nil, body_603153)

var createGraphqlApi* = Call_CreateGraphqlApi_603140(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_603141, base: "/",
    url: url_CreateGraphqlApi_603142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_603125 = ref object of OpenApiRestCall_602433
proc url_ListGraphqlApis_603127(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGraphqlApis_603126(path: JsonNode; query: JsonNode;
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
  var valid_603128 = query.getOrDefault("maxResults")
  valid_603128 = validateParameter(valid_603128, JInt, required = false, default = nil)
  if valid_603128 != nil:
    section.add "maxResults", valid_603128
  var valid_603129 = query.getOrDefault("nextToken")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "nextToken", valid_603129
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
  var valid_603130 = header.getOrDefault("X-Amz-Date")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Date", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Security-Token")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Security-Token", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Content-Sha256", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Algorithm")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Algorithm", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Signature")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Signature", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-SignedHeaders", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Credential")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Credential", valid_603136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603137: Call_ListGraphqlApis_603125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_603137.validator(path, query, header, formData, body)
  let scheme = call_603137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603137.url(scheme.get, call_603137.host, call_603137.base,
                         call_603137.route, valid.getOrDefault("path"))
  result = hook(call_603137, url, valid)

proc call*(call_603138: Call_ListGraphqlApis_603125; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var query_603139 = newJObject()
  add(query_603139, "maxResults", newJInt(maxResults))
  add(query_603139, "nextToken", newJString(nextToken))
  result = call_603138.call(nil, query_603139, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_603125(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_603126, base: "/", url: url_ListGraphqlApis_603127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_603172 = ref object of OpenApiRestCall_602433
proc url_CreateResolver_603174(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateResolver_603173(path: JsonNode; query: JsonNode;
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
  var valid_603175 = path.getOrDefault("apiId")
  valid_603175 = validateParameter(valid_603175, JString, required = true,
                                 default = nil)
  if valid_603175 != nil:
    section.add "apiId", valid_603175
  var valid_603176 = path.getOrDefault("typeName")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = nil)
  if valid_603176 != nil:
    section.add "typeName", valid_603176
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
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Content-Sha256", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Algorithm")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Algorithm", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Signature")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Signature", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-SignedHeaders", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Credential")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Credential", valid_603183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603185: Call_CreateResolver_603172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_603185.validator(path, query, header, formData, body)
  let scheme = call_603185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603185.url(scheme.get, call_603185.host, call_603185.base,
                         call_603185.route, valid.getOrDefault("path"))
  result = hook(call_603185, url, valid)

proc call*(call_603186: Call_CreateResolver_603172; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_603187 = newJObject()
  var body_603188 = newJObject()
  add(path_603187, "apiId", newJString(apiId))
  add(path_603187, "typeName", newJString(typeName))
  if body != nil:
    body_603188 = body
  result = call_603186.call(path_603187, nil, nil, nil, body_603188)

var createResolver* = Call_CreateResolver_603172(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_603173, base: "/", url: url_CreateResolver_603174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_603154 = ref object of OpenApiRestCall_602433
proc url_ListResolvers_603156(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListResolvers_603155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603157 = path.getOrDefault("apiId")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = nil)
  if valid_603157 != nil:
    section.add "apiId", valid_603157
  var valid_603158 = path.getOrDefault("typeName")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "typeName", valid_603158
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_603159 = query.getOrDefault("maxResults")
  valid_603159 = validateParameter(valid_603159, JInt, required = false, default = nil)
  if valid_603159 != nil:
    section.add "maxResults", valid_603159
  var valid_603160 = query.getOrDefault("nextToken")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "nextToken", valid_603160
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
  var valid_603161 = header.getOrDefault("X-Amz-Date")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Date", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Security-Token")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Security-Token", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Content-Sha256", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Algorithm")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Algorithm", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Signature")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Signature", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-SignedHeaders", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Credential")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Credential", valid_603167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603168: Call_ListResolvers_603154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_603168.validator(path, query, header, formData, body)
  let scheme = call_603168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603168.url(scheme.get, call_603168.host, call_603168.base,
                         call_603168.route, valid.getOrDefault("path"))
  result = hook(call_603168, url, valid)

proc call*(call_603169: Call_ListResolvers_603154; apiId: string; typeName: string;
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
  var path_603170 = newJObject()
  var query_603171 = newJObject()
  add(path_603170, "apiId", newJString(apiId))
  add(path_603170, "typeName", newJString(typeName))
  add(query_603171, "maxResults", newJInt(maxResults))
  add(query_603171, "nextToken", newJString(nextToken))
  result = call_603169.call(path_603170, query_603171, nil, nil, nil)

var listResolvers* = Call_ListResolvers_603154(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_603155, base: "/", url: url_ListResolvers_603156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_603189 = ref object of OpenApiRestCall_602433
proc url_CreateType_603191(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateType_603190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603192 = path.getOrDefault("apiId")
  valid_603192 = validateParameter(valid_603192, JString, required = true,
                                 default = nil)
  if valid_603192 != nil:
    section.add "apiId", valid_603192
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
  var valid_603193 = header.getOrDefault("X-Amz-Date")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Date", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Security-Token")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Security-Token", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Content-Sha256", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Algorithm", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Credential")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Credential", valid_603199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_CreateType_603189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_CreateType_603189; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_603203 = newJObject()
  var body_603204 = newJObject()
  add(path_603203, "apiId", newJString(apiId))
  if body != nil:
    body_603204 = body
  result = call_603202.call(path_603203, nil, nil, nil, body_603204)

var createType* = Call_CreateType_603189(name: "createType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types",
                                      validator: validate_CreateType_603190,
                                      base: "/", url: url_CreateType_603191,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_603205 = ref object of OpenApiRestCall_602433
proc url_UpdateApiKey_603207(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateApiKey_603206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603208 = path.getOrDefault("apiId")
  valid_603208 = validateParameter(valid_603208, JString, required = true,
                                 default = nil)
  if valid_603208 != nil:
    section.add "apiId", valid_603208
  var valid_603209 = path.getOrDefault("id")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = nil)
  if valid_603209 != nil:
    section.add "id", valid_603209
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Content-Sha256", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Algorithm")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Algorithm", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Signature")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Signature", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-SignedHeaders", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Credential")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Credential", valid_603216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603218: Call_UpdateApiKey_603205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_603218.validator(path, query, header, formData, body)
  let scheme = call_603218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603218.url(scheme.get, call_603218.host, call_603218.base,
                         call_603218.route, valid.getOrDefault("path"))
  result = hook(call_603218, url, valid)

proc call*(call_603219: Call_UpdateApiKey_603205; apiId: string; id: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   id: string (required)
  ##     : The API key ID.
  ##   body: JObject (required)
  var path_603220 = newJObject()
  var body_603221 = newJObject()
  add(path_603220, "apiId", newJString(apiId))
  add(path_603220, "id", newJString(id))
  if body != nil:
    body_603221 = body
  result = call_603219.call(path_603220, nil, nil, nil, body_603221)

var updateApiKey* = Call_UpdateApiKey_603205(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_603206,
    base: "/", url: url_UpdateApiKey_603207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_603222 = ref object of OpenApiRestCall_602433
proc url_DeleteApiKey_603224(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteApiKey_603223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603225 = path.getOrDefault("apiId")
  valid_603225 = validateParameter(valid_603225, JString, required = true,
                                 default = nil)
  if valid_603225 != nil:
    section.add "apiId", valid_603225
  var valid_603226 = path.getOrDefault("id")
  valid_603226 = validateParameter(valid_603226, JString, required = true,
                                 default = nil)
  if valid_603226 != nil:
    section.add "id", valid_603226
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
  var valid_603227 = header.getOrDefault("X-Amz-Date")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Date", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Security-Token")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Security-Token", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Content-Sha256", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Algorithm")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Algorithm", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Signature")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Signature", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-SignedHeaders", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Credential")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Credential", valid_603233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DeleteApiKey_603222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DeleteApiKey_603222; apiId: string; id: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   id: string (required)
  ##     : The ID for the API key.
  var path_603236 = newJObject()
  add(path_603236, "apiId", newJString(apiId))
  add(path_603236, "id", newJString(id))
  result = call_603235.call(path_603236, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_603222(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_603223,
    base: "/", url: url_DeleteApiKey_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_603252 = ref object of OpenApiRestCall_602433
proc url_UpdateDataSource_603254(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateDataSource_603253(path: JsonNode; query: JsonNode;
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
  var valid_603255 = path.getOrDefault("apiId")
  valid_603255 = validateParameter(valid_603255, JString, required = true,
                                 default = nil)
  if valid_603255 != nil:
    section.add "apiId", valid_603255
  var valid_603256 = path.getOrDefault("name")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = nil)
  if valid_603256 != nil:
    section.add "name", valid_603256
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
  var valid_603257 = header.getOrDefault("X-Amz-Date")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Date", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Security-Token")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Security-Token", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Content-Sha256", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Algorithm")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Algorithm", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Signature")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Signature", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-SignedHeaders", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Credential")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Credential", valid_603263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_UpdateDataSource_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_UpdateDataSource_603252; apiId: string; name: string;
          body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_603267 = newJObject()
  var body_603268 = newJObject()
  add(path_603267, "apiId", newJString(apiId))
  add(path_603267, "name", newJString(name))
  if body != nil:
    body_603268 = body
  result = call_603266.call(path_603267, nil, nil, nil, body_603268)

var updateDataSource* = Call_UpdateDataSource_603252(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_603253, base: "/",
    url: url_UpdateDataSource_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_603237 = ref object of OpenApiRestCall_602433
proc url_GetDataSource_603239(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetDataSource_603238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603240 = path.getOrDefault("apiId")
  valid_603240 = validateParameter(valid_603240, JString, required = true,
                                 default = nil)
  if valid_603240 != nil:
    section.add "apiId", valid_603240
  var valid_603241 = path.getOrDefault("name")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = nil)
  if valid_603241 != nil:
    section.add "name", valid_603241
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
  var valid_603242 = header.getOrDefault("X-Amz-Date")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Date", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Security-Token")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Security-Token", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Content-Sha256", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Algorithm")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Algorithm", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Signature")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Signature", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-SignedHeaders", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Credential")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Credential", valid_603248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_GetDataSource_603237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_GetDataSource_603237; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_603251 = newJObject()
  add(path_603251, "apiId", newJString(apiId))
  add(path_603251, "name", newJString(name))
  result = call_603250.call(path_603251, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_603237(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_603238, base: "/", url: url_GetDataSource_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_603269 = ref object of OpenApiRestCall_602433
proc url_DeleteDataSource_603271(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteDataSource_603270(path: JsonNode; query: JsonNode;
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
  var valid_603272 = path.getOrDefault("apiId")
  valid_603272 = validateParameter(valid_603272, JString, required = true,
                                 default = nil)
  if valid_603272 != nil:
    section.add "apiId", valid_603272
  var valid_603273 = path.getOrDefault("name")
  valid_603273 = validateParameter(valid_603273, JString, required = true,
                                 default = nil)
  if valid_603273 != nil:
    section.add "name", valid_603273
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
  var valid_603274 = header.getOrDefault("X-Amz-Date")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Date", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Security-Token")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Security-Token", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Content-Sha256", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Algorithm")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Algorithm", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Signature")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Signature", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-SignedHeaders", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Credential")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Credential", valid_603280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603281: Call_DeleteDataSource_603269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_603281.validator(path, query, header, formData, body)
  let scheme = call_603281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603281.url(scheme.get, call_603281.host, call_603281.base,
                         call_603281.route, valid.getOrDefault("path"))
  result = hook(call_603281, url, valid)

proc call*(call_603282: Call_DeleteDataSource_603269; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_603283 = newJObject()
  add(path_603283, "apiId", newJString(apiId))
  add(path_603283, "name", newJString(name))
  result = call_603282.call(path_603283, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_603269(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_603270, base: "/",
    url: url_DeleteDataSource_603271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_603299 = ref object of OpenApiRestCall_602433
proc url_UpdateFunction_603301(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateFunction_603300(path: JsonNode; query: JsonNode;
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
  var valid_603302 = path.getOrDefault("apiId")
  valid_603302 = validateParameter(valid_603302, JString, required = true,
                                 default = nil)
  if valid_603302 != nil:
    section.add "apiId", valid_603302
  var valid_603303 = path.getOrDefault("functionId")
  valid_603303 = validateParameter(valid_603303, JString, required = true,
                                 default = nil)
  if valid_603303 != nil:
    section.add "functionId", valid_603303
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
  var valid_603304 = header.getOrDefault("X-Amz-Date")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Date", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Security-Token")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Security-Token", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Content-Sha256", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Algorithm")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Algorithm", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Signature")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Signature", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-SignedHeaders", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Credential")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Credential", valid_603310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603312: Call_UpdateFunction_603299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_603312.validator(path, query, header, formData, body)
  let scheme = call_603312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603312.url(scheme.get, call_603312.host, call_603312.base,
                         call_603312.route, valid.getOrDefault("path"))
  result = hook(call_603312, url, valid)

proc call*(call_603313: Call_UpdateFunction_603299; apiId: string;
          functionId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   body: JObject (required)
  var path_603314 = newJObject()
  var body_603315 = newJObject()
  add(path_603314, "apiId", newJString(apiId))
  add(path_603314, "functionId", newJString(functionId))
  if body != nil:
    body_603315 = body
  result = call_603313.call(path_603314, nil, nil, nil, body_603315)

var updateFunction* = Call_UpdateFunction_603299(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_603300, base: "/", url: url_UpdateFunction_603301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_603284 = ref object of OpenApiRestCall_602433
proc url_GetFunction_603286(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetFunction_603285(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603287 = path.getOrDefault("apiId")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = nil)
  if valid_603287 != nil:
    section.add "apiId", valid_603287
  var valid_603288 = path.getOrDefault("functionId")
  valid_603288 = validateParameter(valid_603288, JString, required = true,
                                 default = nil)
  if valid_603288 != nil:
    section.add "functionId", valid_603288
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
  var valid_603289 = header.getOrDefault("X-Amz-Date")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Date", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Security-Token")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Security-Token", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Content-Sha256", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Algorithm")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Algorithm", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Signature")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Signature", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-SignedHeaders", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Credential")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Credential", valid_603295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603296: Call_GetFunction_603284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_603296.validator(path, query, header, formData, body)
  let scheme = call_603296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603296.url(scheme.get, call_603296.host, call_603296.base,
                         call_603296.route, valid.getOrDefault("path"))
  result = hook(call_603296, url, valid)

proc call*(call_603297: Call_GetFunction_603284; apiId: string; functionId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_603298 = newJObject()
  add(path_603298, "apiId", newJString(apiId))
  add(path_603298, "functionId", newJString(functionId))
  result = call_603297.call(path_603298, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_603284(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/functions/{functionId}",
                                        validator: validate_GetFunction_603285,
                                        base: "/", url: url_GetFunction_603286,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_603316 = ref object of OpenApiRestCall_602433
proc url_DeleteFunction_603318(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteFunction_603317(path: JsonNode; query: JsonNode;
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
  var valid_603319 = path.getOrDefault("apiId")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = nil)
  if valid_603319 != nil:
    section.add "apiId", valid_603319
  var valid_603320 = path.getOrDefault("functionId")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = nil)
  if valid_603320 != nil:
    section.add "functionId", valid_603320
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
  var valid_603321 = header.getOrDefault("X-Amz-Date")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Date", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Security-Token")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Security-Token", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Content-Sha256", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Algorithm")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Algorithm", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Signature")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Signature", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-SignedHeaders", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Credential")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Credential", valid_603327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603328: Call_DeleteFunction_603316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_603328.validator(path, query, header, formData, body)
  let scheme = call_603328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603328.url(scheme.get, call_603328.host, call_603328.base,
                         call_603328.route, valid.getOrDefault("path"))
  result = hook(call_603328, url, valid)

proc call*(call_603329: Call_DeleteFunction_603316; apiId: string; functionId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_603330 = newJObject()
  add(path_603330, "apiId", newJString(apiId))
  add(path_603330, "functionId", newJString(functionId))
  result = call_603329.call(path_603330, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_603316(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_603317, base: "/", url: url_DeleteFunction_603318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_603345 = ref object of OpenApiRestCall_602433
proc url_UpdateGraphqlApi_603347(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateGraphqlApi_603346(path: JsonNode; query: JsonNode;
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
  var valid_603348 = path.getOrDefault("apiId")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = nil)
  if valid_603348 != nil:
    section.add "apiId", valid_603348
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
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Security-Token")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Security-Token", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Content-Sha256", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Algorithm")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Algorithm", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Signature")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Signature", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-SignedHeaders", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Credential")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Credential", valid_603355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603357: Call_UpdateGraphqlApi_603345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_603357.validator(path, query, header, formData, body)
  let scheme = call_603357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603357.url(scheme.get, call_603357.host, call_603357.base,
                         call_603357.route, valid.getOrDefault("path"))
  result = hook(call_603357, url, valid)

proc call*(call_603358: Call_UpdateGraphqlApi_603345; apiId: string; body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_603359 = newJObject()
  var body_603360 = newJObject()
  add(path_603359, "apiId", newJString(apiId))
  if body != nil:
    body_603360 = body
  result = call_603358.call(path_603359, nil, nil, nil, body_603360)

var updateGraphqlApi* = Call_UpdateGraphqlApi_603345(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_603346,
    base: "/", url: url_UpdateGraphqlApi_603347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_603331 = ref object of OpenApiRestCall_602433
proc url_GetGraphqlApi_603333(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetGraphqlApi_603332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603334 = path.getOrDefault("apiId")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = nil)
  if valid_603334 != nil:
    section.add "apiId", valid_603334
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
  var valid_603335 = header.getOrDefault("X-Amz-Date")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Date", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Security-Token")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Security-Token", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Content-Sha256", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Algorithm")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Algorithm", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Signature")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Signature", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-SignedHeaders", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Credential")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Credential", valid_603341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603342: Call_GetGraphqlApi_603331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_603342.validator(path, query, header, formData, body)
  let scheme = call_603342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603342.url(scheme.get, call_603342.host, call_603342.base,
                         call_603342.route, valid.getOrDefault("path"))
  result = hook(call_603342, url, valid)

proc call*(call_603343: Call_GetGraphqlApi_603331; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_603344 = newJObject()
  add(path_603344, "apiId", newJString(apiId))
  result = call_603343.call(path_603344, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_603331(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_603332, base: "/",
    url: url_GetGraphqlApi_603333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_603361 = ref object of OpenApiRestCall_602433
proc url_DeleteGraphqlApi_603363(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteGraphqlApi_603362(path: JsonNode; query: JsonNode;
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
  var valid_603364 = path.getOrDefault("apiId")
  valid_603364 = validateParameter(valid_603364, JString, required = true,
                                 default = nil)
  if valid_603364 != nil:
    section.add "apiId", valid_603364
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
  var valid_603365 = header.getOrDefault("X-Amz-Date")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Date", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Security-Token")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Security-Token", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Content-Sha256", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Algorithm")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Algorithm", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Signature")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Signature", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-SignedHeaders", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Credential")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Credential", valid_603371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603372: Call_DeleteGraphqlApi_603361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_603372.validator(path, query, header, formData, body)
  let scheme = call_603372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603372.url(scheme.get, call_603372.host, call_603372.base,
                         call_603372.route, valid.getOrDefault("path"))
  result = hook(call_603372, url, valid)

proc call*(call_603373: Call_DeleteGraphqlApi_603361; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_603374 = newJObject()
  add(path_603374, "apiId", newJString(apiId))
  result = call_603373.call(path_603374, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_603361(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_603362,
    base: "/", url: url_DeleteGraphqlApi_603363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_603391 = ref object of OpenApiRestCall_602433
proc url_UpdateResolver_603393(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateResolver_603392(path: JsonNode; query: JsonNode;
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
  var valid_603394 = path.getOrDefault("apiId")
  valid_603394 = validateParameter(valid_603394, JString, required = true,
                                 default = nil)
  if valid_603394 != nil:
    section.add "apiId", valid_603394
  var valid_603395 = path.getOrDefault("fieldName")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = nil)
  if valid_603395 != nil:
    section.add "fieldName", valid_603395
  var valid_603396 = path.getOrDefault("typeName")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = nil)
  if valid_603396 != nil:
    section.add "typeName", valid_603396
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
  var valid_603397 = header.getOrDefault("X-Amz-Date")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Date", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Security-Token")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Security-Token", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Content-Sha256", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Algorithm")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Algorithm", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Signature")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Signature", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-SignedHeaders", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Credential")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Credential", valid_603403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603405: Call_UpdateResolver_603391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_603405.validator(path, query, header, formData, body)
  let scheme = call_603405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603405.url(scheme.get, call_603405.host, call_603405.base,
                         call_603405.route, valid.getOrDefault("path"))
  result = hook(call_603405, url, valid)

proc call*(call_603406: Call_UpdateResolver_603391; apiId: string; fieldName: string;
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
  var path_603407 = newJObject()
  var body_603408 = newJObject()
  add(path_603407, "apiId", newJString(apiId))
  add(path_603407, "fieldName", newJString(fieldName))
  add(path_603407, "typeName", newJString(typeName))
  if body != nil:
    body_603408 = body
  result = call_603406.call(path_603407, nil, nil, nil, body_603408)

var updateResolver* = Call_UpdateResolver_603391(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_603392, base: "/", url: url_UpdateResolver_603393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_603375 = ref object of OpenApiRestCall_602433
proc url_GetResolver_603377(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetResolver_603376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603378 = path.getOrDefault("apiId")
  valid_603378 = validateParameter(valid_603378, JString, required = true,
                                 default = nil)
  if valid_603378 != nil:
    section.add "apiId", valid_603378
  var valid_603379 = path.getOrDefault("fieldName")
  valid_603379 = validateParameter(valid_603379, JString, required = true,
                                 default = nil)
  if valid_603379 != nil:
    section.add "fieldName", valid_603379
  var valid_603380 = path.getOrDefault("typeName")
  valid_603380 = validateParameter(valid_603380, JString, required = true,
                                 default = nil)
  if valid_603380 != nil:
    section.add "typeName", valid_603380
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
  var valid_603381 = header.getOrDefault("X-Amz-Date")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Date", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Security-Token")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Security-Token", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Content-Sha256", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Algorithm")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Algorithm", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Signature")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Signature", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-SignedHeaders", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Credential")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Credential", valid_603387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603388: Call_GetResolver_603375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_603388.validator(path, query, header, formData, body)
  let scheme = call_603388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603388.url(scheme.get, call_603388.host, call_603388.base,
                         call_603388.route, valid.getOrDefault("path"))
  result = hook(call_603388, url, valid)

proc call*(call_603389: Call_GetResolver_603375; apiId: string; fieldName: string;
          typeName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The resolver type name.
  var path_603390 = newJObject()
  add(path_603390, "apiId", newJString(apiId))
  add(path_603390, "fieldName", newJString(fieldName))
  add(path_603390, "typeName", newJString(typeName))
  result = call_603389.call(path_603390, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_603375(name: "getResolver",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
                                        validator: validate_GetResolver_603376,
                                        base: "/", url: url_GetResolver_603377,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_603409 = ref object of OpenApiRestCall_602433
proc url_DeleteResolver_603411(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteResolver_603410(path: JsonNode; query: JsonNode;
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
  var valid_603412 = path.getOrDefault("apiId")
  valid_603412 = validateParameter(valid_603412, JString, required = true,
                                 default = nil)
  if valid_603412 != nil:
    section.add "apiId", valid_603412
  var valid_603413 = path.getOrDefault("fieldName")
  valid_603413 = validateParameter(valid_603413, JString, required = true,
                                 default = nil)
  if valid_603413 != nil:
    section.add "fieldName", valid_603413
  var valid_603414 = path.getOrDefault("typeName")
  valid_603414 = validateParameter(valid_603414, JString, required = true,
                                 default = nil)
  if valid_603414 != nil:
    section.add "typeName", valid_603414
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
  var valid_603415 = header.getOrDefault("X-Amz-Date")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Date", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Security-Token")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Security-Token", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Content-Sha256", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Algorithm")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Algorithm", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Signature")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Signature", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-SignedHeaders", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Credential")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Credential", valid_603421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603422: Call_DeleteResolver_603409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_603422.validator(path, query, header, formData, body)
  let scheme = call_603422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603422.url(scheme.get, call_603422.host, call_603422.base,
                         call_603422.route, valid.getOrDefault("path"))
  result = hook(call_603422, url, valid)

proc call*(call_603423: Call_DeleteResolver_603409; apiId: string; fieldName: string;
          typeName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  var path_603424 = newJObject()
  add(path_603424, "apiId", newJString(apiId))
  add(path_603424, "fieldName", newJString(fieldName))
  add(path_603424, "typeName", newJString(typeName))
  result = call_603423.call(path_603424, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_603409(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_603410, base: "/", url: url_DeleteResolver_603411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_603425 = ref object of OpenApiRestCall_602433
proc url_UpdateType_603427(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateType_603426(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603428 = path.getOrDefault("apiId")
  valid_603428 = validateParameter(valid_603428, JString, required = true,
                                 default = nil)
  if valid_603428 != nil:
    section.add "apiId", valid_603428
  var valid_603429 = path.getOrDefault("typeName")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = nil)
  if valid_603429 != nil:
    section.add "typeName", valid_603429
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
  var valid_603430 = header.getOrDefault("X-Amz-Date")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Date", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Security-Token")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Security-Token", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Content-Sha256", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Algorithm")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Algorithm", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Signature")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Signature", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-SignedHeaders", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Credential")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Credential", valid_603436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603438: Call_UpdateType_603425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_603438.validator(path, query, header, formData, body)
  let scheme = call_603438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603438.url(scheme.get, call_603438.host, call_603438.base,
                         call_603438.route, valid.getOrDefault("path"))
  result = hook(call_603438, url, valid)

proc call*(call_603439: Call_UpdateType_603425; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_603440 = newJObject()
  var body_603441 = newJObject()
  add(path_603440, "apiId", newJString(apiId))
  add(path_603440, "typeName", newJString(typeName))
  if body != nil:
    body_603441 = body
  result = call_603439.call(path_603440, nil, nil, nil, body_603441)

var updateType* = Call_UpdateType_603425(name: "updateType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_UpdateType_603426,
                                      base: "/", url: url_UpdateType_603427,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_603442 = ref object of OpenApiRestCall_602433
proc url_DeleteType_603444(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteType_603443(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603445 = path.getOrDefault("apiId")
  valid_603445 = validateParameter(valid_603445, JString, required = true,
                                 default = nil)
  if valid_603445 != nil:
    section.add "apiId", valid_603445
  var valid_603446 = path.getOrDefault("typeName")
  valid_603446 = validateParameter(valid_603446, JString, required = true,
                                 default = nil)
  if valid_603446 != nil:
    section.add "typeName", valid_603446
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
  var valid_603447 = header.getOrDefault("X-Amz-Date")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Date", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Security-Token")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Security-Token", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Content-Sha256", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Algorithm")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Algorithm", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Signature")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Signature", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-SignedHeaders", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Credential")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Credential", valid_603453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603454: Call_DeleteType_603442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_603454.validator(path, query, header, formData, body)
  let scheme = call_603454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603454.url(scheme.get, call_603454.host, call_603454.base,
                         call_603454.route, valid.getOrDefault("path"))
  result = hook(call_603454, url, valid)

proc call*(call_603455: Call_DeleteType_603442; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_603456 = newJObject()
  add(path_603456, "apiId", newJString(apiId))
  add(path_603456, "typeName", newJString(typeName))
  result = call_603455.call(path_603456, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_603442(name: "deleteType",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_DeleteType_603443,
                                      base: "/", url: url_DeleteType_603444,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_603457 = ref object of OpenApiRestCall_602433
proc url_GetIntrospectionSchema_603459(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetIntrospectionSchema_603458(path: JsonNode; query: JsonNode;
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
  var valid_603460 = path.getOrDefault("apiId")
  valid_603460 = validateParameter(valid_603460, JString, required = true,
                                 default = nil)
  if valid_603460 != nil:
    section.add "apiId", valid_603460
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_603461 = query.getOrDefault("includeDirectives")
  valid_603461 = validateParameter(valid_603461, JBool, required = false, default = nil)
  if valid_603461 != nil:
    section.add "includeDirectives", valid_603461
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_603475 = query.getOrDefault("format")
  valid_603475 = validateParameter(valid_603475, JString, required = true,
                                 default = newJString("SDL"))
  if valid_603475 != nil:
    section.add "format", valid_603475
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
  var valid_603476 = header.getOrDefault("X-Amz-Date")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Date", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Security-Token")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Security-Token", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Content-Sha256", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Algorithm")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Algorithm", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Signature")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Signature", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-SignedHeaders", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Credential")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Credential", valid_603482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603483: Call_GetIntrospectionSchema_603457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_603483.validator(path, query, header, formData, body)
  let scheme = call_603483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603483.url(scheme.get, call_603483.host, call_603483.base,
                         call_603483.route, valid.getOrDefault("path"))
  result = hook(call_603483, url, valid)

proc call*(call_603484: Call_GetIntrospectionSchema_603457; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_603485 = newJObject()
  var query_603486 = newJObject()
  add(query_603486, "includeDirectives", newJBool(includeDirectives))
  add(path_603485, "apiId", newJString(apiId))
  add(query_603486, "format", newJString(format))
  result = call_603484.call(path_603485, query_603486, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_603457(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_603458, base: "/",
    url: url_GetIntrospectionSchema_603459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_603501 = ref object of OpenApiRestCall_602433
proc url_StartSchemaCreation_603503(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_StartSchemaCreation_603502(path: JsonNode; query: JsonNode;
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
  var valid_603504 = path.getOrDefault("apiId")
  valid_603504 = validateParameter(valid_603504, JString, required = true,
                                 default = nil)
  if valid_603504 != nil:
    section.add "apiId", valid_603504
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
  var valid_603505 = header.getOrDefault("X-Amz-Date")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Date", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Security-Token")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Security-Token", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Content-Sha256", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Algorithm")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Algorithm", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Signature")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Signature", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-SignedHeaders", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Credential")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Credential", valid_603511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603513: Call_StartSchemaCreation_603501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_603513.validator(path, query, header, formData, body)
  let scheme = call_603513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603513.url(scheme.get, call_603513.host, call_603513.base,
                         call_603513.route, valid.getOrDefault("path"))
  result = hook(call_603513, url, valid)

proc call*(call_603514: Call_StartSchemaCreation_603501; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_603515 = newJObject()
  var body_603516 = newJObject()
  add(path_603515, "apiId", newJString(apiId))
  if body != nil:
    body_603516 = body
  result = call_603514.call(path_603515, nil, nil, nil, body_603516)

var startSchemaCreation* = Call_StartSchemaCreation_603501(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_603502, base: "/",
    url: url_StartSchemaCreation_603503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_603487 = ref object of OpenApiRestCall_602433
proc url_GetSchemaCreationStatus_603489(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetSchemaCreationStatus_603488(path: JsonNode; query: JsonNode;
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
  var valid_603490 = path.getOrDefault("apiId")
  valid_603490 = validateParameter(valid_603490, JString, required = true,
                                 default = nil)
  if valid_603490 != nil:
    section.add "apiId", valid_603490
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
  var valid_603491 = header.getOrDefault("X-Amz-Date")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Date", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Security-Token")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Security-Token", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Content-Sha256", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Algorithm")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Algorithm", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Signature")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Signature", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-SignedHeaders", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Credential")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Credential", valid_603497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603498: Call_GetSchemaCreationStatus_603487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_603498.validator(path, query, header, formData, body)
  let scheme = call_603498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603498.url(scheme.get, call_603498.host, call_603498.base,
                         call_603498.route, valid.getOrDefault("path"))
  result = hook(call_603498, url, valid)

proc call*(call_603499: Call_GetSchemaCreationStatus_603487; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_603500 = newJObject()
  add(path_603500, "apiId", newJString(apiId))
  result = call_603499.call(path_603500, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_603487(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_603488, base: "/",
    url: url_GetSchemaCreationStatus_603489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_603517 = ref object of OpenApiRestCall_602433
proc url_GetType_603519(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetType_603518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603520 = path.getOrDefault("apiId")
  valid_603520 = validateParameter(valid_603520, JString, required = true,
                                 default = nil)
  if valid_603520 != nil:
    section.add "apiId", valid_603520
  var valid_603521 = path.getOrDefault("typeName")
  valid_603521 = validateParameter(valid_603521, JString, required = true,
                                 default = nil)
  if valid_603521 != nil:
    section.add "typeName", valid_603521
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_603522 = query.getOrDefault("format")
  valid_603522 = validateParameter(valid_603522, JString, required = true,
                                 default = newJString("SDL"))
  if valid_603522 != nil:
    section.add "format", valid_603522
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
  var valid_603523 = header.getOrDefault("X-Amz-Date")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Date", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Security-Token")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Security-Token", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Content-Sha256", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Algorithm")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Algorithm", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Signature")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Signature", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-SignedHeaders", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Credential")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Credential", valid_603529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603530: Call_GetType_603517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_603530.validator(path, query, header, formData, body)
  let scheme = call_603530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603530.url(scheme.get, call_603530.host, call_603530.base,
                         call_603530.route, valid.getOrDefault("path"))
  result = hook(call_603530, url, valid)

proc call*(call_603531: Call_GetType_603517; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_603532 = newJObject()
  var query_603533 = newJObject()
  add(path_603532, "apiId", newJString(apiId))
  add(path_603532, "typeName", newJString(typeName))
  add(query_603533, "format", newJString(format))
  result = call_603531.call(path_603532, query_603533, nil, nil, nil)

var getType* = Call_GetType_603517(name: "getType", meth: HttpMethod.HttpGet,
                                host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                validator: validate_GetType_603518, base: "/",
                                url: url_GetType_603519,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_603534 = ref object of OpenApiRestCall_602433
proc url_ListResolversByFunction_603536(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListResolversByFunction_603535(path: JsonNode; query: JsonNode;
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
  var valid_603537 = path.getOrDefault("apiId")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = nil)
  if valid_603537 != nil:
    section.add "apiId", valid_603537
  var valid_603538 = path.getOrDefault("functionId")
  valid_603538 = validateParameter(valid_603538, JString, required = true,
                                 default = nil)
  if valid_603538 != nil:
    section.add "functionId", valid_603538
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  section = newJObject()
  var valid_603539 = query.getOrDefault("maxResults")
  valid_603539 = validateParameter(valid_603539, JInt, required = false, default = nil)
  if valid_603539 != nil:
    section.add "maxResults", valid_603539
  var valid_603540 = query.getOrDefault("nextToken")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "nextToken", valid_603540
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
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603548: Call_ListResolversByFunction_603534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_603548.validator(path, query, header, formData, body)
  let scheme = call_603548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603548.url(scheme.get, call_603548.host, call_603548.base,
                         call_603548.route, valid.getOrDefault("path"))
  result = hook(call_603548, url, valid)

proc call*(call_603549: Call_ListResolversByFunction_603534; apiId: string;
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
  var path_603550 = newJObject()
  var query_603551 = newJObject()
  add(path_603550, "apiId", newJString(apiId))
  add(path_603550, "functionId", newJString(functionId))
  add(query_603551, "maxResults", newJInt(maxResults))
  add(query_603551, "nextToken", newJString(nextToken))
  result = call_603549.call(path_603550, query_603551, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_603534(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_603535, base: "/",
    url: url_ListResolversByFunction_603536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603566 = ref object of OpenApiRestCall_602433
proc url_TagResource_603568(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_TagResource_603567(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603569 = path.getOrDefault("resourceArn")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "resourceArn", valid_603569
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
  var valid_603570 = header.getOrDefault("X-Amz-Date")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Date", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Security-Token")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Security-Token", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Content-Sha256", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Algorithm")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Algorithm", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Signature")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Signature", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-SignedHeaders", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Credential")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Credential", valid_603576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603578: Call_TagResource_603566; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_603578.validator(path, query, header, formData, body)
  let scheme = call_603578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603578.url(scheme.get, call_603578.host, call_603578.base,
                         call_603578.route, valid.getOrDefault("path"))
  result = hook(call_603578, url, valid)

proc call*(call_603579: Call_TagResource_603566; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_603580 = newJObject()
  var body_603581 = newJObject()
  if body != nil:
    body_603581 = body
  add(path_603580, "resourceArn", newJString(resourceArn))
  result = call_603579.call(path_603580, nil, nil, nil, body_603581)

var tagResource* = Call_TagResource_603566(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_603567,
                                        base: "/", url: url_TagResource_603568,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603552 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_603554(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListTagsForResource_603553(path: JsonNode; query: JsonNode;
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
  var valid_603555 = path.getOrDefault("resourceArn")
  valid_603555 = validateParameter(valid_603555, JString, required = true,
                                 default = nil)
  if valid_603555 != nil:
    section.add "resourceArn", valid_603555
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
  var valid_603556 = header.getOrDefault("X-Amz-Date")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Date", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Security-Token")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Security-Token", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Content-Sha256", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Algorithm")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Algorithm", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Signature")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Signature", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Credential")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Credential", valid_603562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603563: Call_ListTagsForResource_603552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_603563.validator(path, query, header, formData, body)
  let scheme = call_603563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603563.url(scheme.get, call_603563.host, call_603563.base,
                         call_603563.route, valid.getOrDefault("path"))
  result = hook(call_603563, url, valid)

proc call*(call_603564: Call_ListTagsForResource_603552; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_603565 = newJObject()
  add(path_603565, "resourceArn", newJString(resourceArn))
  result = call_603564.call(path_603565, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603552(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_603553, base: "/",
    url: url_ListTagsForResource_603554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_603582 = ref object of OpenApiRestCall_602433
proc url_ListTypes_603584(protocol: Scheme; host: string; base: string; route: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListTypes_603583(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603585 = path.getOrDefault("apiId")
  valid_603585 = validateParameter(valid_603585, JString, required = true,
                                 default = nil)
  if valid_603585 != nil:
    section.add "apiId", valid_603585
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_603586 = query.getOrDefault("maxResults")
  valid_603586 = validateParameter(valid_603586, JInt, required = false, default = nil)
  if valid_603586 != nil:
    section.add "maxResults", valid_603586
  var valid_603587 = query.getOrDefault("nextToken")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "nextToken", valid_603587
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_603588 = query.getOrDefault("format")
  valid_603588 = validateParameter(valid_603588, JString, required = true,
                                 default = newJString("SDL"))
  if valid_603588 != nil:
    section.add "format", valid_603588
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
  var valid_603589 = header.getOrDefault("X-Amz-Date")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Date", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Content-Sha256", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Algorithm")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Algorithm", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Signature")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Signature", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-SignedHeaders", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Credential")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Credential", valid_603595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603596: Call_ListTypes_603582; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_603596.validator(path, query, header, formData, body)
  let scheme = call_603596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603596.url(scheme.get, call_603596.host, call_603596.base,
                         call_603596.route, valid.getOrDefault("path"))
  result = hook(call_603596, url, valid)

proc call*(call_603597: Call_ListTypes_603582; apiId: string; maxResults: int = 0;
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
  var path_603598 = newJObject()
  var query_603599 = newJObject()
  add(path_603598, "apiId", newJString(apiId))
  add(query_603599, "maxResults", newJInt(maxResults))
  add(query_603599, "nextToken", newJString(nextToken))
  add(query_603599, "format", newJString(format))
  result = call_603597.call(path_603598, query_603599, nil, nil, nil)

var listTypes* = Call_ListTypes_603582(name: "listTypes", meth: HttpMethod.HttpGet,
                                    host: "appsync.amazonaws.com",
                                    route: "/v1/apis/{apiId}/types#format",
                                    validator: validate_ListTypes_603583,
                                    base: "/", url: url_ListTypes_603584,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603600 = ref object of OpenApiRestCall_602433
proc url_UntagResource_603602(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UntagResource_603601(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603603 = path.getOrDefault("resourceArn")
  valid_603603 = validateParameter(valid_603603, JString, required = true,
                                 default = nil)
  if valid_603603 != nil:
    section.add "resourceArn", valid_603603
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603604 = query.getOrDefault("tagKeys")
  valid_603604 = validateParameter(valid_603604, JArray, required = true, default = nil)
  if valid_603604 != nil:
    section.add "tagKeys", valid_603604
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
  var valid_603605 = header.getOrDefault("X-Amz-Date")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Date", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Security-Token")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Security-Token", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Content-Sha256", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Algorithm")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Algorithm", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Signature")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Signature", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-SignedHeaders", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Credential")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Credential", valid_603611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603612: Call_UntagResource_603600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_603612.validator(path, query, header, formData, body)
  let scheme = call_603612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603612.url(scheme.get, call_603612.host, call_603612.base,
                         call_603612.route, valid.getOrDefault("path"))
  result = hook(call_603612, url, valid)

proc call*(call_603613: Call_UntagResource_603600; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_603614 = newJObject()
  var query_603615 = newJObject()
  if tagKeys != nil:
    query_603615.add "tagKeys", tagKeys
  add(path_603614, "resourceArn", newJString(resourceArn))
  result = call_603613.call(path_603614, query_603615, nil, nil, nil)

var untagResource* = Call_UntagResource_603600(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_603601,
    base: "/", url: url_UntagResource_603602, schemes: {Scheme.Https, Scheme.Http})
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
