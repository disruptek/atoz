
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Amplify
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  Amplify is a fully managed continuous deployment and hosting service for modern web apps. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/amplify/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "amplify.ap-northeast-1.amazonaws.com", "ap-southeast-1": "amplify.ap-southeast-1.amazonaws.com",
                           "us-west-2": "amplify.us-west-2.amazonaws.com",
                           "eu-west-2": "amplify.eu-west-2.amazonaws.com", "ap-northeast-3": "amplify.ap-northeast-3.amazonaws.com", "eu-central-1": "amplify.eu-central-1.amazonaws.com",
                           "us-east-2": "amplify.us-east-2.amazonaws.com",
                           "us-east-1": "amplify.us-east-1.amazonaws.com", "cn-northwest-1": "amplify.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "amplify.ap-south-1.amazonaws.com",
                           "eu-north-1": "amplify.eu-north-1.amazonaws.com", "ap-northeast-2": "amplify.ap-northeast-2.amazonaws.com",
                           "us-west-1": "amplify.us-west-1.amazonaws.com", "us-gov-east-1": "amplify.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "amplify.eu-west-3.amazonaws.com",
                           "cn-north-1": "amplify.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "amplify.sa-east-1.amazonaws.com",
                           "eu-west-1": "amplify.eu-west-1.amazonaws.com", "us-gov-west-1": "amplify.us-gov-west-1.amazonaws.com", "ap-southeast-2": "amplify.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "amplify.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "amplify.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "amplify.ap-southeast-1.amazonaws.com",
      "us-west-2": "amplify.us-west-2.amazonaws.com",
      "eu-west-2": "amplify.eu-west-2.amazonaws.com",
      "ap-northeast-3": "amplify.ap-northeast-3.amazonaws.com",
      "eu-central-1": "amplify.eu-central-1.amazonaws.com",
      "us-east-2": "amplify.us-east-2.amazonaws.com",
      "us-east-1": "amplify.us-east-1.amazonaws.com",
      "cn-northwest-1": "amplify.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "amplify.ap-south-1.amazonaws.com",
      "eu-north-1": "amplify.eu-north-1.amazonaws.com",
      "ap-northeast-2": "amplify.ap-northeast-2.amazonaws.com",
      "us-west-1": "amplify.us-west-1.amazonaws.com",
      "us-gov-east-1": "amplify.us-gov-east-1.amazonaws.com",
      "eu-west-3": "amplify.eu-west-3.amazonaws.com",
      "cn-north-1": "amplify.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "amplify.sa-east-1.amazonaws.com",
      "eu-west-1": "amplify.eu-west-1.amazonaws.com",
      "us-gov-west-1": "amplify.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "amplify.ap-southeast-2.amazonaws.com",
      "ca-central-1": "amplify.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "amplify"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_606184 = ref object of OpenApiRestCall_605589
