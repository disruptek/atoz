
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  Call_CreateApiKey_592976 = ref object of OpenApiRestCall_592364
proc url_CreateApiKey_592978(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiKey_592977(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592979 = path.getOrDefault("apiId")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = nil)
  if valid_592979 != nil:
    section.add "apiId", valid_592979
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
  var valid_592980 = header.getOrDefault("X-Amz-Signature")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Signature", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Content-Sha256", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Date")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Date", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Credential")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Credential", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Security-Token")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Security-Token", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Algorithm")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Algorithm", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-SignedHeaders", valid_592986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592988: Call_CreateApiKey_592976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_592988.validator(path, query, header, formData, body)
  let scheme = call_592988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592988.url(scheme.get, call_592988.host, call_592988.base,
                         call_592988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592988, url, valid)

proc call*(call_592989: Call_CreateApiKey_592976; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_592990 = newJObject()
  var body_592991 = newJObject()
  add(path_592990, "apiId", newJString(apiId))
  if body != nil:
    body_592991 = body
  result = call_592989.call(path_592990, nil, nil, nil, body_592991)

var createApiKey* = Call_CreateApiKey_592976(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_592977,
    base: "/", url: url_CreateApiKey_592978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_592703 = ref object of OpenApiRestCall_592364
proc url_ListApiKeys_592705(protocol: Scheme; host: string; base: string;
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

proc validate_ListApiKeys_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592831 = path.getOrDefault("apiId")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "apiId", valid_592831
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_592832 = query.getOrDefault("nextToken")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "nextToken", valid_592832
  var valid_592833 = query.getOrDefault("maxResults")
  valid_592833 = validateParameter(valid_592833, JInt, required = false, default = nil)
  if valid_592833 != nil:
    section.add "maxResults", valid_592833
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
  var valid_592834 = header.getOrDefault("X-Amz-Signature")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Signature", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Content-Sha256", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Date")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Date", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Credential")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Credential", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Security-Token")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Security-Token", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Algorithm")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Algorithm", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-SignedHeaders", valid_592840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592863: Call_ListApiKeys_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_592863.validator(path, query, header, formData, body)
  let scheme = call_592863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592863.url(scheme.get, call_592863.host, call_592863.base,
                         call_592863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592863, url, valid)

proc call*(call_592934: Call_ListApiKeys_592703; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_592935 = newJObject()
  var query_592937 = newJObject()
  add(query_592937, "nextToken", newJString(nextToken))
  add(path_592935, "apiId", newJString(apiId))
  add(query_592937, "maxResults", newJInt(maxResults))
  result = call_592934.call(path_592935, query_592937, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_592703(name: "listApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/apikeys",
                                        validator: validate_ListApiKeys_592704,
                                        base: "/", url: url_ListApiKeys_592705,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_593009 = ref object of OpenApiRestCall_592364
proc url_CreateDataSource_593011(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSource_593010(path: JsonNode; query: JsonNode;
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
  var valid_593012 = path.getOrDefault("apiId")
  valid_593012 = validateParameter(valid_593012, JString, required = true,
                                 default = nil)
  if valid_593012 != nil:
    section.add "apiId", valid_593012
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
  var valid_593013 = header.getOrDefault("X-Amz-Signature")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Signature", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Content-Sha256", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Date")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Date", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Credential")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Credential", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Security-Token")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Security-Token", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Algorithm")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Algorithm", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-SignedHeaders", valid_593019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593021: Call_CreateDataSource_593009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_593021.validator(path, query, header, formData, body)
  let scheme = call_593021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593021.url(scheme.get, call_593021.host, call_593021.base,
                         call_593021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593021, url, valid)

proc call*(call_593022: Call_CreateDataSource_593009; apiId: string; body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_593023 = newJObject()
  var body_593024 = newJObject()
  add(path_593023, "apiId", newJString(apiId))
  if body != nil:
    body_593024 = body
  result = call_593022.call(path_593023, nil, nil, nil, body_593024)

var createDataSource* = Call_CreateDataSource_593009(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_593010,
    base: "/", url: url_CreateDataSource_593011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_592992 = ref object of OpenApiRestCall_592364
proc url_ListDataSources_592994(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSources_592993(path: JsonNode; query: JsonNode;
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
  var valid_592995 = path.getOrDefault("apiId")
  valid_592995 = validateParameter(valid_592995, JString, required = true,
                                 default = nil)
  if valid_592995 != nil:
    section.add "apiId", valid_592995
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_592996 = query.getOrDefault("nextToken")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "nextToken", valid_592996
  var valid_592997 = query.getOrDefault("maxResults")
  valid_592997 = validateParameter(valid_592997, JInt, required = false, default = nil)
  if valid_592997 != nil:
    section.add "maxResults", valid_592997
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
  var valid_592998 = header.getOrDefault("X-Amz-Signature")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Signature", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Content-Sha256", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Date")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Date", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Credential")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Credential", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Security-Token")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Security-Token", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Algorithm")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Algorithm", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-SignedHeaders", valid_593004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593005: Call_ListDataSources_592992; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_593005.validator(path, query, header, formData, body)
  let scheme = call_593005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593005.url(scheme.get, call_593005.host, call_593005.base,
                         call_593005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593005, url, valid)

proc call*(call_593006: Call_ListDataSources_592992; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_593007 = newJObject()
  var query_593008 = newJObject()
  add(query_593008, "nextToken", newJString(nextToken))
  add(path_593007, "apiId", newJString(apiId))
  add(query_593008, "maxResults", newJInt(maxResults))
  result = call_593006.call(path_593007, query_593008, nil, nil, nil)

var listDataSources* = Call_ListDataSources_592992(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_592993,
    base: "/", url: url_ListDataSources_592994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_593042 = ref object of OpenApiRestCall_592364
proc url_CreateFunction_593044(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFunction_593043(path: JsonNode; query: JsonNode;
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
  var valid_593045 = path.getOrDefault("apiId")
  valid_593045 = validateParameter(valid_593045, JString, required = true,
                                 default = nil)
  if valid_593045 != nil:
    section.add "apiId", valid_593045
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
  var valid_593046 = header.getOrDefault("X-Amz-Signature")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Signature", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Content-Sha256", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Date")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Date", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Credential")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Credential", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Security-Token")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Security-Token", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Algorithm")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Algorithm", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-SignedHeaders", valid_593052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593054: Call_CreateFunction_593042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_593054.validator(path, query, header, formData, body)
  let scheme = call_593054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593054.url(scheme.get, call_593054.host, call_593054.base,
                         call_593054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593054, url, valid)

proc call*(call_593055: Call_CreateFunction_593042; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_593056 = newJObject()
  var body_593057 = newJObject()
  add(path_593056, "apiId", newJString(apiId))
  if body != nil:
    body_593057 = body
  result = call_593055.call(path_593056, nil, nil, nil, body_593057)

var createFunction* = Call_CreateFunction_593042(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_593043,
    base: "/", url: url_CreateFunction_593044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_593025 = ref object of OpenApiRestCall_592364
proc url_ListFunctions_593027(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctions_593026(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593028 = path.getOrDefault("apiId")
  valid_593028 = validateParameter(valid_593028, JString, required = true,
                                 default = nil)
  if valid_593028 != nil:
    section.add "apiId", valid_593028
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_593029 = query.getOrDefault("nextToken")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "nextToken", valid_593029
  var valid_593030 = query.getOrDefault("maxResults")
  valid_593030 = validateParameter(valid_593030, JInt, required = false, default = nil)
  if valid_593030 != nil:
    section.add "maxResults", valid_593030
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
  var valid_593031 = header.getOrDefault("X-Amz-Signature")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Signature", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Content-Sha256", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Date")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Date", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Credential")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Credential", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Security-Token")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Security-Token", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Algorithm")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Algorithm", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-SignedHeaders", valid_593037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593038: Call_ListFunctions_593025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_593038.validator(path, query, header, formData, body)
  let scheme = call_593038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593038.url(scheme.get, call_593038.host, call_593038.base,
                         call_593038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593038, url, valid)

proc call*(call_593039: Call_ListFunctions_593025; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_593040 = newJObject()
  var query_593041 = newJObject()
  add(query_593041, "nextToken", newJString(nextToken))
  add(path_593040, "apiId", newJString(apiId))
  add(query_593041, "maxResults", newJInt(maxResults))
  result = call_593039.call(path_593040, query_593041, nil, nil, nil)

var listFunctions* = Call_ListFunctions_593025(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_593026,
    base: "/", url: url_ListFunctions_593027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_593073 = ref object of OpenApiRestCall_592364
proc url_CreateGraphqlApi_593075(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGraphqlApi_593074(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593076 = header.getOrDefault("X-Amz-Signature")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Signature", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Content-Sha256", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Date")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Date", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Credential")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Credential", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Security-Token")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Security-Token", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Algorithm")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Algorithm", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-SignedHeaders", valid_593082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593084: Call_CreateGraphqlApi_593073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_593084.validator(path, query, header, formData, body)
  let scheme = call_593084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593084.url(scheme.get, call_593084.host, call_593084.base,
                         call_593084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593084, url, valid)

proc call*(call_593085: Call_CreateGraphqlApi_593073; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_593086 = newJObject()
  if body != nil:
    body_593086 = body
  result = call_593085.call(nil, nil, nil, nil, body_593086)

var createGraphqlApi* = Call_CreateGraphqlApi_593073(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_593074, base: "/",
    url: url_CreateGraphqlApi_593075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_593058 = ref object of OpenApiRestCall_592364
proc url_ListGraphqlApis_593060(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGraphqlApis_593059(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists your GraphQL APIs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_593061 = query.getOrDefault("nextToken")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "nextToken", valid_593061
  var valid_593062 = query.getOrDefault("maxResults")
  valid_593062 = validateParameter(valid_593062, JInt, required = false, default = nil)
  if valid_593062 != nil:
    section.add "maxResults", valid_593062
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
  var valid_593063 = header.getOrDefault("X-Amz-Signature")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Signature", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Content-Sha256", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Date")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Date", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Credential")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Credential", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Security-Token")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Security-Token", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Algorithm")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Algorithm", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-SignedHeaders", valid_593069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593070: Call_ListGraphqlApis_593058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_593070.validator(path, query, header, formData, body)
  let scheme = call_593070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593070.url(scheme.get, call_593070.host, call_593070.base,
                         call_593070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593070, url, valid)

proc call*(call_593071: Call_ListGraphqlApis_593058; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var query_593072 = newJObject()
  add(query_593072, "nextToken", newJString(nextToken))
  add(query_593072, "maxResults", newJInt(maxResults))
  result = call_593071.call(nil, query_593072, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_593058(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_593059, base: "/", url: url_ListGraphqlApis_593060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_593105 = ref object of OpenApiRestCall_592364
proc url_CreateResolver_593107(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResolver_593106(path: JsonNode; query: JsonNode;
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
  var valid_593108 = path.getOrDefault("apiId")
  valid_593108 = validateParameter(valid_593108, JString, required = true,
                                 default = nil)
  if valid_593108 != nil:
    section.add "apiId", valid_593108
  var valid_593109 = path.getOrDefault("typeName")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = nil)
  if valid_593109 != nil:
    section.add "typeName", valid_593109
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
  var valid_593110 = header.getOrDefault("X-Amz-Signature")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Signature", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Content-Sha256", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Date")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Date", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Credential")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Credential", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Security-Token")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Security-Token", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Algorithm")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Algorithm", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-SignedHeaders", valid_593116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593118: Call_CreateResolver_593105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_593118.validator(path, query, header, formData, body)
  let scheme = call_593118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593118.url(scheme.get, call_593118.host, call_593118.base,
                         call_593118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593118, url, valid)

proc call*(call_593119: Call_CreateResolver_593105; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_593120 = newJObject()
  var body_593121 = newJObject()
  add(path_593120, "apiId", newJString(apiId))
  add(path_593120, "typeName", newJString(typeName))
  if body != nil:
    body_593121 = body
  result = call_593119.call(path_593120, nil, nil, nil, body_593121)

var createResolver* = Call_CreateResolver_593105(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_593106, base: "/", url: url_CreateResolver_593107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_593087 = ref object of OpenApiRestCall_592364
proc url_ListResolvers_593089(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolvers_593088(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593090 = path.getOrDefault("apiId")
  valid_593090 = validateParameter(valid_593090, JString, required = true,
                                 default = nil)
  if valid_593090 != nil:
    section.add "apiId", valid_593090
  var valid_593091 = path.getOrDefault("typeName")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = nil)
  if valid_593091 != nil:
    section.add "typeName", valid_593091
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_593092 = query.getOrDefault("nextToken")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "nextToken", valid_593092
  var valid_593093 = query.getOrDefault("maxResults")
  valid_593093 = validateParameter(valid_593093, JInt, required = false, default = nil)
  if valid_593093 != nil:
    section.add "maxResults", valid_593093
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
  var valid_593094 = header.getOrDefault("X-Amz-Signature")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Signature", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Content-Sha256", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Date")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Date", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Credential")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Credential", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Security-Token")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Security-Token", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Algorithm")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Algorithm", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-SignedHeaders", valid_593100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593101: Call_ListResolvers_593087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_593101.validator(path, query, header, formData, body)
  let scheme = call_593101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593101.url(scheme.get, call_593101.host, call_593101.base,
                         call_593101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593101, url, valid)

proc call*(call_593102: Call_ListResolvers_593087; apiId: string; typeName: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listResolvers
  ## Lists the resolvers for a given API and type.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_593103 = newJObject()
  var query_593104 = newJObject()
  add(query_593104, "nextToken", newJString(nextToken))
  add(path_593103, "apiId", newJString(apiId))
  add(path_593103, "typeName", newJString(typeName))
  add(query_593104, "maxResults", newJInt(maxResults))
  result = call_593102.call(path_593103, query_593104, nil, nil, nil)

var listResolvers* = Call_ListResolvers_593087(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_593088, base: "/", url: url_ListResolvers_593089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_593122 = ref object of OpenApiRestCall_592364
proc url_CreateType_593124(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateType_593123(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593125 = path.getOrDefault("apiId")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = nil)
  if valid_593125 != nil:
    section.add "apiId", valid_593125
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
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593134: Call_CreateType_593122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_CreateType_593122; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_593136 = newJObject()
  var body_593137 = newJObject()
  add(path_593136, "apiId", newJString(apiId))
  if body != nil:
    body_593137 = body
  result = call_593135.call(path_593136, nil, nil, nil, body_593137)

var createType* = Call_CreateType_593122(name: "createType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types",
                                      validator: validate_CreateType_593123,
                                      base: "/", url: url_CreateType_593124,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_593138 = ref object of OpenApiRestCall_592364
proc url_UpdateApiKey_593140(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_593139(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The API key ID.
  ##   apiId: JString (required)
  ##        : The ID for the GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_593141 = path.getOrDefault("id")
  valid_593141 = validateParameter(valid_593141, JString, required = true,
                                 default = nil)
  if valid_593141 != nil:
    section.add "id", valid_593141
  var valid_593142 = path.getOrDefault("apiId")
  valid_593142 = validateParameter(valid_593142, JString, required = true,
                                 default = nil)
  if valid_593142 != nil:
    section.add "apiId", valid_593142
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
  var valid_593143 = header.getOrDefault("X-Amz-Signature")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Signature", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Content-Sha256", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Date")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Date", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Credential")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Credential", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Security-Token")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Security-Token", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Algorithm")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Algorithm", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-SignedHeaders", valid_593149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593151: Call_UpdateApiKey_593138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_593151.validator(path, query, header, formData, body)
  let scheme = call_593151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593151.url(scheme.get, call_593151.host, call_593151.base,
                         call_593151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593151, url, valid)

proc call*(call_593152: Call_UpdateApiKey_593138; id: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   id: string (required)
  ##     : The API key ID.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   body: JObject (required)
  var path_593153 = newJObject()
  var body_593154 = newJObject()
  add(path_593153, "id", newJString(id))
  add(path_593153, "apiId", newJString(apiId))
  if body != nil:
    body_593154 = body
  result = call_593152.call(path_593153, nil, nil, nil, body_593154)

var updateApiKey* = Call_UpdateApiKey_593138(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_593139,
    base: "/", url: url_UpdateApiKey_593140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_593155 = ref object of OpenApiRestCall_592364
proc url_DeleteApiKey_593157(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_593156(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the API key.
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_593158 = path.getOrDefault("id")
  valid_593158 = validateParameter(valid_593158, JString, required = true,
                                 default = nil)
  if valid_593158 != nil:
    section.add "id", valid_593158
  var valid_593159 = path.getOrDefault("apiId")
  valid_593159 = validateParameter(valid_593159, JString, required = true,
                                 default = nil)
  if valid_593159 != nil:
    section.add "apiId", valid_593159
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
  var valid_593160 = header.getOrDefault("X-Amz-Signature")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Signature", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Content-Sha256", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Date")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Date", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Credential")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Credential", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Security-Token")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Security-Token", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Algorithm")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Algorithm", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-SignedHeaders", valid_593166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593167: Call_DeleteApiKey_593155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_593167.validator(path, query, header, formData, body)
  let scheme = call_593167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593167.url(scheme.get, call_593167.host, call_593167.base,
                         call_593167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593167, url, valid)

proc call*(call_593168: Call_DeleteApiKey_593155; id: string; apiId: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   id: string (required)
  ##     : The ID for the API key.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_593169 = newJObject()
  add(path_593169, "id", newJString(id))
  add(path_593169, "apiId", newJString(apiId))
  result = call_593168.call(path_593169, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_593155(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_593156,
    base: "/", url: url_DeleteApiKey_593157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_593185 = ref object of OpenApiRestCall_592364
proc url_UpdateDataSource_593187(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSource_593186(path: JsonNode; query: JsonNode;
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
  var valid_593188 = path.getOrDefault("apiId")
  valid_593188 = validateParameter(valid_593188, JString, required = true,
                                 default = nil)
  if valid_593188 != nil:
    section.add "apiId", valid_593188
  var valid_593189 = path.getOrDefault("name")
  valid_593189 = validateParameter(valid_593189, JString, required = true,
                                 default = nil)
  if valid_593189 != nil:
    section.add "name", valid_593189
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
  var valid_593190 = header.getOrDefault("X-Amz-Signature")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Signature", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Content-Sha256", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Date")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Date", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Credential")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Credential", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Security-Token")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Security-Token", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Algorithm")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Algorithm", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-SignedHeaders", valid_593196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593198: Call_UpdateDataSource_593185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_593198.validator(path, query, header, formData, body)
  let scheme = call_593198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593198.url(scheme.get, call_593198.host, call_593198.base,
                         call_593198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593198, url, valid)

proc call*(call_593199: Call_UpdateDataSource_593185; apiId: string; name: string;
          body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_593200 = newJObject()
  var body_593201 = newJObject()
  add(path_593200, "apiId", newJString(apiId))
  add(path_593200, "name", newJString(name))
  if body != nil:
    body_593201 = body
  result = call_593199.call(path_593200, nil, nil, nil, body_593201)

var updateDataSource* = Call_UpdateDataSource_593185(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_593186, base: "/",
    url: url_UpdateDataSource_593187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_593170 = ref object of OpenApiRestCall_592364
proc url_GetDataSource_593172(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataSource_593171(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593173 = path.getOrDefault("apiId")
  valid_593173 = validateParameter(valid_593173, JString, required = true,
                                 default = nil)
  if valid_593173 != nil:
    section.add "apiId", valid_593173
  var valid_593174 = path.getOrDefault("name")
  valid_593174 = validateParameter(valid_593174, JString, required = true,
                                 default = nil)
  if valid_593174 != nil:
    section.add "name", valid_593174
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
  var valid_593175 = header.getOrDefault("X-Amz-Signature")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Signature", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Content-Sha256", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Date")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Date", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Credential")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Credential", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Security-Token")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Security-Token", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Algorithm")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Algorithm", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-SignedHeaders", valid_593181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593182: Call_GetDataSource_593170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_593182.validator(path, query, header, formData, body)
  let scheme = call_593182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593182.url(scheme.get, call_593182.host, call_593182.base,
                         call_593182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593182, url, valid)

proc call*(call_593183: Call_GetDataSource_593170; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_593184 = newJObject()
  add(path_593184, "apiId", newJString(apiId))
  add(path_593184, "name", newJString(name))
  result = call_593183.call(path_593184, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_593170(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_593171, base: "/", url: url_GetDataSource_593172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_593202 = ref object of OpenApiRestCall_592364
proc url_DeleteDataSource_593204(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSource_593203(path: JsonNode; query: JsonNode;
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
  var valid_593205 = path.getOrDefault("apiId")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = nil)
  if valid_593205 != nil:
    section.add "apiId", valid_593205
  var valid_593206 = path.getOrDefault("name")
  valid_593206 = validateParameter(valid_593206, JString, required = true,
                                 default = nil)
  if valid_593206 != nil:
    section.add "name", valid_593206
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
  var valid_593207 = header.getOrDefault("X-Amz-Signature")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Signature", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Content-Sha256", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Date")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Date", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Credential")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Credential", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Security-Token")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Security-Token", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Algorithm")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Algorithm", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-SignedHeaders", valid_593213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593214: Call_DeleteDataSource_593202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_593214.validator(path, query, header, formData, body)
  let scheme = call_593214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593214.url(scheme.get, call_593214.host, call_593214.base,
                         call_593214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593214, url, valid)

proc call*(call_593215: Call_DeleteDataSource_593202; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_593216 = newJObject()
  add(path_593216, "apiId", newJString(apiId))
  add(path_593216, "name", newJString(name))
  result = call_593215.call(path_593216, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_593202(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_593203, base: "/",
    url: url_DeleteDataSource_593204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_593232 = ref object of OpenApiRestCall_592364
proc url_UpdateFunction_593234(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFunction_593233(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a <code>Function</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The function ID.
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_593235 = path.getOrDefault("functionId")
  valid_593235 = validateParameter(valid_593235, JString, required = true,
                                 default = nil)
  if valid_593235 != nil:
    section.add "functionId", valid_593235
  var valid_593236 = path.getOrDefault("apiId")
  valid_593236 = validateParameter(valid_593236, JString, required = true,
                                 default = nil)
  if valid_593236 != nil:
    section.add "apiId", valid_593236
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
  var valid_593237 = header.getOrDefault("X-Amz-Signature")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Signature", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Content-Sha256", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Date")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Date", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Credential")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Credential", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Security-Token")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Security-Token", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Algorithm")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Algorithm", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-SignedHeaders", valid_593243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593245: Call_UpdateFunction_593232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_593245.validator(path, query, header, formData, body)
  let scheme = call_593245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593245.url(scheme.get, call_593245.host, call_593245.base,
                         call_593245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593245, url, valid)

proc call*(call_593246: Call_UpdateFunction_593232; functionId: string;
          apiId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_593247 = newJObject()
  var body_593248 = newJObject()
  add(path_593247, "functionId", newJString(functionId))
  add(path_593247, "apiId", newJString(apiId))
  if body != nil:
    body_593248 = body
  result = call_593246.call(path_593247, nil, nil, nil, body_593248)

var updateFunction* = Call_UpdateFunction_593232(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_593233, base: "/", url: url_UpdateFunction_593234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_593217 = ref object of OpenApiRestCall_592364
proc url_GetFunction_593219(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_593218(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Get a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_593220 = path.getOrDefault("functionId")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "functionId", valid_593220
  var valid_593221 = path.getOrDefault("apiId")
  valid_593221 = validateParameter(valid_593221, JString, required = true,
                                 default = nil)
  if valid_593221 != nil:
    section.add "apiId", valid_593221
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
  var valid_593222 = header.getOrDefault("X-Amz-Signature")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Signature", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Content-Sha256", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Date")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Date", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Credential")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Credential", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Security-Token")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Security-Token", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Algorithm")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Algorithm", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-SignedHeaders", valid_593228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593229: Call_GetFunction_593217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_593229.validator(path, query, header, formData, body)
  let scheme = call_593229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593229.url(scheme.get, call_593229.host, call_593229.base,
                         call_593229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593229, url, valid)

proc call*(call_593230: Call_GetFunction_593217; functionId: string; apiId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_593231 = newJObject()
  add(path_593231, "functionId", newJString(functionId))
  add(path_593231, "apiId", newJString(apiId))
  result = call_593230.call(path_593231, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_593217(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/functions/{functionId}",
                                        validator: validate_GetFunction_593218,
                                        base: "/", url: url_GetFunction_593219,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_593249 = ref object of OpenApiRestCall_592364
proc url_DeleteFunction_593251(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_593250(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_593252 = path.getOrDefault("functionId")
  valid_593252 = validateParameter(valid_593252, JString, required = true,
                                 default = nil)
  if valid_593252 != nil:
    section.add "functionId", valid_593252
  var valid_593253 = path.getOrDefault("apiId")
  valid_593253 = validateParameter(valid_593253, JString, required = true,
                                 default = nil)
  if valid_593253 != nil:
    section.add "apiId", valid_593253
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
  var valid_593254 = header.getOrDefault("X-Amz-Signature")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Signature", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Content-Sha256", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-Date")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Date", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Credential")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Credential", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Security-Token")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Security-Token", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Algorithm")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Algorithm", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-SignedHeaders", valid_593260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593261: Call_DeleteFunction_593249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_593261.validator(path, query, header, formData, body)
  let scheme = call_593261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593261.url(scheme.get, call_593261.host, call_593261.base,
                         call_593261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593261, url, valid)

proc call*(call_593262: Call_DeleteFunction_593249; functionId: string; apiId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_593263 = newJObject()
  add(path_593263, "functionId", newJString(functionId))
  add(path_593263, "apiId", newJString(apiId))
  result = call_593262.call(path_593263, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_593249(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_593250, base: "/", url: url_DeleteFunction_593251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_593278 = ref object of OpenApiRestCall_592364
proc url_UpdateGraphqlApi_593280(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGraphqlApi_593279(path: JsonNode; query: JsonNode;
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
  var valid_593281 = path.getOrDefault("apiId")
  valid_593281 = validateParameter(valid_593281, JString, required = true,
                                 default = nil)
  if valid_593281 != nil:
    section.add "apiId", valid_593281
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
  var valid_593282 = header.getOrDefault("X-Amz-Signature")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Signature", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Content-Sha256", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-Date")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Date", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Credential")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Credential", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Security-Token")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Security-Token", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Algorithm")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Algorithm", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-SignedHeaders", valid_593288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593290: Call_UpdateGraphqlApi_593278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_593290.validator(path, query, header, formData, body)
  let scheme = call_593290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593290.url(scheme.get, call_593290.host, call_593290.base,
                         call_593290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593290, url, valid)

proc call*(call_593291: Call_UpdateGraphqlApi_593278; apiId: string; body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_593292 = newJObject()
  var body_593293 = newJObject()
  add(path_593292, "apiId", newJString(apiId))
  if body != nil:
    body_593293 = body
  result = call_593291.call(path_593292, nil, nil, nil, body_593293)

var updateGraphqlApi* = Call_UpdateGraphqlApi_593278(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_593279,
    base: "/", url: url_UpdateGraphqlApi_593280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_593264 = ref object of OpenApiRestCall_592364
proc url_GetGraphqlApi_593266(protocol: Scheme; host: string; base: string;
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

proc validate_GetGraphqlApi_593265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593267 = path.getOrDefault("apiId")
  valid_593267 = validateParameter(valid_593267, JString, required = true,
                                 default = nil)
  if valid_593267 != nil:
    section.add "apiId", valid_593267
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
  var valid_593268 = header.getOrDefault("X-Amz-Signature")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Signature", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Content-Sha256", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Date")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Date", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Credential")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Credential", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Security-Token")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Security-Token", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Algorithm")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Algorithm", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-SignedHeaders", valid_593274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593275: Call_GetGraphqlApi_593264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_593275.validator(path, query, header, formData, body)
  let scheme = call_593275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593275.url(scheme.get, call_593275.host, call_593275.base,
                         call_593275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593275, url, valid)

proc call*(call_593276: Call_GetGraphqlApi_593264; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_593277 = newJObject()
  add(path_593277, "apiId", newJString(apiId))
  result = call_593276.call(path_593277, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_593264(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_593265, base: "/",
    url: url_GetGraphqlApi_593266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_593294 = ref object of OpenApiRestCall_592364
proc url_DeleteGraphqlApi_593296(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGraphqlApi_593295(path: JsonNode; query: JsonNode;
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
  var valid_593297 = path.getOrDefault("apiId")
  valid_593297 = validateParameter(valid_593297, JString, required = true,
                                 default = nil)
  if valid_593297 != nil:
    section.add "apiId", valid_593297
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
  var valid_593298 = header.getOrDefault("X-Amz-Signature")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Signature", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Content-Sha256", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Date")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Date", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Credential")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Credential", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Security-Token")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Security-Token", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Algorithm")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Algorithm", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-SignedHeaders", valid_593304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593305: Call_DeleteGraphqlApi_593294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_593305.validator(path, query, header, formData, body)
  let scheme = call_593305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593305.url(scheme.get, call_593305.host, call_593305.base,
                         call_593305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593305, url, valid)

proc call*(call_593306: Call_DeleteGraphqlApi_593294; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_593307 = newJObject()
  add(path_593307, "apiId", newJString(apiId))
  result = call_593306.call(path_593307, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_593294(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_593295,
    base: "/", url: url_DeleteGraphqlApi_593296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_593324 = ref object of OpenApiRestCall_592364
proc url_UpdateResolver_593326(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResolver_593325(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The new type name.
  ##   fieldName: JString (required)
  ##            : The new field name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593327 = path.getOrDefault("apiId")
  valid_593327 = validateParameter(valid_593327, JString, required = true,
                                 default = nil)
  if valid_593327 != nil:
    section.add "apiId", valid_593327
  var valid_593328 = path.getOrDefault("typeName")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = nil)
  if valid_593328 != nil:
    section.add "typeName", valid_593328
  var valid_593329 = path.getOrDefault("fieldName")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = nil)
  if valid_593329 != nil:
    section.add "fieldName", valid_593329
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
  var valid_593330 = header.getOrDefault("X-Amz-Signature")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Signature", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Content-Sha256", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Date")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Date", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Credential")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Credential", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Security-Token")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Security-Token", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Algorithm")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Algorithm", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-SignedHeaders", valid_593336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_UpdateResolver_593324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_UpdateResolver_593324; apiId: string; typeName: string;
          body: JsonNode; fieldName: string): Recallable =
  ## updateResolver
  ## Updates a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  ##   fieldName: string (required)
  ##            : The new field name.
  var path_593340 = newJObject()
  var body_593341 = newJObject()
  add(path_593340, "apiId", newJString(apiId))
  add(path_593340, "typeName", newJString(typeName))
  if body != nil:
    body_593341 = body
  add(path_593340, "fieldName", newJString(fieldName))
  result = call_593339.call(path_593340, nil, nil, nil, body_593341)

var updateResolver* = Call_UpdateResolver_593324(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_593325, base: "/", url: url_UpdateResolver_593326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_593308 = ref object of OpenApiRestCall_592364
proc url_GetResolver_593310(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolver_593309(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The resolver type name.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593311 = path.getOrDefault("apiId")
  valid_593311 = validateParameter(valid_593311, JString, required = true,
                                 default = nil)
  if valid_593311 != nil:
    section.add "apiId", valid_593311
  var valid_593312 = path.getOrDefault("typeName")
  valid_593312 = validateParameter(valid_593312, JString, required = true,
                                 default = nil)
  if valid_593312 != nil:
    section.add "typeName", valid_593312
  var valid_593313 = path.getOrDefault("fieldName")
  valid_593313 = validateParameter(valid_593313, JString, required = true,
                                 default = nil)
  if valid_593313 != nil:
    section.add "fieldName", valid_593313
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
  var valid_593314 = header.getOrDefault("X-Amz-Signature")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Signature", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Content-Sha256", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Date")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Date", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Credential")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Credential", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Security-Token")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Security-Token", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Algorithm")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Algorithm", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-SignedHeaders", valid_593320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593321: Call_GetResolver_593308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_593321.validator(path, query, header, formData, body)
  let scheme = call_593321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593321.url(scheme.get, call_593321.host, call_593321.base,
                         call_593321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593321, url, valid)

proc call*(call_593322: Call_GetResolver_593308; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The resolver type name.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_593323 = newJObject()
  add(path_593323, "apiId", newJString(apiId))
  add(path_593323, "typeName", newJString(typeName))
  add(path_593323, "fieldName", newJString(fieldName))
  result = call_593322.call(path_593323, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_593308(name: "getResolver",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
                                        validator: validate_GetResolver_593309,
                                        base: "/", url: url_GetResolver_593310,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_593342 = ref object of OpenApiRestCall_592364
proc url_DeleteResolver_593344(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResolver_593343(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The name of the resolver type.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593345 = path.getOrDefault("apiId")
  valid_593345 = validateParameter(valid_593345, JString, required = true,
                                 default = nil)
  if valid_593345 != nil:
    section.add "apiId", valid_593345
  var valid_593346 = path.getOrDefault("typeName")
  valid_593346 = validateParameter(valid_593346, JString, required = true,
                                 default = nil)
  if valid_593346 != nil:
    section.add "typeName", valid_593346
  var valid_593347 = path.getOrDefault("fieldName")
  valid_593347 = validateParameter(valid_593347, JString, required = true,
                                 default = nil)
  if valid_593347 != nil:
    section.add "fieldName", valid_593347
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
  var valid_593348 = header.getOrDefault("X-Amz-Signature")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Signature", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Content-Sha256", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Date")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Date", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Credential")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Credential", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Security-Token")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Security-Token", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Algorithm")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Algorithm", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-SignedHeaders", valid_593354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593355: Call_DeleteResolver_593342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_593355.validator(path, query, header, formData, body)
  let scheme = call_593355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593355.url(scheme.get, call_593355.host, call_593355.base,
                         call_593355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593355, url, valid)

proc call*(call_593356: Call_DeleteResolver_593342; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_593357 = newJObject()
  add(path_593357, "apiId", newJString(apiId))
  add(path_593357, "typeName", newJString(typeName))
  add(path_593357, "fieldName", newJString(fieldName))
  result = call_593356.call(path_593357, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_593342(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_593343, base: "/", url: url_DeleteResolver_593344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_593358 = ref object of OpenApiRestCall_592364
proc url_UpdateType_593360(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateType_593359(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593361 = path.getOrDefault("apiId")
  valid_593361 = validateParameter(valid_593361, JString, required = true,
                                 default = nil)
  if valid_593361 != nil:
    section.add "apiId", valid_593361
  var valid_593362 = path.getOrDefault("typeName")
  valid_593362 = validateParameter(valid_593362, JString, required = true,
                                 default = nil)
  if valid_593362 != nil:
    section.add "typeName", valid_593362
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
  var valid_593363 = header.getOrDefault("X-Amz-Signature")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Signature", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Content-Sha256", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Date")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Date", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Credential")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Credential", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Security-Token")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Security-Token", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Algorithm")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Algorithm", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-SignedHeaders", valid_593369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593371: Call_UpdateType_593358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_593371.validator(path, query, header, formData, body)
  let scheme = call_593371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593371.url(scheme.get, call_593371.host, call_593371.base,
                         call_593371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593371, url, valid)

proc call*(call_593372: Call_UpdateType_593358; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_593373 = newJObject()
  var body_593374 = newJObject()
  add(path_593373, "apiId", newJString(apiId))
  add(path_593373, "typeName", newJString(typeName))
  if body != nil:
    body_593374 = body
  result = call_593372.call(path_593373, nil, nil, nil, body_593374)

var updateType* = Call_UpdateType_593358(name: "updateType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_UpdateType_593359,
                                      base: "/", url: url_UpdateType_593360,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_593375 = ref object of OpenApiRestCall_592364
proc url_DeleteType_593377(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteType_593376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593378 = path.getOrDefault("apiId")
  valid_593378 = validateParameter(valid_593378, JString, required = true,
                                 default = nil)
  if valid_593378 != nil:
    section.add "apiId", valid_593378
  var valid_593379 = path.getOrDefault("typeName")
  valid_593379 = validateParameter(valid_593379, JString, required = true,
                                 default = nil)
  if valid_593379 != nil:
    section.add "typeName", valid_593379
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
  var valid_593380 = header.getOrDefault("X-Amz-Signature")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-Signature", valid_593380
  var valid_593381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Content-Sha256", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Date")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Date", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Credential")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Credential", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Security-Token")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Security-Token", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Algorithm")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Algorithm", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-SignedHeaders", valid_593386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593387: Call_DeleteType_593375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_593387.validator(path, query, header, formData, body)
  let scheme = call_593387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593387.url(scheme.get, call_593387.host, call_593387.base,
                         call_593387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593387, url, valid)

proc call*(call_593388: Call_DeleteType_593375; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_593389 = newJObject()
  add(path_593389, "apiId", newJString(apiId))
  add(path_593389, "typeName", newJString(typeName))
  result = call_593388.call(path_593389, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_593375(name: "deleteType",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_DeleteType_593376,
                                      base: "/", url: url_DeleteType_593377,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_593390 = ref object of OpenApiRestCall_592364
proc url_GetIntrospectionSchema_593392(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntrospectionSchema_593391(path: JsonNode; query: JsonNode;
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
  var valid_593393 = path.getOrDefault("apiId")
  valid_593393 = validateParameter(valid_593393, JString, required = true,
                                 default = nil)
  if valid_593393 != nil:
    section.add "apiId", valid_593393
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_593394 = query.getOrDefault("includeDirectives")
  valid_593394 = validateParameter(valid_593394, JBool, required = false, default = nil)
  if valid_593394 != nil:
    section.add "includeDirectives", valid_593394
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_593408 = query.getOrDefault("format")
  valid_593408 = validateParameter(valid_593408, JString, required = true,
                                 default = newJString("SDL"))
  if valid_593408 != nil:
    section.add "format", valid_593408
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
  var valid_593409 = header.getOrDefault("X-Amz-Signature")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Signature", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Content-Sha256", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Date")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Date", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Credential")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Credential", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Security-Token")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Security-Token", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Algorithm")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Algorithm", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-SignedHeaders", valid_593415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593416: Call_GetIntrospectionSchema_593390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_593416.validator(path, query, header, formData, body)
  let scheme = call_593416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593416.url(scheme.get, call_593416.host, call_593416.base,
                         call_593416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593416, url, valid)

proc call*(call_593417: Call_GetIntrospectionSchema_593390; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_593418 = newJObject()
  var query_593419 = newJObject()
  add(path_593418, "apiId", newJString(apiId))
  add(query_593419, "includeDirectives", newJBool(includeDirectives))
  add(query_593419, "format", newJString(format))
  result = call_593417.call(path_593418, query_593419, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_593390(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_593391, base: "/",
    url: url_GetIntrospectionSchema_593392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_593434 = ref object of OpenApiRestCall_592364
proc url_StartSchemaCreation_593436(protocol: Scheme; host: string; base: string;
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

proc validate_StartSchemaCreation_593435(path: JsonNode; query: JsonNode;
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
  var valid_593437 = path.getOrDefault("apiId")
  valid_593437 = validateParameter(valid_593437, JString, required = true,
                                 default = nil)
  if valid_593437 != nil:
    section.add "apiId", valid_593437
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
  var valid_593438 = header.getOrDefault("X-Amz-Signature")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Signature", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Content-Sha256", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Date")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Date", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-Credential")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-Credential", valid_593441
  var valid_593442 = header.getOrDefault("X-Amz-Security-Token")
  valid_593442 = validateParameter(valid_593442, JString, required = false,
                                 default = nil)
  if valid_593442 != nil:
    section.add "X-Amz-Security-Token", valid_593442
  var valid_593443 = header.getOrDefault("X-Amz-Algorithm")
  valid_593443 = validateParameter(valid_593443, JString, required = false,
                                 default = nil)
  if valid_593443 != nil:
    section.add "X-Amz-Algorithm", valid_593443
  var valid_593444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-SignedHeaders", valid_593444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593446: Call_StartSchemaCreation_593434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_593446.validator(path, query, header, formData, body)
  let scheme = call_593446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593446.url(scheme.get, call_593446.host, call_593446.base,
                         call_593446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593446, url, valid)

proc call*(call_593447: Call_StartSchemaCreation_593434; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_593448 = newJObject()
  var body_593449 = newJObject()
  add(path_593448, "apiId", newJString(apiId))
  if body != nil:
    body_593449 = body
  result = call_593447.call(path_593448, nil, nil, nil, body_593449)

var startSchemaCreation* = Call_StartSchemaCreation_593434(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_593435, base: "/",
    url: url_StartSchemaCreation_593436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_593420 = ref object of OpenApiRestCall_592364
proc url_GetSchemaCreationStatus_593422(protocol: Scheme; host: string; base: string;
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

proc validate_GetSchemaCreationStatus_593421(path: JsonNode; query: JsonNode;
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
  var valid_593423 = path.getOrDefault("apiId")
  valid_593423 = validateParameter(valid_593423, JString, required = true,
                                 default = nil)
  if valid_593423 != nil:
    section.add "apiId", valid_593423
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
  var valid_593424 = header.getOrDefault("X-Amz-Signature")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Signature", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Content-Sha256", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Date")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Date", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Credential")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Credential", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Security-Token")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Security-Token", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Algorithm")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Algorithm", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-SignedHeaders", valid_593430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593431: Call_GetSchemaCreationStatus_593420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_593431.validator(path, query, header, formData, body)
  let scheme = call_593431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593431.url(scheme.get, call_593431.host, call_593431.base,
                         call_593431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593431, url, valid)

proc call*(call_593432: Call_GetSchemaCreationStatus_593420; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_593433 = newJObject()
  add(path_593433, "apiId", newJString(apiId))
  result = call_593432.call(path_593433, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_593420(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_593421, base: "/",
    url: url_GetSchemaCreationStatus_593422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_593450 = ref object of OpenApiRestCall_592364
proc url_GetType_593452(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetType_593451(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593453 = path.getOrDefault("apiId")
  valid_593453 = validateParameter(valid_593453, JString, required = true,
                                 default = nil)
  if valid_593453 != nil:
    section.add "apiId", valid_593453
  var valid_593454 = path.getOrDefault("typeName")
  valid_593454 = validateParameter(valid_593454, JString, required = true,
                                 default = nil)
  if valid_593454 != nil:
    section.add "typeName", valid_593454
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_593455 = query.getOrDefault("format")
  valid_593455 = validateParameter(valid_593455, JString, required = true,
                                 default = newJString("SDL"))
  if valid_593455 != nil:
    section.add "format", valid_593455
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
  var valid_593456 = header.getOrDefault("X-Amz-Signature")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-Signature", valid_593456
  var valid_593457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593457 = validateParameter(valid_593457, JString, required = false,
                                 default = nil)
  if valid_593457 != nil:
    section.add "X-Amz-Content-Sha256", valid_593457
  var valid_593458 = header.getOrDefault("X-Amz-Date")
  valid_593458 = validateParameter(valid_593458, JString, required = false,
                                 default = nil)
  if valid_593458 != nil:
    section.add "X-Amz-Date", valid_593458
  var valid_593459 = header.getOrDefault("X-Amz-Credential")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Credential", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Security-Token")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Security-Token", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Algorithm")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Algorithm", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-SignedHeaders", valid_593462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593463: Call_GetType_593450; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_593463.validator(path, query, header, formData, body)
  let scheme = call_593463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593463.url(scheme.get, call_593463.host, call_593463.base,
                         call_593463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593463, url, valid)

proc call*(call_593464: Call_GetType_593450; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_593465 = newJObject()
  var query_593466 = newJObject()
  add(path_593465, "apiId", newJString(apiId))
  add(path_593465, "typeName", newJString(typeName))
  add(query_593466, "format", newJString(format))
  result = call_593464.call(path_593465, query_593466, nil, nil, nil)

var getType* = Call_GetType_593450(name: "getType", meth: HttpMethod.HttpGet,
                                host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                validator: validate_GetType_593451, base: "/",
                                url: url_GetType_593452,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_593467 = ref object of OpenApiRestCall_592364
proc url_ListResolversByFunction_593469(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolversByFunction_593468(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the resolvers that are associated with a specific function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The Function ID.
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_593470 = path.getOrDefault("functionId")
  valid_593470 = validateParameter(valid_593470, JString, required = true,
                                 default = nil)
  if valid_593470 != nil:
    section.add "functionId", valid_593470
  var valid_593471 = path.getOrDefault("apiId")
  valid_593471 = validateParameter(valid_593471, JString, required = true,
                                 default = nil)
  if valid_593471 != nil:
    section.add "apiId", valid_593471
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_593472 = query.getOrDefault("nextToken")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "nextToken", valid_593472
  var valid_593473 = query.getOrDefault("maxResults")
  valid_593473 = validateParameter(valid_593473, JInt, required = false, default = nil)
  if valid_593473 != nil:
    section.add "maxResults", valid_593473
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
  var valid_593474 = header.getOrDefault("X-Amz-Signature")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Signature", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Content-Sha256", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Date")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Date", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Credential")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Credential", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Security-Token")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Security-Token", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Algorithm")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Algorithm", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-SignedHeaders", valid_593480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593481: Call_ListResolversByFunction_593467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_593481.validator(path, query, header, formData, body)
  let scheme = call_593481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593481.url(scheme.get, call_593481.host, call_593481.base,
                         call_593481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593481, url, valid)

proc call*(call_593482: Call_ListResolversByFunction_593467; functionId: string;
          apiId: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listResolversByFunction
  ## List the resolvers that are associated with a specific function.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  ##   functionId: string (required)
  ##             : The Function ID.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_593483 = newJObject()
  var query_593484 = newJObject()
  add(query_593484, "nextToken", newJString(nextToken))
  add(path_593483, "functionId", newJString(functionId))
  add(path_593483, "apiId", newJString(apiId))
  add(query_593484, "maxResults", newJInt(maxResults))
  result = call_593482.call(path_593483, query_593484, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_593467(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_593468, base: "/",
    url: url_ListResolversByFunction_593469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593499 = ref object of OpenApiRestCall_592364
proc url_TagResource_593501(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_593500(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593502 = path.getOrDefault("resourceArn")
  valid_593502 = validateParameter(valid_593502, JString, required = true,
                                 default = nil)
  if valid_593502 != nil:
    section.add "resourceArn", valid_593502
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
  var valid_593503 = header.getOrDefault("X-Amz-Signature")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Signature", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-Content-Sha256", valid_593504
  var valid_593505 = header.getOrDefault("X-Amz-Date")
  valid_593505 = validateParameter(valid_593505, JString, required = false,
                                 default = nil)
  if valid_593505 != nil:
    section.add "X-Amz-Date", valid_593505
  var valid_593506 = header.getOrDefault("X-Amz-Credential")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Credential", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-Security-Token")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Security-Token", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-Algorithm")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Algorithm", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-SignedHeaders", valid_593509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593511: Call_TagResource_593499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_593511.validator(path, query, header, formData, body)
  let scheme = call_593511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593511.url(scheme.get, call_593511.host, call_593511.base,
                         call_593511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593511, url, valid)

proc call*(call_593512: Call_TagResource_593499; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   body: JObject (required)
  var path_593513 = newJObject()
  var body_593514 = newJObject()
  add(path_593513, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_593514 = body
  result = call_593512.call(path_593513, nil, nil, nil, body_593514)

var tagResource* = Call_TagResource_593499(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_593500,
                                        base: "/", url: url_TagResource_593501,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593485 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593487(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_593486(path: JsonNode; query: JsonNode;
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
  var valid_593488 = path.getOrDefault("resourceArn")
  valid_593488 = validateParameter(valid_593488, JString, required = true,
                                 default = nil)
  if valid_593488 != nil:
    section.add "resourceArn", valid_593488
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
  var valid_593489 = header.getOrDefault("X-Amz-Signature")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Signature", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Content-Sha256", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-Date")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Date", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-Credential")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-Credential", valid_593492
  var valid_593493 = header.getOrDefault("X-Amz-Security-Token")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "X-Amz-Security-Token", valid_593493
  var valid_593494 = header.getOrDefault("X-Amz-Algorithm")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amz-Algorithm", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-SignedHeaders", valid_593495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593496: Call_ListTagsForResource_593485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_593496.validator(path, query, header, formData, body)
  let scheme = call_593496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593496.url(scheme.get, call_593496.host, call_593496.base,
                         call_593496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593496, url, valid)

proc call*(call_593497: Call_ListTagsForResource_593485; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_593498 = newJObject()
  add(path_593498, "resourceArn", newJString(resourceArn))
  result = call_593497.call(path_593498, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593485(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_593486, base: "/",
    url: url_ListTagsForResource_593487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_593515 = ref object of OpenApiRestCall_592364
proc url_ListTypes_593517(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTypes_593516(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593518 = path.getOrDefault("apiId")
  valid_593518 = validateParameter(valid_593518, JString, required = true,
                                 default = nil)
  if valid_593518 != nil:
    section.add "apiId", valid_593518
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_593519 = query.getOrDefault("nextToken")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "nextToken", valid_593519
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_593520 = query.getOrDefault("format")
  valid_593520 = validateParameter(valid_593520, JString, required = true,
                                 default = newJString("SDL"))
  if valid_593520 != nil:
    section.add "format", valid_593520
  var valid_593521 = query.getOrDefault("maxResults")
  valid_593521 = validateParameter(valid_593521, JInt, required = false, default = nil)
  if valid_593521 != nil:
    section.add "maxResults", valid_593521
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
  var valid_593522 = header.getOrDefault("X-Amz-Signature")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Signature", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Content-Sha256", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Date")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Date", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Credential")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Credential", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-Security-Token")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-Security-Token", valid_593526
  var valid_593527 = header.getOrDefault("X-Amz-Algorithm")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amz-Algorithm", valid_593527
  var valid_593528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "X-Amz-SignedHeaders", valid_593528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593529: Call_ListTypes_593515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_593529.validator(path, query, header, formData, body)
  let scheme = call_593529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593529.url(scheme.get, call_593529.host, call_593529.base,
                         call_593529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593529, url, valid)

proc call*(call_593530: Call_ListTypes_593515; apiId: string; nextToken: string = "";
          format: string = "SDL"; maxResults: int = 0): Recallable =
  ## listTypes
  ## Lists the types for a given API.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_593531 = newJObject()
  var query_593532 = newJObject()
  add(query_593532, "nextToken", newJString(nextToken))
  add(path_593531, "apiId", newJString(apiId))
  add(query_593532, "format", newJString(format))
  add(query_593532, "maxResults", newJInt(maxResults))
  result = call_593530.call(path_593531, query_593532, nil, nil, nil)

var listTypes* = Call_ListTypes_593515(name: "listTypes", meth: HttpMethod.HttpGet,
                                    host: "appsync.amazonaws.com",
                                    route: "/v1/apis/{apiId}/types#format",
                                    validator: validate_ListTypes_593516,
                                    base: "/", url: url_ListTypes_593517,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593533 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593535(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_593534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593536 = path.getOrDefault("resourceArn")
  valid_593536 = validateParameter(valid_593536, JString, required = true,
                                 default = nil)
  if valid_593536 != nil:
    section.add "resourceArn", valid_593536
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593537 = query.getOrDefault("tagKeys")
  valid_593537 = validateParameter(valid_593537, JArray, required = true, default = nil)
  if valid_593537 != nil:
    section.add "tagKeys", valid_593537
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
  var valid_593538 = header.getOrDefault("X-Amz-Signature")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Signature", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-Content-Sha256", valid_593539
  var valid_593540 = header.getOrDefault("X-Amz-Date")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Date", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Credential")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Credential", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-Security-Token")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-Security-Token", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Algorithm")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Algorithm", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-SignedHeaders", valid_593544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593545: Call_UntagResource_593533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_593545.validator(path, query, header, formData, body)
  let scheme = call_593545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593545.url(scheme.get, call_593545.host, call_593545.base,
                         call_593545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593545, url, valid)

proc call*(call_593546: Call_UntagResource_593533; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  var path_593547 = newJObject()
  var query_593548 = newJObject()
  add(path_593547, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_593548.add "tagKeys", tagKeys
  result = call_593546.call(path_593547, query_593548, nil, nil, nil)

var untagResource* = Call_UntagResource_593533(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_593534,
    base: "/", url: url_UntagResource_593535, schemes: {Scheme.Https, Scheme.Http})
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
