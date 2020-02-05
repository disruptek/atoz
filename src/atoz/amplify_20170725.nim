
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
  Call_CreateApp_613253 = ref object of OpenApiRestCall_612658
proc url_CreateApp_613255(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_613254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613256 = header.getOrDefault("X-Amz-Signature")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Signature", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Content-Sha256", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Date")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Date", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Credential")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Credential", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Security-Token")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Security-Token", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Algorithm")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Algorithm", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-SignedHeaders", valid_613262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613264: Call_CreateApp_613253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_613264.validator(path, query, header, formData, body)
  let scheme = call_613264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613264.url(scheme.get, call_613264.host, call_613264.base,
                         call_613264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613264, url, valid)

proc call*(call_613265: Call_CreateApp_613253; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_613266 = newJObject()
  if body != nil:
    body_613266 = body
  result = call_613265.call(nil, nil, nil, nil, body_613266)

var createApp* = Call_CreateApp_613253(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_613254,
                                    base: "/", url: url_CreateApp_613255,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_612996 = ref object of OpenApiRestCall_612658
proc url_ListApps_612998(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListApps_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613110 = query.getOrDefault("nextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "nextToken", valid_613110
  var valid_613111 = query.getOrDefault("maxResults")
  valid_613111 = validateParameter(valid_613111, JInt, required = false, default = nil)
  if valid_613111 != nil:
    section.add "maxResults", valid_613111
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
  var valid_613112 = header.getOrDefault("X-Amz-Signature")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Signature", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Content-Sha256", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Date")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Date", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Credential")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Credential", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Security-Token")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Security-Token", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Algorithm")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Algorithm", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-SignedHeaders", valid_613118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_ListApps_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613212: Call_ListApps_612996; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_613213 = newJObject()
  add(query_613213, "nextToken", newJString(nextToken))
  add(query_613213, "maxResults", newJInt(maxResults))
  result = call_613212.call(nil, query_613213, nil, nil, nil)

var listApps* = Call_ListApps_612996(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_612997, base: "/",
                                  url: url_ListApps_612998,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackendEnvironment_613300 = ref object of OpenApiRestCall_612658
proc url_CreateBackendEnvironment_613302(protocol: Scheme; host: string;
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

proc validate_CreateBackendEnvironment_613301(path: JsonNode; query: JsonNode;
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
  var valid_613303 = path.getOrDefault("appId")
  valid_613303 = validateParameter(valid_613303, JString, required = true,
                                 default = nil)
  if valid_613303 != nil:
    section.add "appId", valid_613303
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
  var valid_613304 = header.getOrDefault("X-Amz-Signature")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Signature", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Content-Sha256", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Date")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Date", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Credential")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Credential", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Security-Token")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Security-Token", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Algorithm")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Algorithm", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-SignedHeaders", valid_613310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613312: Call_CreateBackendEnvironment_613300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new backend environment for an Amplify App. 
  ## 
  let valid = call_613312.validator(path, query, header, formData, body)
  let scheme = call_613312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613312.url(scheme.get, call_613312.host, call_613312.base,
                         call_613312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613312, url, valid)

proc call*(call_613313: Call_CreateBackendEnvironment_613300; appId: string;
          body: JsonNode): Recallable =
  ## createBackendEnvironment
  ##  Creates a new backend environment for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613314 = newJObject()
  var body_613315 = newJObject()
  add(path_613314, "appId", newJString(appId))
  if body != nil:
    body_613315 = body
  result = call_613313.call(path_613314, nil, nil, nil, body_613315)

var createBackendEnvironment* = Call_CreateBackendEnvironment_613300(
    name: "createBackendEnvironment", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_CreateBackendEnvironment_613301, base: "/",
    url: url_CreateBackendEnvironment_613302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackendEnvironments_613267 = ref object of OpenApiRestCall_612658
proc url_ListBackendEnvironments_613269(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackendEnvironments_613268(path: JsonNode; query: JsonNode;
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
  var valid_613284 = path.getOrDefault("appId")
  valid_613284 = validateParameter(valid_613284, JString, required = true,
                                 default = nil)
  if valid_613284 != nil:
    section.add "appId", valid_613284
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing backen environments from start. If a non-null pagination token is returned in a result, then pass its value in here to list more backend environments. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613285 = query.getOrDefault("nextToken")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "nextToken", valid_613285
  var valid_613286 = query.getOrDefault("maxResults")
  valid_613286 = validateParameter(valid_613286, JInt, required = false, default = nil)
  if valid_613286 != nil:
    section.add "maxResults", valid_613286
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
  var valid_613287 = header.getOrDefault("X-Amz-Signature")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Signature", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Content-Sha256", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Date")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Date", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Credential")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Credential", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Security-Token")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Security-Token", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Algorithm")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Algorithm", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-SignedHeaders", valid_613293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613295: Call_ListBackendEnvironments_613267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists backend environments for an Amplify App. 
  ## 
  let valid = call_613295.validator(path, query, header, formData, body)
  let scheme = call_613295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613295.url(scheme.get, call_613295.host, call_613295.base,
                         call_613295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613295, url, valid)

proc call*(call_613296: Call_ListBackendEnvironments_613267; appId: string;
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
  var path_613297 = newJObject()
  var query_613298 = newJObject()
  var body_613299 = newJObject()
  add(query_613298, "nextToken", newJString(nextToken))
  add(path_613297, "appId", newJString(appId))
  if body != nil:
    body_613299 = body
  add(query_613298, "maxResults", newJInt(maxResults))
  result = call_613296.call(path_613297, query_613298, nil, nil, body_613299)

var listBackendEnvironments* = Call_ListBackendEnvironments_613267(
    name: "listBackendEnvironments", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_ListBackendEnvironments_613268, base: "/",
    url: url_ListBackendEnvironments_613269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_613333 = ref object of OpenApiRestCall_612658
proc url_CreateBranch_613335(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBranch_613334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613336 = path.getOrDefault("appId")
  valid_613336 = validateParameter(valid_613336, JString, required = true,
                                 default = nil)
  if valid_613336 != nil:
    section.add "appId", valid_613336
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
  var valid_613337 = header.getOrDefault("X-Amz-Signature")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Signature", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Content-Sha256", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Date")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Date", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Credential")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Credential", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Security-Token")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Security-Token", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Algorithm")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Algorithm", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-SignedHeaders", valid_613343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613345: Call_CreateBranch_613333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_613345.validator(path, query, header, formData, body)
  let scheme = call_613345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613345.url(scheme.get, call_613345.host, call_613345.base,
                         call_613345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613345, url, valid)

proc call*(call_613346: Call_CreateBranch_613333; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613347 = newJObject()
  var body_613348 = newJObject()
  add(path_613347, "appId", newJString(appId))
  if body != nil:
    body_613348 = body
  result = call_613346.call(path_613347, nil, nil, nil, body_613348)

var createBranch* = Call_CreateBranch_613333(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_613334,
    base: "/", url: url_CreateBranch_613335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_613316 = ref object of OpenApiRestCall_612658
proc url_ListBranches_613318(protocol: Scheme; host: string; base: string;
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

proc validate_ListBranches_613317(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613319 = path.getOrDefault("appId")
  valid_613319 = validateParameter(valid_613319, JString, required = true,
                                 default = nil)
  if valid_613319 != nil:
    section.add "appId", valid_613319
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613320 = query.getOrDefault("nextToken")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "nextToken", valid_613320
  var valid_613321 = query.getOrDefault("maxResults")
  valid_613321 = validateParameter(valid_613321, JInt, required = false, default = nil)
  if valid_613321 != nil:
    section.add "maxResults", valid_613321
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
  var valid_613322 = header.getOrDefault("X-Amz-Signature")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Signature", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Content-Sha256", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Date")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Date", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Credential")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Credential", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Security-Token")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Security-Token", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Algorithm")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Algorithm", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-SignedHeaders", valid_613328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613329: Call_ListBranches_613316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_613329.validator(path, query, header, formData, body)
  let scheme = call_613329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613329.url(scheme.get, call_613329.host, call_613329.base,
                         call_613329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613329, url, valid)

proc call*(call_613330: Call_ListBranches_613316; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_613331 = newJObject()
  var query_613332 = newJObject()
  add(query_613332, "nextToken", newJString(nextToken))
  add(path_613331, "appId", newJString(appId))
  add(query_613332, "maxResults", newJInt(maxResults))
  result = call_613330.call(path_613331, query_613332, nil, nil, nil)

var listBranches* = Call_ListBranches_613316(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_613317,
    base: "/", url: url_ListBranches_613318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_613349 = ref object of OpenApiRestCall_612658
proc url_CreateDeployment_613351(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_613350(path: JsonNode; query: JsonNode;
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
  var valid_613352 = path.getOrDefault("branchName")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "branchName", valid_613352
  var valid_613353 = path.getOrDefault("appId")
  valid_613353 = validateParameter(valid_613353, JString, required = true,
                                 default = nil)
  if valid_613353 != nil:
    section.add "appId", valid_613353
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
  var valid_613354 = header.getOrDefault("X-Amz-Signature")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Signature", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Content-Sha256", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Date")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Date", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Credential")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Credential", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Security-Token")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Security-Token", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Algorithm")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Algorithm", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-SignedHeaders", valid_613360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613362: Call_CreateDeployment_613349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_613362.validator(path, query, header, formData, body)
  let scheme = call_613362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613362.url(scheme.get, call_613362.host, call_613362.base,
                         call_613362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613362, url, valid)

proc call*(call_613363: Call_CreateDeployment_613349; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613364 = newJObject()
  var body_613365 = newJObject()
  add(path_613364, "branchName", newJString(branchName))
  add(path_613364, "appId", newJString(appId))
  if body != nil:
    body_613365 = body
  result = call_613363.call(path_613364, nil, nil, nil, body_613365)

var createDeployment* = Call_CreateDeployment_613349(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_613350, base: "/",
    url: url_CreateDeployment_613351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_613383 = ref object of OpenApiRestCall_612658
proc url_CreateDomainAssociation_613385(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainAssociation_613384(path: JsonNode; query: JsonNode;
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
  var valid_613386 = path.getOrDefault("appId")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = nil)
  if valid_613386 != nil:
    section.add "appId", valid_613386
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
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_CreateDomainAssociation_613383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_CreateDomainAssociation_613383; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613397 = newJObject()
  var body_613398 = newJObject()
  add(path_613397, "appId", newJString(appId))
  if body != nil:
    body_613398 = body
  result = call_613396.call(path_613397, nil, nil, nil, body_613398)

var createDomainAssociation* = Call_CreateDomainAssociation_613383(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_613384, base: "/",
    url: url_CreateDomainAssociation_613385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_613366 = ref object of OpenApiRestCall_612658
proc url_ListDomainAssociations_613368(protocol: Scheme; host: string; base: string;
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

proc validate_ListDomainAssociations_613367(path: JsonNode; query: JsonNode;
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
  var valid_613369 = path.getOrDefault("appId")
  valid_613369 = validateParameter(valid_613369, JString, required = true,
                                 default = nil)
  if valid_613369 != nil:
    section.add "appId", valid_613369
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613370 = query.getOrDefault("nextToken")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "nextToken", valid_613370
  var valid_613371 = query.getOrDefault("maxResults")
  valid_613371 = validateParameter(valid_613371, JInt, required = false, default = nil)
  if valid_613371 != nil:
    section.add "maxResults", valid_613371
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
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613379: Call_ListDomainAssociations_613366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_613379.validator(path, query, header, formData, body)
  let scheme = call_613379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613379.url(scheme.get, call_613379.host, call_613379.base,
                         call_613379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613379, url, valid)

proc call*(call_613380: Call_ListDomainAssociations_613366; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_613381 = newJObject()
  var query_613382 = newJObject()
  add(query_613382, "nextToken", newJString(nextToken))
  add(path_613381, "appId", newJString(appId))
  add(query_613382, "maxResults", newJInt(maxResults))
  result = call_613380.call(path_613381, query_613382, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_613366(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_613367, base: "/",
    url: url_ListDomainAssociations_613368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_613416 = ref object of OpenApiRestCall_612658
proc url_CreateWebhook_613418(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWebhook_613417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613419 = path.getOrDefault("appId")
  valid_613419 = validateParameter(valid_613419, JString, required = true,
                                 default = nil)
  if valid_613419 != nil:
    section.add "appId", valid_613419
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
  var valid_613420 = header.getOrDefault("X-Amz-Signature")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Signature", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Content-Sha256", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Date")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Date", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Credential")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Credential", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Security-Token")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Security-Token", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Algorithm")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Algorithm", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-SignedHeaders", valid_613426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613428: Call_CreateWebhook_613416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_613428.validator(path, query, header, formData, body)
  let scheme = call_613428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613428.url(scheme.get, call_613428.host, call_613428.base,
                         call_613428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613428, url, valid)

proc call*(call_613429: Call_CreateWebhook_613416; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613430 = newJObject()
  var body_613431 = newJObject()
  add(path_613430, "appId", newJString(appId))
  if body != nil:
    body_613431 = body
  result = call_613429.call(path_613430, nil, nil, nil, body_613431)

var createWebhook* = Call_CreateWebhook_613416(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_613417,
    base: "/", url: url_CreateWebhook_613418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_613399 = ref object of OpenApiRestCall_612658
proc url_ListWebhooks_613401(protocol: Scheme; host: string; base: string;
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

proc validate_ListWebhooks_613400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613402 = path.getOrDefault("appId")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = nil)
  if valid_613402 != nil:
    section.add "appId", valid_613402
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613403 = query.getOrDefault("nextToken")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "nextToken", valid_613403
  var valid_613404 = query.getOrDefault("maxResults")
  valid_613404 = validateParameter(valid_613404, JInt, required = false, default = nil)
  if valid_613404 != nil:
    section.add "maxResults", valid_613404
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
  var valid_613405 = header.getOrDefault("X-Amz-Signature")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Signature", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Content-Sha256", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Date")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Date", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Credential")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Credential", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Security-Token")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Security-Token", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Algorithm")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Algorithm", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-SignedHeaders", valid_613411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_ListWebhooks_613399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_ListWebhooks_613399; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_613414 = newJObject()
  var query_613415 = newJObject()
  add(query_613415, "nextToken", newJString(nextToken))
  add(path_613414, "appId", newJString(appId))
  add(query_613415, "maxResults", newJInt(maxResults))
  result = call_613413.call(path_613414, query_613415, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_613399(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_613400,
    base: "/", url: url_ListWebhooks_613401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_613446 = ref object of OpenApiRestCall_612658
proc url_UpdateApp_613448(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApp_613447(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613449 = path.getOrDefault("appId")
  valid_613449 = validateParameter(valid_613449, JString, required = true,
                                 default = nil)
  if valid_613449 != nil:
    section.add "appId", valid_613449
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
  var valid_613450 = header.getOrDefault("X-Amz-Signature")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Signature", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Content-Sha256", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Date")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Date", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Credential")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Credential", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Security-Token")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Security-Token", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Algorithm")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Algorithm", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-SignedHeaders", valid_613456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613458: Call_UpdateApp_613446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_613458.validator(path, query, header, formData, body)
  let scheme = call_613458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613458.url(scheme.get, call_613458.host, call_613458.base,
                         call_613458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613458, url, valid)

proc call*(call_613459: Call_UpdateApp_613446; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613460 = newJObject()
  var body_613461 = newJObject()
  add(path_613460, "appId", newJString(appId))
  if body != nil:
    body_613461 = body
  result = call_613459.call(path_613460, nil, nil, nil, body_613461)

var updateApp* = Call_UpdateApp_613446(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_613447,
                                    base: "/", url: url_UpdateApp_613448,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_613432 = ref object of OpenApiRestCall_612658
proc url_GetApp_613434(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_613433(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613435 = path.getOrDefault("appId")
  valid_613435 = validateParameter(valid_613435, JString, required = true,
                                 default = nil)
  if valid_613435 != nil:
    section.add "appId", valid_613435
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
  var valid_613436 = header.getOrDefault("X-Amz-Signature")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Signature", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Content-Sha256", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Date")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Date", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Credential")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Credential", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Security-Token")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Security-Token", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Algorithm")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Algorithm", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-SignedHeaders", valid_613442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613443: Call_GetApp_613432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_613443.validator(path, query, header, formData, body)
  let scheme = call_613443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613443.url(scheme.get, call_613443.host, call_613443.base,
                         call_613443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613443, url, valid)

proc call*(call_613444: Call_GetApp_613432; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613445 = newJObject()
  add(path_613445, "appId", newJString(appId))
  result = call_613444.call(path_613445, nil, nil, nil, nil)

var getApp* = Call_GetApp_613432(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_613433,
                              base: "/", url: url_GetApp_613434,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_613462 = ref object of OpenApiRestCall_612658
proc url_DeleteApp_613464(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_613463(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613465 = path.getOrDefault("appId")
  valid_613465 = validateParameter(valid_613465, JString, required = true,
                                 default = nil)
  if valid_613465 != nil:
    section.add "appId", valid_613465
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
  var valid_613466 = header.getOrDefault("X-Amz-Signature")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Signature", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Content-Sha256", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Date")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Date", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Credential")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Credential", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Security-Token")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Security-Token", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Algorithm")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Algorithm", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-SignedHeaders", valid_613472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613473: Call_DeleteApp_613462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_613473.validator(path, query, header, formData, body)
  let scheme = call_613473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613473.url(scheme.get, call_613473.host, call_613473.base,
                         call_613473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613473, url, valid)

proc call*(call_613474: Call_DeleteApp_613462; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613475 = newJObject()
  add(path_613475, "appId", newJString(appId))
  result = call_613474.call(path_613475, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_613462(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_613463,
                                    base: "/", url: url_DeleteApp_613464,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackendEnvironment_613476 = ref object of OpenApiRestCall_612658
proc url_GetBackendEnvironment_613478(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackendEnvironment_613477(path: JsonNode; query: JsonNode;
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
  var valid_613479 = path.getOrDefault("environmentName")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = nil)
  if valid_613479 != nil:
    section.add "environmentName", valid_613479
  var valid_613480 = path.getOrDefault("appId")
  valid_613480 = validateParameter(valid_613480, JString, required = true,
                                 default = nil)
  if valid_613480 != nil:
    section.add "appId", valid_613480
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
  var valid_613481 = header.getOrDefault("X-Amz-Signature")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Signature", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Content-Sha256", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Date")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Date", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Credential")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Credential", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Security-Token")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Security-Token", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Algorithm")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Algorithm", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-SignedHeaders", valid_613487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613488: Call_GetBackendEnvironment_613476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a backend environment for an Amplify App. 
  ## 
  let valid = call_613488.validator(path, query, header, formData, body)
  let scheme = call_613488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613488.url(scheme.get, call_613488.host, call_613488.base,
                         call_613488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613488, url, valid)

proc call*(call_613489: Call_GetBackendEnvironment_613476; environmentName: string;
          appId: string): Recallable =
  ## getBackendEnvironment
  ##  Retrieves a backend environment for an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name for the backend environment. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613490 = newJObject()
  add(path_613490, "environmentName", newJString(environmentName))
  add(path_613490, "appId", newJString(appId))
  result = call_613489.call(path_613490, nil, nil, nil, nil)

var getBackendEnvironment* = Call_GetBackendEnvironment_613476(
    name: "getBackendEnvironment", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_GetBackendEnvironment_613477, base: "/",
    url: url_GetBackendEnvironment_613478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackendEnvironment_613491 = ref object of OpenApiRestCall_612658
proc url_DeleteBackendEnvironment_613493(protocol: Scheme; host: string;
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

proc validate_DeleteBackendEnvironment_613492(path: JsonNode; query: JsonNode;
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
  var valid_613494 = path.getOrDefault("environmentName")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = nil)
  if valid_613494 != nil:
    section.add "environmentName", valid_613494
  var valid_613495 = path.getOrDefault("appId")
  valid_613495 = validateParameter(valid_613495, JString, required = true,
                                 default = nil)
  if valid_613495 != nil:
    section.add "appId", valid_613495
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
  var valid_613496 = header.getOrDefault("X-Amz-Signature")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Signature", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Content-Sha256", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Date")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Date", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Credential")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Credential", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Security-Token")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Security-Token", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Algorithm")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Algorithm", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-SignedHeaders", valid_613502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613503: Call_DeleteBackendEnvironment_613491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete backend environment for an Amplify App. 
  ## 
  let valid = call_613503.validator(path, query, header, formData, body)
  let scheme = call_613503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613503.url(scheme.get, call_613503.host, call_613503.base,
                         call_613503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613503, url, valid)

proc call*(call_613504: Call_DeleteBackendEnvironment_613491;
          environmentName: string; appId: string): Recallable =
  ## deleteBackendEnvironment
  ##  Delete backend environment for an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name of a backend environment of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id of an Amplify App. 
  var path_613505 = newJObject()
  add(path_613505, "environmentName", newJString(environmentName))
  add(path_613505, "appId", newJString(appId))
  result = call_613504.call(path_613505, nil, nil, nil, nil)

var deleteBackendEnvironment* = Call_DeleteBackendEnvironment_613491(
    name: "deleteBackendEnvironment", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_DeleteBackendEnvironment_613492, base: "/",
    url: url_DeleteBackendEnvironment_613493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_613521 = ref object of OpenApiRestCall_612658
proc url_UpdateBranch_613523(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBranch_613522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613524 = path.getOrDefault("branchName")
  valid_613524 = validateParameter(valid_613524, JString, required = true,
                                 default = nil)
  if valid_613524 != nil:
    section.add "branchName", valid_613524
  var valid_613525 = path.getOrDefault("appId")
  valid_613525 = validateParameter(valid_613525, JString, required = true,
                                 default = nil)
  if valid_613525 != nil:
    section.add "appId", valid_613525
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
  var valid_613526 = header.getOrDefault("X-Amz-Signature")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Signature", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Content-Sha256", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Date")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Date", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Credential")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Credential", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Security-Token")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Security-Token", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Algorithm")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Algorithm", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-SignedHeaders", valid_613532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613534: Call_UpdateBranch_613521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_613534.validator(path, query, header, formData, body)
  let scheme = call_613534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613534.url(scheme.get, call_613534.host, call_613534.base,
                         call_613534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613534, url, valid)

proc call*(call_613535: Call_UpdateBranch_613521; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613536 = newJObject()
  var body_613537 = newJObject()
  add(path_613536, "branchName", newJString(branchName))
  add(path_613536, "appId", newJString(appId))
  if body != nil:
    body_613537 = body
  result = call_613535.call(path_613536, nil, nil, nil, body_613537)

var updateBranch* = Call_UpdateBranch_613521(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_613522, base: "/", url: url_UpdateBranch_613523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_613506 = ref object of OpenApiRestCall_612658
proc url_GetBranch_613508(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBranch_613507(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613509 = path.getOrDefault("branchName")
  valid_613509 = validateParameter(valid_613509, JString, required = true,
                                 default = nil)
  if valid_613509 != nil:
    section.add "branchName", valid_613509
  var valid_613510 = path.getOrDefault("appId")
  valid_613510 = validateParameter(valid_613510, JString, required = true,
                                 default = nil)
  if valid_613510 != nil:
    section.add "appId", valid_613510
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
  var valid_613511 = header.getOrDefault("X-Amz-Signature")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Signature", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Content-Sha256", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Date")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Date", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Credential")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Credential", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Security-Token")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Security-Token", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Algorithm")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Algorithm", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-SignedHeaders", valid_613517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613518: Call_GetBranch_613506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_613518.validator(path, query, header, formData, body)
  let scheme = call_613518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613518.url(scheme.get, call_613518.host, call_613518.base,
                         call_613518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613518, url, valid)

proc call*(call_613519: Call_GetBranch_613506; branchName: string; appId: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613520 = newJObject()
  add(path_613520, "branchName", newJString(branchName))
  add(path_613520, "appId", newJString(appId))
  result = call_613519.call(path_613520, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_613506(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_613507,
                                    base: "/", url: url_GetBranch_613508,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_613538 = ref object of OpenApiRestCall_612658
proc url_DeleteBranch_613540(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBranch_613539(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613541 = path.getOrDefault("branchName")
  valid_613541 = validateParameter(valid_613541, JString, required = true,
                                 default = nil)
  if valid_613541 != nil:
    section.add "branchName", valid_613541
  var valid_613542 = path.getOrDefault("appId")
  valid_613542 = validateParameter(valid_613542, JString, required = true,
                                 default = nil)
  if valid_613542 != nil:
    section.add "appId", valid_613542
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
  var valid_613543 = header.getOrDefault("X-Amz-Signature")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Signature", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Content-Sha256", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Date")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Date", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Credential")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Credential", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Security-Token")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Security-Token", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Algorithm")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Algorithm", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-SignedHeaders", valid_613549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613550: Call_DeleteBranch_613538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_613550.validator(path, query, header, formData, body)
  let scheme = call_613550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613550.url(scheme.get, call_613550.host, call_613550.base,
                         call_613550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613550, url, valid)

proc call*(call_613551: Call_DeleteBranch_613538; branchName: string; appId: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613552 = newJObject()
  add(path_613552, "branchName", newJString(branchName))
  add(path_613552, "appId", newJString(appId))
  result = call_613551.call(path_613552, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_613538(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_613539, base: "/", url: url_DeleteBranch_613540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_613568 = ref object of OpenApiRestCall_612658
proc url_UpdateDomainAssociation_613570(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainAssociation_613569(path: JsonNode; query: JsonNode;
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
  var valid_613571 = path.getOrDefault("appId")
  valid_613571 = validateParameter(valid_613571, JString, required = true,
                                 default = nil)
  if valid_613571 != nil:
    section.add "appId", valid_613571
  var valid_613572 = path.getOrDefault("domainName")
  valid_613572 = validateParameter(valid_613572, JString, required = true,
                                 default = nil)
  if valid_613572 != nil:
    section.add "domainName", valid_613572
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
  var valid_613573 = header.getOrDefault("X-Amz-Signature")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Signature", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Content-Sha256", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Date")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Date", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Credential")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Credential", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Security-Token")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Security-Token", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Algorithm")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Algorithm", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-SignedHeaders", valid_613579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613581: Call_UpdateDomainAssociation_613568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_613581.validator(path, query, header, formData, body)
  let scheme = call_613581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613581.url(scheme.get, call_613581.host, call_613581.base,
                         call_613581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613581, url, valid)

proc call*(call_613582: Call_UpdateDomainAssociation_613568; appId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_613583 = newJObject()
  var body_613584 = newJObject()
  add(path_613583, "appId", newJString(appId))
  if body != nil:
    body_613584 = body
  add(path_613583, "domainName", newJString(domainName))
  result = call_613582.call(path_613583, nil, nil, nil, body_613584)

var updateDomainAssociation* = Call_UpdateDomainAssociation_613568(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_613569, base: "/",
    url: url_UpdateDomainAssociation_613570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_613553 = ref object of OpenApiRestCall_612658
proc url_GetDomainAssociation_613555(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainAssociation_613554(path: JsonNode; query: JsonNode;
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
  var valid_613556 = path.getOrDefault("appId")
  valid_613556 = validateParameter(valid_613556, JString, required = true,
                                 default = nil)
  if valid_613556 != nil:
    section.add "appId", valid_613556
  var valid_613557 = path.getOrDefault("domainName")
  valid_613557 = validateParameter(valid_613557, JString, required = true,
                                 default = nil)
  if valid_613557 != nil:
    section.add "domainName", valid_613557
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
  var valid_613558 = header.getOrDefault("X-Amz-Signature")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Signature", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Content-Sha256", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Date")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Date", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Credential")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Credential", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Security-Token")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Security-Token", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Algorithm")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Algorithm", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-SignedHeaders", valid_613564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613565: Call_GetDomainAssociation_613553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_613565.validator(path, query, header, formData, body)
  let scheme = call_613565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613565.url(scheme.get, call_613565.host, call_613565.base,
                         call_613565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613565, url, valid)

proc call*(call_613566: Call_GetDomainAssociation_613553; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_613567 = newJObject()
  add(path_613567, "appId", newJString(appId))
  add(path_613567, "domainName", newJString(domainName))
  result = call_613566.call(path_613567, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_613553(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_613554, base: "/",
    url: url_GetDomainAssociation_613555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_613585 = ref object of OpenApiRestCall_612658
proc url_DeleteDomainAssociation_613587(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainAssociation_613586(path: JsonNode; query: JsonNode;
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
  var valid_613588 = path.getOrDefault("appId")
  valid_613588 = validateParameter(valid_613588, JString, required = true,
                                 default = nil)
  if valid_613588 != nil:
    section.add "appId", valid_613588
  var valid_613589 = path.getOrDefault("domainName")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = nil)
  if valid_613589 != nil:
    section.add "domainName", valid_613589
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
  var valid_613590 = header.getOrDefault("X-Amz-Signature")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Signature", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Content-Sha256", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Date")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Date", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Credential")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Credential", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Security-Token")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Security-Token", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Algorithm")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Algorithm", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-SignedHeaders", valid_613596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613597: Call_DeleteDomainAssociation_613585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_613597.validator(path, query, header, formData, body)
  let scheme = call_613597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613597.url(scheme.get, call_613597.host, call_613597.base,
                         call_613597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613597, url, valid)

proc call*(call_613598: Call_DeleteDomainAssociation_613585; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_613599 = newJObject()
  add(path_613599, "appId", newJString(appId))
  add(path_613599, "domainName", newJString(domainName))
  result = call_613598.call(path_613599, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_613585(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_613586, base: "/",
    url: url_DeleteDomainAssociation_613587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_613600 = ref object of OpenApiRestCall_612658
proc url_GetJob_613602(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_613601(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613603 = path.getOrDefault("jobId")
  valid_613603 = validateParameter(valid_613603, JString, required = true,
                                 default = nil)
  if valid_613603 != nil:
    section.add "jobId", valid_613603
  var valid_613604 = path.getOrDefault("branchName")
  valid_613604 = validateParameter(valid_613604, JString, required = true,
                                 default = nil)
  if valid_613604 != nil:
    section.add "branchName", valid_613604
  var valid_613605 = path.getOrDefault("appId")
  valid_613605 = validateParameter(valid_613605, JString, required = true,
                                 default = nil)
  if valid_613605 != nil:
    section.add "appId", valid_613605
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
  var valid_613606 = header.getOrDefault("X-Amz-Signature")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Signature", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Content-Sha256", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Date")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Date", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Credential")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Credential", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Security-Token")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Security-Token", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Algorithm")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Algorithm", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-SignedHeaders", valid_613612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613613: Call_GetJob_613600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_613613.validator(path, query, header, formData, body)
  let scheme = call_613613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613613.url(scheme.get, call_613613.host, call_613613.base,
                         call_613613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613613, url, valid)

proc call*(call_613614: Call_GetJob_613600; jobId: string; branchName: string;
          appId: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613615 = newJObject()
  add(path_613615, "jobId", newJString(jobId))
  add(path_613615, "branchName", newJString(branchName))
  add(path_613615, "appId", newJString(appId))
  result = call_613614.call(path_613615, nil, nil, nil, nil)

var getJob* = Call_GetJob_613600(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_613601, base: "/",
                              url: url_GetJob_613602,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_613616 = ref object of OpenApiRestCall_612658
proc url_DeleteJob_613618(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_613617(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613619 = path.getOrDefault("jobId")
  valid_613619 = validateParameter(valid_613619, JString, required = true,
                                 default = nil)
  if valid_613619 != nil:
    section.add "jobId", valid_613619
  var valid_613620 = path.getOrDefault("branchName")
  valid_613620 = validateParameter(valid_613620, JString, required = true,
                                 default = nil)
  if valid_613620 != nil:
    section.add "branchName", valid_613620
  var valid_613621 = path.getOrDefault("appId")
  valid_613621 = validateParameter(valid_613621, JString, required = true,
                                 default = nil)
  if valid_613621 != nil:
    section.add "appId", valid_613621
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
  var valid_613622 = header.getOrDefault("X-Amz-Signature")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Signature", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Content-Sha256", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Date")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Date", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Credential")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Credential", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Security-Token")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Security-Token", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Algorithm")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Algorithm", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-SignedHeaders", valid_613628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613629: Call_DeleteJob_613616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_613629.validator(path, query, header, formData, body)
  let scheme = call_613629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613629.url(scheme.get, call_613629.host, call_613629.base,
                         call_613629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613629, url, valid)

proc call*(call_613630: Call_DeleteJob_613616; jobId: string; branchName: string;
          appId: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613631 = newJObject()
  add(path_613631, "jobId", newJString(jobId))
  add(path_613631, "branchName", newJString(branchName))
  add(path_613631, "appId", newJString(appId))
  result = call_613630.call(path_613631, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_613616(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_613617,
                                    base: "/", url: url_DeleteJob_613618,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_613646 = ref object of OpenApiRestCall_612658
proc url_UpdateWebhook_613648(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWebhook_613647(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613649 = path.getOrDefault("webhookId")
  valid_613649 = validateParameter(valid_613649, JString, required = true,
                                 default = nil)
  if valid_613649 != nil:
    section.add "webhookId", valid_613649
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
  var valid_613650 = header.getOrDefault("X-Amz-Signature")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Signature", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Content-Sha256", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Date")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Date", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Credential")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Credential", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Security-Token")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Security-Token", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Algorithm")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Algorithm", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-SignedHeaders", valid_613656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613658: Call_UpdateWebhook_613646; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_613658.validator(path, query, header, formData, body)
  let scheme = call_613658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613658.url(scheme.get, call_613658.host, call_613658.base,
                         call_613658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613658, url, valid)

proc call*(call_613659: Call_UpdateWebhook_613646; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_613660 = newJObject()
  var body_613661 = newJObject()
  add(path_613660, "webhookId", newJString(webhookId))
  if body != nil:
    body_613661 = body
  result = call_613659.call(path_613660, nil, nil, nil, body_613661)

var updateWebhook* = Call_UpdateWebhook_613646(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_613647,
    base: "/", url: url_UpdateWebhook_613648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_613632 = ref object of OpenApiRestCall_612658
proc url_GetWebhook_613634(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetWebhook_613633(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613635 = path.getOrDefault("webhookId")
  valid_613635 = validateParameter(valid_613635, JString, required = true,
                                 default = nil)
  if valid_613635 != nil:
    section.add "webhookId", valid_613635
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
  var valid_613636 = header.getOrDefault("X-Amz-Signature")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Signature", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Content-Sha256", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Date")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Date", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Credential")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Credential", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Security-Token")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Security-Token", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Algorithm")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Algorithm", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-SignedHeaders", valid_613642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613643: Call_GetWebhook_613632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_613643.validator(path, query, header, formData, body)
  let scheme = call_613643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613643.url(scheme.get, call_613643.host, call_613643.base,
                         call_613643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613643, url, valid)

proc call*(call_613644: Call_GetWebhook_613632; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_613645 = newJObject()
  add(path_613645, "webhookId", newJString(webhookId))
  result = call_613644.call(path_613645, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_613632(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_613633,
                                      base: "/", url: url_GetWebhook_613634,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_613662 = ref object of OpenApiRestCall_612658
proc url_DeleteWebhook_613664(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_613663(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613665 = path.getOrDefault("webhookId")
  valid_613665 = validateParameter(valid_613665, JString, required = true,
                                 default = nil)
  if valid_613665 != nil:
    section.add "webhookId", valid_613665
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
  var valid_613666 = header.getOrDefault("X-Amz-Signature")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Signature", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Content-Sha256", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Date")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Date", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Credential")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Credential", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Security-Token")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Security-Token", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Algorithm")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Algorithm", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-SignedHeaders", valid_613672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613673: Call_DeleteWebhook_613662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_613673.validator(path, query, header, formData, body)
  let scheme = call_613673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613673.url(scheme.get, call_613673.host, call_613673.base,
                         call_613673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613673, url, valid)

proc call*(call_613674: Call_DeleteWebhook_613662; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_613675 = newJObject()
  add(path_613675, "webhookId", newJString(webhookId))
  result = call_613674.call(path_613675, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_613662(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_613663,
    base: "/", url: url_DeleteWebhook_613664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_613676 = ref object of OpenApiRestCall_612658
proc url_GenerateAccessLogs_613678(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateAccessLogs_613677(path: JsonNode; query: JsonNode;
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
  var valid_613679 = path.getOrDefault("appId")
  valid_613679 = validateParameter(valid_613679, JString, required = true,
                                 default = nil)
  if valid_613679 != nil:
    section.add "appId", valid_613679
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
  var valid_613680 = header.getOrDefault("X-Amz-Signature")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Signature", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Content-Sha256", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Date")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Date", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Credential")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Credential", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Security-Token")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Security-Token", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Algorithm")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Algorithm", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-SignedHeaders", valid_613686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613688: Call_GenerateAccessLogs_613676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ## 
  let valid = call_613688.validator(path, query, header, formData, body)
  let scheme = call_613688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613688.url(scheme.get, call_613688.host, call_613688.base,
                         call_613688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613688, url, valid)

proc call*(call_613689: Call_GenerateAccessLogs_613676; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613690 = newJObject()
  var body_613691 = newJObject()
  add(path_613690, "appId", newJString(appId))
  if body != nil:
    body_613691 = body
  result = call_613689.call(path_613690, nil, nil, nil, body_613691)

var generateAccessLogs* = Call_GenerateAccessLogs_613676(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_613677, base: "/",
    url: url_GenerateAccessLogs_613678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_613692 = ref object of OpenApiRestCall_612658
proc url_GetArtifactUrl_613694(protocol: Scheme; host: string; base: string;
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

proc validate_GetArtifactUrl_613693(path: JsonNode; query: JsonNode;
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
  var valid_613695 = path.getOrDefault("artifactId")
  valid_613695 = validateParameter(valid_613695, JString, required = true,
                                 default = nil)
  if valid_613695 != nil:
    section.add "artifactId", valid_613695
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
  var valid_613696 = header.getOrDefault("X-Amz-Signature")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Signature", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Content-Sha256", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Date")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Date", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Credential")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Credential", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Security-Token")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Security-Token", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Algorithm")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Algorithm", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-SignedHeaders", valid_613702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613703: Call_GetArtifactUrl_613692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_613703.validator(path, query, header, formData, body)
  let scheme = call_613703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613703.url(scheme.get, call_613703.host, call_613703.base,
                         call_613703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613703, url, valid)

proc call*(call_613704: Call_GetArtifactUrl_613692; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_613705 = newJObject()
  add(path_613705, "artifactId", newJString(artifactId))
  result = call_613704.call(path_613705, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_613692(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_613693,
    base: "/", url: url_GetArtifactUrl_613694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_613706 = ref object of OpenApiRestCall_612658
proc url_ListArtifacts_613708(protocol: Scheme; host: string; base: string;
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

proc validate_ListArtifacts_613707(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613709 = path.getOrDefault("jobId")
  valid_613709 = validateParameter(valid_613709, JString, required = true,
                                 default = nil)
  if valid_613709 != nil:
    section.add "jobId", valid_613709
  var valid_613710 = path.getOrDefault("branchName")
  valid_613710 = validateParameter(valid_613710, JString, required = true,
                                 default = nil)
  if valid_613710 != nil:
    section.add "branchName", valid_613710
  var valid_613711 = path.getOrDefault("appId")
  valid_613711 = validateParameter(valid_613711, JString, required = true,
                                 default = nil)
  if valid_613711 != nil:
    section.add "appId", valid_613711
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613712 = query.getOrDefault("nextToken")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "nextToken", valid_613712
  var valid_613713 = query.getOrDefault("maxResults")
  valid_613713 = validateParameter(valid_613713, JInt, required = false, default = nil)
  if valid_613713 != nil:
    section.add "maxResults", valid_613713
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
  var valid_613714 = header.getOrDefault("X-Amz-Signature")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Signature", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Content-Sha256", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Date")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Date", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Credential")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Credential", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Security-Token")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Security-Token", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Algorithm")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Algorithm", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-SignedHeaders", valid_613720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613721: Call_ListArtifacts_613706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_613721.validator(path, query, header, formData, body)
  let scheme = call_613721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613721.url(scheme.get, call_613721.host, call_613721.base,
                         call_613721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613721, url, valid)

proc call*(call_613722: Call_ListArtifacts_613706; jobId: string; branchName: string;
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
  var path_613723 = newJObject()
  var query_613724 = newJObject()
  add(query_613724, "nextToken", newJString(nextToken))
  add(path_613723, "jobId", newJString(jobId))
  add(path_613723, "branchName", newJString(branchName))
  add(path_613723, "appId", newJString(appId))
  add(query_613724, "maxResults", newJInt(maxResults))
  result = call_613722.call(path_613723, query_613724, nil, nil, nil)

var listArtifacts* = Call_ListArtifacts_613706(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_613707, base: "/", url: url_ListArtifacts_613708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_613743 = ref object of OpenApiRestCall_612658
proc url_StartJob_613745(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartJob_613744(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613746 = path.getOrDefault("branchName")
  valid_613746 = validateParameter(valid_613746, JString, required = true,
                                 default = nil)
  if valid_613746 != nil:
    section.add "branchName", valid_613746
  var valid_613747 = path.getOrDefault("appId")
  valid_613747 = validateParameter(valid_613747, JString, required = true,
                                 default = nil)
  if valid_613747 != nil:
    section.add "appId", valid_613747
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
  var valid_613748 = header.getOrDefault("X-Amz-Signature")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Signature", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Content-Sha256", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Date")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Date", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Credential")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Credential", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Security-Token")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Security-Token", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Algorithm")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Algorithm", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-SignedHeaders", valid_613754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613756: Call_StartJob_613743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_613756.validator(path, query, header, formData, body)
  let scheme = call_613756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613756.url(scheme.get, call_613756.host, call_613756.base,
                         call_613756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613756, url, valid)

proc call*(call_613757: Call_StartJob_613743; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613758 = newJObject()
  var body_613759 = newJObject()
  add(path_613758, "branchName", newJString(branchName))
  add(path_613758, "appId", newJString(appId))
  if body != nil:
    body_613759 = body
  result = call_613757.call(path_613758, nil, nil, nil, body_613759)

var startJob* = Call_StartJob_613743(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_613744, base: "/",
                                  url: url_StartJob_613745,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_613725 = ref object of OpenApiRestCall_612658
proc url_ListJobs_613727(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_613726(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613728 = path.getOrDefault("branchName")
  valid_613728 = validateParameter(valid_613728, JString, required = true,
                                 default = nil)
  if valid_613728 != nil:
    section.add "branchName", valid_613728
  var valid_613729 = path.getOrDefault("appId")
  valid_613729 = validateParameter(valid_613729, JString, required = true,
                                 default = nil)
  if valid_613729 != nil:
    section.add "appId", valid_613729
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_613730 = query.getOrDefault("nextToken")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "nextToken", valid_613730
  var valid_613731 = query.getOrDefault("maxResults")
  valid_613731 = validateParameter(valid_613731, JInt, required = false, default = nil)
  if valid_613731 != nil:
    section.add "maxResults", valid_613731
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
  var valid_613732 = header.getOrDefault("X-Amz-Signature")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Signature", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Content-Sha256", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Date")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Date", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Credential")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Credential", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Security-Token")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Security-Token", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Algorithm")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Algorithm", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-SignedHeaders", valid_613738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613739: Call_ListJobs_613725; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_613739.validator(path, query, header, formData, body)
  let scheme = call_613739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613739.url(scheme.get, call_613739.host, call_613739.base,
                         call_613739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613739, url, valid)

proc call*(call_613740: Call_ListJobs_613725; branchName: string; appId: string;
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
  var path_613741 = newJObject()
  var query_613742 = newJObject()
  add(query_613742, "nextToken", newJString(nextToken))
  add(path_613741, "branchName", newJString(branchName))
  add(path_613741, "appId", newJString(appId))
  add(query_613742, "maxResults", newJInt(maxResults))
  result = call_613740.call(path_613741, query_613742, nil, nil, nil)

var listJobs* = Call_ListJobs_613725(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_613726, base: "/",
                                  url: url_ListJobs_613727,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613774 = ref object of OpenApiRestCall_612658
proc url_TagResource_613776(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613777 = path.getOrDefault("resourceArn")
  valid_613777 = validateParameter(valid_613777, JString, required = true,
                                 default = nil)
  if valid_613777 != nil:
    section.add "resourceArn", valid_613777
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
  var valid_613778 = header.getOrDefault("X-Amz-Signature")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Signature", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Content-Sha256", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Date")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Date", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Credential")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Credential", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Security-Token")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Security-Token", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Algorithm")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Algorithm", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-SignedHeaders", valid_613784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613786: Call_TagResource_613774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_613786.validator(path, query, header, formData, body)
  let scheme = call_613786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613786.url(scheme.get, call_613786.host, call_613786.base,
                         call_613786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613786, url, valid)

proc call*(call_613787: Call_TagResource_613774; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  ##   body: JObject (required)
  var path_613788 = newJObject()
  var body_613789 = newJObject()
  add(path_613788, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613789 = body
  result = call_613787.call(path_613788, nil, nil, nil, body_613789)

var tagResource* = Call_TagResource_613774(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613775,
                                        base: "/", url: url_TagResource_613776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613760 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613762(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613761(path: JsonNode; query: JsonNode;
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
  var valid_613763 = path.getOrDefault("resourceArn")
  valid_613763 = validateParameter(valid_613763, JString, required = true,
                                 default = nil)
  if valid_613763 != nil:
    section.add "resourceArn", valid_613763
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
  var valid_613764 = header.getOrDefault("X-Amz-Signature")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Signature", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Content-Sha256", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Date")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Date", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Credential")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Credential", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Security-Token")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Security-Token", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Algorithm")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Algorithm", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-SignedHeaders", valid_613770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613771: Call_ListTagsForResource_613760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_613771.validator(path, query, header, formData, body)
  let scheme = call_613771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613771.url(scheme.get, call_613771.host, call_613771.base,
                         call_613771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613771, url, valid)

proc call*(call_613772: Call_ListTagsForResource_613760; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_613773 = newJObject()
  add(path_613773, "resourceArn", newJString(resourceArn))
  result = call_613772.call(path_613773, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613760(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613761, base: "/",
    url: url_ListTagsForResource_613762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_613790 = ref object of OpenApiRestCall_612658
proc url_StartDeployment_613792(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_613791(path: JsonNode; query: JsonNode;
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
  var valid_613793 = path.getOrDefault("branchName")
  valid_613793 = validateParameter(valid_613793, JString, required = true,
                                 default = nil)
  if valid_613793 != nil:
    section.add "branchName", valid_613793
  var valid_613794 = path.getOrDefault("appId")
  valid_613794 = validateParameter(valid_613794, JString, required = true,
                                 default = nil)
  if valid_613794 != nil:
    section.add "appId", valid_613794
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
  var valid_613795 = header.getOrDefault("X-Amz-Signature")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Signature", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Content-Sha256", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Date")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Date", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Credential")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Credential", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Security-Token")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Security-Token", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Algorithm")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Algorithm", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-SignedHeaders", valid_613801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613803: Call_StartDeployment_613790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_613803.validator(path, query, header, formData, body)
  let scheme = call_613803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613803.url(scheme.get, call_613803.host, call_613803.base,
                         call_613803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613803, url, valid)

proc call*(call_613804: Call_StartDeployment_613790; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_613805 = newJObject()
  var body_613806 = newJObject()
  add(path_613805, "branchName", newJString(branchName))
  add(path_613805, "appId", newJString(appId))
  if body != nil:
    body_613806 = body
  result = call_613804.call(path_613805, nil, nil, nil, body_613806)

var startDeployment* = Call_StartDeployment_613790(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_613791, base: "/", url: url_StartDeployment_613792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_613807 = ref object of OpenApiRestCall_612658
proc url_StopJob_613809(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopJob_613808(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613810 = path.getOrDefault("jobId")
  valid_613810 = validateParameter(valid_613810, JString, required = true,
                                 default = nil)
  if valid_613810 != nil:
    section.add "jobId", valid_613810
  var valid_613811 = path.getOrDefault("branchName")
  valid_613811 = validateParameter(valid_613811, JString, required = true,
                                 default = nil)
  if valid_613811 != nil:
    section.add "branchName", valid_613811
  var valid_613812 = path.getOrDefault("appId")
  valid_613812 = validateParameter(valid_613812, JString, required = true,
                                 default = nil)
  if valid_613812 != nil:
    section.add "appId", valid_613812
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
  var valid_613813 = header.getOrDefault("X-Amz-Signature")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Signature", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Content-Sha256", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Date")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Date", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Credential")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Credential", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Security-Token")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Security-Token", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Algorithm")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Algorithm", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-SignedHeaders", valid_613819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613820: Call_StopJob_613807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_613820.validator(path, query, header, formData, body)
  let scheme = call_613820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613820.url(scheme.get, call_613820.host, call_613820.base,
                         call_613820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613820, url, valid)

proc call*(call_613821: Call_StopJob_613807; jobId: string; branchName: string;
          appId: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_613822 = newJObject()
  add(path_613822, "jobId", newJString(jobId))
  add(path_613822, "branchName", newJString(branchName))
  add(path_613822, "appId", newJString(appId))
  result = call_613821.call(path_613822, nil, nil, nil, nil)

var stopJob* = Call_StopJob_613807(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_613808, base: "/",
                                url: url_StopJob_613809,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613823 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613825(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613824(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613826 = path.getOrDefault("resourceArn")
  valid_613826 = validateParameter(valid_613826, JString, required = true,
                                 default = nil)
  if valid_613826 != nil:
    section.add "resourceArn", valid_613826
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613827 = query.getOrDefault("tagKeys")
  valid_613827 = validateParameter(valid_613827, JArray, required = true, default = nil)
  if valid_613827 != nil:
    section.add "tagKeys", valid_613827
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
  var valid_613828 = header.getOrDefault("X-Amz-Signature")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Signature", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Content-Sha256", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Date")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Date", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Credential")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Credential", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Security-Token")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Security-Token", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Algorithm")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Algorithm", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-SignedHeaders", valid_613834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613835: Call_UntagResource_613823; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_613835.validator(path, query, header, formData, body)
  let scheme = call_613835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613835.url(scheme.get, call_613835.host, call_613835.base,
                         call_613835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613835, url, valid)

proc call*(call_613836: Call_UntagResource_613823; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  var path_613837 = newJObject()
  var query_613838 = newJObject()
  add(path_613837, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613838.add "tagKeys", tagKeys
  result = call_613836.call(path_613837, query_613838, nil, nil, nil)

var untagResource* = Call_UntagResource_613823(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613824,
    base: "/", url: url_UntagResource_613825, schemes: {Scheme.Https, Scheme.Http})
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
