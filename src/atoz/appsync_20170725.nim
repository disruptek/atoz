
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiCache_601997 = ref object of OpenApiRestCall_601389
proc url_CreateApiCache_601999(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiCache_601998(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a cache for the GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API Id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602000 = path.getOrDefault("apiId")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "apiId", valid_602000
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_CreateApiCache_601997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a cache for the GraphQL API.
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_CreateApiCache_601997; apiId: string; body: JsonNode): Recallable =
  ## createApiCache
  ## Creates a cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_602011 = newJObject()
  var body_602012 = newJObject()
  add(path_602011, "apiId", newJString(apiId))
  if body != nil:
    body_602012 = body
  result = call_602010.call(path_602011, nil, nil, nil, body_602012)

var createApiCache* = Call_CreateApiCache_601997(name: "createApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_CreateApiCache_601998,
    base: "/", url: url_CreateApiCache_601999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiCache_601727 = ref object of OpenApiRestCall_601389
proc url_GetApiCache_601729(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiCache_601728(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_601855 = path.getOrDefault("apiId")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "apiId", valid_601855
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
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_GetApiCache_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an <code>ApiCache</code> object.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_GetApiCache_601727; apiId: string): Recallable =
  ## getApiCache
  ## Retrieves an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_601957 = newJObject()
  add(path_601957, "apiId", newJString(apiId))
  result = call_601956.call(path_601957, nil, nil, nil, nil)

var getApiCache* = Call_GetApiCache_601727(name: "getApiCache",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/ApiCaches",
                                        validator: validate_GetApiCache_601728,
                                        base: "/", url: url_GetApiCache_601729,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiCache_602013 = ref object of OpenApiRestCall_601389
proc url_DeleteApiCache_602015(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiCache_602014(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602016 = path.getOrDefault("apiId")
  valid_602016 = validateParameter(valid_602016, JString, required = true,
                                 default = nil)
  if valid_602016 != nil:
    section.add "apiId", valid_602016
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
  var valid_602017 = header.getOrDefault("X-Amz-Signature")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Signature", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Content-Sha256", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Date")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Date", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Credential")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Credential", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Security-Token")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Security-Token", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Algorithm")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Algorithm", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-SignedHeaders", valid_602023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_DeleteApiCache_602013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an <code>ApiCache</code> object.
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_DeleteApiCache_602013; apiId: string): Recallable =
  ## deleteApiCache
  ## Deletes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_602026 = newJObject()
  add(path_602026, "apiId", newJString(apiId))
  result = call_602025.call(path_602026, nil, nil, nil, nil)

var deleteApiCache* = Call_DeleteApiCache_602013(name: "deleteApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_DeleteApiCache_602014,
    base: "/", url: url_DeleteApiCache_602015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiKey_602044 = ref object of OpenApiRestCall_601389
proc url_CreateApiKey_602046(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiKey_602045(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602047 = path.getOrDefault("apiId")
  valid_602047 = validateParameter(valid_602047, JString, required = true,
                                 default = nil)
  if valid_602047 != nil:
    section.add "apiId", valid_602047
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
  var valid_602048 = header.getOrDefault("X-Amz-Signature")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Signature", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Content-Sha256", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Date")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Date", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Credential")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Credential", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Security-Token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Security-Token", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Algorithm")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Algorithm", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-SignedHeaders", valid_602054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602056: Call_CreateApiKey_602044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_602056.validator(path, query, header, formData, body)
  let scheme = call_602056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602056.url(scheme.get, call_602056.host, call_602056.base,
                         call_602056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602056, url, valid)

proc call*(call_602057: Call_CreateApiKey_602044; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_602058 = newJObject()
  var body_602059 = newJObject()
  add(path_602058, "apiId", newJString(apiId))
  if body != nil:
    body_602059 = body
  result = call_602057.call(path_602058, nil, nil, nil, body_602059)

var createApiKey* = Call_CreateApiKey_602044(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_602045,
    base: "/", url: url_CreateApiKey_602046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_602027 = ref object of OpenApiRestCall_601389
proc url_ListApiKeys_602029(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListApiKeys_602028(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602030 = path.getOrDefault("apiId")
  valid_602030 = validateParameter(valid_602030, JString, required = true,
                                 default = nil)
  if valid_602030 != nil:
    section.add "apiId", valid_602030
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_602031 = query.getOrDefault("nextToken")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "nextToken", valid_602031
  var valid_602032 = query.getOrDefault("maxResults")
  valid_602032 = validateParameter(valid_602032, JInt, required = false, default = nil)
  if valid_602032 != nil:
    section.add "maxResults", valid_602032
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
  var valid_602033 = header.getOrDefault("X-Amz-Signature")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Signature", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Content-Sha256", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Date")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Date", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Credential")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Credential", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Security-Token")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Security-Token", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Algorithm")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Algorithm", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-SignedHeaders", valid_602039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602040: Call_ListApiKeys_602027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_602040.validator(path, query, header, formData, body)
  let scheme = call_602040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602040.url(scheme.get, call_602040.host, call_602040.base,
                         call_602040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602040, url, valid)

proc call*(call_602041: Call_ListApiKeys_602027; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_602042 = newJObject()
  var query_602043 = newJObject()
  add(query_602043, "nextToken", newJString(nextToken))
  add(path_602042, "apiId", newJString(apiId))
  add(query_602043, "maxResults", newJInt(maxResults))
  result = call_602041.call(path_602042, query_602043, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_602027(name: "listApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/apikeys",
                                        validator: validate_ListApiKeys_602028,
                                        base: "/", url: url_ListApiKeys_602029,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_602077 = ref object of OpenApiRestCall_601389
proc url_CreateDataSource_602079(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_602078(path: JsonNode; query: JsonNode;
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
  var valid_602080 = path.getOrDefault("apiId")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "apiId", valid_602080
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
  var valid_602081 = header.getOrDefault("X-Amz-Signature")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Signature", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Content-Sha256", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Date")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Date", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Credential")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Credential", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Security-Token")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Security-Token", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Algorithm")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Algorithm", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-SignedHeaders", valid_602087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602089: Call_CreateDataSource_602077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_602089.validator(path, query, header, formData, body)
  let scheme = call_602089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602089.url(scheme.get, call_602089.host, call_602089.base,
                         call_602089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602089, url, valid)

proc call*(call_602090: Call_CreateDataSource_602077; apiId: string; body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_602091 = newJObject()
  var body_602092 = newJObject()
  add(path_602091, "apiId", newJString(apiId))
  if body != nil:
    body_602092 = body
  result = call_602090.call(path_602091, nil, nil, nil, body_602092)

var createDataSource* = Call_CreateDataSource_602077(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_602078,
    base: "/", url: url_CreateDataSource_602079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_602060 = ref object of OpenApiRestCall_601389
proc url_ListDataSources_602062(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_602061(path: JsonNode; query: JsonNode;
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
  var valid_602063 = path.getOrDefault("apiId")
  valid_602063 = validateParameter(valid_602063, JString, required = true,
                                 default = nil)
  if valid_602063 != nil:
    section.add "apiId", valid_602063
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_602064 = query.getOrDefault("nextToken")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "nextToken", valid_602064
  var valid_602065 = query.getOrDefault("maxResults")
  valid_602065 = validateParameter(valid_602065, JInt, required = false, default = nil)
  if valid_602065 != nil:
    section.add "maxResults", valid_602065
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
  var valid_602066 = header.getOrDefault("X-Amz-Signature")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Signature", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Credential")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Credential", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Security-Token")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Security-Token", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-SignedHeaders", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_ListDataSources_602060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_ListDataSources_602060; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_602075 = newJObject()
  var query_602076 = newJObject()
  add(query_602076, "nextToken", newJString(nextToken))
  add(path_602075, "apiId", newJString(apiId))
  add(query_602076, "maxResults", newJInt(maxResults))
  result = call_602074.call(path_602075, query_602076, nil, nil, nil)

var listDataSources* = Call_ListDataSources_602060(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_602061,
    base: "/", url: url_ListDataSources_602062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_602110 = ref object of OpenApiRestCall_601389
proc url_CreateFunction_602112(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFunction_602111(path: JsonNode; query: JsonNode;
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
  var valid_602113 = path.getOrDefault("apiId")
  valid_602113 = validateParameter(valid_602113, JString, required = true,
                                 default = nil)
  if valid_602113 != nil:
    section.add "apiId", valid_602113
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
  var valid_602114 = header.getOrDefault("X-Amz-Signature")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Signature", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Content-Sha256", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Date")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Date", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Credential")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Credential", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Security-Token")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Security-Token", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Algorithm")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Algorithm", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-SignedHeaders", valid_602120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602122: Call_CreateFunction_602110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_602122.validator(path, query, header, formData, body)
  let scheme = call_602122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602122.url(scheme.get, call_602122.host, call_602122.base,
                         call_602122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602122, url, valid)

proc call*(call_602123: Call_CreateFunction_602110; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_602124 = newJObject()
  var body_602125 = newJObject()
  add(path_602124, "apiId", newJString(apiId))
  if body != nil:
    body_602125 = body
  result = call_602123.call(path_602124, nil, nil, nil, body_602125)

var createFunction* = Call_CreateFunction_602110(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_602111,
    base: "/", url: url_CreateFunction_602112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_602093 = ref object of OpenApiRestCall_601389
proc url_ListFunctions_602095(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctions_602094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602096 = path.getOrDefault("apiId")
  valid_602096 = validateParameter(valid_602096, JString, required = true,
                                 default = nil)
  if valid_602096 != nil:
    section.add "apiId", valid_602096
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_602097 = query.getOrDefault("nextToken")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "nextToken", valid_602097
  var valid_602098 = query.getOrDefault("maxResults")
  valid_602098 = validateParameter(valid_602098, JInt, required = false, default = nil)
  if valid_602098 != nil:
    section.add "maxResults", valid_602098
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
  var valid_602099 = header.getOrDefault("X-Amz-Signature")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Signature", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Content-Sha256", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Date")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Date", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Credential")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Credential", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Security-Token")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Security-Token", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Algorithm")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Algorithm", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-SignedHeaders", valid_602105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602106: Call_ListFunctions_602093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_602106.validator(path, query, header, formData, body)
  let scheme = call_602106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602106.url(scheme.get, call_602106.host, call_602106.base,
                         call_602106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602106, url, valid)

proc call*(call_602107: Call_ListFunctions_602093; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_602108 = newJObject()
  var query_602109 = newJObject()
  add(query_602109, "nextToken", newJString(nextToken))
  add(path_602108, "apiId", newJString(apiId))
  add(query_602109, "maxResults", newJInt(maxResults))
  result = call_602107.call(path_602108, query_602109, nil, nil, nil)

var listFunctions* = Call_ListFunctions_602093(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_602094,
    base: "/", url: url_ListFunctions_602095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_602141 = ref object of OpenApiRestCall_601389
proc url_CreateGraphqlApi_602143(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGraphqlApi_602142(path: JsonNode; query: JsonNode;
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
  var valid_602144 = header.getOrDefault("X-Amz-Signature")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Signature", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Content-Sha256", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Date")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Date", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Credential")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Credential", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Security-Token")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Security-Token", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Algorithm")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Algorithm", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-SignedHeaders", valid_602150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602152: Call_CreateGraphqlApi_602141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_602152.validator(path, query, header, formData, body)
  let scheme = call_602152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602152.url(scheme.get, call_602152.host, call_602152.base,
                         call_602152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602152, url, valid)

proc call*(call_602153: Call_CreateGraphqlApi_602141; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_602154 = newJObject()
  if body != nil:
    body_602154 = body
  result = call_602153.call(nil, nil, nil, nil, body_602154)

var createGraphqlApi* = Call_CreateGraphqlApi_602141(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_602142, base: "/",
    url: url_CreateGraphqlApi_602143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_602126 = ref object of OpenApiRestCall_601389
proc url_ListGraphqlApis_602128(protocol: Scheme; host: string; base: string;
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

proc validate_ListGraphqlApis_602127(path: JsonNode; query: JsonNode;
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
  var valid_602129 = query.getOrDefault("nextToken")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "nextToken", valid_602129
  var valid_602130 = query.getOrDefault("maxResults")
  valid_602130 = validateParameter(valid_602130, JInt, required = false, default = nil)
  if valid_602130 != nil:
    section.add "maxResults", valid_602130
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
  var valid_602131 = header.getOrDefault("X-Amz-Signature")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Signature", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Content-Sha256", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Date")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Date", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Credential")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Credential", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Security-Token")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Security-Token", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Algorithm")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Algorithm", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-SignedHeaders", valid_602137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602138: Call_ListGraphqlApis_602126; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_602138.validator(path, query, header, formData, body)
  let scheme = call_602138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602138.url(scheme.get, call_602138.host, call_602138.base,
                         call_602138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602138, url, valid)

proc call*(call_602139: Call_ListGraphqlApis_602126; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var query_602140 = newJObject()
  add(query_602140, "nextToken", newJString(nextToken))
  add(query_602140, "maxResults", newJInt(maxResults))
  result = call_602139.call(nil, query_602140, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_602126(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_602127, base: "/", url: url_ListGraphqlApis_602128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_602173 = ref object of OpenApiRestCall_601389
proc url_CreateResolver_602175(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResolver_602174(path: JsonNode; query: JsonNode;
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
  var valid_602176 = path.getOrDefault("apiId")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = nil)
  if valid_602176 != nil:
    section.add "apiId", valid_602176
  var valid_602177 = path.getOrDefault("typeName")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = nil)
  if valid_602177 != nil:
    section.add "typeName", valid_602177
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
  var valid_602178 = header.getOrDefault("X-Amz-Signature")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Signature", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Date")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Date", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Credential")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Credential", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Security-Token")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Security-Token", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Algorithm")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Algorithm", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-SignedHeaders", valid_602184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_CreateResolver_602173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602186, url, valid)

proc call*(call_602187: Call_CreateResolver_602173; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_602188 = newJObject()
  var body_602189 = newJObject()
  add(path_602188, "apiId", newJString(apiId))
  add(path_602188, "typeName", newJString(typeName))
  if body != nil:
    body_602189 = body
  result = call_602187.call(path_602188, nil, nil, nil, body_602189)

var createResolver* = Call_CreateResolver_602173(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_602174, base: "/", url: url_CreateResolver_602175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_602155 = ref object of OpenApiRestCall_601389
proc url_ListResolvers_602157(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResolvers_602156(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602158 = path.getOrDefault("apiId")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = nil)
  if valid_602158 != nil:
    section.add "apiId", valid_602158
  var valid_602159 = path.getOrDefault("typeName")
  valid_602159 = validateParameter(valid_602159, JString, required = true,
                                 default = nil)
  if valid_602159 != nil:
    section.add "typeName", valid_602159
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_602160 = query.getOrDefault("nextToken")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "nextToken", valid_602160
  var valid_602161 = query.getOrDefault("maxResults")
  valid_602161 = validateParameter(valid_602161, JInt, required = false, default = nil)
  if valid_602161 != nil:
    section.add "maxResults", valid_602161
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
  var valid_602162 = header.getOrDefault("X-Amz-Signature")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Signature", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Content-Sha256", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Date")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Date", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Credential")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Credential", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Security-Token")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Security-Token", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Algorithm")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Algorithm", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-SignedHeaders", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602169: Call_ListResolvers_602155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_602169.validator(path, query, header, formData, body)
  let scheme = call_602169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602169.url(scheme.get, call_602169.host, call_602169.base,
                         call_602169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602169, url, valid)

proc call*(call_602170: Call_ListResolvers_602155; apiId: string; typeName: string;
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
  var path_602171 = newJObject()
  var query_602172 = newJObject()
  add(query_602172, "nextToken", newJString(nextToken))
  add(path_602171, "apiId", newJString(apiId))
  add(path_602171, "typeName", newJString(typeName))
  add(query_602172, "maxResults", newJInt(maxResults))
  result = call_602170.call(path_602171, query_602172, nil, nil, nil)

var listResolvers* = Call_ListResolvers_602155(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_602156, base: "/", url: url_ListResolvers_602157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_602190 = ref object of OpenApiRestCall_601389
proc url_CreateType_602192(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateType_602191(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602193 = path.getOrDefault("apiId")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "apiId", valid_602193
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
  var valid_602194 = header.getOrDefault("X-Amz-Signature")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Signature", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Credential")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Credential", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Security-Token")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Security-Token", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Algorithm")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Algorithm", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-SignedHeaders", valid_602200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_CreateType_602190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_CreateType_602190; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_602204 = newJObject()
  var body_602205 = newJObject()
  add(path_602204, "apiId", newJString(apiId))
  if body != nil:
    body_602205 = body
  result = call_602203.call(path_602204, nil, nil, nil, body_602205)

var createType* = Call_CreateType_602190(name: "createType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types",
                                      validator: validate_CreateType_602191,
                                      base: "/", url: url_CreateType_602192,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_602206 = ref object of OpenApiRestCall_601389
proc url_UpdateApiKey_602208(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiKey_602207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602209 = path.getOrDefault("id")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = nil)
  if valid_602209 != nil:
    section.add "id", valid_602209
  var valid_602210 = path.getOrDefault("apiId")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = nil)
  if valid_602210 != nil:
    section.add "apiId", valid_602210
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
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Security-Token")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Security-Token", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Algorithm")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Algorithm", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-SignedHeaders", valid_602217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602219: Call_UpdateApiKey_602206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_602219.validator(path, query, header, formData, body)
  let scheme = call_602219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602219.url(scheme.get, call_602219.host, call_602219.base,
                         call_602219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602219, url, valid)

proc call*(call_602220: Call_UpdateApiKey_602206; id: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   id: string (required)
  ##     : The API key ID.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   body: JObject (required)
  var path_602221 = newJObject()
  var body_602222 = newJObject()
  add(path_602221, "id", newJString(id))
  add(path_602221, "apiId", newJString(apiId))
  if body != nil:
    body_602222 = body
  result = call_602220.call(path_602221, nil, nil, nil, body_602222)

var updateApiKey* = Call_UpdateApiKey_602206(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_602207,
    base: "/", url: url_UpdateApiKey_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_602223 = ref object of OpenApiRestCall_601389
proc url_DeleteApiKey_602225(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiKey_602224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602226 = path.getOrDefault("id")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = nil)
  if valid_602226 != nil:
    section.add "id", valid_602226
  var valid_602227 = path.getOrDefault("apiId")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "apiId", valid_602227
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
  var valid_602228 = header.getOrDefault("X-Amz-Signature")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Signature", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Content-Sha256", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Date")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Date", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Credential")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Credential", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Security-Token")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Security-Token", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Algorithm")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Algorithm", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-SignedHeaders", valid_602234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602235: Call_DeleteApiKey_602223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_602235.validator(path, query, header, formData, body)
  let scheme = call_602235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602235.url(scheme.get, call_602235.host, call_602235.base,
                         call_602235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602235, url, valid)

proc call*(call_602236: Call_DeleteApiKey_602223; id: string; apiId: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   id: string (required)
  ##     : The ID for the API key.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_602237 = newJObject()
  add(path_602237, "id", newJString(id))
  add(path_602237, "apiId", newJString(apiId))
  result = call_602236.call(path_602237, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_602223(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_602224,
    base: "/", url: url_DeleteApiKey_602225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_602253 = ref object of OpenApiRestCall_601389
proc url_UpdateDataSource_602255(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSource_602254(path: JsonNode; query: JsonNode;
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
  var valid_602256 = path.getOrDefault("apiId")
  valid_602256 = validateParameter(valid_602256, JString, required = true,
                                 default = nil)
  if valid_602256 != nil:
    section.add "apiId", valid_602256
  var valid_602257 = path.getOrDefault("name")
  valid_602257 = validateParameter(valid_602257, JString, required = true,
                                 default = nil)
  if valid_602257 != nil:
    section.add "name", valid_602257
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
  var valid_602258 = header.getOrDefault("X-Amz-Signature")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Signature", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Content-Sha256", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Date")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Date", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Credential")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Credential", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Security-Token")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Security-Token", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Algorithm")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Algorithm", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-SignedHeaders", valid_602264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602266: Call_UpdateDataSource_602253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_602266.validator(path, query, header, formData, body)
  let scheme = call_602266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602266.url(scheme.get, call_602266.host, call_602266.base,
                         call_602266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602266, url, valid)

proc call*(call_602267: Call_UpdateDataSource_602253; apiId: string; name: string;
          body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_602268 = newJObject()
  var body_602269 = newJObject()
  add(path_602268, "apiId", newJString(apiId))
  add(path_602268, "name", newJString(name))
  if body != nil:
    body_602269 = body
  result = call_602267.call(path_602268, nil, nil, nil, body_602269)

var updateDataSource* = Call_UpdateDataSource_602253(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_602254, base: "/",
    url: url_UpdateDataSource_602255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_602238 = ref object of OpenApiRestCall_601389
proc url_GetDataSource_602240(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSource_602239(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602241 = path.getOrDefault("apiId")
  valid_602241 = validateParameter(valid_602241, JString, required = true,
                                 default = nil)
  if valid_602241 != nil:
    section.add "apiId", valid_602241
  var valid_602242 = path.getOrDefault("name")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = nil)
  if valid_602242 != nil:
    section.add "name", valid_602242
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
  var valid_602243 = header.getOrDefault("X-Amz-Signature")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Signature", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Content-Sha256", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Date")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Date", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Credential")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Credential", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Security-Token")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Security-Token", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Algorithm")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Algorithm", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-SignedHeaders", valid_602249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602250: Call_GetDataSource_602238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_602250.validator(path, query, header, formData, body)
  let scheme = call_602250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602250.url(scheme.get, call_602250.host, call_602250.base,
                         call_602250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602250, url, valid)

proc call*(call_602251: Call_GetDataSource_602238; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_602252 = newJObject()
  add(path_602252, "apiId", newJString(apiId))
  add(path_602252, "name", newJString(name))
  result = call_602251.call(path_602252, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_602238(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_602239, base: "/", url: url_GetDataSource_602240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_602270 = ref object of OpenApiRestCall_601389
proc url_DeleteDataSource_602272(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSource_602271(path: JsonNode; query: JsonNode;
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
  var valid_602273 = path.getOrDefault("apiId")
  valid_602273 = validateParameter(valid_602273, JString, required = true,
                                 default = nil)
  if valid_602273 != nil:
    section.add "apiId", valid_602273
  var valid_602274 = path.getOrDefault("name")
  valid_602274 = validateParameter(valid_602274, JString, required = true,
                                 default = nil)
  if valid_602274 != nil:
    section.add "name", valid_602274
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
  var valid_602275 = header.getOrDefault("X-Amz-Signature")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Signature", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Content-Sha256", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Date")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Date", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Credential")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Credential", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Security-Token")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Security-Token", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Algorithm")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Algorithm", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-SignedHeaders", valid_602281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602282: Call_DeleteDataSource_602270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_602282.validator(path, query, header, formData, body)
  let scheme = call_602282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602282.url(scheme.get, call_602282.host, call_602282.base,
                         call_602282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602282, url, valid)

proc call*(call_602283: Call_DeleteDataSource_602270; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_602284 = newJObject()
  add(path_602284, "apiId", newJString(apiId))
  add(path_602284, "name", newJString(name))
  result = call_602283.call(path_602284, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_602270(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_602271, base: "/",
    url: url_DeleteDataSource_602272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_602300 = ref object of OpenApiRestCall_601389
proc url_UpdateFunction_602302(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunction_602301(path: JsonNode; query: JsonNode;
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
  var valid_602303 = path.getOrDefault("functionId")
  valid_602303 = validateParameter(valid_602303, JString, required = true,
                                 default = nil)
  if valid_602303 != nil:
    section.add "functionId", valid_602303
  var valid_602304 = path.getOrDefault("apiId")
  valid_602304 = validateParameter(valid_602304, JString, required = true,
                                 default = nil)
  if valid_602304 != nil:
    section.add "apiId", valid_602304
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
  var valid_602305 = header.getOrDefault("X-Amz-Signature")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Signature", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Content-Sha256", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Date")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Date", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Credential")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Credential", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Security-Token")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Security-Token", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Algorithm")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Algorithm", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-SignedHeaders", valid_602311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602313: Call_UpdateFunction_602300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_602313.validator(path, query, header, formData, body)
  let scheme = call_602313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602313.url(scheme.get, call_602313.host, call_602313.base,
                         call_602313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602313, url, valid)

proc call*(call_602314: Call_UpdateFunction_602300; functionId: string;
          apiId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_602315 = newJObject()
  var body_602316 = newJObject()
  add(path_602315, "functionId", newJString(functionId))
  add(path_602315, "apiId", newJString(apiId))
  if body != nil:
    body_602316 = body
  result = call_602314.call(path_602315, nil, nil, nil, body_602316)

var updateFunction* = Call_UpdateFunction_602300(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_602301, base: "/", url: url_UpdateFunction_602302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_602285 = ref object of OpenApiRestCall_601389
proc url_GetFunction_602287(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_602286(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602288 = path.getOrDefault("functionId")
  valid_602288 = validateParameter(valid_602288, JString, required = true,
                                 default = nil)
  if valid_602288 != nil:
    section.add "functionId", valid_602288
  var valid_602289 = path.getOrDefault("apiId")
  valid_602289 = validateParameter(valid_602289, JString, required = true,
                                 default = nil)
  if valid_602289 != nil:
    section.add "apiId", valid_602289
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
  var valid_602290 = header.getOrDefault("X-Amz-Signature")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Signature", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Content-Sha256", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Date")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Date", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Credential")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Credential", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Security-Token")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Security-Token", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Algorithm")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Algorithm", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-SignedHeaders", valid_602296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602297: Call_GetFunction_602285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_602297.validator(path, query, header, formData, body)
  let scheme = call_602297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602297.url(scheme.get, call_602297.host, call_602297.base,
                         call_602297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602297, url, valid)

proc call*(call_602298: Call_GetFunction_602285; functionId: string; apiId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_602299 = newJObject()
  add(path_602299, "functionId", newJString(functionId))
  add(path_602299, "apiId", newJString(apiId))
  result = call_602298.call(path_602299, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_602285(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/functions/{functionId}",
                                        validator: validate_GetFunction_602286,
                                        base: "/", url: url_GetFunction_602287,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_602317 = ref object of OpenApiRestCall_601389
proc url_DeleteFunction_602319(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_602318(path: JsonNode; query: JsonNode;
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
  var valid_602320 = path.getOrDefault("functionId")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = nil)
  if valid_602320 != nil:
    section.add "functionId", valid_602320
  var valid_602321 = path.getOrDefault("apiId")
  valid_602321 = validateParameter(valid_602321, JString, required = true,
                                 default = nil)
  if valid_602321 != nil:
    section.add "apiId", valid_602321
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
  var valid_602322 = header.getOrDefault("X-Amz-Signature")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Signature", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Content-Sha256", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Date")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Date", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Credential")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Credential", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Security-Token")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Security-Token", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Algorithm")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Algorithm", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-SignedHeaders", valid_602328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602329: Call_DeleteFunction_602317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_602329.validator(path, query, header, formData, body)
  let scheme = call_602329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602329.url(scheme.get, call_602329.host, call_602329.base,
                         call_602329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602329, url, valid)

proc call*(call_602330: Call_DeleteFunction_602317; functionId: string; apiId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_602331 = newJObject()
  add(path_602331, "functionId", newJString(functionId))
  add(path_602331, "apiId", newJString(apiId))
  result = call_602330.call(path_602331, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_602317(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_602318, base: "/", url: url_DeleteFunction_602319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_602346 = ref object of OpenApiRestCall_601389
proc url_UpdateGraphqlApi_602348(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGraphqlApi_602347(path: JsonNode; query: JsonNode;
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
  var valid_602349 = path.getOrDefault("apiId")
  valid_602349 = validateParameter(valid_602349, JString, required = true,
                                 default = nil)
  if valid_602349 != nil:
    section.add "apiId", valid_602349
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
  var valid_602350 = header.getOrDefault("X-Amz-Signature")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Signature", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Content-Sha256", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Date")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Date", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Credential")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Credential", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Security-Token")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Security-Token", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Algorithm")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Algorithm", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-SignedHeaders", valid_602356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602358: Call_UpdateGraphqlApi_602346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_602358.validator(path, query, header, formData, body)
  let scheme = call_602358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602358.url(scheme.get, call_602358.host, call_602358.base,
                         call_602358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602358, url, valid)

proc call*(call_602359: Call_UpdateGraphqlApi_602346; apiId: string; body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_602360 = newJObject()
  var body_602361 = newJObject()
  add(path_602360, "apiId", newJString(apiId))
  if body != nil:
    body_602361 = body
  result = call_602359.call(path_602360, nil, nil, nil, body_602361)

var updateGraphqlApi* = Call_UpdateGraphqlApi_602346(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_602347,
    base: "/", url: url_UpdateGraphqlApi_602348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_602332 = ref object of OpenApiRestCall_601389
proc url_GetGraphqlApi_602334(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGraphqlApi_602333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602335 = path.getOrDefault("apiId")
  valid_602335 = validateParameter(valid_602335, JString, required = true,
                                 default = nil)
  if valid_602335 != nil:
    section.add "apiId", valid_602335
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
  var valid_602336 = header.getOrDefault("X-Amz-Signature")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Signature", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Content-Sha256", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Date")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Date", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Credential")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Credential", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Security-Token")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Security-Token", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Algorithm")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Algorithm", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-SignedHeaders", valid_602342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602343: Call_GetGraphqlApi_602332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_602343.validator(path, query, header, formData, body)
  let scheme = call_602343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602343.url(scheme.get, call_602343.host, call_602343.base,
                         call_602343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602343, url, valid)

proc call*(call_602344: Call_GetGraphqlApi_602332; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_602345 = newJObject()
  add(path_602345, "apiId", newJString(apiId))
  result = call_602344.call(path_602345, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_602332(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_602333, base: "/",
    url: url_GetGraphqlApi_602334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_602362 = ref object of OpenApiRestCall_601389
proc url_DeleteGraphqlApi_602364(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGraphqlApi_602363(path: JsonNode; query: JsonNode;
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
  var valid_602365 = path.getOrDefault("apiId")
  valid_602365 = validateParameter(valid_602365, JString, required = true,
                                 default = nil)
  if valid_602365 != nil:
    section.add "apiId", valid_602365
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
  var valid_602366 = header.getOrDefault("X-Amz-Signature")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Signature", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Content-Sha256", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Date")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Date", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Credential")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Credential", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Security-Token")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Security-Token", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Algorithm")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Algorithm", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-SignedHeaders", valid_602372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602373: Call_DeleteGraphqlApi_602362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_602373.validator(path, query, header, formData, body)
  let scheme = call_602373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602373.url(scheme.get, call_602373.host, call_602373.base,
                         call_602373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602373, url, valid)

proc call*(call_602374: Call_DeleteGraphqlApi_602362; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_602375 = newJObject()
  add(path_602375, "apiId", newJString(apiId))
  result = call_602374.call(path_602375, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_602362(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_602363,
    base: "/", url: url_DeleteGraphqlApi_602364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_602392 = ref object of OpenApiRestCall_601389
proc url_UpdateResolver_602394(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResolver_602393(path: JsonNode; query: JsonNode;
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
  var valid_602395 = path.getOrDefault("apiId")
  valid_602395 = validateParameter(valid_602395, JString, required = true,
                                 default = nil)
  if valid_602395 != nil:
    section.add "apiId", valid_602395
  var valid_602396 = path.getOrDefault("typeName")
  valid_602396 = validateParameter(valid_602396, JString, required = true,
                                 default = nil)
  if valid_602396 != nil:
    section.add "typeName", valid_602396
  var valid_602397 = path.getOrDefault("fieldName")
  valid_602397 = validateParameter(valid_602397, JString, required = true,
                                 default = nil)
  if valid_602397 != nil:
    section.add "fieldName", valid_602397
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
  var valid_602398 = header.getOrDefault("X-Amz-Signature")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Signature", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Content-Sha256", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Date")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Date", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Credential")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Credential", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Security-Token")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Security-Token", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Algorithm")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Algorithm", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-SignedHeaders", valid_602404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602406: Call_UpdateResolver_602392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_602406.validator(path, query, header, formData, body)
  let scheme = call_602406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602406.url(scheme.get, call_602406.host, call_602406.base,
                         call_602406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602406, url, valid)

proc call*(call_602407: Call_UpdateResolver_602392; apiId: string; typeName: string;
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
  var path_602408 = newJObject()
  var body_602409 = newJObject()
  add(path_602408, "apiId", newJString(apiId))
  add(path_602408, "typeName", newJString(typeName))
  if body != nil:
    body_602409 = body
  add(path_602408, "fieldName", newJString(fieldName))
  result = call_602407.call(path_602408, nil, nil, nil, body_602409)

var updateResolver* = Call_UpdateResolver_602392(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_602393, base: "/", url: url_UpdateResolver_602394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_602376 = ref object of OpenApiRestCall_601389
proc url_GetResolver_602378(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResolver_602377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602379 = path.getOrDefault("apiId")
  valid_602379 = validateParameter(valid_602379, JString, required = true,
                                 default = nil)
  if valid_602379 != nil:
    section.add "apiId", valid_602379
  var valid_602380 = path.getOrDefault("typeName")
  valid_602380 = validateParameter(valid_602380, JString, required = true,
                                 default = nil)
  if valid_602380 != nil:
    section.add "typeName", valid_602380
  var valid_602381 = path.getOrDefault("fieldName")
  valid_602381 = validateParameter(valid_602381, JString, required = true,
                                 default = nil)
  if valid_602381 != nil:
    section.add "fieldName", valid_602381
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
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602389: Call_GetResolver_602376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_602389.validator(path, query, header, formData, body)
  let scheme = call_602389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602389.url(scheme.get, call_602389.host, call_602389.base,
                         call_602389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602389, url, valid)

proc call*(call_602390: Call_GetResolver_602376; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The resolver type name.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_602391 = newJObject()
  add(path_602391, "apiId", newJString(apiId))
  add(path_602391, "typeName", newJString(typeName))
  add(path_602391, "fieldName", newJString(fieldName))
  result = call_602390.call(path_602391, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_602376(name: "getResolver",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
                                        validator: validate_GetResolver_602377,
                                        base: "/", url: url_GetResolver_602378,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_602410 = ref object of OpenApiRestCall_601389
proc url_DeleteResolver_602412(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResolver_602411(path: JsonNode; query: JsonNode;
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
  var valid_602413 = path.getOrDefault("apiId")
  valid_602413 = validateParameter(valid_602413, JString, required = true,
                                 default = nil)
  if valid_602413 != nil:
    section.add "apiId", valid_602413
  var valid_602414 = path.getOrDefault("typeName")
  valid_602414 = validateParameter(valid_602414, JString, required = true,
                                 default = nil)
  if valid_602414 != nil:
    section.add "typeName", valid_602414
  var valid_602415 = path.getOrDefault("fieldName")
  valid_602415 = validateParameter(valid_602415, JString, required = true,
                                 default = nil)
  if valid_602415 != nil:
    section.add "fieldName", valid_602415
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
  var valid_602416 = header.getOrDefault("X-Amz-Signature")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Signature", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Content-Sha256", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Date")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Date", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Credential")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Credential", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Security-Token")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Security-Token", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Algorithm")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Algorithm", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-SignedHeaders", valid_602422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602423: Call_DeleteResolver_602410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_602423.validator(path, query, header, formData, body)
  let scheme = call_602423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602423.url(scheme.get, call_602423.host, call_602423.base,
                         call_602423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602423, url, valid)

proc call*(call_602424: Call_DeleteResolver_602410; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_602425 = newJObject()
  add(path_602425, "apiId", newJString(apiId))
  add(path_602425, "typeName", newJString(typeName))
  add(path_602425, "fieldName", newJString(fieldName))
  result = call_602424.call(path_602425, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_602410(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_602411, base: "/", url: url_DeleteResolver_602412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_602426 = ref object of OpenApiRestCall_601389
proc url_UpdateType_602428(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateType_602427(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602429 = path.getOrDefault("apiId")
  valid_602429 = validateParameter(valid_602429, JString, required = true,
                                 default = nil)
  if valid_602429 != nil:
    section.add "apiId", valid_602429
  var valid_602430 = path.getOrDefault("typeName")
  valid_602430 = validateParameter(valid_602430, JString, required = true,
                                 default = nil)
  if valid_602430 != nil:
    section.add "typeName", valid_602430
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
  var valid_602431 = header.getOrDefault("X-Amz-Signature")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Signature", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Content-Sha256", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Date")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Date", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Credential")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Credential", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Security-Token")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Security-Token", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Algorithm")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Algorithm", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-SignedHeaders", valid_602437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602439: Call_UpdateType_602426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_602439.validator(path, query, header, formData, body)
  let scheme = call_602439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602439.url(scheme.get, call_602439.host, call_602439.base,
                         call_602439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602439, url, valid)

proc call*(call_602440: Call_UpdateType_602426; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_602441 = newJObject()
  var body_602442 = newJObject()
  add(path_602441, "apiId", newJString(apiId))
  add(path_602441, "typeName", newJString(typeName))
  if body != nil:
    body_602442 = body
  result = call_602440.call(path_602441, nil, nil, nil, body_602442)

var updateType* = Call_UpdateType_602426(name: "updateType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_UpdateType_602427,
                                      base: "/", url: url_UpdateType_602428,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_602443 = ref object of OpenApiRestCall_601389
proc url_DeleteType_602445(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteType_602444(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602446 = path.getOrDefault("apiId")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = nil)
  if valid_602446 != nil:
    section.add "apiId", valid_602446
  var valid_602447 = path.getOrDefault("typeName")
  valid_602447 = validateParameter(valid_602447, JString, required = true,
                                 default = nil)
  if valid_602447 != nil:
    section.add "typeName", valid_602447
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
  var valid_602448 = header.getOrDefault("X-Amz-Signature")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Signature", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Content-Sha256", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Date")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Date", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Credential")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Credential", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Security-Token")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Security-Token", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Algorithm")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Algorithm", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-SignedHeaders", valid_602454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602455: Call_DeleteType_602443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_602455.validator(path, query, header, formData, body)
  let scheme = call_602455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602455.url(scheme.get, call_602455.host, call_602455.base,
                         call_602455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602455, url, valid)

proc call*(call_602456: Call_DeleteType_602443; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_602457 = newJObject()
  add(path_602457, "apiId", newJString(apiId))
  add(path_602457, "typeName", newJString(typeName))
  result = call_602456.call(path_602457, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_602443(name: "deleteType",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_DeleteType_602444,
                                      base: "/", url: url_DeleteType_602445,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushApiCache_602458 = ref object of OpenApiRestCall_601389
proc url_FlushApiCache_602460(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/FlushCache")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FlushApiCache_602459(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Flushes an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602461 = path.getOrDefault("apiId")
  valid_602461 = validateParameter(valid_602461, JString, required = true,
                                 default = nil)
  if valid_602461 != nil:
    section.add "apiId", valid_602461
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
  var valid_602462 = header.getOrDefault("X-Amz-Signature")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Signature", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Content-Sha256", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Date")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Date", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Credential")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Credential", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Security-Token")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Security-Token", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Algorithm")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Algorithm", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-SignedHeaders", valid_602468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602469: Call_FlushApiCache_602458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes an <code>ApiCache</code> object.
  ## 
  let valid = call_602469.validator(path, query, header, formData, body)
  let scheme = call_602469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602469.url(scheme.get, call_602469.host, call_602469.base,
                         call_602469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602469, url, valid)

proc call*(call_602470: Call_FlushApiCache_602458; apiId: string): Recallable =
  ## flushApiCache
  ## Flushes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_602471 = newJObject()
  add(path_602471, "apiId", newJString(apiId))
  result = call_602470.call(path_602471, nil, nil, nil, nil)

var flushApiCache* = Call_FlushApiCache_602458(name: "flushApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/FlushCache", validator: validate_FlushApiCache_602459,
    base: "/", url: url_FlushApiCache_602460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_602472 = ref object of OpenApiRestCall_601389
proc url_GetIntrospectionSchema_602474(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntrospectionSchema_602473(path: JsonNode; query: JsonNode;
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
  var valid_602475 = path.getOrDefault("apiId")
  valid_602475 = validateParameter(valid_602475, JString, required = true,
                                 default = nil)
  if valid_602475 != nil:
    section.add "apiId", valid_602475
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_602476 = query.getOrDefault("includeDirectives")
  valid_602476 = validateParameter(valid_602476, JBool, required = false, default = nil)
  if valid_602476 != nil:
    section.add "includeDirectives", valid_602476
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_602490 = query.getOrDefault("format")
  valid_602490 = validateParameter(valid_602490, JString, required = true,
                                 default = newJString("SDL"))
  if valid_602490 != nil:
    section.add "format", valid_602490
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
  var valid_602491 = header.getOrDefault("X-Amz-Signature")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Signature", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Content-Sha256", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-Date")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Date", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Credential")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Credential", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Security-Token")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Security-Token", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Algorithm")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Algorithm", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-SignedHeaders", valid_602497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602498: Call_GetIntrospectionSchema_602472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_602498.validator(path, query, header, formData, body)
  let scheme = call_602498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602498.url(scheme.get, call_602498.host, call_602498.base,
                         call_602498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602498, url, valid)

proc call*(call_602499: Call_GetIntrospectionSchema_602472; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_602500 = newJObject()
  var query_602501 = newJObject()
  add(path_602500, "apiId", newJString(apiId))
  add(query_602501, "includeDirectives", newJBool(includeDirectives))
  add(query_602501, "format", newJString(format))
  result = call_602499.call(path_602500, query_602501, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_602472(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_602473, base: "/",
    url: url_GetIntrospectionSchema_602474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_602516 = ref object of OpenApiRestCall_601389
proc url_StartSchemaCreation_602518(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartSchemaCreation_602517(path: JsonNode; query: JsonNode;
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
  var valid_602519 = path.getOrDefault("apiId")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = nil)
  if valid_602519 != nil:
    section.add "apiId", valid_602519
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
  var valid_602520 = header.getOrDefault("X-Amz-Signature")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Signature", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Content-Sha256", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Date")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Date", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Credential")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Credential", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Security-Token")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Security-Token", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Algorithm")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Algorithm", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-SignedHeaders", valid_602526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602528: Call_StartSchemaCreation_602516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_602528.validator(path, query, header, formData, body)
  let scheme = call_602528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602528.url(scheme.get, call_602528.host, call_602528.base,
                         call_602528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602528, url, valid)

proc call*(call_602529: Call_StartSchemaCreation_602516; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_602530 = newJObject()
  var body_602531 = newJObject()
  add(path_602530, "apiId", newJString(apiId))
  if body != nil:
    body_602531 = body
  result = call_602529.call(path_602530, nil, nil, nil, body_602531)

var startSchemaCreation* = Call_StartSchemaCreation_602516(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_602517, base: "/",
    url: url_StartSchemaCreation_602518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_602502 = ref object of OpenApiRestCall_601389
proc url_GetSchemaCreationStatus_602504(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSchemaCreationStatus_602503(path: JsonNode; query: JsonNode;
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
  var valid_602505 = path.getOrDefault("apiId")
  valid_602505 = validateParameter(valid_602505, JString, required = true,
                                 default = nil)
  if valid_602505 != nil:
    section.add "apiId", valid_602505
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
  var valid_602506 = header.getOrDefault("X-Amz-Signature")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Signature", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Content-Sha256", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Date")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Date", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Credential")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Credential", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Security-Token")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Security-Token", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Algorithm")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Algorithm", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-SignedHeaders", valid_602512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602513: Call_GetSchemaCreationStatus_602502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_602513.validator(path, query, header, formData, body)
  let scheme = call_602513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602513.url(scheme.get, call_602513.host, call_602513.base,
                         call_602513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602513, url, valid)

proc call*(call_602514: Call_GetSchemaCreationStatus_602502; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_602515 = newJObject()
  add(path_602515, "apiId", newJString(apiId))
  result = call_602514.call(path_602515, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_602502(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_602503, base: "/",
    url: url_GetSchemaCreationStatus_602504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_602532 = ref object of OpenApiRestCall_601389
proc url_GetType_602534(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetType_602533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602535 = path.getOrDefault("apiId")
  valid_602535 = validateParameter(valid_602535, JString, required = true,
                                 default = nil)
  if valid_602535 != nil:
    section.add "apiId", valid_602535
  var valid_602536 = path.getOrDefault("typeName")
  valid_602536 = validateParameter(valid_602536, JString, required = true,
                                 default = nil)
  if valid_602536 != nil:
    section.add "typeName", valid_602536
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_602537 = query.getOrDefault("format")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = newJString("SDL"))
  if valid_602537 != nil:
    section.add "format", valid_602537
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
  var valid_602538 = header.getOrDefault("X-Amz-Signature")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Signature", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Content-Sha256", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Date")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Date", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Credential")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Credential", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Security-Token")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Security-Token", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Algorithm")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Algorithm", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-SignedHeaders", valid_602544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602545: Call_GetType_602532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_602545.validator(path, query, header, formData, body)
  let scheme = call_602545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602545.url(scheme.get, call_602545.host, call_602545.base,
                         call_602545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602545, url, valid)

proc call*(call_602546: Call_GetType_602532; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_602547 = newJObject()
  var query_602548 = newJObject()
  add(path_602547, "apiId", newJString(apiId))
  add(path_602547, "typeName", newJString(typeName))
  add(query_602548, "format", newJString(format))
  result = call_602546.call(path_602547, query_602548, nil, nil, nil)

var getType* = Call_GetType_602532(name: "getType", meth: HttpMethod.HttpGet,
                                host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                validator: validate_GetType_602533, base: "/",
                                url: url_GetType_602534,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_602549 = ref object of OpenApiRestCall_601389
proc url_ListResolversByFunction_602551(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResolversByFunction_602550(path: JsonNode; query: JsonNode;
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
  var valid_602552 = path.getOrDefault("functionId")
  valid_602552 = validateParameter(valid_602552, JString, required = true,
                                 default = nil)
  if valid_602552 != nil:
    section.add "functionId", valid_602552
  var valid_602553 = path.getOrDefault("apiId")
  valid_602553 = validateParameter(valid_602553, JString, required = true,
                                 default = nil)
  if valid_602553 != nil:
    section.add "apiId", valid_602553
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_602554 = query.getOrDefault("nextToken")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "nextToken", valid_602554
  var valid_602555 = query.getOrDefault("maxResults")
  valid_602555 = validateParameter(valid_602555, JInt, required = false, default = nil)
  if valid_602555 != nil:
    section.add "maxResults", valid_602555
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
  var valid_602556 = header.getOrDefault("X-Amz-Signature")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Signature", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Content-Sha256", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Date")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Date", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Credential")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Credential", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Security-Token")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Security-Token", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Algorithm")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Algorithm", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-SignedHeaders", valid_602562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602563: Call_ListResolversByFunction_602549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_602563.validator(path, query, header, formData, body)
  let scheme = call_602563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602563.url(scheme.get, call_602563.host, call_602563.base,
                         call_602563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602563, url, valid)

proc call*(call_602564: Call_ListResolversByFunction_602549; functionId: string;
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
  var path_602565 = newJObject()
  var query_602566 = newJObject()
  add(query_602566, "nextToken", newJString(nextToken))
  add(path_602565, "functionId", newJString(functionId))
  add(path_602565, "apiId", newJString(apiId))
  add(query_602566, "maxResults", newJInt(maxResults))
  result = call_602564.call(path_602565, query_602566, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_602549(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_602550, base: "/",
    url: url_ListResolversByFunction_602551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602581 = ref object of OpenApiRestCall_601389
proc url_TagResource_602583(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_602582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602584 = path.getOrDefault("resourceArn")
  valid_602584 = validateParameter(valid_602584, JString, required = true,
                                 default = nil)
  if valid_602584 != nil:
    section.add "resourceArn", valid_602584
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
  var valid_602585 = header.getOrDefault("X-Amz-Signature")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Signature", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Content-Sha256", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Date")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Date", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Credential")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Credential", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Security-Token")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Security-Token", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Algorithm")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Algorithm", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-SignedHeaders", valid_602591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602593: Call_TagResource_602581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_602593.validator(path, query, header, formData, body)
  let scheme = call_602593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602593.url(scheme.get, call_602593.host, call_602593.base,
                         call_602593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602593, url, valid)

proc call*(call_602594: Call_TagResource_602581; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   body: JObject (required)
  var path_602595 = newJObject()
  var body_602596 = newJObject()
  add(path_602595, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_602596 = body
  result = call_602594.call(path_602595, nil, nil, nil, body_602596)

var tagResource* = Call_TagResource_602581(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_602582,
                                        base: "/", url: url_TagResource_602583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602567 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602569(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_602568(path: JsonNode; query: JsonNode;
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
  var valid_602570 = path.getOrDefault("resourceArn")
  valid_602570 = validateParameter(valid_602570, JString, required = true,
                                 default = nil)
  if valid_602570 != nil:
    section.add "resourceArn", valid_602570
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
  var valid_602571 = header.getOrDefault("X-Amz-Signature")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Signature", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Content-Sha256", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Date")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Date", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Credential")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Credential", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Security-Token")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Security-Token", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Algorithm")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Algorithm", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-SignedHeaders", valid_602577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602578: Call_ListTagsForResource_602567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_602578.validator(path, query, header, formData, body)
  let scheme = call_602578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602578.url(scheme.get, call_602578.host, call_602578.base,
                         call_602578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602578, url, valid)

proc call*(call_602579: Call_ListTagsForResource_602567; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_602580 = newJObject()
  add(path_602580, "resourceArn", newJString(resourceArn))
  result = call_602579.call(path_602580, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602567(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_602568, base: "/",
    url: url_ListTagsForResource_602569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_602597 = ref object of OpenApiRestCall_601389
proc url_ListTypes_602599(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTypes_602598(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602600 = path.getOrDefault("apiId")
  valid_602600 = validateParameter(valid_602600, JString, required = true,
                                 default = nil)
  if valid_602600 != nil:
    section.add "apiId", valid_602600
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_602601 = query.getOrDefault("nextToken")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "nextToken", valid_602601
  assert query != nil, "query argument is necessary due to required `format` field"
  var valid_602602 = query.getOrDefault("format")
  valid_602602 = validateParameter(valid_602602, JString, required = true,
                                 default = newJString("SDL"))
  if valid_602602 != nil:
    section.add "format", valid_602602
  var valid_602603 = query.getOrDefault("maxResults")
  valid_602603 = validateParameter(valid_602603, JInt, required = false, default = nil)
  if valid_602603 != nil:
    section.add "maxResults", valid_602603
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
  var valid_602604 = header.getOrDefault("X-Amz-Signature")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Signature", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Content-Sha256", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Date")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Date", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Credential")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Credential", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Security-Token")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Security-Token", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Algorithm")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Algorithm", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-SignedHeaders", valid_602610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602611: Call_ListTypes_602597; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_602611.validator(path, query, header, formData, body)
  let scheme = call_602611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602611.url(scheme.get, call_602611.host, call_602611.base,
                         call_602611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602611, url, valid)

proc call*(call_602612: Call_ListTypes_602597; apiId: string; nextToken: string = "";
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
  var path_602613 = newJObject()
  var query_602614 = newJObject()
  add(query_602614, "nextToken", newJString(nextToken))
  add(path_602613, "apiId", newJString(apiId))
  add(query_602614, "format", newJString(format))
  add(query_602614, "maxResults", newJInt(maxResults))
  result = call_602612.call(path_602613, query_602614, nil, nil, nil)

var listTypes* = Call_ListTypes_602597(name: "listTypes", meth: HttpMethod.HttpGet,
                                    host: "appsync.amazonaws.com",
                                    route: "/v1/apis/{apiId}/types#format",
                                    validator: validate_ListTypes_602598,
                                    base: "/", url: url_ListTypes_602599,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602615 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602617(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_602616(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602618 = path.getOrDefault("resourceArn")
  valid_602618 = validateParameter(valid_602618, JString, required = true,
                                 default = nil)
  if valid_602618 != nil:
    section.add "resourceArn", valid_602618
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602619 = query.getOrDefault("tagKeys")
  valid_602619 = validateParameter(valid_602619, JArray, required = true, default = nil)
  if valid_602619 != nil:
    section.add "tagKeys", valid_602619
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
  var valid_602620 = header.getOrDefault("X-Amz-Signature")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Signature", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Content-Sha256", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Date")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Date", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Credential")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Credential", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Security-Token")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Security-Token", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Algorithm")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Algorithm", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-SignedHeaders", valid_602626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602627: Call_UntagResource_602615; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_602627.validator(path, query, header, formData, body)
  let scheme = call_602627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602627.url(scheme.get, call_602627.host, call_602627.base,
                         call_602627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602627, url, valid)

proc call*(call_602628: Call_UntagResource_602615; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  var path_602629 = newJObject()
  var query_602630 = newJObject()
  add(path_602629, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_602630.add "tagKeys", tagKeys
  result = call_602628.call(path_602629, query_602630, nil, nil, nil)

var untagResource* = Call_UntagResource_602615(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_602616,
    base: "/", url: url_UntagResource_602617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiCache_602631 = ref object of OpenApiRestCall_601389
proc url_UpdateApiCache_602633(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches/update")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiCache_602632(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the cache for the GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API Id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_602634 = path.getOrDefault("apiId")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = nil)
  if valid_602634 != nil:
    section.add "apiId", valid_602634
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
  var valid_602635 = header.getOrDefault("X-Amz-Signature")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Signature", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Content-Sha256", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Date")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Date", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Credential")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Credential", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Security-Token")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Security-Token", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Algorithm")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Algorithm", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-SignedHeaders", valid_602641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602643: Call_UpdateApiCache_602631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the cache for the GraphQL API.
  ## 
  let valid = call_602643.validator(path, query, header, formData, body)
  let scheme = call_602643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602643.url(scheme.get, call_602643.host, call_602643.base,
                         call_602643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602643, url, valid)

proc call*(call_602644: Call_UpdateApiCache_602631; apiId: string; body: JsonNode): Recallable =
  ## updateApiCache
  ## Updates the cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_602645 = newJObject()
  var body_602646 = newJObject()
  add(path_602645, "apiId", newJString(apiId))
  if body != nil:
    body_602646 = body
  result = call_602644.call(path_602645, nil, nil, nil, body_602646)

var updateApiCache* = Call_UpdateApiCache_602631(name: "updateApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches/update",
    validator: validate_UpdateApiCache_602632, base: "/", url: url_UpdateApiCache_602633,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