proc url_CreateApp_606186(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_606185(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new Amplify App. 
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
  var valid_606187 = header.getOrDefault("X-Amz-Signature")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Signature", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Content-Sha256", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Date")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Date", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Credential")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Credential", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Security-Token")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Security-Token", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Algorithm")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Algorithm", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-SignedHeaders", valid_606193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606195: Call_CreateApp_606184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_606195.validator(path, query, header, formData, body)
  let scheme = call_606195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606195.url(scheme.get, call_606195.host, call_606195.base,
                         call_606195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606195, url, valid)

proc call*(call_606196: Call_CreateApp_606184; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_606197 = newJObject()
  if body != nil:
    body_606197 = body
  result = call_606196.call(nil, nil, nil, nil, body_606197)

var createApp* = Call_CreateApp_606184(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_606185,
                                    base: "/", url: url_CreateApp_606186,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_605927 = ref object of OpenApiRestCall_605589
proc url_ListApps_605929(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_605928(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists existing Amplify Apps. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606042 = query.getOrDefault("maxResults")
  valid_606042 = validateParameter(valid_606042, JInt, required = false, default = nil)
  if valid_606042 != nil:
    section.add "maxResults", valid_606042
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
  var valid_606043 = header.getOrDefault("X-Amz-Signature")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Signature", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Content-Sha256", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Date")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Date", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Credential")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Credential", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Security-Token")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Security-Token", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Algorithm")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Algorithm", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-SignedHeaders", valid_606049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606072: Call_ListApps_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_606072.validator(path, query, header, formData, body)
  let scheme = call_606072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606072.url(scheme.get, call_606072.host, call_606072.base,
                         call_606072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606072, url, valid)

proc call*(call_606143: Call_ListApps_605927; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_606144 = newJObject()
  add(query_606144, "nextToken", newJString(nextToken))
  add(query_606144, "maxResults", newJInt(maxResults))
  result = call_606143.call(nil, query_606144, nil, nil, nil)

var listApps* = Call_ListApps_605927(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_605928, base: "/",
                                  url: url_ListApps_605929,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackendEnvironment_606231 = ref object of OpenApiRestCall_605589
proc url_CreateBackendEnvironment_606233(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackendEnvironment_606232(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606234 = path.getOrDefault("appId")
  valid_606234 = validateParameter(valid_606234, JString, required = true,
                                 default = nil)
  if valid_606234 != nil:
    section.add "appId", valid_606234
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
  var valid_606235 = header.getOrDefault("X-Amz-Signature")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Signature", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Content-Sha256", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Date")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Date", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Credential")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Credential", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Security-Token")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Security-Token", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Algorithm")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Algorithm", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-SignedHeaders", valid_606241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606243: Call_CreateBackendEnvironment_606231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new backend environment for an Amplify App. 
  ## 
  let valid = call_606243.validator(path, query, header, formData, body)
  let scheme = call_606243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606243.url(scheme.get, call_606243.host, call_606243.base,
                         call_606243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606243, url, valid)

proc call*(call_606244: Call_CreateBackendEnvironment_606231; appId: string;
          body: JsonNode): Recallable =
  ## createBackendEnvironment
  ##  Creates a new backend environment for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606245 = newJObject()
  var body_606246 = newJObject()
  add(path_606245, "appId", newJString(appId))
  if body != nil:
    body_606246 = body
  result = call_606244.call(path_606245, nil, nil, nil, body_606246)

var createBackendEnvironment* = Call_CreateBackendEnvironment_606231(
    name: "createBackendEnvironment", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_CreateBackendEnvironment_606232, base: "/",
    url: url_CreateBackendEnvironment_606233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackendEnvironments_606198 = ref object of OpenApiRestCall_605589
proc url_ListBackendEnvironments_606200(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackendEnvironments_606199(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists backend environments for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606215 = path.getOrDefault("appId")
  valid_606215 = validateParameter(valid_606215, JString, required = true,
                                 default = nil)
  if valid_606215 != nil:
    section.add "appId", valid_606215
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing backen environments from start. If a non-null pagination token is returned in a result, then pass its value in here to list more backend environments. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_606216 = query.getOrDefault("nextToken")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "nextToken", valid_606216
  var valid_606217 = query.getOrDefault("maxResults")
  valid_606217 = validateParameter(valid_606217, JInt, required = false, default = nil)
  if valid_606217 != nil:
    section.add "maxResults", valid_606217
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
  var valid_606218 = header.getOrDefault("X-Amz-Signature")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Signature", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Content-Sha256", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Date")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Date", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Credential")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Credential", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Security-Token")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Security-Token", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Algorithm")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Algorithm", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-SignedHeaders", valid_606224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606226: Call_ListBackendEnvironments_606198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists backend environments for an Amplify App. 
  ## 
  let valid = call_606226.validator(path, query, header, formData, body)
  let scheme = call_606226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606226.url(scheme.get, call_606226.host, call_606226.base,
                         call_606226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606226, url, valid)

proc call*(call_606227: Call_ListBackendEnvironments_606198; appId: string;
          body: JsonNode; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBackendEnvironments
  ##  Lists backend environments for an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing backen environments from start. If a non-null pagination token is returned in a result, then pass its value in here to list more backend environments. 
  ##   appId: string (required)
  ##        :  Unique Id for an amplify App. 
  ##   body: JObject (required)
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_606228 = newJObject()
  var query_606229 = newJObject()
  var body_606230 = newJObject()
  add(query_606229, "nextToken", newJString(nextToken))
  add(path_606228, "appId", newJString(appId))
  if body != nil:
    body_606230 = body
  add(query_606229, "maxResults", newJInt(maxResults))
  result = call_606227.call(path_606228, query_606229, nil, nil, body_606230)

var listBackendEnvironments* = Call_ListBackendEnvironments_606198(
    name: "listBackendEnvironments", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_ListBackendEnvironments_606199, base: "/",
    url: url_ListBackendEnvironments_606200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_606264 = ref object of OpenApiRestCall_605589
proc url_CreateBranch_606266(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBranch_606265(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606267 = path.getOrDefault("appId")
  valid_606267 = validateParameter(valid_606267, JString, required = true,
                                 default = nil)
  if valid_606267 != nil:
    section.add "appId", valid_606267
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
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606276: Call_CreateBranch_606264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_606276.validator(path, query, header, formData, body)
  let scheme = call_606276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606276.url(scheme.get, call_606276.host, call_606276.base,
                         call_606276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606276, url, valid)

proc call*(call_606277: Call_CreateBranch_606264; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606278 = newJObject()
  var body_606279 = newJObject()
  add(path_606278, "appId", newJString(appId))
  if body != nil:
    body_606279 = body
  result = call_606277.call(path_606278, nil, nil, nil, body_606279)

var createBranch* = Call_CreateBranch_606264(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_606265,
    base: "/", url: url_CreateBranch_606266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_606247 = ref object of OpenApiRestCall_605589
proc url_ListBranches_606249(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBranches_606248(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists branches for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606250 = path.getOrDefault("appId")
  valid_606250 = validateParameter(valid_606250, JString, required = true,
                                 default = nil)
  if valid_606250 != nil:
    section.add "appId", valid_606250
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_606251 = query.getOrDefault("nextToken")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "nextToken", valid_606251
  var valid_606252 = query.getOrDefault("maxResults")
  valid_606252 = validateParameter(valid_606252, JInt, required = false, default = nil)
  if valid_606252 != nil:
    section.add "maxResults", valid_606252
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
  var valid_606253 = header.getOrDefault("X-Amz-Signature")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Signature", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Content-Sha256", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Date")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Date", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Credential")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Credential", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Security-Token")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Security-Token", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Algorithm")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Algorithm", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-SignedHeaders", valid_606259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606260: Call_ListBranches_606247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_606260.validator(path, query, header, formData, body)
  let scheme = call_606260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606260.url(scheme.get, call_606260.host, call_606260.base,
                         call_606260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606260, url, valid)

proc call*(call_606261: Call_ListBranches_606247; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_606262 = newJObject()
  var query_606263 = newJObject()
  add(query_606263, "nextToken", newJString(nextToken))
  add(path_606262, "appId", newJString(appId))
  add(query_606263, "maxResults", newJInt(maxResults))
  result = call_606261.call(path_606262, query_606263, nil, nil, nil)

var listBranches* = Call_ListBranches_606247(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_606248,
    base: "/", url: url_ListBranches_606249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_606280 = ref object of OpenApiRestCall_605589
proc url_CreateDeployment_606282(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_606281(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_606283 = path.getOrDefault("branchName")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "branchName", valid_606283
  var valid_606284 = path.getOrDefault("appId")
  valid_606284 = validateParameter(valid_606284, JString, required = true,
                                 default = nil)
  if valid_606284 != nil:
    section.add "appId", valid_606284
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
  var valid_606285 = header.getOrDefault("X-Amz-Signature")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Signature", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Content-Sha256", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Date")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Date", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Credential")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Credential", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Security-Token")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Security-Token", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Algorithm")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Algorithm", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-SignedHeaders", valid_606291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606293: Call_CreateDeployment_606280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_606293.validator(path, query, header, formData, body)
  let scheme = call_606293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606293.url(scheme.get, call_606293.host, call_606293.base,
                         call_606293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606293, url, valid)

proc call*(call_606294: Call_CreateDeployment_606280; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606295 = newJObject()
  var body_606296 = newJObject()
  add(path_606295, "branchName", newJString(branchName))
  add(path_606295, "appId", newJString(appId))
  if body != nil:
    body_606296 = body
  result = call_606294.call(path_606295, nil, nil, nil, body_606296)

var createDeployment* = Call_CreateDeployment_606280(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_606281, base: "/",
    url: url_CreateDeployment_606282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_606314 = ref object of OpenApiRestCall_605589
proc url_CreateDomainAssociation_606316(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDomainAssociation_606315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Create a new DomainAssociation on an App 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606317 = path.getOrDefault("appId")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = nil)
  if valid_606317 != nil:
    section.add "appId", valid_606317
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
  var valid_606318 = header.getOrDefault("X-Amz-Signature")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Signature", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Content-Sha256", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Date")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Date", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Credential")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Credential", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Security-Token")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Security-Token", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Algorithm")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Algorithm", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-SignedHeaders", valid_606324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606326: Call_CreateDomainAssociation_606314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_606326.validator(path, query, header, formData, body)
  let scheme = call_606326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606326.url(scheme.get, call_606326.host, call_606326.base,
                         call_606326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606326, url, valid)

proc call*(call_606327: Call_CreateDomainAssociation_606314; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606328 = newJObject()
  var body_606329 = newJObject()
  add(path_606328, "appId", newJString(appId))
  if body != nil:
    body_606329 = body
  result = call_606327.call(path_606328, nil, nil, nil, body_606329)

var createDomainAssociation* = Call_CreateDomainAssociation_606314(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_606315, base: "/",
    url: url_CreateDomainAssociation_606316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_606297 = ref object of OpenApiRestCall_605589
proc url_ListDomainAssociations_606299(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDomainAssociations_606298(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  List domains with an app 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606300 = path.getOrDefault("appId")
  valid_606300 = validateParameter(valid_606300, JString, required = true,
                                 default = nil)
  if valid_606300 != nil:
    section.add "appId", valid_606300
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_606301 = query.getOrDefault("nextToken")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "nextToken", valid_606301
  var valid_606302 = query.getOrDefault("maxResults")
  valid_606302 = validateParameter(valid_606302, JInt, required = false, default = nil)
  if valid_606302 != nil:
    section.add "maxResults", valid_606302
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
  var valid_606303 = header.getOrDefault("X-Amz-Signature")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Signature", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Content-Sha256", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Date")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Date", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Credential")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Credential", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Security-Token")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Security-Token", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Algorithm")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Algorithm", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-SignedHeaders", valid_606309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606310: Call_ListDomainAssociations_606297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_606310.validator(path, query, header, formData, body)
  let scheme = call_606310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606310.url(scheme.get, call_606310.host, call_606310.base,
                         call_606310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606310, url, valid)

proc call*(call_606311: Call_ListDomainAssociations_606297; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_606312 = newJObject()
  var query_606313 = newJObject()
  add(query_606313, "nextToken", newJString(nextToken))
  add(path_606312, "appId", newJString(appId))
  add(query_606313, "maxResults", newJInt(maxResults))
  result = call_606311.call(path_606312, query_606313, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_606297(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_606298, base: "/",
    url: url_ListDomainAssociations_606299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_606347 = ref object of OpenApiRestCall_605589
proc url_CreateWebhook_606349(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/webhooks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateWebhook_606348(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Create a new webhook on an App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606350 = path.getOrDefault("appId")
  valid_606350 = validateParameter(valid_606350, JString, required = true,
                                 default = nil)
  if valid_606350 != nil:
    section.add "appId", valid_606350
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
  var valid_606351 = header.getOrDefault("X-Amz-Signature")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Signature", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Content-Sha256", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Date")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Date", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Credential")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Credential", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Security-Token")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Security-Token", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Algorithm")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Algorithm", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-SignedHeaders", valid_606357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606359: Call_CreateWebhook_606347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_606359.validator(path, query, header, formData, body)
  let scheme = call_606359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606359.url(scheme.get, call_606359.host, call_606359.base,
                         call_606359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606359, url, valid)

proc call*(call_606360: Call_CreateWebhook_606347; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606361 = newJObject()
  var body_606362 = newJObject()
  add(path_606361, "appId", newJString(appId))
  if body != nil:
    body_606362 = body
  result = call_606360.call(path_606361, nil, nil, nil, body_606362)

var createWebhook* = Call_CreateWebhook_606347(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_606348,
    base: "/", url: url_CreateWebhook_606349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_606330 = ref object of OpenApiRestCall_605589
proc url_ListWebhooks_606332(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/webhooks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListWebhooks_606331(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  List webhooks with an app. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606333 = path.getOrDefault("appId")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = nil)
  if valid_606333 != nil:
    section.add "appId", valid_606333
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_606334 = query.getOrDefault("nextToken")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "nextToken", valid_606334
  var valid_606335 = query.getOrDefault("maxResults")
  valid_606335 = validateParameter(valid_606335, JInt, required = false, default = nil)
  if valid_606335 != nil:
    section.add "maxResults", valid_606335
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
  var valid_606336 = header.getOrDefault("X-Amz-Signature")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Signature", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Content-Sha256", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Date")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Date", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Credential")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Credential", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Security-Token")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Security-Token", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Algorithm")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Algorithm", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-SignedHeaders", valid_606342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_ListWebhooks_606330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_ListWebhooks_606330; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_606345 = newJObject()
  var query_606346 = newJObject()
  add(query_606346, "nextToken", newJString(nextToken))
  add(path_606345, "appId", newJString(appId))
  add(query_606346, "maxResults", newJInt(maxResults))
  result = call_606344.call(path_606345, query_606346, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_606330(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_606331,
    base: "/", url: url_ListWebhooks_606332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_606377 = ref object of OpenApiRestCall_605589
proc url_UpdateApp_606379(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApp_606378(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates an existing Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606380 = path.getOrDefault("appId")
  valid_606380 = validateParameter(valid_606380, JString, required = true,
                                 default = nil)
  if valid_606380 != nil:
    section.add "appId", valid_606380
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
  var valid_606381 = header.getOrDefault("X-Amz-Signature")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Signature", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Content-Sha256", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Date")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Date", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Credential")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Credential", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Security-Token")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Security-Token", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Algorithm")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Algorithm", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-SignedHeaders", valid_606387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606389: Call_UpdateApp_606377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_606389.validator(path, query, header, formData, body)
  let scheme = call_606389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606389.url(scheme.get, call_606389.host, call_606389.base,
                         call_606389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606389, url, valid)

proc call*(call_606390: Call_UpdateApp_606377; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606391 = newJObject()
  var body_606392 = newJObject()
  add(path_606391, "appId", newJString(appId))
  if body != nil:
    body_606392 = body
  result = call_606390.call(path_606391, nil, nil, nil, body_606392)

var updateApp* = Call_UpdateApp_606377(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_606378,
                                    base: "/", url: url_UpdateApp_606379,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_606363 = ref object of OpenApiRestCall_605589
proc url_GetApp_606365(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApp_606364(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606366 = path.getOrDefault("appId")
  valid_606366 = validateParameter(valid_606366, JString, required = true,
                                 default = nil)
  if valid_606366 != nil:
    section.add "appId", valid_606366
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
  var valid_606367 = header.getOrDefault("X-Amz-Signature")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Signature", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Content-Sha256", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Date")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Date", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Credential")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Credential", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Security-Token")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Security-Token", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Algorithm")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Algorithm", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-SignedHeaders", valid_606373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606374: Call_GetApp_606363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_606374.validator(path, query, header, formData, body)
  let scheme = call_606374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606374.url(scheme.get, call_606374.host, call_606374.base,
                         call_606374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606374, url, valid)

proc call*(call_606375: Call_GetApp_606363; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606376 = newJObject()
  add(path_606376, "appId", newJString(appId))
  result = call_606375.call(path_606376, nil, nil, nil, nil)

var getApp* = Call_GetApp_606363(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_606364,
                              base: "/", url: url_GetApp_606365,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_606393 = ref object of OpenApiRestCall_605589
proc url_DeleteApp_606395(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApp_606394(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete an existing Amplify App by appId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606396 = path.getOrDefault("appId")
  valid_606396 = validateParameter(valid_606396, JString, required = true,
                                 default = nil)
  if valid_606396 != nil:
    section.add "appId", valid_606396
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
  var valid_606397 = header.getOrDefault("X-Amz-Signature")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Signature", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Content-Sha256", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Date")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Date", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Credential")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Credential", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Security-Token")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Security-Token", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Algorithm")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Algorithm", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-SignedHeaders", valid_606403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606404: Call_DeleteApp_606393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_606404.validator(path, query, header, formData, body)
  let scheme = call_606404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606404.url(scheme.get, call_606404.host, call_606404.base,
                         call_606404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606404, url, valid)

proc call*(call_606405: Call_DeleteApp_606393; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606406 = newJObject()
  add(path_606406, "appId", newJString(appId))
  result = call_606405.call(path_606406, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_606393(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_606394,
                                    base: "/", url: url_DeleteApp_606395,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackendEnvironment_606407 = ref object of OpenApiRestCall_605589
proc url_GetBackendEnvironment_606409(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "environmentName" in path, "`environmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments/"),
               (kind: VariableSegment, value: "environmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackendEnvironment_606408(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves a backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   environmentName: JString (required)
  ##                  :  Name for the backend environment. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `environmentName` field"
  var valid_606410 = path.getOrDefault("environmentName")
  valid_606410 = validateParameter(valid_606410, JString, required = true,
                                 default = nil)
  if valid_606410 != nil:
    section.add "environmentName", valid_606410
  var valid_606411 = path.getOrDefault("appId")
  valid_606411 = validateParameter(valid_606411, JString, required = true,
                                 default = nil)
  if valid_606411 != nil:
    section.add "appId", valid_606411
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
  var valid_606412 = header.getOrDefault("X-Amz-Signature")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Signature", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Content-Sha256", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Date")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Date", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Credential")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Credential", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Security-Token")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Security-Token", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Algorithm")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Algorithm", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-SignedHeaders", valid_606418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606419: Call_GetBackendEnvironment_606407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a backend environment for an Amplify App. 
  ## 
  let valid = call_606419.validator(path, query, header, formData, body)
  let scheme = call_606419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606419.url(scheme.get, call_606419.host, call_606419.base,
                         call_606419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606419, url, valid)

proc call*(call_606420: Call_GetBackendEnvironment_606407; environmentName: string;
          appId: string): Recallable =
  ## getBackendEnvironment
  ##  Retrieves a backend environment for an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name for the backend environment. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606421 = newJObject()
  add(path_606421, "environmentName", newJString(environmentName))
  add(path_606421, "appId", newJString(appId))
  result = call_606420.call(path_606421, nil, nil, nil, nil)

var getBackendEnvironment* = Call_GetBackendEnvironment_606407(
    name: "getBackendEnvironment", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_GetBackendEnvironment_606408, base: "/",
    url: url_GetBackendEnvironment_606409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackendEnvironment_606422 = ref object of OpenApiRestCall_605589
proc url_DeleteBackendEnvironment_606424(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "environmentName" in path, "`environmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments/"),
               (kind: VariableSegment, value: "environmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackendEnvironment_606423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   environmentName: JString (required)
  ##                  :  Name of a backend environment of an Amplify App. 
  ##   appId: JString (required)
  ##        :  Unique Id of an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `environmentName` field"
  var valid_606425 = path.getOrDefault("environmentName")
  valid_606425 = validateParameter(valid_606425, JString, required = true,
                                 default = nil)
  if valid_606425 != nil:
    section.add "environmentName", valid_606425
  var valid_606426 = path.getOrDefault("appId")
  valid_606426 = validateParameter(valid_606426, JString, required = true,
                                 default = nil)
  if valid_606426 != nil:
    section.add "appId", valid_606426
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
  var valid_606427 = header.getOrDefault("X-Amz-Signature")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Signature", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Content-Sha256", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Date")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Date", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Credential")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Credential", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Security-Token")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Security-Token", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Algorithm")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Algorithm", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-SignedHeaders", valid_606433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606434: Call_DeleteBackendEnvironment_606422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete backend environment for an Amplify App. 
  ## 
  let valid = call_606434.validator(path, query, header, formData, body)
  let scheme = call_606434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606434.url(scheme.get, call_606434.host, call_606434.base,
                         call_606434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606434, url, valid)

proc call*(call_606435: Call_DeleteBackendEnvironment_606422;
          environmentName: string; appId: string): Recallable =
  ## deleteBackendEnvironment
  ##  Delete backend environment for an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name of a backend environment of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id of an Amplify App. 
  var path_606436 = newJObject()
  add(path_606436, "environmentName", newJString(environmentName))
  add(path_606436, "appId", newJString(appId))
  result = call_606435.call(path_606436, nil, nil, nil, nil)

var deleteBackendEnvironment* = Call_DeleteBackendEnvironment_606422(
    name: "deleteBackendEnvironment", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_DeleteBackendEnvironment_606423, base: "/",
    url: url_DeleteBackendEnvironment_606424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_606452 = ref object of OpenApiRestCall_605589
proc url_UpdateBranch_606454(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBranch_606453(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_606455 = path.getOrDefault("branchName")
  valid_606455 = validateParameter(valid_606455, JString, required = true,
                                 default = nil)
  if valid_606455 != nil:
    section.add "branchName", valid_606455
  var valid_606456 = path.getOrDefault("appId")
  valid_606456 = validateParameter(valid_606456, JString, required = true,
                                 default = nil)
  if valid_606456 != nil:
    section.add "appId", valid_606456
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
  var valid_606457 = header.getOrDefault("X-Amz-Signature")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Signature", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Content-Sha256", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Date")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Date", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Credential")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Credential", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Security-Token")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Security-Token", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Algorithm")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Algorithm", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-SignedHeaders", valid_606463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606465: Call_UpdateBranch_606452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_606465.validator(path, query, header, formData, body)
  let scheme = call_606465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606465.url(scheme.get, call_606465.host, call_606465.base,
                         call_606465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606465, url, valid)

proc call*(call_606466: Call_UpdateBranch_606452; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606467 = newJObject()
  var body_606468 = newJObject()
  add(path_606467, "branchName", newJString(branchName))
  add(path_606467, "appId", newJString(appId))
  if body != nil:
    body_606468 = body
  result = call_606466.call(path_606467, nil, nil, nil, body_606468)

var updateBranch* = Call_UpdateBranch_606452(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_606453, base: "/", url: url_UpdateBranch_606454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_606437 = ref object of OpenApiRestCall_605589
proc url_GetBranch_606439(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBranch_606438(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_606440 = path.getOrDefault("branchName")
  valid_606440 = validateParameter(valid_606440, JString, required = true,
                                 default = nil)
  if valid_606440 != nil:
    section.add "branchName", valid_606440
  var valid_606441 = path.getOrDefault("appId")
  valid_606441 = validateParameter(valid_606441, JString, required = true,
                                 default = nil)
  if valid_606441 != nil:
    section.add "appId", valid_606441
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
  var valid_606442 = header.getOrDefault("X-Amz-Signature")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Signature", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Content-Sha256", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Date")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Date", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Credential")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Credential", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Security-Token")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Security-Token", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Algorithm")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Algorithm", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-SignedHeaders", valid_606448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606449: Call_GetBranch_606437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_606449.validator(path, query, header, formData, body)
  let scheme = call_606449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606449.url(scheme.get, call_606449.host, call_606449.base,
                         call_606449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606449, url, valid)

proc call*(call_606450: Call_GetBranch_606437; branchName: string; appId: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606451 = newJObject()
  add(path_606451, "branchName", newJString(branchName))
  add(path_606451, "appId", newJString(appId))
  result = call_606450.call(path_606451, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_606437(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_606438,
                                    base: "/", url: url_GetBranch_606439,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_606469 = ref object of OpenApiRestCall_605589
proc url_DeleteBranch_606471(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBranch_606470(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_606472 = path.getOrDefault("branchName")
  valid_606472 = validateParameter(valid_606472, JString, required = true,
                                 default = nil)
  if valid_606472 != nil:
    section.add "branchName", valid_606472
  var valid_606473 = path.getOrDefault("appId")
  valid_606473 = validateParameter(valid_606473, JString, required = true,
                                 default = nil)
  if valid_606473 != nil:
    section.add "appId", valid_606473
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
  var valid_606474 = header.getOrDefault("X-Amz-Signature")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Signature", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Content-Sha256", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Date")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Date", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Credential")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Credential", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Security-Token")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Security-Token", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Algorithm")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Algorithm", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-SignedHeaders", valid_606480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606481: Call_DeleteBranch_606469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_606481.validator(path, query, header, formData, body)
  let scheme = call_606481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606481.url(scheme.get, call_606481.host, call_606481.base,
                         call_606481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606481, url, valid)

proc call*(call_606482: Call_DeleteBranch_606469; branchName: string; appId: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606483 = newJObject()
  add(path_606483, "branchName", newJString(branchName))
  add(path_606483, "appId", newJString(appId))
  result = call_606482.call(path_606483, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_606469(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_606470, base: "/", url: url_DeleteBranch_606471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_606499 = ref object of OpenApiRestCall_605589
proc url_UpdateDomainAssociation_606501(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainAssociation_606500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Create a new DomainAssociation on an App 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: JString (required)
  ##             :  Name of the domain. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606502 = path.getOrDefault("appId")
  valid_606502 = validateParameter(valid_606502, JString, required = true,
                                 default = nil)
  if valid_606502 != nil:
    section.add "appId", valid_606502
  var valid_606503 = path.getOrDefault("domainName")
  valid_606503 = validateParameter(valid_606503, JString, required = true,
                                 default = nil)
  if valid_606503 != nil:
    section.add "domainName", valid_606503
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
  var valid_606504 = header.getOrDefault("X-Amz-Signature")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Signature", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Content-Sha256", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Date")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Date", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Credential")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Credential", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Security-Token")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Security-Token", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Algorithm")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Algorithm", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-SignedHeaders", valid_606510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606512: Call_UpdateDomainAssociation_606499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_606512.validator(path, query, header, formData, body)
  let scheme = call_606512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606512.url(scheme.get, call_606512.host, call_606512.base,
                         call_606512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606512, url, valid)

proc call*(call_606513: Call_UpdateDomainAssociation_606499; appId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_606514 = newJObject()
  var body_606515 = newJObject()
  add(path_606514, "appId", newJString(appId))
  if body != nil:
    body_606515 = body
  add(path_606514, "domainName", newJString(domainName))
  result = call_606513.call(path_606514, nil, nil, nil, body_606515)

var updateDomainAssociation* = Call_UpdateDomainAssociation_606499(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_606500, base: "/",
    url: url_UpdateDomainAssociation_606501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_606484 = ref object of OpenApiRestCall_605589
proc url_GetDomainAssociation_606486(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainAssociation_606485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: JString (required)
  ##             :  Name of the domain. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606487 = path.getOrDefault("appId")
  valid_606487 = validateParameter(valid_606487, JString, required = true,
                                 default = nil)
  if valid_606487 != nil:
    section.add "appId", valid_606487
  var valid_606488 = path.getOrDefault("domainName")
  valid_606488 = validateParameter(valid_606488, JString, required = true,
                                 default = nil)
  if valid_606488 != nil:
    section.add "domainName", valid_606488
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
  var valid_606489 = header.getOrDefault("X-Amz-Signature")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Signature", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Content-Sha256", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Date")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Date", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Credential")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Credential", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Security-Token")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Security-Token", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Algorithm")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Algorithm", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-SignedHeaders", valid_606495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606496: Call_GetDomainAssociation_606484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_606496.validator(path, query, header, formData, body)
  let scheme = call_606496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606496.url(scheme.get, call_606496.host, call_606496.base,
                         call_606496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606496, url, valid)

proc call*(call_606497: Call_GetDomainAssociation_606484; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_606498 = newJObject()
  add(path_606498, "appId", newJString(appId))
  add(path_606498, "domainName", newJString(domainName))
  result = call_606497.call(path_606498, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_606484(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_606485, base: "/",
    url: url_GetDomainAssociation_606486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_606516 = ref object of OpenApiRestCall_605589
proc url_DeleteDomainAssociation_606518(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainAssociation_606517(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a DomainAssociation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: JString (required)
  ##             :  Name of the domain. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606519 = path.getOrDefault("appId")
  valid_606519 = validateParameter(valid_606519, JString, required = true,
                                 default = nil)
  if valid_606519 != nil:
    section.add "appId", valid_606519
  var valid_606520 = path.getOrDefault("domainName")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = nil)
  if valid_606520 != nil:
    section.add "domainName", valid_606520
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
  var valid_606521 = header.getOrDefault("X-Amz-Signature")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Signature", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Content-Sha256", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Date")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Date", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Credential")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Credential", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Security-Token")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Security-Token", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Algorithm")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Algorithm", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-SignedHeaders", valid_606527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606528: Call_DeleteDomainAssociation_606516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_606528.validator(path, query, header, formData, body)
  let scheme = call_606528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606528.url(scheme.get, call_606528.host, call_606528.base,
                         call_606528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606528, url, valid)

proc call*(call_606529: Call_DeleteDomainAssociation_606516; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_606530 = newJObject()
  add(path_606530, "appId", newJString(appId))
  add(path_606530, "domainName", newJString(domainName))
  result = call_606529.call(path_606530, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_606516(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_606517, base: "/",
    url: url_DeleteDomainAssociation_606518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_606531 = ref object of OpenApiRestCall_605589
proc url_GetJob_606533(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_606532(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_606534 = path.getOrDefault("jobId")
  valid_606534 = validateParameter(valid_606534, JString, required = true,
                                 default = nil)
  if valid_606534 != nil:
    section.add "jobId", valid_606534
  var valid_606535 = path.getOrDefault("branchName")
  valid_606535 = validateParameter(valid_606535, JString, required = true,
                                 default = nil)
  if valid_606535 != nil:
    section.add "branchName", valid_606535
  var valid_606536 = path.getOrDefault("appId")
  valid_606536 = validateParameter(valid_606536, JString, required = true,
                                 default = nil)
  if valid_606536 != nil:
    section.add "appId", valid_606536
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
  var valid_606537 = header.getOrDefault("X-Amz-Signature")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Signature", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Content-Sha256", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Date")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Date", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Credential")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Credential", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Security-Token")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Security-Token", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Algorithm")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Algorithm", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-SignedHeaders", valid_606543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606544: Call_GetJob_606531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_606544.validator(path, query, header, formData, body)
  let scheme = call_606544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606544.url(scheme.get, call_606544.host, call_606544.base,
                         call_606544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606544, url, valid)

proc call*(call_606545: Call_GetJob_606531; jobId: string; branchName: string;
          appId: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606546 = newJObject()
  add(path_606546, "jobId", newJString(jobId))
  add(path_606546, "branchName", newJString(branchName))
  add(path_606546, "appId", newJString(appId))
  result = call_606545.call(path_606546, nil, nil, nil, nil)

var getJob* = Call_GetJob_606531(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_606532, base: "/",
                              url: url_GetJob_606533,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_606547 = ref object of OpenApiRestCall_605589
proc url_DeleteJob_606549(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteJob_606548(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_606550 = path.getOrDefault("jobId")
  valid_606550 = validateParameter(valid_606550, JString, required = true,
                                 default = nil)
  if valid_606550 != nil:
    section.add "jobId", valid_606550
  var valid_606551 = path.getOrDefault("branchName")
  valid_606551 = validateParameter(valid_606551, JString, required = true,
                                 default = nil)
  if valid_606551 != nil:
    section.add "branchName", valid_606551
  var valid_606552 = path.getOrDefault("appId")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = nil)
  if valid_606552 != nil:
    section.add "appId", valid_606552
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
  var valid_606553 = header.getOrDefault("X-Amz-Signature")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Signature", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Content-Sha256", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Date")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Date", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Credential")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Credential", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Security-Token")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Security-Token", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Algorithm")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Algorithm", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-SignedHeaders", valid_606559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606560: Call_DeleteJob_606547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_606560.validator(path, query, header, formData, body)
  let scheme = call_606560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606560.url(scheme.get, call_606560.host, call_606560.base,
                         call_606560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606560, url, valid)

proc call*(call_606561: Call_DeleteJob_606547; jobId: string; branchName: string;
          appId: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606562 = newJObject()
  add(path_606562, "jobId", newJString(jobId))
  add(path_606562, "branchName", newJString(branchName))
  add(path_606562, "appId", newJString(appId))
  result = call_606561.call(path_606562, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_606547(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_606548,
                                    base: "/", url: url_DeleteJob_606549,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_606577 = ref object of OpenApiRestCall_605589
proc url_UpdateWebhook_606579(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
               (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateWebhook_606578(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Update a webhook. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
  ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `webhookId` field"
  var valid_606580 = path.getOrDefault("webhookId")
  valid_606580 = validateParameter(valid_606580, JString, required = true,
                                 default = nil)
  if valid_606580 != nil:
    section.add "webhookId", valid_606580
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
  var valid_606581 = header.getOrDefault("X-Amz-Signature")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Signature", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Content-Sha256", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Date")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Date", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Credential")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Credential", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Security-Token")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Security-Token", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Algorithm")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Algorithm", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-SignedHeaders", valid_606587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_UpdateWebhook_606577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_UpdateWebhook_606577; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_606591 = newJObject()
  var body_606592 = newJObject()
  add(path_606591, "webhookId", newJString(webhookId))
  if body != nil:
    body_606592 = body
  result = call_606590.call(path_606591, nil, nil, nil, body_606592)

var updateWebhook* = Call_UpdateWebhook_606577(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_606578,
    base: "/", url: url_UpdateWebhook_606579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_606563 = ref object of OpenApiRestCall_605589
proc url_GetWebhook_606565(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
               (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetWebhook_606564(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
  ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `webhookId` field"
  var valid_606566 = path.getOrDefault("webhookId")
  valid_606566 = validateParameter(valid_606566, JString, required = true,
                                 default = nil)
  if valid_606566 != nil:
    section.add "webhookId", valid_606566
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
  var valid_606567 = header.getOrDefault("X-Amz-Signature")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Signature", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Content-Sha256", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Date")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Date", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Credential")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Credential", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Security-Token")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Security-Token", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Algorithm")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Algorithm", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-SignedHeaders", valid_606573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606574: Call_GetWebhook_606563; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_606574.validator(path, query, header, formData, body)
  let scheme = call_606574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606574.url(scheme.get, call_606574.host, call_606574.base,
                         call_606574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606574, url, valid)

proc call*(call_606575: Call_GetWebhook_606563; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_606576 = newJObject()
  add(path_606576, "webhookId", newJString(webhookId))
  result = call_606575.call(path_606576, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_606563(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_606564,
                                      base: "/", url: url_GetWebhook_606565,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_606593 = ref object of OpenApiRestCall_605589
proc url_DeleteWebhook_606595(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
               (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteWebhook_606594(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a webhook. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
  ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `webhookId` field"
  var valid_606596 = path.getOrDefault("webhookId")
  valid_606596 = validateParameter(valid_606596, JString, required = true,
                                 default = nil)
  if valid_606596 != nil:
    section.add "webhookId", valid_606596
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
  var valid_606597 = header.getOrDefault("X-Amz-Signature")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Signature", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Content-Sha256", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Date")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Date", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Credential")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Credential", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Security-Token")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Security-Token", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Algorithm")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Algorithm", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-SignedHeaders", valid_606603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606604: Call_DeleteWebhook_606593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_606604.validator(path, query, header, formData, body)
  let scheme = call_606604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606604.url(scheme.get, call_606604.host, call_606604.base,
                         call_606604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606604, url, valid)

proc call*(call_606605: Call_DeleteWebhook_606593; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_606606 = newJObject()
  add(path_606606, "webhookId", newJString(webhookId))
  result = call_606605.call(path_606606, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_606593(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_606594,
    base: "/", url: url_DeleteWebhook_606595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_606607 = ref object of OpenApiRestCall_605589
proc url_GenerateAccessLogs_606609(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/accesslogs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GenerateAccessLogs_606608(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_606610 = path.getOrDefault("appId")
  valid_606610 = validateParameter(valid_606610, JString, required = true,
                                 default = nil)
  if valid_606610 != nil:
    section.add "appId", valid_606610
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
  var valid_606611 = header.getOrDefault("X-Amz-Signature")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Signature", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Content-Sha256", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Date")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Date", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Credential")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Credential", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Security-Token")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Security-Token", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Algorithm")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Algorithm", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-SignedHeaders", valid_606617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606619: Call_GenerateAccessLogs_606607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ## 
  let valid = call_606619.validator(path, query, header, formData, body)
  let scheme = call_606619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606619.url(scheme.get, call_606619.host, call_606619.base,
                         call_606619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606619, url, valid)

proc call*(call_606620: Call_GenerateAccessLogs_606607; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606621 = newJObject()
  var body_606622 = newJObject()
  add(path_606621, "appId", newJString(appId))
  if body != nil:
    body_606622 = body
  result = call_606620.call(path_606621, nil, nil, nil, body_606622)

var generateAccessLogs* = Call_GenerateAccessLogs_606607(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_606608, base: "/",
    url: url_GenerateAccessLogs_606609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_606623 = ref object of OpenApiRestCall_605589
proc url_GetArtifactUrl_606625(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "artifactId" in path, "`artifactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/artifacts/"),
               (kind: VariableSegment, value: "artifactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetArtifactUrl_606624(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   artifactId: JString (required)
  ##             :  Unique Id for a artifact. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `artifactId` field"
  var valid_606626 = path.getOrDefault("artifactId")
  valid_606626 = validateParameter(valid_606626, JString, required = true,
                                 default = nil)
  if valid_606626 != nil:
    section.add "artifactId", valid_606626
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
  var valid_606627 = header.getOrDefault("X-Amz-Signature")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Signature", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Content-Sha256", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Date")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Date", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Credential")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Credential", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Security-Token")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Security-Token", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Algorithm")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Algorithm", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-SignedHeaders", valid_606633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606634: Call_GetArtifactUrl_606623; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_606634.validator(path, query, header, formData, body)
  let scheme = call_606634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606634.url(scheme.get, call_606634.host, call_606634.base,
                         call_606634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606634, url, valid)

proc call*(call_606635: Call_GetArtifactUrl_606623; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_606636 = newJObject()
  add(path_606636, "artifactId", newJString(artifactId))
  result = call_606635.call(path_606636, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_606623(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_606624,
    base: "/", url: url_GetArtifactUrl_606625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_606637 = ref object of OpenApiRestCall_605589
proc url_ListArtifacts_606639(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId"),
               (kind: ConstantSegment, value: "/artifacts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListArtifacts_606638(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for an Job. 
  ##   branchName: JString (required)
  ##             :  Name for a branch, part of an Amplify App. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_606640 = path.getOrDefault("jobId")
  valid_606640 = validateParameter(valid_606640, JString, required = true,
                                 default = nil)
  if valid_606640 != nil:
    section.add "jobId", valid_606640
  var valid_606641 = path.getOrDefault("branchName")
  valid_606641 = validateParameter(valid_606641, JString, required = true,
                                 default = nil)
  if valid_606641 != nil:
    section.add "branchName", valid_606641
  var valid_606642 = path.getOrDefault("appId")
  valid_606642 = validateParameter(valid_606642, JString, required = true,
                                 default = nil)
  if valid_606642 != nil:
    section.add "appId", valid_606642
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_606643 = query.getOrDefault("nextToken")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "nextToken", valid_606643
  var valid_606644 = query.getOrDefault("maxResults")
  valid_606644 = validateParameter(valid_606644, JInt, required = false, default = nil)
  if valid_606644 != nil:
    section.add "maxResults", valid_606644
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
  var valid_606645 = header.getOrDefault("X-Amz-Signature")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Signature", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Content-Sha256", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Date")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Date", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Credential")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Credential", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Security-Token")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Security-Token", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Algorithm")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Algorithm", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-SignedHeaders", valid_606651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606652: Call_ListArtifacts_606637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_606652.validator(path, query, header, formData, body)
  let scheme = call_606652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606652.url(scheme.get, call_606652.host, call_606652.base,
                         call_606652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606652, url, valid)

proc call*(call_606653: Call_ListArtifacts_606637; jobId: string; branchName: string;
          appId: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listArtifacts
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   jobId: string (required)
  ##        :  Unique Id for an Job. 
  ##   branchName: string (required)
  ##             :  Name for a branch, part of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_606654 = newJObject()
  var query_606655 = newJObject()
  add(query_606655, "nextToken", newJString(nextToken))
  add(path_606654, "jobId", newJString(jobId))
  add(path_606654, "branchName", newJString(branchName))
  add(path_606654, "appId", newJString(appId))
  add(query_606655, "maxResults", newJInt(maxResults))
  result = call_606653.call(path_606654, query_606655, nil, nil, nil)

var listArtifacts* = Call_ListArtifacts_606637(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_606638, base: "/", url: url_ListArtifacts_606639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_606674 = ref object of OpenApiRestCall_605589
proc url_StartJob_606676(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_606675(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_606677 = path.getOrDefault("branchName")
  valid_606677 = validateParameter(valid_606677, JString, required = true,
                                 default = nil)
  if valid_606677 != nil:
    section.add "branchName", valid_606677
  var valid_606678 = path.getOrDefault("appId")
  valid_606678 = validateParameter(valid_606678, JString, required = true,
                                 default = nil)
  if valid_606678 != nil:
    section.add "appId", valid_606678
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
  var valid_606679 = header.getOrDefault("X-Amz-Signature")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Signature", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Content-Sha256", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Date")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Date", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Credential")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Credential", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Security-Token")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Security-Token", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Algorithm")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Algorithm", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-SignedHeaders", valid_606685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606687: Call_StartJob_606674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_606687.validator(path, query, header, formData, body)
  let scheme = call_606687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606687.url(scheme.get, call_606687.host, call_606687.base,
                         call_606687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606687, url, valid)

proc call*(call_606688: Call_StartJob_606674; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606689 = newJObject()
  var body_606690 = newJObject()
  add(path_606689, "branchName", newJString(branchName))
  add(path_606689, "appId", newJString(appId))
  if body != nil:
    body_606690 = body
  result = call_606688.call(path_606689, nil, nil, nil, body_606690)

var startJob* = Call_StartJob_606674(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_606675, base: "/",
                                  url: url_StartJob_606676,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_606656 = ref object of OpenApiRestCall_605589
proc url_ListJobs_606658(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJobs_606657(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for a branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_606659 = path.getOrDefault("branchName")
  valid_606659 = validateParameter(valid_606659, JString, required = true,
                                 default = nil)
  if valid_606659 != nil:
    section.add "branchName", valid_606659
  var valid_606660 = path.getOrDefault("appId")
  valid_606660 = validateParameter(valid_606660, JString, required = true,
                                 default = nil)
  if valid_606660 != nil:
    section.add "appId", valid_606660
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_606661 = query.getOrDefault("nextToken")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "nextToken", valid_606661
  var valid_606662 = query.getOrDefault("maxResults")
  valid_606662 = validateParameter(valid_606662, JInt, required = false, default = nil)
  if valid_606662 != nil:
    section.add "maxResults", valid_606662
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
  var valid_606663 = header.getOrDefault("X-Amz-Signature")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Signature", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Content-Sha256", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Date")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Date", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Credential")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Credential", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Security-Token")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Security-Token", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Algorithm")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Algorithm", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-SignedHeaders", valid_606669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606670: Call_ListJobs_606656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_606670.validator(path, query, header, formData, body)
  let scheme = call_606670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606670.url(scheme.get, call_606670.host, call_606670.base,
                         call_606670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606670, url, valid)

proc call*(call_606671: Call_ListJobs_606656; branchName: string; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listJobs
  ##  List Jobs for a branch, part of an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   branchName: string (required)
  ##             :  Name for a branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_606672 = newJObject()
  var query_606673 = newJObject()
  add(query_606673, "nextToken", newJString(nextToken))
  add(path_606672, "branchName", newJString(branchName))
  add(path_606672, "appId", newJString(appId))
  add(query_606673, "maxResults", newJInt(maxResults))
  result = call_606671.call(path_606672, query_606673, nil, nil, nil)

var listJobs* = Call_ListJobs_606656(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_606657, base: "/",
                                  url: url_ListJobs_606658,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606705 = ref object of OpenApiRestCall_605589
proc url_TagResource_606707(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
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

proc validate_TagResource_606706(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Tag resource with tag key and value. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  Resource arn used to tag resource. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606708 = path.getOrDefault("resourceArn")
  valid_606708 = validateParameter(valid_606708, JString, required = true,
                                 default = nil)
  if valid_606708 != nil:
    section.add "resourceArn", valid_606708
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
  var valid_606709 = header.getOrDefault("X-Amz-Signature")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Signature", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Content-Sha256", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Date")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Date", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Credential")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Credential", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Security-Token")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Security-Token", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Algorithm")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Algorithm", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-SignedHeaders", valid_606715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606717: Call_TagResource_606705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_606717.validator(path, query, header, formData, body)
  let scheme = call_606717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606717.url(scheme.get, call_606717.host, call_606717.base,
                         call_606717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606717, url, valid)

proc call*(call_606718: Call_TagResource_606705; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  ##   body: JObject (required)
  var path_606719 = newJObject()
  var body_606720 = newJObject()
  add(path_606719, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606720 = body
  result = call_606718.call(path_606719, nil, nil, nil, body_606720)

var tagResource* = Call_TagResource_606705(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606706,
                                        base: "/", url: url_TagResource_606707,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606691 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606693(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
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

proc validate_ListTagsForResource_606692(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  List tags for resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  Resource arn used to list tags. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606694 = path.getOrDefault("resourceArn")
  valid_606694 = validateParameter(valid_606694, JString, required = true,
                                 default = nil)
  if valid_606694 != nil:
    section.add "resourceArn", valid_606694
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
  var valid_606695 = header.getOrDefault("X-Amz-Signature")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Signature", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Content-Sha256", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Date")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Date", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Credential")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Credential", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Security-Token")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Security-Token", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Algorithm")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Algorithm", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-SignedHeaders", valid_606701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606702: Call_ListTagsForResource_606691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_606702.validator(path, query, header, formData, body)
  let scheme = call_606702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606702.url(scheme.get, call_606702.host, call_606702.base,
                         call_606702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606702, url, valid)

proc call*(call_606703: Call_ListTagsForResource_606691; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_606704 = newJObject()
  add(path_606704, "resourceArn", newJString(resourceArn))
  result = call_606703.call(path_606704, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606691(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606692, base: "/",
    url: url_ListTagsForResource_606693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_606721 = ref object of OpenApiRestCall_605589
proc url_StartDeployment_606723(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/deployments/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDeployment_606722(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_606724 = path.getOrDefault("branchName")
  valid_606724 = validateParameter(valid_606724, JString, required = true,
                                 default = nil)
  if valid_606724 != nil:
    section.add "branchName", valid_606724
  var valid_606725 = path.getOrDefault("appId")
  valid_606725 = validateParameter(valid_606725, JString, required = true,
                                 default = nil)
  if valid_606725 != nil:
    section.add "appId", valid_606725
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
  var valid_606726 = header.getOrDefault("X-Amz-Signature")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Signature", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Content-Sha256", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Date")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Date", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Credential")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Credential", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Security-Token")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Security-Token", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Algorithm")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Algorithm", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-SignedHeaders", valid_606732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606734: Call_StartDeployment_606721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_606734.validator(path, query, header, formData, body)
  let scheme = call_606734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606734.url(scheme.get, call_606734.host, call_606734.base,
                         call_606734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606734, url, valid)

proc call*(call_606735: Call_StartDeployment_606721; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_606736 = newJObject()
  var body_606737 = newJObject()
  add(path_606736, "branchName", newJString(branchName))
  add(path_606736, "appId", newJString(appId))
  if body != nil:
    body_606737 = body
  result = call_606735.call(path_606736, nil, nil, nil, body_606737)

var startDeployment* = Call_StartDeployment_606721(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_606722, base: "/", url: url_StartDeployment_606723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_606738 = ref object of OpenApiRestCall_605589
proc url_StopJob_606740(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId"),
               (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopJob_606739(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_606741 = path.getOrDefault("jobId")
  valid_606741 = validateParameter(valid_606741, JString, required = true,
                                 default = nil)
  if valid_606741 != nil:
    section.add "jobId", valid_606741
  var valid_606742 = path.getOrDefault("branchName")
  valid_606742 = validateParameter(valid_606742, JString, required = true,
                                 default = nil)
  if valid_606742 != nil:
    section.add "branchName", valid_606742
  var valid_606743 = path.getOrDefault("appId")
  valid_606743 = validateParameter(valid_606743, JString, required = true,
                                 default = nil)
  if valid_606743 != nil:
    section.add "appId", valid_606743
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
  var valid_606744 = header.getOrDefault("X-Amz-Signature")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Signature", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Content-Sha256", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Date")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Date", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Credential")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Credential", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Security-Token")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Security-Token", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Algorithm")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Algorithm", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-SignedHeaders", valid_606750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606751: Call_StopJob_606738; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_606751.validator(path, query, header, formData, body)
  let scheme = call_606751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606751.url(scheme.get, call_606751.host, call_606751.base,
                         call_606751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606751, url, valid)

proc call*(call_606752: Call_StopJob_606738; jobId: string; branchName: string;
          appId: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_606753 = newJObject()
  add(path_606753, "jobId", newJString(jobId))
  add(path_606753, "branchName", newJString(branchName))
  add(path_606753, "appId", newJString(appId))
  result = call_606752.call(path_606753, nil, nil, nil, nil)

var stopJob* = Call_StopJob_606738(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_606739, base: "/",
                                url: url_StopJob_606740,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606754 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606756(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
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

proc validate_UntagResource_606755(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Untag resource with resourceArn. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  Resource arn used to untag resource. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_606757 = path.getOrDefault("resourceArn")
  valid_606757 = validateParameter(valid_606757, JString, required = true,
                                 default = nil)
  if valid_606757 != nil:
    section.add "resourceArn", valid_606757
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606758 = query.getOrDefault("tagKeys")
  valid_606758 = validateParameter(valid_606758, JArray, required = true, default = nil)
  if valid_606758 != nil:
    section.add "tagKeys", valid_606758
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
  var valid_606759 = header.getOrDefault("X-Amz-Signature")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Signature", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Content-Sha256", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Date")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Date", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Credential")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Credential", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Security-Token")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Security-Token", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Algorithm")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Algorithm", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-SignedHeaders", valid_606765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606766: Call_UntagResource_606754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_606766.validator(path, query, header, formData, body)
  let scheme = call_606766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606766.url(scheme.get, call_606766.host, call_606766.base,
                         call_606766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606766, url, valid)

proc call*(call_606767: Call_UntagResource_606754; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  var path_606768 = newJObject()
  var query_606769 = newJObject()
  add(path_606768, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606769.add "tagKeys", tagKeys
  result = call_606767.call(path_606768, query_606769, nil, nil, nil)

var untagResource* = Call_UntagResource_606754(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606755,
    base: "/", url: url_UntagResource_606756, schemes: {Scheme.Https, Scheme.Http})
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
