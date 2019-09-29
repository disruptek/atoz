
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiKey_594047 = ref object of OpenApiRestCall_593437
proc url_CreateApiKey_594049(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateApiKey_594048(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594050 = path.getOrDefault("apiId")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = nil)
  if valid_594050 != nil:
    section.add "apiId", valid_594050
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
  var valid_594051 = header.getOrDefault("X-Amz-Date")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Date", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Security-Token")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Security-Token", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Content-Sha256", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Algorithm")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Algorithm", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-SignedHeaders", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Credential")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Credential", valid_594057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594059: Call_CreateApiKey_594047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_594059.validator(path, query, header, formData, body)
  let scheme = call_594059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594059.url(scheme.get, call_594059.host, call_594059.base,
                         call_594059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594059, url, valid)

proc call*(call_594060: Call_CreateApiKey_594047; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_594061 = newJObject()
  var body_594062 = newJObject()
  add(path_594061, "apiId", newJString(apiId))
  if body != nil:
    body_594062 = body
  result = call_594060.call(path_594061, nil, nil, nil, body_594062)

var createApiKey* = Call_CreateApiKey_594047(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_594048,
    base: "/", url: url_CreateApiKey_594049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_593774 = ref object of OpenApiRestCall_593437
proc url_ListApiKeys_593776(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListApiKeys_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593902 = path.getOrDefault("apiId")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "apiId", valid_593902
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_593903 = query.getOrDefault("maxResults")
  valid_593903 = validateParameter(valid_593903, JInt, required = false, default = nil)
  if valid_593903 != nil:
    section.add "maxResults", valid_593903
  var valid_593904 = query.getOrDefault("nextToken")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "nextToken", valid_593904
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
  var valid_593905 = header.getOrDefault("X-Amz-Date")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Date", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Security-Token")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Security-Token", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Content-Sha256", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Algorithm")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Algorithm", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Signature")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Signature", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-SignedHeaders", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Credential")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Credential", valid_593911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593934: Call_ListApiKeys_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_593934.validator(path, query, header, formData, body)
  let scheme = call_593934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593934.url(scheme.get, call_593934.host, call_593934.base,
                         call_593934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593934, url, valid)

proc call*(call_594005: Call_ListApiKeys_593774; apiId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_594006 = newJObject()
  var query_594008 = newJObject()
  add(path_594006, "apiId", newJString(apiId))
  add(query_594008, "maxResults", newJInt(maxResults))
  add(query_594008, "nextToken", newJString(nextToken))
  result = call_594005.call(path_594006, query_594008, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_593774(name: "listApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/apikeys",
                                        validator: validate_ListApiKeys_593775,
                                        base: "/", url: url_ListApiKeys_593776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_594080 = ref object of OpenApiRestCall_593437
proc url_CreateDataSource_594082(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateDataSource_594081(path: JsonNode; query: JsonNode;
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
  var valid_594083 = path.getOrDefault("apiId")
  valid_594083 = validateParameter(valid_594083, JString, required = true,
                                 default = nil)
  if valid_594083 != nil:
    section.add "apiId", valid_594083
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
  var valid_594084 = header.getOrDefault("X-Amz-Date")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Date", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Security-Token")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Security-Token", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Content-Sha256", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Algorithm")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Algorithm", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Signature")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Signature", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-SignedHeaders", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Credential")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Credential", valid_594090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594092: Call_CreateDataSource_594080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_594092.validator(path, query, header, formData, body)
  let scheme = call_594092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594092.url(scheme.get, call_594092.host, call_594092.base,
                         call_594092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594092, url, valid)

proc call*(call_594093: Call_CreateDataSource_594080; apiId: string; body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_594094 = newJObject()
  var body_594095 = newJObject()
  add(path_594094, "apiId", newJString(apiId))
  if body != nil:
    body_594095 = body
  result = call_594093.call(path_594094, nil, nil, nil, body_594095)

var createDataSource* = Call_CreateDataSource_594080(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_594081,
    base: "/", url: url_CreateDataSource_594082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_594063 = ref object of OpenApiRestCall_593437
proc url_ListDataSources_594065(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListDataSources_594064(path: JsonNode; query: JsonNode;
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
  var valid_594066 = path.getOrDefault("apiId")
  valid_594066 = validateParameter(valid_594066, JString, required = true,
                                 default = nil)
  if valid_594066 != nil:
    section.add "apiId", valid_594066
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_594067 = query.getOrDefault("maxResults")
  valid_594067 = validateParameter(valid_594067, JInt, required = false, default = nil)
  if valid_594067 != nil:
    section.add "maxResults", valid_594067
  var valid_594068 = query.getOrDefault("nextToken")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "nextToken", valid_594068
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
  var valid_594069 = header.getOrDefault("X-Amz-Date")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Date", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Security-Token")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Security-Token", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Content-Sha256", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Algorithm")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Algorithm", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Signature")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Signature", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-SignedHeaders", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Credential")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Credential", valid_594075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594076: Call_ListDataSources_594063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_594076.validator(path, query, header, formData, body)
  let scheme = call_594076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594076.url(scheme.get, call_594076.host, call_594076.base,
                         call_594076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594076, url, valid)

proc call*(call_594077: Call_ListDataSources_594063; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var path_594078 = newJObject()
  var query_594079 = newJObject()
  add(path_594078, "apiId", newJString(apiId))
  add(query_594079, "maxResults", newJInt(maxResults))
  add(query_594079, "nextToken", newJString(nextToken))
  result = call_594077.call(path_594078, query_594079, nil, nil, nil)

var listDataSources* = Call_ListDataSources_594063(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_594064,
    base: "/", url: url_ListDataSources_594065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_594113 = ref object of OpenApiRestCall_593437
proc url_CreateFunction_594115(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateFunction_594114(path: JsonNode; query: JsonNode;
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
  var valid_594116 = path.getOrDefault("apiId")
  valid_594116 = validateParameter(valid_594116, JString, required = true,
                                 default = nil)
  if valid_594116 != nil:
    section.add "apiId", valid_594116
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
  var valid_594117 = header.getOrDefault("X-Amz-Date")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Date", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Security-Token")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Security-Token", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Content-Sha256", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Algorithm")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Algorithm", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Signature")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Signature", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-SignedHeaders", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Credential")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Credential", valid_594123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594125: Call_CreateFunction_594113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_594125.validator(path, query, header, formData, body)
  let scheme = call_594125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594125.url(scheme.get, call_594125.host, call_594125.base,
                         call_594125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594125, url, valid)

proc call*(call_594126: Call_CreateFunction_594113; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_594127 = newJObject()
  var body_594128 = newJObject()
  add(path_594127, "apiId", newJString(apiId))
  if body != nil:
    body_594128 = body
  result = call_594126.call(path_594127, nil, nil, nil, body_594128)

var createFunction* = Call_CreateFunction_594113(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_594114,
    base: "/", url: url_CreateFunction_594115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_594096 = ref object of OpenApiRestCall_593437
proc url_ListFunctions_594098(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListFunctions_594097(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594099 = path.getOrDefault("apiId")
  valid_594099 = validateParameter(valid_594099, JString, required = true,
                                 default = nil)
  if valid_594099 != nil:
    section.add "apiId", valid_594099
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_594100 = query.getOrDefault("maxResults")
  valid_594100 = validateParameter(valid_594100, JInt, required = false, default = nil)
  if valid_594100 != nil:
    section.add "maxResults", valid_594100
  var valid_594101 = query.getOrDefault("nextToken")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "nextToken", valid_594101
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
  var valid_594102 = header.getOrDefault("X-Amz-Date")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Date", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Security-Token")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Security-Token", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Content-Sha256", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Algorithm")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Algorithm", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Signature")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Signature", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-SignedHeaders", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Credential")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Credential", valid_594108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594109: Call_ListFunctions_594096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_594109.validator(path, query, header, formData, body)
  let scheme = call_594109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594109.url(scheme.get, call_594109.host, call_594109.base,
                         call_594109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594109, url, valid)

proc call*(call_594110: Call_ListFunctions_594096; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_594111 = newJObject()
  var query_594112 = newJObject()
  add(path_594111, "apiId", newJString(apiId))
  add(query_594112, "maxResults", newJInt(maxResults))
  add(query_594112, "nextToken", newJString(nextToken))
  result = call_594110.call(path_594111, query_594112, nil, nil, nil)

var listFunctions* = Call_ListFunctions_594096(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_594097,
    base: "/", url: url_ListFunctions_594098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_594144 = ref object of OpenApiRestCall_593437
proc url_CreateGraphqlApi_594146(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGraphqlApi_594145(path: JsonNode; query: JsonNode;
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
  var valid_594147 = header.getOrDefault("X-Amz-Date")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Date", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Security-Token")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Security-Token", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Content-Sha256", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Algorithm")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Algorithm", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Signature")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Signature", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-SignedHeaders", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Credential")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Credential", valid_594153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594155: Call_CreateGraphqlApi_594144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_594155.validator(path, query, header, formData, body)
  let scheme = call_594155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594155.url(scheme.get, call_594155.host, call_594155.base,
                         call_594155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594155, url, valid)

proc call*(call_594156: Call_CreateGraphqlApi_594144; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_594157 = newJObject()
  if body != nil:
    body_594157 = body
  result = call_594156.call(nil, nil, nil, nil, body_594157)

var createGraphqlApi* = Call_CreateGraphqlApi_594144(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_594145, base: "/",
    url: url_CreateGraphqlApi_594146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_594129 = ref object of OpenApiRestCall_593437
proc url_ListGraphqlApis_594131(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGraphqlApis_594130(path: JsonNode; query: JsonNode;
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
  var valid_594132 = query.getOrDefault("maxResults")
  valid_594132 = validateParameter(valid_594132, JInt, required = false, default = nil)
  if valid_594132 != nil:
    section.add "maxResults", valid_594132
  var valid_594133 = query.getOrDefault("nextToken")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "nextToken", valid_594133
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
  var valid_594134 = header.getOrDefault("X-Amz-Date")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Date", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Security-Token")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Security-Token", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Content-Sha256", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Algorithm")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Algorithm", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Signature")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Signature", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-SignedHeaders", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Credential")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Credential", valid_594140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594141: Call_ListGraphqlApis_594129; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_594141.validator(path, query, header, formData, body)
  let scheme = call_594141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594141.url(scheme.get, call_594141.host, call_594141.base,
                         call_594141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594141, url, valid)

proc call*(call_594142: Call_ListGraphqlApis_594129; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var query_594143 = newJObject()
  add(query_594143, "maxResults", newJInt(maxResults))
  add(query_594143, "nextToken", newJString(nextToken))
  result = call_594142.call(nil, query_594143, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_594129(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_594130, base: "/", url: url_ListGraphqlApis_594131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_594176 = ref object of OpenApiRestCall_593437
proc url_CreateResolver_594178(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_CreateResolver_594177(path: JsonNode; query: JsonNode;
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
  var valid_594179 = path.getOrDefault("apiId")
  valid_594179 = validateParameter(valid_594179, JString, required = true,
                                 default = nil)
  if valid_594179 != nil:
    section.add "apiId", valid_594179
  var valid_594180 = path.getOrDefault("typeName")
  valid_594180 = validateParameter(valid_594180, JString, required = true,
                                 default = nil)
  if valid_594180 != nil:
    section.add "typeName", valid_594180
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Content-Sha256", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Algorithm")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Algorithm", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Signature")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Signature", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Credential")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Credential", valid_594187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594189: Call_CreateResolver_594176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_594189.validator(path, query, header, formData, body)
  let scheme = call_594189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594189.url(scheme.get, call_594189.host, call_594189.base,
                         call_594189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594189, url, valid)

proc call*(call_594190: Call_CreateResolver_594176; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_594191 = newJObject()
  var body_594192 = newJObject()
  add(path_594191, "apiId", newJString(apiId))
  add(path_594191, "typeName", newJString(typeName))
  if body != nil:
    body_594192 = body
  result = call_594190.call(path_594191, nil, nil, nil, body_594192)

var createResolver* = Call_CreateResolver_594176(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_594177, base: "/", url: url_CreateResolver_594178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_594158 = ref object of OpenApiRestCall_593437
proc url_ListResolvers_594160(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_ListResolvers_594159(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594161 = path.getOrDefault("apiId")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = nil)
  if valid_594161 != nil:
    section.add "apiId", valid_594161
  var valid_594162 = path.getOrDefault("typeName")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "typeName", valid_594162
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_594163 = query.getOrDefault("maxResults")
  valid_594163 = validateParameter(valid_594163, JInt, required = false, default = nil)
  if valid_594163 != nil:
    section.add "maxResults", valid_594163
  var valid_594164 = query.getOrDefault("nextToken")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "nextToken", valid_594164
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
  var valid_594165 = header.getOrDefault("X-Amz-Date")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Date", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Security-Token")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Security-Token", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Content-Sha256", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Algorithm")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Algorithm", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Signature")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Signature", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-SignedHeaders", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Credential")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Credential", valid_594171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594172: Call_ListResolvers_594158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_594172.validator(path, query, header, formData, body)
  let scheme = call_594172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594172.url(scheme.get, call_594172.host, call_594172.base,
                         call_594172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594172, url, valid)

proc call*(call_594173: Call_ListResolvers_594158; apiId: string; typeName: string;
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
  var path_594174 = newJObject()
  var query_594175 = newJObject()
  add(path_594174, "apiId", newJString(apiId))
  add(path_594174, "typeName", newJString(typeName))
  add(query_594175, "maxResults", newJInt(maxResults))
  add(query_594175, "nextToken", newJString(nextToken))
  result = call_594173.call(path_594174, query_594175, nil, nil, nil)

var listResolvers* = Call_ListResolvers_594158(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_594159, base: "/", url: url_ListResolvers_594160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_594193 = ref object of OpenApiRestCall_593437
proc url_CreateType_594195(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateType_594194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594196 = path.getOrDefault("apiId")
  valid_594196 = validateParameter(valid_594196, JString, required = true,
                                 default = nil)
  if valid_594196 != nil:
    section.add "apiId", valid_594196
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
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Security-Token")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Security-Token", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_CreateType_594193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_CreateType_594193; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_594207 = newJObject()
  var body_594208 = newJObject()
  add(path_594207, "apiId", newJString(apiId))
  if body != nil:
    body_594208 = body
  result = call_594206.call(path_594207, nil, nil, nil, body_594208)

var createType* = Call_CreateType_594193(name: "createType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types",
                                      validator: validate_CreateType_594194,
                                      base: "/", url: url_CreateType_594195,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_594209 = ref object of OpenApiRestCall_593437
proc url_UpdateApiKey_594211(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateApiKey_594210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594212 = path.getOrDefault("apiId")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = nil)
  if valid_594212 != nil:
    section.add "apiId", valid_594212
  var valid_594213 = path.getOrDefault("id")
  valid_594213 = validateParameter(valid_594213, JString, required = true,
                                 default = nil)
  if valid_594213 != nil:
    section.add "id", valid_594213
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
  var valid_594214 = header.getOrDefault("X-Amz-Date")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Date", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Security-Token")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Security-Token", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Content-Sha256", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Algorithm")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Algorithm", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Signature")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Signature", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-SignedHeaders", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Credential")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Credential", valid_594220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594222: Call_UpdateApiKey_594209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_594222.validator(path, query, header, formData, body)
  let scheme = call_594222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594222.url(scheme.get, call_594222.host, call_594222.base,
                         call_594222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594222, url, valid)

proc call*(call_594223: Call_UpdateApiKey_594209; apiId: string; id: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   id: string (required)
  ##     : The API key ID.
  ##   body: JObject (required)
  var path_594224 = newJObject()
  var body_594225 = newJObject()
  add(path_594224, "apiId", newJString(apiId))
  add(path_594224, "id", newJString(id))
  if body != nil:
    body_594225 = body
  result = call_594223.call(path_594224, nil, nil, nil, body_594225)

var updateApiKey* = Call_UpdateApiKey_594209(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_594210,
    base: "/", url: url_UpdateApiKey_594211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_594226 = ref object of OpenApiRestCall_593437
proc url_DeleteApiKey_594228(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteApiKey_594227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594229 = path.getOrDefault("apiId")
  valid_594229 = validateParameter(valid_594229, JString, required = true,
                                 default = nil)
  if valid_594229 != nil:
    section.add "apiId", valid_594229
  var valid_594230 = path.getOrDefault("id")
  valid_594230 = validateParameter(valid_594230, JString, required = true,
                                 default = nil)
  if valid_594230 != nil:
    section.add "id", valid_594230
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
  var valid_594231 = header.getOrDefault("X-Amz-Date")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Date", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-Security-Token")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Security-Token", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Content-Sha256", valid_594233
  var valid_594234 = header.getOrDefault("X-Amz-Algorithm")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-Algorithm", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-Signature")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Signature", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-SignedHeaders", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Credential")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Credential", valid_594237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594238: Call_DeleteApiKey_594226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_594238.validator(path, query, header, formData, body)
  let scheme = call_594238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594238.url(scheme.get, call_594238.host, call_594238.base,
                         call_594238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594238, url, valid)

proc call*(call_594239: Call_DeleteApiKey_594226; apiId: string; id: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   id: string (required)
  ##     : The ID for the API key.
  var path_594240 = newJObject()
  add(path_594240, "apiId", newJString(apiId))
  add(path_594240, "id", newJString(id))
  result = call_594239.call(path_594240, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_594226(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_594227,
    base: "/", url: url_DeleteApiKey_594228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_594256 = ref object of OpenApiRestCall_593437
proc url_UpdateDataSource_594258(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateDataSource_594257(path: JsonNode; query: JsonNode;
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
  var valid_594259 = path.getOrDefault("apiId")
  valid_594259 = validateParameter(valid_594259, JString, required = true,
                                 default = nil)
  if valid_594259 != nil:
    section.add "apiId", valid_594259
  var valid_594260 = path.getOrDefault("name")
  valid_594260 = validateParameter(valid_594260, JString, required = true,
                                 default = nil)
  if valid_594260 != nil:
    section.add "name", valid_594260
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
  var valid_594261 = header.getOrDefault("X-Amz-Date")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Date", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Security-Token")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Security-Token", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Content-Sha256", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Algorithm")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Algorithm", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Signature")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Signature", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-SignedHeaders", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Credential")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Credential", valid_594267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594269: Call_UpdateDataSource_594256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_594269.validator(path, query, header, formData, body)
  let scheme = call_594269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594269.url(scheme.get, call_594269.host, call_594269.base,
                         call_594269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594269, url, valid)

proc call*(call_594270: Call_UpdateDataSource_594256; apiId: string; name: string;
          body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_594271 = newJObject()
  var body_594272 = newJObject()
  add(path_594271, "apiId", newJString(apiId))
  add(path_594271, "name", newJString(name))
  if body != nil:
    body_594272 = body
  result = call_594270.call(path_594271, nil, nil, nil, body_594272)

var updateDataSource* = Call_UpdateDataSource_594256(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_594257, base: "/",
    url: url_UpdateDataSource_594258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_594241 = ref object of OpenApiRestCall_593437
proc url_GetDataSource_594243(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_GetDataSource_594242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594244 = path.getOrDefault("apiId")
  valid_594244 = validateParameter(valid_594244, JString, required = true,
                                 default = nil)
  if valid_594244 != nil:
    section.add "apiId", valid_594244
  var valid_594245 = path.getOrDefault("name")
  valid_594245 = validateParameter(valid_594245, JString, required = true,
                                 default = nil)
  if valid_594245 != nil:
    section.add "name", valid_594245
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
  var valid_594246 = header.getOrDefault("X-Amz-Date")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Date", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Security-Token")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Security-Token", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Content-Sha256", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Algorithm")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Algorithm", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Signature")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Signature", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-SignedHeaders", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Credential")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Credential", valid_594252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594253: Call_GetDataSource_594241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_594253.validator(path, query, header, formData, body)
  let scheme = call_594253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594253.url(scheme.get, call_594253.host, call_594253.base,
                         call_594253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594253, url, valid)

proc call*(call_594254: Call_GetDataSource_594241; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_594255 = newJObject()
  add(path_594255, "apiId", newJString(apiId))
  add(path_594255, "name", newJString(name))
  result = call_594254.call(path_594255, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_594241(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_594242, base: "/", url: url_GetDataSource_594243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_594273 = ref object of OpenApiRestCall_593437
proc url_DeleteDataSource_594275(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteDataSource_594274(path: JsonNode; query: JsonNode;
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
  var valid_594276 = path.getOrDefault("apiId")
  valid_594276 = validateParameter(valid_594276, JString, required = true,
                                 default = nil)
  if valid_594276 != nil:
    section.add "apiId", valid_594276
  var valid_594277 = path.getOrDefault("name")
  valid_594277 = validateParameter(valid_594277, JString, required = true,
                                 default = nil)
  if valid_594277 != nil:
    section.add "name", valid_594277
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
  var valid_594278 = header.getOrDefault("X-Amz-Date")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Date", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Security-Token")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Security-Token", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Content-Sha256", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Algorithm")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Algorithm", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Signature")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Signature", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-SignedHeaders", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Credential")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Credential", valid_594284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594285: Call_DeleteDataSource_594273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_594285.validator(path, query, header, formData, body)
  let scheme = call_594285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594285.url(scheme.get, call_594285.host, call_594285.base,
                         call_594285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594285, url, valid)

proc call*(call_594286: Call_DeleteDataSource_594273; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_594287 = newJObject()
  add(path_594287, "apiId", newJString(apiId))
  add(path_594287, "name", newJString(name))
  result = call_594286.call(path_594287, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_594273(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_594274, base: "/",
    url: url_DeleteDataSource_594275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_594303 = ref object of OpenApiRestCall_593437
proc url_UpdateFunction_594305(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateFunction_594304(path: JsonNode; query: JsonNode;
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
  var valid_594306 = path.getOrDefault("apiId")
  valid_594306 = validateParameter(valid_594306, JString, required = true,
                                 default = nil)
  if valid_594306 != nil:
    section.add "apiId", valid_594306
  var valid_594307 = path.getOrDefault("functionId")
  valid_594307 = validateParameter(valid_594307, JString, required = true,
                                 default = nil)
  if valid_594307 != nil:
    section.add "functionId", valid_594307
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
  var valid_594308 = header.getOrDefault("X-Amz-Date")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Date", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Security-Token")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Security-Token", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Content-Sha256", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Algorithm")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Algorithm", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Signature")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Signature", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-SignedHeaders", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Credential")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Credential", valid_594314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594316: Call_UpdateFunction_594303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_594316.validator(path, query, header, formData, body)
  let scheme = call_594316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594316.url(scheme.get, call_594316.host, call_594316.base,
                         call_594316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594316, url, valid)

proc call*(call_594317: Call_UpdateFunction_594303; apiId: string;
          functionId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   body: JObject (required)
  var path_594318 = newJObject()
  var body_594319 = newJObject()
  add(path_594318, "apiId", newJString(apiId))
  add(path_594318, "functionId", newJString(functionId))
  if body != nil:
    body_594319 = body
  result = call_594317.call(path_594318, nil, nil, nil, body_594319)

var updateFunction* = Call_UpdateFunction_594303(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_594304, base: "/", url: url_UpdateFunction_594305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_594288 = ref object of OpenApiRestCall_593437
proc url_GetFunction_594290(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_GetFunction_594289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594291 = path.getOrDefault("apiId")
  valid_594291 = validateParameter(valid_594291, JString, required = true,
                                 default = nil)
  if valid_594291 != nil:
    section.add "apiId", valid_594291
  var valid_594292 = path.getOrDefault("functionId")
  valid_594292 = validateParameter(valid_594292, JString, required = true,
                                 default = nil)
  if valid_594292 != nil:
    section.add "functionId", valid_594292
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
  var valid_594293 = header.getOrDefault("X-Amz-Date")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Date", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Security-Token")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Security-Token", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Content-Sha256", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Algorithm")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Algorithm", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Signature")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Signature", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-SignedHeaders", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Credential")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Credential", valid_594299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594300: Call_GetFunction_594288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_594300.validator(path, query, header, formData, body)
  let scheme = call_594300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594300.url(scheme.get, call_594300.host, call_594300.base,
                         call_594300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594300, url, valid)

proc call*(call_594301: Call_GetFunction_594288; apiId: string; functionId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_594302 = newJObject()
  add(path_594302, "apiId", newJString(apiId))
  add(path_594302, "functionId", newJString(functionId))
  result = call_594301.call(path_594302, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_594288(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/functions/{functionId}",
                                        validator: validate_GetFunction_594289,
                                        base: "/", url: url_GetFunction_594290,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_594320 = ref object of OpenApiRestCall_593437
proc url_DeleteFunction_594322(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteFunction_594321(path: JsonNode; query: JsonNode;
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
  var valid_594323 = path.getOrDefault("apiId")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = nil)
  if valid_594323 != nil:
    section.add "apiId", valid_594323
  var valid_594324 = path.getOrDefault("functionId")
  valid_594324 = validateParameter(valid_594324, JString, required = true,
                                 default = nil)
  if valid_594324 != nil:
    section.add "functionId", valid_594324
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
  var valid_594325 = header.getOrDefault("X-Amz-Date")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Date", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Security-Token")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Security-Token", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Content-Sha256", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Algorithm")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Algorithm", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Signature")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Signature", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-SignedHeaders", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Credential")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Credential", valid_594331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594332: Call_DeleteFunction_594320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_594332.validator(path, query, header, formData, body)
  let scheme = call_594332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594332.url(scheme.get, call_594332.host, call_594332.base,
                         call_594332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594332, url, valid)

proc call*(call_594333: Call_DeleteFunction_594320; apiId: string; functionId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_594334 = newJObject()
  add(path_594334, "apiId", newJString(apiId))
  add(path_594334, "functionId", newJString(functionId))
  result = call_594333.call(path_594334, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_594320(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_594321, base: "/", url: url_DeleteFunction_594322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_594349 = ref object of OpenApiRestCall_593437
proc url_UpdateGraphqlApi_594351(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateGraphqlApi_594350(path: JsonNode; query: JsonNode;
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
  var valid_594352 = path.getOrDefault("apiId")
  valid_594352 = validateParameter(valid_594352, JString, required = true,
                                 default = nil)
  if valid_594352 != nil:
    section.add "apiId", valid_594352
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
  var valid_594353 = header.getOrDefault("X-Amz-Date")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Date", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Security-Token")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Security-Token", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Content-Sha256", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Algorithm")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Algorithm", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Signature")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Signature", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-SignedHeaders", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Credential")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Credential", valid_594359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594361: Call_UpdateGraphqlApi_594349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_594361.validator(path, query, header, formData, body)
  let scheme = call_594361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594361.url(scheme.get, call_594361.host, call_594361.base,
                         call_594361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594361, url, valid)

proc call*(call_594362: Call_UpdateGraphqlApi_594349; apiId: string; body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_594363 = newJObject()
  var body_594364 = newJObject()
  add(path_594363, "apiId", newJString(apiId))
  if body != nil:
    body_594364 = body
  result = call_594362.call(path_594363, nil, nil, nil, body_594364)

var updateGraphqlApi* = Call_UpdateGraphqlApi_594349(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_594350,
    base: "/", url: url_UpdateGraphqlApi_594351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_594335 = ref object of OpenApiRestCall_593437
proc url_GetGraphqlApi_594337(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetGraphqlApi_594336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594338 = path.getOrDefault("apiId")
  valid_594338 = validateParameter(valid_594338, JString, required = true,
                                 default = nil)
  if valid_594338 != nil:
    section.add "apiId", valid_594338
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
  var valid_594339 = header.getOrDefault("X-Amz-Date")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Date", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Security-Token")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Security-Token", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Content-Sha256", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Algorithm")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Algorithm", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Signature")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Signature", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-SignedHeaders", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Credential")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Credential", valid_594345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594346: Call_GetGraphqlApi_594335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_594346.validator(path, query, header, formData, body)
  let scheme = call_594346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594346.url(scheme.get, call_594346.host, call_594346.base,
                         call_594346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594346, url, valid)

proc call*(call_594347: Call_GetGraphqlApi_594335; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_594348 = newJObject()
  add(path_594348, "apiId", newJString(apiId))
  result = call_594347.call(path_594348, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_594335(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_594336, base: "/",
    url: url_GetGraphqlApi_594337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_594365 = ref object of OpenApiRestCall_593437
proc url_DeleteGraphqlApi_594367(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteGraphqlApi_594366(path: JsonNode; query: JsonNode;
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
  var valid_594368 = path.getOrDefault("apiId")
  valid_594368 = validateParameter(valid_594368, JString, required = true,
                                 default = nil)
  if valid_594368 != nil:
    section.add "apiId", valid_594368
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
  var valid_594369 = header.getOrDefault("X-Amz-Date")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Date", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Security-Token")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Security-Token", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Content-Sha256", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Algorithm")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Algorithm", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-Signature")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-Signature", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-SignedHeaders", valid_594374
  var valid_594375 = header.getOrDefault("X-Amz-Credential")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "X-Amz-Credential", valid_594375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594376: Call_DeleteGraphqlApi_594365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_594376.validator(path, query, header, formData, body)
  let scheme = call_594376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594376.url(scheme.get, call_594376.host, call_594376.base,
                         call_594376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594376, url, valid)

proc call*(call_594377: Call_DeleteGraphqlApi_594365; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_594378 = newJObject()
  add(path_594378, "apiId", newJString(apiId))
  result = call_594377.call(path_594378, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_594365(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_594366,
    base: "/", url: url_DeleteGraphqlApi_594367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_594395 = ref object of OpenApiRestCall_593437
proc url_UpdateResolver_594397(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateResolver_594396(path: JsonNode; query: JsonNode;
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
  var valid_594398 = path.getOrDefault("apiId")
  valid_594398 = validateParameter(valid_594398, JString, required = true,
                                 default = nil)
  if valid_594398 != nil:
    section.add "apiId", valid_594398
  var valid_594399 = path.getOrDefault("fieldName")
  valid_594399 = validateParameter(valid_594399, JString, required = true,
                                 default = nil)
  if valid_594399 != nil:
    section.add "fieldName", valid_594399
  var valid_594400 = path.getOrDefault("typeName")
  valid_594400 = validateParameter(valid_594400, JString, required = true,
                                 default = nil)
  if valid_594400 != nil:
    section.add "typeName", valid_594400
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
  var valid_594401 = header.getOrDefault("X-Amz-Date")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Date", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Security-Token")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Security-Token", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Content-Sha256", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Algorithm")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Algorithm", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Signature")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Signature", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-SignedHeaders", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Credential")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Credential", valid_594407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594409: Call_UpdateResolver_594395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_594409.validator(path, query, header, formData, body)
  let scheme = call_594409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594409.url(scheme.get, call_594409.host, call_594409.base,
                         call_594409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594409, url, valid)

proc call*(call_594410: Call_UpdateResolver_594395; apiId: string; fieldName: string;
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
  var path_594411 = newJObject()
  var body_594412 = newJObject()
  add(path_594411, "apiId", newJString(apiId))
  add(path_594411, "fieldName", newJString(fieldName))
  add(path_594411, "typeName", newJString(typeName))
  if body != nil:
    body_594412 = body
  result = call_594410.call(path_594411, nil, nil, nil, body_594412)

var updateResolver* = Call_UpdateResolver_594395(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_594396, base: "/", url: url_UpdateResolver_594397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_594379 = ref object of OpenApiRestCall_593437
proc url_GetResolver_594381(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_GetResolver_594380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594382 = path.getOrDefault("apiId")
  valid_594382 = validateParameter(valid_594382, JString, required = true,
                                 default = nil)
  if valid_594382 != nil:
    section.add "apiId", valid_594382
  var valid_594383 = path.getOrDefault("fieldName")
  valid_594383 = validateParameter(valid_594383, JString, required = true,
                                 default = nil)
  if valid_594383 != nil:
    section.add "fieldName", valid_594383
  var valid_594384 = path.getOrDefault("typeName")
  valid_594384 = validateParameter(valid_594384, JString, required = true,
                                 default = nil)
  if valid_594384 != nil:
    section.add "typeName", valid_594384
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
  var valid_594385 = header.getOrDefault("X-Amz-Date")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Date", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-Security-Token")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-Security-Token", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Content-Sha256", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-Algorithm")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-Algorithm", valid_594388
  var valid_594389 = header.getOrDefault("X-Amz-Signature")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Signature", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-SignedHeaders", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Credential")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Credential", valid_594391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594392: Call_GetResolver_594379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_594392.validator(path, query, header, formData, body)
  let scheme = call_594392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594392.url(scheme.get, call_594392.host, call_594392.base,
                         call_594392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594392, url, valid)

proc call*(call_594393: Call_GetResolver_594379; apiId: string; fieldName: string;
          typeName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The resolver type name.
  var path_594394 = newJObject()
  add(path_594394, "apiId", newJString(apiId))
  add(path_594394, "fieldName", newJString(fieldName))
  add(path_594394, "typeName", newJString(typeName))
  result = call_594393.call(path_594394, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_594379(name: "getResolver",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
                                        validator: validate_GetResolver_594380,
                                        base: "/", url: url_GetResolver_594381,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_594413 = ref object of OpenApiRestCall_593437
proc url_DeleteResolver_594415(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteResolver_594414(path: JsonNode; query: JsonNode;
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
  var valid_594416 = path.getOrDefault("apiId")
  valid_594416 = validateParameter(valid_594416, JString, required = true,
                                 default = nil)
  if valid_594416 != nil:
    section.add "apiId", valid_594416
  var valid_594417 = path.getOrDefault("fieldName")
  valid_594417 = validateParameter(valid_594417, JString, required = true,
                                 default = nil)
  if valid_594417 != nil:
    section.add "fieldName", valid_594417
  var valid_594418 = path.getOrDefault("typeName")
  valid_594418 = validateParameter(valid_594418, JString, required = true,
                                 default = nil)
  if valid_594418 != nil:
    section.add "typeName", valid_594418
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
  var valid_594419 = header.getOrDefault("X-Amz-Date")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Date", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-Security-Token")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Security-Token", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Content-Sha256", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Algorithm")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Algorithm", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Signature")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Signature", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-SignedHeaders", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Credential")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Credential", valid_594425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594426: Call_DeleteResolver_594413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_594426.validator(path, query, header, formData, body)
  let scheme = call_594426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594426.url(scheme.get, call_594426.host, call_594426.base,
                         call_594426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594426, url, valid)

proc call*(call_594427: Call_DeleteResolver_594413; apiId: string; fieldName: string;
          typeName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  var path_594428 = newJObject()
  add(path_594428, "apiId", newJString(apiId))
  add(path_594428, "fieldName", newJString(fieldName))
  add(path_594428, "typeName", newJString(typeName))
  result = call_594427.call(path_594428, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_594413(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_594414, base: "/", url: url_DeleteResolver_594415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_594429 = ref object of OpenApiRestCall_593437
proc url_UpdateType_594431(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_UpdateType_594430(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594432 = path.getOrDefault("apiId")
  valid_594432 = validateParameter(valid_594432, JString, required = true,
                                 default = nil)
  if valid_594432 != nil:
    section.add "apiId", valid_594432
  var valid_594433 = path.getOrDefault("typeName")
  valid_594433 = validateParameter(valid_594433, JString, required = true,
                                 default = nil)
  if valid_594433 != nil:
    section.add "typeName", valid_594433
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
  var valid_594434 = header.getOrDefault("X-Amz-Date")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Date", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-Security-Token")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Security-Token", valid_594435
  var valid_594436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Content-Sha256", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Algorithm")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Algorithm", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Signature")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Signature", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-SignedHeaders", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Credential")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Credential", valid_594440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594442: Call_UpdateType_594429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_594442.validator(path, query, header, formData, body)
  let scheme = call_594442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594442.url(scheme.get, call_594442.host, call_594442.base,
                         call_594442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594442, url, valid)

proc call*(call_594443: Call_UpdateType_594429; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_594444 = newJObject()
  var body_594445 = newJObject()
  add(path_594444, "apiId", newJString(apiId))
  add(path_594444, "typeName", newJString(typeName))
  if body != nil:
    body_594445 = body
  result = call_594443.call(path_594444, nil, nil, nil, body_594445)

var updateType* = Call_UpdateType_594429(name: "updateType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_UpdateType_594430,
                                      base: "/", url: url_UpdateType_594431,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_594446 = ref object of OpenApiRestCall_593437
proc url_DeleteType_594448(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_DeleteType_594447(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594449 = path.getOrDefault("apiId")
  valid_594449 = validateParameter(valid_594449, JString, required = true,
                                 default = nil)
  if valid_594449 != nil:
    section.add "apiId", valid_594449
  var valid_594450 = path.getOrDefault("typeName")
  valid_594450 = validateParameter(valid_594450, JString, required = true,
                                 default = nil)
  if valid_594450 != nil:
    section.add "typeName", valid_594450
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
  var valid_594451 = header.getOrDefault("X-Amz-Date")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Date", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Security-Token")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Security-Token", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Content-Sha256", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Algorithm")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Algorithm", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Signature")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Signature", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-SignedHeaders", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Credential")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Credential", valid_594457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594458: Call_DeleteType_594446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_594458.validator(path, query, header, formData, body)
  let scheme = call_594458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594458.url(scheme.get, call_594458.host, call_594458.base,
                         call_594458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594458, url, valid)

proc call*(call_594459: Call_DeleteType_594446; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_594460 = newJObject()
  add(path_594460, "apiId", newJString(apiId))
  add(path_594460, "typeName", newJString(typeName))
  result = call_594459.call(path_594460, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_594446(name: "deleteType",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_DeleteType_594447,
                                      base: "/", url: url_DeleteType_594448,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_594461 = ref object of OpenApiRestCall_593437
proc url_GetIntrospectionSchema_594463(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schema#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetIntrospectionSchema_594462(path: JsonNode; query: JsonNode;
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
  var valid_594464 = path.getOrDefault("apiId")
  valid_594464 = validateParameter(valid_594464, JString, required = true,
                                 default = nil)
  if valid_594464 != nil:
    section.add "apiId", valid_594464
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_594465 = query.getOrDefault("includeDirectives")
  valid_594465 = validateParameter(valid_594465, JBool, required = false, default = nil)
  if valid_594465 != nil:
    section.add "includeDirectives", valid_594465
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_594479 = query.getOrDefault("format")
  valid_594479 = validateParameter(valid_594479, JString, required = true,
                                 default = newJString("SDL"))
  if valid_594479 != nil:
    section.add "format", valid_594479
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
  var valid_594480 = header.getOrDefault("X-Amz-Date")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Date", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Security-Token")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Security-Token", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Content-Sha256", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-Algorithm")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Algorithm", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Signature")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Signature", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-SignedHeaders", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Credential")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Credential", valid_594486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594487: Call_GetIntrospectionSchema_594461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_594487.validator(path, query, header, formData, body)
  let scheme = call_594487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594487.url(scheme.get, call_594487.host, call_594487.base,
                         call_594487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594487, url, valid)

proc call*(call_594488: Call_GetIntrospectionSchema_594461; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_594489 = newJObject()
  var query_594490 = newJObject()
  add(query_594490, "includeDirectives", newJBool(includeDirectives))
  add(path_594489, "apiId", newJString(apiId))
  add(query_594490, "format", newJString(format))
  result = call_594488.call(path_594489, query_594490, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_594461(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_594462, base: "/",
    url: url_GetIntrospectionSchema_594463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_594505 = ref object of OpenApiRestCall_593437
proc url_StartSchemaCreation_594507(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schemacreation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_StartSchemaCreation_594506(path: JsonNode; query: JsonNode;
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
  var valid_594508 = path.getOrDefault("apiId")
  valid_594508 = validateParameter(valid_594508, JString, required = true,
                                 default = nil)
  if valid_594508 != nil:
    section.add "apiId", valid_594508
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
  var valid_594509 = header.getOrDefault("X-Amz-Date")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Date", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Security-Token")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Security-Token", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Content-Sha256", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Algorithm")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Algorithm", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-Signature")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-Signature", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-SignedHeaders", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Credential")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Credential", valid_594515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594517: Call_StartSchemaCreation_594505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_594517.validator(path, query, header, formData, body)
  let scheme = call_594517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594517.url(scheme.get, call_594517.host, call_594517.base,
                         call_594517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594517, url, valid)

proc call*(call_594518: Call_StartSchemaCreation_594505; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_594519 = newJObject()
  var body_594520 = newJObject()
  add(path_594519, "apiId", newJString(apiId))
  if body != nil:
    body_594520 = body
  result = call_594518.call(path_594519, nil, nil, nil, body_594520)

var startSchemaCreation* = Call_StartSchemaCreation_594505(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_594506, base: "/",
    url: url_StartSchemaCreation_594507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_594491 = ref object of OpenApiRestCall_593437
proc url_GetSchemaCreationStatus_594493(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schemacreation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetSchemaCreationStatus_594492(path: JsonNode; query: JsonNode;
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
  var valid_594494 = path.getOrDefault("apiId")
  valid_594494 = validateParameter(valid_594494, JString, required = true,
                                 default = nil)
  if valid_594494 != nil:
    section.add "apiId", valid_594494
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
  var valid_594495 = header.getOrDefault("X-Amz-Date")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Date", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-Security-Token")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Security-Token", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Content-Sha256", valid_594497
  var valid_594498 = header.getOrDefault("X-Amz-Algorithm")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-Algorithm", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Signature")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Signature", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-SignedHeaders", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Credential")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Credential", valid_594501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594502: Call_GetSchemaCreationStatus_594491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_594502.validator(path, query, header, formData, body)
  let scheme = call_594502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594502.url(scheme.get, call_594502.host, call_594502.base,
                         call_594502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594502, url, valid)

proc call*(call_594503: Call_GetSchemaCreationStatus_594491; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_594504 = newJObject()
  add(path_594504, "apiId", newJString(apiId))
  result = call_594503.call(path_594504, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_594491(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_594492, base: "/",
    url: url_GetSchemaCreationStatus_594493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_594521 = ref object of OpenApiRestCall_593437
proc url_GetType_594523(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_GetType_594522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594524 = path.getOrDefault("apiId")
  valid_594524 = validateParameter(valid_594524, JString, required = true,
                                 default = nil)
  if valid_594524 != nil:
    section.add "apiId", valid_594524
  var valid_594525 = path.getOrDefault("typeName")
  valid_594525 = validateParameter(valid_594525, JString, required = true,
                                 default = nil)
  if valid_594525 != nil:
    section.add "typeName", valid_594525
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_594526 = query.getOrDefault("format")
  valid_594526 = validateParameter(valid_594526, JString, required = true,
                                 default = newJString("SDL"))
  if valid_594526 != nil:
    section.add "format", valid_594526
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
  var valid_594527 = header.getOrDefault("X-Amz-Date")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Date", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-Security-Token")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-Security-Token", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Content-Sha256", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Algorithm")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Algorithm", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-SignedHeaders", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Credential")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Credential", valid_594533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594534: Call_GetType_594521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_594534.validator(path, query, header, formData, body)
  let scheme = call_594534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594534.url(scheme.get, call_594534.host, call_594534.base,
                         call_594534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594534, url, valid)

proc call*(call_594535: Call_GetType_594521; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_594536 = newJObject()
  var query_594537 = newJObject()
  add(path_594536, "apiId", newJString(apiId))
  add(path_594536, "typeName", newJString(typeName))
  add(query_594537, "format", newJString(format))
  result = call_594535.call(path_594536, query_594537, nil, nil, nil)

var getType* = Call_GetType_594521(name: "getType", meth: HttpMethod.HttpGet,
                                host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                validator: validate_GetType_594522, base: "/",
                                url: url_GetType_594523,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_594538 = ref object of OpenApiRestCall_593437
proc url_ListResolversByFunction_594540(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
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
  result.path = base & hydrated.get

proc validate_ListResolversByFunction_594539(path: JsonNode; query: JsonNode;
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
  var valid_594541 = path.getOrDefault("apiId")
  valid_594541 = validateParameter(valid_594541, JString, required = true,
                                 default = nil)
  if valid_594541 != nil:
    section.add "apiId", valid_594541
  var valid_594542 = path.getOrDefault("functionId")
  valid_594542 = validateParameter(valid_594542, JString, required = true,
                                 default = nil)
  if valid_594542 != nil:
    section.add "functionId", valid_594542
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  section = newJObject()
  var valid_594543 = query.getOrDefault("maxResults")
  valid_594543 = validateParameter(valid_594543, JInt, required = false, default = nil)
  if valid_594543 != nil:
    section.add "maxResults", valid_594543
  var valid_594544 = query.getOrDefault("nextToken")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "nextToken", valid_594544
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
  var valid_594545 = header.getOrDefault("X-Amz-Date")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Date", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Security-Token")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Security-Token", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Content-Sha256", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Algorithm")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Algorithm", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Signature")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Signature", valid_594549
  var valid_594550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-SignedHeaders", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Credential")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Credential", valid_594551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594552: Call_ListResolversByFunction_594538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_594552.validator(path, query, header, formData, body)
  let scheme = call_594552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594552.url(scheme.get, call_594552.host, call_594552.base,
                         call_594552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594552, url, valid)

proc call*(call_594553: Call_ListResolversByFunction_594538; apiId: string;
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
  var path_594554 = newJObject()
  var query_594555 = newJObject()
  add(path_594554, "apiId", newJString(apiId))
  add(path_594554, "functionId", newJString(functionId))
  add(query_594555, "maxResults", newJInt(maxResults))
  add(query_594555, "nextToken", newJString(nextToken))
  result = call_594553.call(path_594554, query_594555, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_594538(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_594539, base: "/",
    url: url_ListResolversByFunction_594540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594570 = ref object of OpenApiRestCall_593437
proc url_TagResource_594572(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_TagResource_594571(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594573 = path.getOrDefault("resourceArn")
  valid_594573 = validateParameter(valid_594573, JString, required = true,
                                 default = nil)
  if valid_594573 != nil:
    section.add "resourceArn", valid_594573
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
  var valid_594574 = header.getOrDefault("X-Amz-Date")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Date", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Security-Token")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Security-Token", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Content-Sha256", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Algorithm")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Algorithm", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Signature")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Signature", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-SignedHeaders", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Credential")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Credential", valid_594580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594582: Call_TagResource_594570; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_594582.validator(path, query, header, formData, body)
  let scheme = call_594582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594582.url(scheme.get, call_594582.host, call_594582.base,
                         call_594582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594582, url, valid)

proc call*(call_594583: Call_TagResource_594570; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_594584 = newJObject()
  var body_594585 = newJObject()
  if body != nil:
    body_594585 = body
  add(path_594584, "resourceArn", newJString(resourceArn))
  result = call_594583.call(path_594584, nil, nil, nil, body_594585)

var tagResource* = Call_TagResource_594570(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_594571,
                                        base: "/", url: url_TagResource_594572,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594556 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594558(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTagsForResource_594557(path: JsonNode; query: JsonNode;
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
  var valid_594559 = path.getOrDefault("resourceArn")
  valid_594559 = validateParameter(valid_594559, JString, required = true,
                                 default = nil)
  if valid_594559 != nil:
    section.add "resourceArn", valid_594559
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
  var valid_594560 = header.getOrDefault("X-Amz-Date")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Date", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Security-Token")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Security-Token", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Content-Sha256", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Algorithm")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Algorithm", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Signature")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Signature", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-SignedHeaders", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Credential")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Credential", valid_594566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594567: Call_ListTagsForResource_594556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_594567.validator(path, query, header, formData, body)
  let scheme = call_594567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594567.url(scheme.get, call_594567.host, call_594567.base,
                         call_594567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594567, url, valid)

proc call*(call_594568: Call_ListTagsForResource_594556; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_594569 = newJObject()
  add(path_594569, "resourceArn", newJString(resourceArn))
  result = call_594568.call(path_594569, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594556(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594557, base: "/",
    url: url_ListTagsForResource_594558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_594586 = ref object of OpenApiRestCall_593437
proc url_ListTypes_594588(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTypes_594587(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594589 = path.getOrDefault("apiId")
  valid_594589 = validateParameter(valid_594589, JString, required = true,
                                 default = nil)
  if valid_594589 != nil:
    section.add "apiId", valid_594589
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_594590 = query.getOrDefault("maxResults")
  valid_594590 = validateParameter(valid_594590, JInt, required = false, default = nil)
  if valid_594590 != nil:
    section.add "maxResults", valid_594590
  var valid_594591 = query.getOrDefault("nextToken")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "nextToken", valid_594591
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_594592 = query.getOrDefault("format")
  valid_594592 = validateParameter(valid_594592, JString, required = true,
                                 default = newJString("SDL"))
  if valid_594592 != nil:
    section.add "format", valid_594592
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
  var valid_594593 = header.getOrDefault("X-Amz-Date")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Date", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Security-Token")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Security-Token", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Content-Sha256", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Algorithm")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Algorithm", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Signature")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Signature", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-SignedHeaders", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-Credential")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Credential", valid_594599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594600: Call_ListTypes_594586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_594600.validator(path, query, header, formData, body)
  let scheme = call_594600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594600.url(scheme.get, call_594600.host, call_594600.base,
                         call_594600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594600, url, valid)

proc call*(call_594601: Call_ListTypes_594586; apiId: string; maxResults: int = 0;
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
  var path_594602 = newJObject()
  var query_594603 = newJObject()
  add(path_594602, "apiId", newJString(apiId))
  add(query_594603, "maxResults", newJInt(maxResults))
  add(query_594603, "nextToken", newJString(nextToken))
  add(query_594603, "format", newJString(format))
  result = call_594601.call(path_594602, query_594603, nil, nil, nil)

var listTypes* = Call_ListTypes_594586(name: "listTypes", meth: HttpMethod.HttpGet,
                                    host: "appsync.amazonaws.com",
                                    route: "/v1/apis/{apiId}/types#format",
                                    validator: validate_ListTypes_594587,
                                    base: "/", url: url_ListTypes_594588,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594604 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594606(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UntagResource_594605(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594607 = path.getOrDefault("resourceArn")
  valid_594607 = validateParameter(valid_594607, JString, required = true,
                                 default = nil)
  if valid_594607 != nil:
    section.add "resourceArn", valid_594607
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594608 = query.getOrDefault("tagKeys")
  valid_594608 = validateParameter(valid_594608, JArray, required = true, default = nil)
  if valid_594608 != nil:
    section.add "tagKeys", valid_594608
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
  var valid_594609 = header.getOrDefault("X-Amz-Date")
  valid_594609 = validateParameter(valid_594609, JString, required = false,
                                 default = nil)
  if valid_594609 != nil:
    section.add "X-Amz-Date", valid_594609
  var valid_594610 = header.getOrDefault("X-Amz-Security-Token")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Security-Token", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Content-Sha256", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Algorithm")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Algorithm", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Signature")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Signature", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-SignedHeaders", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Credential")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Credential", valid_594615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594616: Call_UntagResource_594604; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_594616.validator(path, query, header, formData, body)
  let scheme = call_594616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594616.url(scheme.get, call_594616.host, call_594616.base,
                         call_594616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594616, url, valid)

proc call*(call_594617: Call_UntagResource_594604; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_594618 = newJObject()
  var query_594619 = newJObject()
  if tagKeys != nil:
    query_594619.add "tagKeys", tagKeys
  add(path_594618, "resourceArn", newJString(resourceArn))
  result = call_594617.call(path_594618, query_594619, nil, nil, nil)

var untagResource* = Call_UntagResource_594604(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594605,
    base: "/", url: url_UntagResource_594606, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
