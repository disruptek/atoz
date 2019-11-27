
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_CreateApp_599962 = ref object of OpenApiRestCall_599368
proc url_CreateApp_599964(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_599963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599965 = header.getOrDefault("X-Amz-Date")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Date", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Security-Token")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Security-Token", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Content-Sha256", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Algorithm")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Algorithm", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Signature")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Signature", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-SignedHeaders", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Credential")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Credential", valid_599971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599973: Call_CreateApp_599962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_599973.validator(path, query, header, formData, body)
  let scheme = call_599973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599973.url(scheme.get, call_599973.host, call_599973.base,
                         call_599973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599973, url, valid)

proc call*(call_599974: Call_CreateApp_599962; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_599975 = newJObject()
  if body != nil:
    body_599975 = body
  result = call_599974.call(nil, nil, nil, nil, body_599975)

var createApp* = Call_CreateApp_599962(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_599963,
                                    base: "/", url: url_CreateApp_599964,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_599705 = ref object of OpenApiRestCall_599368
proc url_ListApps_599707(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists existing Amplify Apps. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  section = newJObject()
  var valid_599819 = query.getOrDefault("maxResults")
  valid_599819 = validateParameter(valid_599819, JInt, required = false, default = nil)
  if valid_599819 != nil:
    section.add "maxResults", valid_599819
  var valid_599820 = query.getOrDefault("nextToken")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "nextToken", valid_599820
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
  var valid_599821 = header.getOrDefault("X-Amz-Date")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Date", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Security-Token")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Security-Token", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Content-Sha256", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Algorithm")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Algorithm", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Signature")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Signature", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-SignedHeaders", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Credential")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Credential", valid_599827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599850: Call_ListApps_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_599850.validator(path, query, header, formData, body)
  let scheme = call_599850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599850.url(scheme.get, call_599850.host, call_599850.base,
                         call_599850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599850, url, valid)

proc call*(call_599921: Call_ListApps_599705; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  var query_599922 = newJObject()
  add(query_599922, "maxResults", newJInt(maxResults))
  add(query_599922, "nextToken", newJString(nextToken))
  result = call_599921.call(nil, query_599922, nil, nil, nil)

var listApps* = Call_ListApps_599705(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_599706, base: "/",
                                  url: url_ListApps_599707,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackendEnvironment_600009 = ref object of OpenApiRestCall_599368
proc url_CreateBackendEnvironment_600011(protocol: Scheme; host: string;
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

proc validate_CreateBackendEnvironment_600010(path: JsonNode; query: JsonNode;
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
  var valid_600012 = path.getOrDefault("appId")
  valid_600012 = validateParameter(valid_600012, JString, required = true,
                                 default = nil)
  if valid_600012 != nil:
    section.add "appId", valid_600012
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
  var valid_600013 = header.getOrDefault("X-Amz-Date")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Date", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Security-Token")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Security-Token", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Content-Sha256", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Algorithm")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Algorithm", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Signature")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Signature", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-SignedHeaders", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Credential")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Credential", valid_600019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600021: Call_CreateBackendEnvironment_600009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new backend environment for an Amplify App. 
  ## 
  let valid = call_600021.validator(path, query, header, formData, body)
  let scheme = call_600021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600021.url(scheme.get, call_600021.host, call_600021.base,
                         call_600021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600021, url, valid)

proc call*(call_600022: Call_CreateBackendEnvironment_600009; appId: string;
          body: JsonNode): Recallable =
  ## createBackendEnvironment
  ##  Creates a new backend environment for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_600023 = newJObject()
  var body_600024 = newJObject()
  add(path_600023, "appId", newJString(appId))
  if body != nil:
    body_600024 = body
  result = call_600022.call(path_600023, nil, nil, nil, body_600024)

var createBackendEnvironment* = Call_CreateBackendEnvironment_600009(
    name: "createBackendEnvironment", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_CreateBackendEnvironment_600010, base: "/",
    url: url_CreateBackendEnvironment_600011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackendEnvironments_599976 = ref object of OpenApiRestCall_599368
proc url_ListBackendEnvironments_599978(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackendEnvironments_599977(path: JsonNode; query: JsonNode;
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
  var valid_599993 = path.getOrDefault("appId")
  valid_599993 = validateParameter(valid_599993, JString, required = true,
                                 default = nil)
  if valid_599993 != nil:
    section.add "appId", valid_599993
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing backen environments from start. If a non-null pagination token is returned in a result, then pass its value in here to list more backend environments. 
  section = newJObject()
  var valid_599994 = query.getOrDefault("maxResults")
  valid_599994 = validateParameter(valid_599994, JInt, required = false, default = nil)
  if valid_599994 != nil:
    section.add "maxResults", valid_599994
  var valid_599995 = query.getOrDefault("nextToken")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "nextToken", valid_599995
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
  var valid_599996 = header.getOrDefault("X-Amz-Date")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Date", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Security-Token")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Security-Token", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Content-Sha256", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Algorithm")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Algorithm", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Signature")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Signature", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-SignedHeaders", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Credential")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Credential", valid_600002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600004: Call_ListBackendEnvironments_599976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists backend environments for an Amplify App. 
  ## 
  let valid = call_600004.validator(path, query, header, formData, body)
  let scheme = call_600004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600004.url(scheme.get, call_600004.host, call_600004.base,
                         call_600004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600004, url, valid)

proc call*(call_600005: Call_ListBackendEnvironments_599976; appId: string;
          body: JsonNode; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listBackendEnvironments
  ##  Lists backend environments for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing backen environments from start. If a non-null pagination token is returned in a result, then pass its value in here to list more backend environments. 
  ##   body: JObject (required)
  var path_600006 = newJObject()
  var query_600007 = newJObject()
  var body_600008 = newJObject()
  add(path_600006, "appId", newJString(appId))
  add(query_600007, "maxResults", newJInt(maxResults))
  add(query_600007, "nextToken", newJString(nextToken))
  if body != nil:
    body_600008 = body
  result = call_600005.call(path_600006, query_600007, nil, nil, body_600008)

var listBackendEnvironments* = Call_ListBackendEnvironments_599976(
    name: "listBackendEnvironments", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_ListBackendEnvironments_599977, base: "/",
    url: url_ListBackendEnvironments_599978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_600042 = ref object of OpenApiRestCall_599368
proc url_CreateBranch_600044(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBranch_600043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600045 = path.getOrDefault("appId")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = nil)
  if valid_600045 != nil:
    section.add "appId", valid_600045
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
  var valid_600046 = header.getOrDefault("X-Amz-Date")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Date", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Security-Token")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Security-Token", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Content-Sha256", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Algorithm")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Algorithm", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Signature")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Signature", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-SignedHeaders", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Credential")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Credential", valid_600052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600054: Call_CreateBranch_600042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_600054.validator(path, query, header, formData, body)
  let scheme = call_600054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600054.url(scheme.get, call_600054.host, call_600054.base,
                         call_600054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600054, url, valid)

proc call*(call_600055: Call_CreateBranch_600042; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_600056 = newJObject()
  var body_600057 = newJObject()
  add(path_600056, "appId", newJString(appId))
  if body != nil:
    body_600057 = body
  result = call_600055.call(path_600056, nil, nil, nil, body_600057)

var createBranch* = Call_CreateBranch_600042(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_600043,
    base: "/", url: url_CreateBranch_600044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_600025 = ref object of OpenApiRestCall_599368
proc url_ListBranches_600027(protocol: Scheme; host: string; base: string;
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

proc validate_ListBranches_600026(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600028 = path.getOrDefault("appId")
  valid_600028 = validateParameter(valid_600028, JString, required = true,
                                 default = nil)
  if valid_600028 != nil:
    section.add "appId", valid_600028
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  section = newJObject()
  var valid_600029 = query.getOrDefault("maxResults")
  valid_600029 = validateParameter(valid_600029, JInt, required = false, default = nil)
  if valid_600029 != nil:
    section.add "maxResults", valid_600029
  var valid_600030 = query.getOrDefault("nextToken")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "nextToken", valid_600030
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
  var valid_600031 = header.getOrDefault("X-Amz-Date")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Date", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Security-Token")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Security-Token", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Content-Sha256", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Algorithm")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Algorithm", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Signature")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Signature", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-SignedHeaders", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Credential")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Credential", valid_600037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600038: Call_ListBranches_600025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_600038.validator(path, query, header, formData, body)
  let scheme = call_600038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600038.url(scheme.get, call_600038.host, call_600038.base,
                         call_600038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600038, url, valid)

proc call*(call_600039: Call_ListBranches_600025; appId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  var path_600040 = newJObject()
  var query_600041 = newJObject()
  add(path_600040, "appId", newJString(appId))
  add(query_600041, "maxResults", newJInt(maxResults))
  add(query_600041, "nextToken", newJString(nextToken))
  result = call_600039.call(path_600040, query_600041, nil, nil, nil)

var listBranches* = Call_ListBranches_600025(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_600026,
    base: "/", url: url_ListBranches_600027, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_600058 = ref object of OpenApiRestCall_599368
proc url_CreateDeployment_600060(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_600059(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600061 = path.getOrDefault("appId")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = nil)
  if valid_600061 != nil:
    section.add "appId", valid_600061
  var valid_600062 = path.getOrDefault("branchName")
  valid_600062 = validateParameter(valid_600062, JString, required = true,
                                 default = nil)
  if valid_600062 != nil:
    section.add "branchName", valid_600062
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
  var valid_600063 = header.getOrDefault("X-Amz-Date")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Date", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Security-Token")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Security-Token", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Content-Sha256", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Algorithm")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Algorithm", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Signature")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Signature", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-SignedHeaders", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Credential")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Credential", valid_600069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600071: Call_CreateDeployment_600058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_600071.validator(path, query, header, formData, body)
  let scheme = call_600071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600071.url(scheme.get, call_600071.host, call_600071.base,
                         call_600071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600071, url, valid)

proc call*(call_600072: Call_CreateDeployment_600058; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_600073 = newJObject()
  var body_600074 = newJObject()
  add(path_600073, "appId", newJString(appId))
  if body != nil:
    body_600074 = body
  add(path_600073, "branchName", newJString(branchName))
  result = call_600072.call(path_600073, nil, nil, nil, body_600074)

var createDeployment* = Call_CreateDeployment_600058(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_600059, base: "/",
    url: url_CreateDeployment_600060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_600092 = ref object of OpenApiRestCall_599368
proc url_CreateDomainAssociation_600094(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomainAssociation_600093(path: JsonNode; query: JsonNode;
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
  var valid_600095 = path.getOrDefault("appId")
  valid_600095 = validateParameter(valid_600095, JString, required = true,
                                 default = nil)
  if valid_600095 != nil:
    section.add "appId", valid_600095
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
  var valid_600096 = header.getOrDefault("X-Amz-Date")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Date", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Security-Token")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Security-Token", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Content-Sha256", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Algorithm")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Algorithm", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Signature")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Signature", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-SignedHeaders", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Credential")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Credential", valid_600102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600104: Call_CreateDomainAssociation_600092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_600104.validator(path, query, header, formData, body)
  let scheme = call_600104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600104.url(scheme.get, call_600104.host, call_600104.base,
                         call_600104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600104, url, valid)

proc call*(call_600105: Call_CreateDomainAssociation_600092; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_600106 = newJObject()
  var body_600107 = newJObject()
  add(path_600106, "appId", newJString(appId))
  if body != nil:
    body_600107 = body
  result = call_600105.call(path_600106, nil, nil, nil, body_600107)

var createDomainAssociation* = Call_CreateDomainAssociation_600092(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_600093, base: "/",
    url: url_CreateDomainAssociation_600094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_600075 = ref object of OpenApiRestCall_599368
proc url_ListDomainAssociations_600077(protocol: Scheme; host: string; base: string;
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

proc validate_ListDomainAssociations_600076(path: JsonNode; query: JsonNode;
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
  var valid_600078 = path.getOrDefault("appId")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = nil)
  if valid_600078 != nil:
    section.add "appId", valid_600078
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  section = newJObject()
  var valid_600079 = query.getOrDefault("maxResults")
  valid_600079 = validateParameter(valid_600079, JInt, required = false, default = nil)
  if valid_600079 != nil:
    section.add "maxResults", valid_600079
  var valid_600080 = query.getOrDefault("nextToken")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "nextToken", valid_600080
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
  var valid_600081 = header.getOrDefault("X-Amz-Date")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Date", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Security-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Security-Token", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Content-Sha256", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Algorithm")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Algorithm", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Signature")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Signature", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-SignedHeaders", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Credential")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Credential", valid_600087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600088: Call_ListDomainAssociations_600075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_600088.validator(path, query, header, formData, body)
  let scheme = call_600088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600088.url(scheme.get, call_600088.host, call_600088.base,
                         call_600088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600088, url, valid)

proc call*(call_600089: Call_ListDomainAssociations_600075; appId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  var path_600090 = newJObject()
  var query_600091 = newJObject()
  add(path_600090, "appId", newJString(appId))
  add(query_600091, "maxResults", newJInt(maxResults))
  add(query_600091, "nextToken", newJString(nextToken))
  result = call_600089.call(path_600090, query_600091, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_600075(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_600076, base: "/",
    url: url_ListDomainAssociations_600077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_600125 = ref object of OpenApiRestCall_599368
proc url_CreateWebhook_600127(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWebhook_600126(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600128 = path.getOrDefault("appId")
  valid_600128 = validateParameter(valid_600128, JString, required = true,
                                 default = nil)
  if valid_600128 != nil:
    section.add "appId", valid_600128
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
  var valid_600129 = header.getOrDefault("X-Amz-Date")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Date", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Security-Token")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Security-Token", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Content-Sha256", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Algorithm")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Algorithm", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Signature")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Signature", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-SignedHeaders", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Credential")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Credential", valid_600135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600137: Call_CreateWebhook_600125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_CreateWebhook_600125; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_600139 = newJObject()
  var body_600140 = newJObject()
  add(path_600139, "appId", newJString(appId))
  if body != nil:
    body_600140 = body
  result = call_600138.call(path_600139, nil, nil, nil, body_600140)

var createWebhook* = Call_CreateWebhook_600125(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_600126,
    base: "/", url: url_CreateWebhook_600127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_600108 = ref object of OpenApiRestCall_599368
proc url_ListWebhooks_600110(protocol: Scheme; host: string; base: string;
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

proc validate_ListWebhooks_600109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600111 = path.getOrDefault("appId")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = nil)
  if valid_600111 != nil:
    section.add "appId", valid_600111
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  section = newJObject()
  var valid_600112 = query.getOrDefault("maxResults")
  valid_600112 = validateParameter(valid_600112, JInt, required = false, default = nil)
  if valid_600112 != nil:
    section.add "maxResults", valid_600112
  var valid_600113 = query.getOrDefault("nextToken")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "nextToken", valid_600113
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
  var valid_600114 = header.getOrDefault("X-Amz-Date")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Date", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Security-Token")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Security-Token", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Content-Sha256", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Algorithm")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Algorithm", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Signature")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Signature", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-SignedHeaders", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Credential")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Credential", valid_600120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_ListWebhooks_600108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_ListWebhooks_600108; appId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  var path_600123 = newJObject()
  var query_600124 = newJObject()
  add(path_600123, "appId", newJString(appId))
  add(query_600124, "maxResults", newJInt(maxResults))
  add(query_600124, "nextToken", newJString(nextToken))
  result = call_600122.call(path_600123, query_600124, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_600108(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_600109,
    base: "/", url: url_ListWebhooks_600110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_600155 = ref object of OpenApiRestCall_599368
proc url_UpdateApp_600157(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApp_600156(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600158 = path.getOrDefault("appId")
  valid_600158 = validateParameter(valid_600158, JString, required = true,
                                 default = nil)
  if valid_600158 != nil:
    section.add "appId", valid_600158
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
  var valid_600159 = header.getOrDefault("X-Amz-Date")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Date", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Security-Token")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Security-Token", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Content-Sha256", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Algorithm")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Algorithm", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Signature")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Signature", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-SignedHeaders", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Credential")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Credential", valid_600165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600167: Call_UpdateApp_600155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_600167.validator(path, query, header, formData, body)
  let scheme = call_600167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600167.url(scheme.get, call_600167.host, call_600167.base,
                         call_600167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600167, url, valid)

proc call*(call_600168: Call_UpdateApp_600155; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_600169 = newJObject()
  var body_600170 = newJObject()
  add(path_600169, "appId", newJString(appId))
  if body != nil:
    body_600170 = body
  result = call_600168.call(path_600169, nil, nil, nil, body_600170)

var updateApp* = Call_UpdateApp_600155(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_600156,
                                    base: "/", url: url_UpdateApp_600157,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_600141 = ref object of OpenApiRestCall_599368
proc url_GetApp_600143(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_600142(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600144 = path.getOrDefault("appId")
  valid_600144 = validateParameter(valid_600144, JString, required = true,
                                 default = nil)
  if valid_600144 != nil:
    section.add "appId", valid_600144
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
  var valid_600145 = header.getOrDefault("X-Amz-Date")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Date", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Security-Token")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Security-Token", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Content-Sha256", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Algorithm")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Algorithm", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Signature")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Signature", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-SignedHeaders", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Credential")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Credential", valid_600151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600152: Call_GetApp_600141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_600152.validator(path, query, header, formData, body)
  let scheme = call_600152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600152.url(scheme.get, call_600152.host, call_600152.base,
                         call_600152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600152, url, valid)

proc call*(call_600153: Call_GetApp_600141; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_600154 = newJObject()
  add(path_600154, "appId", newJString(appId))
  result = call_600153.call(path_600154, nil, nil, nil, nil)

var getApp* = Call_GetApp_600141(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_600142,
                              base: "/", url: url_GetApp_600143,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_600171 = ref object of OpenApiRestCall_599368
proc url_DeleteApp_600173(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_600172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600174 = path.getOrDefault("appId")
  valid_600174 = validateParameter(valid_600174, JString, required = true,
                                 default = nil)
  if valid_600174 != nil:
    section.add "appId", valid_600174
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
  var valid_600175 = header.getOrDefault("X-Amz-Date")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Date", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Security-Token")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Security-Token", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Content-Sha256", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Algorithm")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Algorithm", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Signature")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Signature", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-SignedHeaders", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Credential")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Credential", valid_600181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600182: Call_DeleteApp_600171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_600182.validator(path, query, header, formData, body)
  let scheme = call_600182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600182.url(scheme.get, call_600182.host, call_600182.base,
                         call_600182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600182, url, valid)

proc call*(call_600183: Call_DeleteApp_600171; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_600184 = newJObject()
  add(path_600184, "appId", newJString(appId))
  result = call_600183.call(path_600184, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_600171(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_600172,
                                    base: "/", url: url_DeleteApp_600173,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackendEnvironment_600185 = ref object of OpenApiRestCall_599368
proc url_GetBackendEnvironment_600187(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackendEnvironment_600186(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves a backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   environmentName: JString (required)
  ##                  :  Name for the backend environment. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600188 = path.getOrDefault("appId")
  valid_600188 = validateParameter(valid_600188, JString, required = true,
                                 default = nil)
  if valid_600188 != nil:
    section.add "appId", valid_600188
  var valid_600189 = path.getOrDefault("environmentName")
  valid_600189 = validateParameter(valid_600189, JString, required = true,
                                 default = nil)
  if valid_600189 != nil:
    section.add "environmentName", valid_600189
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
  var valid_600190 = header.getOrDefault("X-Amz-Date")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Date", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Security-Token")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Security-Token", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600197: Call_GetBackendEnvironment_600185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a backend environment for an Amplify App. 
  ## 
  let valid = call_600197.validator(path, query, header, formData, body)
  let scheme = call_600197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600197.url(scheme.get, call_600197.host, call_600197.base,
                         call_600197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600197, url, valid)

proc call*(call_600198: Call_GetBackendEnvironment_600185; appId: string;
          environmentName: string): Recallable =
  ## getBackendEnvironment
  ##  Retrieves a backend environment for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name for the backend environment. 
  var path_600199 = newJObject()
  add(path_600199, "appId", newJString(appId))
  add(path_600199, "environmentName", newJString(environmentName))
  result = call_600198.call(path_600199, nil, nil, nil, nil)

var getBackendEnvironment* = Call_GetBackendEnvironment_600185(
    name: "getBackendEnvironment", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_GetBackendEnvironment_600186, base: "/",
    url: url_GetBackendEnvironment_600187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackendEnvironment_600200 = ref object of OpenApiRestCall_599368
proc url_DeleteBackendEnvironment_600202(protocol: Scheme; host: string;
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

proc validate_DeleteBackendEnvironment_600201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id of an Amplify App. 
  ##   environmentName: JString (required)
  ##                  :  Name of a backend environment of an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600203 = path.getOrDefault("appId")
  valid_600203 = validateParameter(valid_600203, JString, required = true,
                                 default = nil)
  if valid_600203 != nil:
    section.add "appId", valid_600203
  var valid_600204 = path.getOrDefault("environmentName")
  valid_600204 = validateParameter(valid_600204, JString, required = true,
                                 default = nil)
  if valid_600204 != nil:
    section.add "environmentName", valid_600204
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
  var valid_600205 = header.getOrDefault("X-Amz-Date")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Date", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Security-Token")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Security-Token", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Content-Sha256", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Algorithm")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Algorithm", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Signature")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Signature", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-SignedHeaders", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Credential")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Credential", valid_600211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600212: Call_DeleteBackendEnvironment_600200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete backend environment for an Amplify App. 
  ## 
  let valid = call_600212.validator(path, query, header, formData, body)
  let scheme = call_600212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600212.url(scheme.get, call_600212.host, call_600212.base,
                         call_600212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600212, url, valid)

proc call*(call_600213: Call_DeleteBackendEnvironment_600200; appId: string;
          environmentName: string): Recallable =
  ## deleteBackendEnvironment
  ##  Delete backend environment for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id of an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name of a backend environment of an Amplify App. 
  var path_600214 = newJObject()
  add(path_600214, "appId", newJString(appId))
  add(path_600214, "environmentName", newJString(environmentName))
  result = call_600213.call(path_600214, nil, nil, nil, nil)

var deleteBackendEnvironment* = Call_DeleteBackendEnvironment_600200(
    name: "deleteBackendEnvironment", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_DeleteBackendEnvironment_600201, base: "/",
    url: url_DeleteBackendEnvironment_600202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_600230 = ref object of OpenApiRestCall_599368
proc url_UpdateBranch_600232(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBranch_600231(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600233 = path.getOrDefault("appId")
  valid_600233 = validateParameter(valid_600233, JString, required = true,
                                 default = nil)
  if valid_600233 != nil:
    section.add "appId", valid_600233
  var valid_600234 = path.getOrDefault("branchName")
  valid_600234 = validateParameter(valid_600234, JString, required = true,
                                 default = nil)
  if valid_600234 != nil:
    section.add "branchName", valid_600234
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
  var valid_600235 = header.getOrDefault("X-Amz-Date")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Date", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Security-Token")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Security-Token", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Content-Sha256", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Algorithm")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Algorithm", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Signature")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Signature", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-SignedHeaders", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Credential")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Credential", valid_600241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600243: Call_UpdateBranch_600230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_600243.validator(path, query, header, formData, body)
  let scheme = call_600243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600243.url(scheme.get, call_600243.host, call_600243.base,
                         call_600243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600243, url, valid)

proc call*(call_600244: Call_UpdateBranch_600230; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_600245 = newJObject()
  var body_600246 = newJObject()
  add(path_600245, "appId", newJString(appId))
  if body != nil:
    body_600246 = body
  add(path_600245, "branchName", newJString(branchName))
  result = call_600244.call(path_600245, nil, nil, nil, body_600246)

var updateBranch* = Call_UpdateBranch_600230(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_600231, base: "/", url: url_UpdateBranch_600232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_600215 = ref object of OpenApiRestCall_599368
proc url_GetBranch_600217(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBranch_600216(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600218 = path.getOrDefault("appId")
  valid_600218 = validateParameter(valid_600218, JString, required = true,
                                 default = nil)
  if valid_600218 != nil:
    section.add "appId", valid_600218
  var valid_600219 = path.getOrDefault("branchName")
  valid_600219 = validateParameter(valid_600219, JString, required = true,
                                 default = nil)
  if valid_600219 != nil:
    section.add "branchName", valid_600219
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
  var valid_600220 = header.getOrDefault("X-Amz-Date")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Date", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Security-Token")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Security-Token", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Content-Sha256", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Algorithm")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Algorithm", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Signature")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Signature", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-SignedHeaders", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Credential")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Credential", valid_600226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600227: Call_GetBranch_600215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_600227.validator(path, query, header, formData, body)
  let scheme = call_600227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600227.url(scheme.get, call_600227.host, call_600227.base,
                         call_600227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600227, url, valid)

proc call*(call_600228: Call_GetBranch_600215; appId: string; branchName: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_600229 = newJObject()
  add(path_600229, "appId", newJString(appId))
  add(path_600229, "branchName", newJString(branchName))
  result = call_600228.call(path_600229, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_600215(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_600216,
                                    base: "/", url: url_GetBranch_600217,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_600247 = ref object of OpenApiRestCall_599368
proc url_DeleteBranch_600249(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBranch_600248(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600250 = path.getOrDefault("appId")
  valid_600250 = validateParameter(valid_600250, JString, required = true,
                                 default = nil)
  if valid_600250 != nil:
    section.add "appId", valid_600250
  var valid_600251 = path.getOrDefault("branchName")
  valid_600251 = validateParameter(valid_600251, JString, required = true,
                                 default = nil)
  if valid_600251 != nil:
    section.add "branchName", valid_600251
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
  var valid_600252 = header.getOrDefault("X-Amz-Date")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Date", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Security-Token")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Security-Token", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Content-Sha256", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Algorithm")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Algorithm", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Signature")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Signature", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-SignedHeaders", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Credential")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Credential", valid_600258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600259: Call_DeleteBranch_600247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_600259.validator(path, query, header, formData, body)
  let scheme = call_600259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600259.url(scheme.get, call_600259.host, call_600259.base,
                         call_600259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600259, url, valid)

proc call*(call_600260: Call_DeleteBranch_600247; appId: string; branchName: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_600261 = newJObject()
  add(path_600261, "appId", newJString(appId))
  add(path_600261, "branchName", newJString(branchName))
  result = call_600260.call(path_600261, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_600247(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_600248, base: "/", url: url_DeleteBranch_600249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_600277 = ref object of OpenApiRestCall_599368
proc url_UpdateDomainAssociation_600279(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainAssociation_600278(path: JsonNode; query: JsonNode;
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
  var valid_600280 = path.getOrDefault("appId")
  valid_600280 = validateParameter(valid_600280, JString, required = true,
                                 default = nil)
  if valid_600280 != nil:
    section.add "appId", valid_600280
  var valid_600281 = path.getOrDefault("domainName")
  valid_600281 = validateParameter(valid_600281, JString, required = true,
                                 default = nil)
  if valid_600281 != nil:
    section.add "domainName", valid_600281
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
  var valid_600282 = header.getOrDefault("X-Amz-Date")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Date", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Security-Token")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Security-Token", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Content-Sha256", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Algorithm")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Algorithm", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Signature")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Signature", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-SignedHeaders", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Credential")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Credential", valid_600288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600290: Call_UpdateDomainAssociation_600277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_600290.validator(path, query, header, formData, body)
  let scheme = call_600290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600290.url(scheme.get, call_600290.host, call_600290.base,
                         call_600290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600290, url, valid)

proc call*(call_600291: Call_UpdateDomainAssociation_600277; appId: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  ##   body: JObject (required)
  var path_600292 = newJObject()
  var body_600293 = newJObject()
  add(path_600292, "appId", newJString(appId))
  add(path_600292, "domainName", newJString(domainName))
  if body != nil:
    body_600293 = body
  result = call_600291.call(path_600292, nil, nil, nil, body_600293)

var updateDomainAssociation* = Call_UpdateDomainAssociation_600277(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_600278, base: "/",
    url: url_UpdateDomainAssociation_600279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_600262 = ref object of OpenApiRestCall_599368
proc url_GetDomainAssociation_600264(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainAssociation_600263(path: JsonNode; query: JsonNode;
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
  var valid_600265 = path.getOrDefault("appId")
  valid_600265 = validateParameter(valid_600265, JString, required = true,
                                 default = nil)
  if valid_600265 != nil:
    section.add "appId", valid_600265
  var valid_600266 = path.getOrDefault("domainName")
  valid_600266 = validateParameter(valid_600266, JString, required = true,
                                 default = nil)
  if valid_600266 != nil:
    section.add "domainName", valid_600266
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
  var valid_600267 = header.getOrDefault("X-Amz-Date")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Date", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Security-Token")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Security-Token", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Content-Sha256", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Algorithm")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Algorithm", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-Signature")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Signature", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-SignedHeaders", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Credential")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Credential", valid_600273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600274: Call_GetDomainAssociation_600262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_600274.validator(path, query, header, formData, body)
  let scheme = call_600274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600274.url(scheme.get, call_600274.host, call_600274.base,
                         call_600274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600274, url, valid)

proc call*(call_600275: Call_GetDomainAssociation_600262; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_600276 = newJObject()
  add(path_600276, "appId", newJString(appId))
  add(path_600276, "domainName", newJString(domainName))
  result = call_600275.call(path_600276, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_600262(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_600263, base: "/",
    url: url_GetDomainAssociation_600264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_600294 = ref object of OpenApiRestCall_599368
proc url_DeleteDomainAssociation_600296(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainAssociation_600295(path: JsonNode; query: JsonNode;
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
  var valid_600297 = path.getOrDefault("appId")
  valid_600297 = validateParameter(valid_600297, JString, required = true,
                                 default = nil)
  if valid_600297 != nil:
    section.add "appId", valid_600297
  var valid_600298 = path.getOrDefault("domainName")
  valid_600298 = validateParameter(valid_600298, JString, required = true,
                                 default = nil)
  if valid_600298 != nil:
    section.add "domainName", valid_600298
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
  var valid_600299 = header.getOrDefault("X-Amz-Date")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Date", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Security-Token")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Security-Token", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Content-Sha256", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Algorithm")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Algorithm", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Signature")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Signature", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-SignedHeaders", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Credential")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Credential", valid_600305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600306: Call_DeleteDomainAssociation_600294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_600306.validator(path, query, header, formData, body)
  let scheme = call_600306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600306.url(scheme.get, call_600306.host, call_600306.base,
                         call_600306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600306, url, valid)

proc call*(call_600307: Call_DeleteDomainAssociation_600294; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_600308 = newJObject()
  add(path_600308, "appId", newJString(appId))
  add(path_600308, "domainName", newJString(domainName))
  result = call_600307.call(path_600308, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_600294(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_600295, base: "/",
    url: url_DeleteDomainAssociation_600296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_600309 = ref object of OpenApiRestCall_599368
proc url_GetJob_600311(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_600310(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_600312 = path.getOrDefault("jobId")
  valid_600312 = validateParameter(valid_600312, JString, required = true,
                                 default = nil)
  if valid_600312 != nil:
    section.add "jobId", valid_600312
  var valid_600313 = path.getOrDefault("appId")
  valid_600313 = validateParameter(valid_600313, JString, required = true,
                                 default = nil)
  if valid_600313 != nil:
    section.add "appId", valid_600313
  var valid_600314 = path.getOrDefault("branchName")
  valid_600314 = validateParameter(valid_600314, JString, required = true,
                                 default = nil)
  if valid_600314 != nil:
    section.add "branchName", valid_600314
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
  var valid_600315 = header.getOrDefault("X-Amz-Date")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Date", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Security-Token")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Security-Token", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Content-Sha256", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Algorithm")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Algorithm", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Signature")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Signature", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-SignedHeaders", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Credential")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Credential", valid_600321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600322: Call_GetJob_600309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_600322.validator(path, query, header, formData, body)
  let scheme = call_600322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600322.url(scheme.get, call_600322.host, call_600322.base,
                         call_600322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600322, url, valid)

proc call*(call_600323: Call_GetJob_600309; jobId: string; appId: string;
          branchName: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_600324 = newJObject()
  add(path_600324, "jobId", newJString(jobId))
  add(path_600324, "appId", newJString(appId))
  add(path_600324, "branchName", newJString(branchName))
  result = call_600323.call(path_600324, nil, nil, nil, nil)

var getJob* = Call_GetJob_600309(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_600310, base: "/",
                              url: url_GetJob_600311,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_600325 = ref object of OpenApiRestCall_599368
proc url_DeleteJob_600327(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_600326(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_600328 = path.getOrDefault("jobId")
  valid_600328 = validateParameter(valid_600328, JString, required = true,
                                 default = nil)
  if valid_600328 != nil:
    section.add "jobId", valid_600328
  var valid_600329 = path.getOrDefault("appId")
  valid_600329 = validateParameter(valid_600329, JString, required = true,
                                 default = nil)
  if valid_600329 != nil:
    section.add "appId", valid_600329
  var valid_600330 = path.getOrDefault("branchName")
  valid_600330 = validateParameter(valid_600330, JString, required = true,
                                 default = nil)
  if valid_600330 != nil:
    section.add "branchName", valid_600330
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
  var valid_600331 = header.getOrDefault("X-Amz-Date")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Date", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-Security-Token")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Security-Token", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Content-Sha256", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Algorithm")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Algorithm", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Signature")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Signature", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-SignedHeaders", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Credential")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Credential", valid_600337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600338: Call_DeleteJob_600325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_600338.validator(path, query, header, formData, body)
  let scheme = call_600338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600338.url(scheme.get, call_600338.host, call_600338.base,
                         call_600338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600338, url, valid)

proc call*(call_600339: Call_DeleteJob_600325; jobId: string; appId: string;
          branchName: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_600340 = newJObject()
  add(path_600340, "jobId", newJString(jobId))
  add(path_600340, "appId", newJString(appId))
  add(path_600340, "branchName", newJString(branchName))
  result = call_600339.call(path_600340, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_600325(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_600326,
                                    base: "/", url: url_DeleteJob_600327,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_600355 = ref object of OpenApiRestCall_599368
proc url_UpdateWebhook_600357(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWebhook_600356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600358 = path.getOrDefault("webhookId")
  valid_600358 = validateParameter(valid_600358, JString, required = true,
                                 default = nil)
  if valid_600358 != nil:
    section.add "webhookId", valid_600358
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
  var valid_600359 = header.getOrDefault("X-Amz-Date")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Date", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Security-Token")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Security-Token", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Content-Sha256", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Algorithm")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Algorithm", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Signature")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Signature", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-SignedHeaders", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Credential")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Credential", valid_600365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600367: Call_UpdateWebhook_600355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_600367.validator(path, query, header, formData, body)
  let scheme = call_600367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600367.url(scheme.get, call_600367.host, call_600367.base,
                         call_600367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600367, url, valid)

proc call*(call_600368: Call_UpdateWebhook_600355; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_600369 = newJObject()
  var body_600370 = newJObject()
  add(path_600369, "webhookId", newJString(webhookId))
  if body != nil:
    body_600370 = body
  result = call_600368.call(path_600369, nil, nil, nil, body_600370)

var updateWebhook* = Call_UpdateWebhook_600355(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_600356,
    base: "/", url: url_UpdateWebhook_600357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_600341 = ref object of OpenApiRestCall_599368
proc url_GetWebhook_600343(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetWebhook_600342(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600344 = path.getOrDefault("webhookId")
  valid_600344 = validateParameter(valid_600344, JString, required = true,
                                 default = nil)
  if valid_600344 != nil:
    section.add "webhookId", valid_600344
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
  var valid_600345 = header.getOrDefault("X-Amz-Date")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Date", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Security-Token")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Security-Token", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Content-Sha256", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Algorithm")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Algorithm", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Signature")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Signature", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-SignedHeaders", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Credential")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Credential", valid_600351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600352: Call_GetWebhook_600341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_600352.validator(path, query, header, formData, body)
  let scheme = call_600352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600352.url(scheme.get, call_600352.host, call_600352.base,
                         call_600352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600352, url, valid)

proc call*(call_600353: Call_GetWebhook_600341; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_600354 = newJObject()
  add(path_600354, "webhookId", newJString(webhookId))
  result = call_600353.call(path_600354, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_600341(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_600342,
                                      base: "/", url: url_GetWebhook_600343,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_600371 = ref object of OpenApiRestCall_599368
proc url_DeleteWebhook_600373(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWebhook_600372(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600374 = path.getOrDefault("webhookId")
  valid_600374 = validateParameter(valid_600374, JString, required = true,
                                 default = nil)
  if valid_600374 != nil:
    section.add "webhookId", valid_600374
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
  var valid_600375 = header.getOrDefault("X-Amz-Date")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Date", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Security-Token")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Security-Token", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Content-Sha256", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Algorithm")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Algorithm", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-Signature")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Signature", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-SignedHeaders", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Credential")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Credential", valid_600381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600382: Call_DeleteWebhook_600371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_600382.validator(path, query, header, formData, body)
  let scheme = call_600382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600382.url(scheme.get, call_600382.host, call_600382.base,
                         call_600382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600382, url, valid)

proc call*(call_600383: Call_DeleteWebhook_600371; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_600384 = newJObject()
  add(path_600384, "webhookId", newJString(webhookId))
  result = call_600383.call(path_600384, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_600371(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_600372,
    base: "/", url: url_DeleteWebhook_600373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_600385 = ref object of OpenApiRestCall_599368
proc url_GenerateAccessLogs_600387(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateAccessLogs_600386(path: JsonNode; query: JsonNode;
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
  var valid_600388 = path.getOrDefault("appId")
  valid_600388 = validateParameter(valid_600388, JString, required = true,
                                 default = nil)
  if valid_600388 != nil:
    section.add "appId", valid_600388
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
  var valid_600389 = header.getOrDefault("X-Amz-Date")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Date", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Security-Token")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Security-Token", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Content-Sha256", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Algorithm")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Algorithm", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Signature")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Signature", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-SignedHeaders", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Credential")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Credential", valid_600395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600397: Call_GenerateAccessLogs_600385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ## 
  let valid = call_600397.validator(path, query, header, formData, body)
  let scheme = call_600397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600397.url(scheme.get, call_600397.host, call_600397.base,
                         call_600397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600397, url, valid)

proc call*(call_600398: Call_GenerateAccessLogs_600385; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_600399 = newJObject()
  var body_600400 = newJObject()
  add(path_600399, "appId", newJString(appId))
  if body != nil:
    body_600400 = body
  result = call_600398.call(path_600399, nil, nil, nil, body_600400)

var generateAccessLogs* = Call_GenerateAccessLogs_600385(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_600386, base: "/",
    url: url_GenerateAccessLogs_600387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_600401 = ref object of OpenApiRestCall_599368
proc url_GetArtifactUrl_600403(protocol: Scheme; host: string; base: string;
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

proc validate_GetArtifactUrl_600402(path: JsonNode; query: JsonNode;
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
  var valid_600404 = path.getOrDefault("artifactId")
  valid_600404 = validateParameter(valid_600404, JString, required = true,
                                 default = nil)
  if valid_600404 != nil:
    section.add "artifactId", valid_600404
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
  var valid_600405 = header.getOrDefault("X-Amz-Date")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Date", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Security-Token")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Security-Token", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Content-Sha256", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Algorithm")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Algorithm", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Signature")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Signature", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-SignedHeaders", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Credential")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Credential", valid_600411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600412: Call_GetArtifactUrl_600401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_600412.validator(path, query, header, formData, body)
  let scheme = call_600412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600412.url(scheme.get, call_600412.host, call_600412.base,
                         call_600412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600412, url, valid)

proc call*(call_600413: Call_GetArtifactUrl_600401; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_600414 = newJObject()
  add(path_600414, "artifactId", newJString(artifactId))
  result = call_600413.call(path_600414, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_600401(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_600402,
    base: "/", url: url_GetArtifactUrl_600403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_600415 = ref object of OpenApiRestCall_599368
proc url_ListArtifacts_600417(protocol: Scheme; host: string; base: string;
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

proc validate_ListArtifacts_600416(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for an Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for a branch, part of an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_600418 = path.getOrDefault("jobId")
  valid_600418 = validateParameter(valid_600418, JString, required = true,
                                 default = nil)
  if valid_600418 != nil:
    section.add "jobId", valid_600418
  var valid_600419 = path.getOrDefault("appId")
  valid_600419 = validateParameter(valid_600419, JString, required = true,
                                 default = nil)
  if valid_600419 != nil:
    section.add "appId", valid_600419
  var valid_600420 = path.getOrDefault("branchName")
  valid_600420 = validateParameter(valid_600420, JString, required = true,
                                 default = nil)
  if valid_600420 != nil:
    section.add "branchName", valid_600420
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  section = newJObject()
  var valid_600421 = query.getOrDefault("maxResults")
  valid_600421 = validateParameter(valid_600421, JInt, required = false, default = nil)
  if valid_600421 != nil:
    section.add "maxResults", valid_600421
  var valid_600422 = query.getOrDefault("nextToken")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "nextToken", valid_600422
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
  var valid_600423 = header.getOrDefault("X-Amz-Date")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Date", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-Security-Token")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-Security-Token", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Content-Sha256", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-Algorithm")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Algorithm", valid_600426
  var valid_600427 = header.getOrDefault("X-Amz-Signature")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Signature", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-SignedHeaders", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Credential")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Credential", valid_600429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600430: Call_ListArtifacts_600415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_600430.validator(path, query, header, formData, body)
  let scheme = call_600430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600430.url(scheme.get, call_600430.host, call_600430.base,
                         call_600430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600430, url, valid)

proc call*(call_600431: Call_ListArtifacts_600415; jobId: string; appId: string;
          branchName: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listArtifacts
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ##   jobId: string (required)
  ##        :  Unique Id for an Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   branchName: string (required)
  ##             :  Name for a branch, part of an Amplify App. 
  var path_600432 = newJObject()
  var query_600433 = newJObject()
  add(path_600432, "jobId", newJString(jobId))
  add(path_600432, "appId", newJString(appId))
  add(query_600433, "maxResults", newJInt(maxResults))
  add(query_600433, "nextToken", newJString(nextToken))
  add(path_600432, "branchName", newJString(branchName))
  result = call_600431.call(path_600432, query_600433, nil, nil, nil)

var listArtifacts* = Call_ListArtifacts_600415(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_600416, base: "/", url: url_ListArtifacts_600417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_600452 = ref object of OpenApiRestCall_599368
proc url_StartJob_600454(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartJob_600453(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600455 = path.getOrDefault("appId")
  valid_600455 = validateParameter(valid_600455, JString, required = true,
                                 default = nil)
  if valid_600455 != nil:
    section.add "appId", valid_600455
  var valid_600456 = path.getOrDefault("branchName")
  valid_600456 = validateParameter(valid_600456, JString, required = true,
                                 default = nil)
  if valid_600456 != nil:
    section.add "branchName", valid_600456
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
  var valid_600457 = header.getOrDefault("X-Amz-Date")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Date", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Security-Token")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Security-Token", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Content-Sha256", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Algorithm")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Algorithm", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Signature")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Signature", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-SignedHeaders", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Credential")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Credential", valid_600463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600465: Call_StartJob_600452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_600465.validator(path, query, header, formData, body)
  let scheme = call_600465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600465.url(scheme.get, call_600465.host, call_600465.base,
                         call_600465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600465, url, valid)

proc call*(call_600466: Call_StartJob_600452; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_600467 = newJObject()
  var body_600468 = newJObject()
  add(path_600467, "appId", newJString(appId))
  if body != nil:
    body_600468 = body
  add(path_600467, "branchName", newJString(branchName))
  result = call_600466.call(path_600467, nil, nil, nil, body_600468)

var startJob* = Call_StartJob_600452(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_600453, base: "/",
                                  url: url_StartJob_600454,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_600434 = ref object of OpenApiRestCall_599368
proc url_ListJobs_600436(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_600435(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for a branch. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600437 = path.getOrDefault("appId")
  valid_600437 = validateParameter(valid_600437, JString, required = true,
                                 default = nil)
  if valid_600437 != nil:
    section.add "appId", valid_600437
  var valid_600438 = path.getOrDefault("branchName")
  valid_600438 = validateParameter(valid_600438, JString, required = true,
                                 default = nil)
  if valid_600438 != nil:
    section.add "branchName", valid_600438
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  section = newJObject()
  var valid_600439 = query.getOrDefault("maxResults")
  valid_600439 = validateParameter(valid_600439, JInt, required = false, default = nil)
  if valid_600439 != nil:
    section.add "maxResults", valid_600439
  var valid_600440 = query.getOrDefault("nextToken")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "nextToken", valid_600440
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
  var valid_600441 = header.getOrDefault("X-Amz-Date")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Date", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Security-Token")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Security-Token", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Content-Sha256", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Algorithm")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Algorithm", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Signature")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Signature", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-SignedHeaders", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Credential")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Credential", valid_600447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600448: Call_ListJobs_600434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_600448.validator(path, query, header, formData, body)
  let scheme = call_600448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600448.url(scheme.get, call_600448.host, call_600448.base,
                         call_600448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600448, url, valid)

proc call*(call_600449: Call_ListJobs_600434; appId: string; branchName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listJobs
  ##  List Jobs for a branch, part of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   branchName: string (required)
  ##             :  Name for a branch. 
  var path_600450 = newJObject()
  var query_600451 = newJObject()
  add(path_600450, "appId", newJString(appId))
  add(query_600451, "maxResults", newJInt(maxResults))
  add(query_600451, "nextToken", newJString(nextToken))
  add(path_600450, "branchName", newJString(branchName))
  result = call_600449.call(path_600450, query_600451, nil, nil, nil)

var listJobs* = Call_ListJobs_600434(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_600435, base: "/",
                                  url: url_ListJobs_600436,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600483 = ref object of OpenApiRestCall_599368
proc url_TagResource_600485(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600484(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600486 = path.getOrDefault("resourceArn")
  valid_600486 = validateParameter(valid_600486, JString, required = true,
                                 default = nil)
  if valid_600486 != nil:
    section.add "resourceArn", valid_600486
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
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Content-Sha256", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Algorithm")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Algorithm", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Signature")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Signature", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-SignedHeaders", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Credential")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Credential", valid_600493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600495: Call_TagResource_600483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_600495.validator(path, query, header, formData, body)
  let scheme = call_600495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600495.url(scheme.get, call_600495.host, call_600495.base,
                         call_600495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600495, url, valid)

proc call*(call_600496: Call_TagResource_600483; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  var path_600497 = newJObject()
  var body_600498 = newJObject()
  if body != nil:
    body_600498 = body
  add(path_600497, "resourceArn", newJString(resourceArn))
  result = call_600496.call(path_600497, nil, nil, nil, body_600498)

var tagResource* = Call_TagResource_600483(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600484,
                                        base: "/", url: url_TagResource_600485,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600469 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600471(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600470(path: JsonNode; query: JsonNode;
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
  var valid_600472 = path.getOrDefault("resourceArn")
  valid_600472 = validateParameter(valid_600472, JString, required = true,
                                 default = nil)
  if valid_600472 != nil:
    section.add "resourceArn", valid_600472
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
  var valid_600473 = header.getOrDefault("X-Amz-Date")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Date", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Security-Token")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Security-Token", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Content-Sha256", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Algorithm")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Algorithm", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Signature")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Signature", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-SignedHeaders", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Credential")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Credential", valid_600479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600480: Call_ListTagsForResource_600469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_600480.validator(path, query, header, formData, body)
  let scheme = call_600480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600480.url(scheme.get, call_600480.host, call_600480.base,
                         call_600480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600480, url, valid)

proc call*(call_600481: Call_ListTagsForResource_600469; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_600482 = newJObject()
  add(path_600482, "resourceArn", newJString(resourceArn))
  result = call_600481.call(path_600482, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600469(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_600470, base: "/",
    url: url_ListTagsForResource_600471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_600499 = ref object of OpenApiRestCall_599368
proc url_StartDeployment_600501(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_600500(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_600502 = path.getOrDefault("appId")
  valid_600502 = validateParameter(valid_600502, JString, required = true,
                                 default = nil)
  if valid_600502 != nil:
    section.add "appId", valid_600502
  var valid_600503 = path.getOrDefault("branchName")
  valid_600503 = validateParameter(valid_600503, JString, required = true,
                                 default = nil)
  if valid_600503 != nil:
    section.add "branchName", valid_600503
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
  var valid_600504 = header.getOrDefault("X-Amz-Date")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Date", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Security-Token")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Security-Token", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Content-Sha256", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Algorithm")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Algorithm", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Signature")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Signature", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-SignedHeaders", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Credential")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Credential", valid_600510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600512: Call_StartDeployment_600499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_600512.validator(path, query, header, formData, body)
  let scheme = call_600512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600512.url(scheme.get, call_600512.host, call_600512.base,
                         call_600512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600512, url, valid)

proc call*(call_600513: Call_StartDeployment_600499; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_600514 = newJObject()
  var body_600515 = newJObject()
  add(path_600514, "appId", newJString(appId))
  if body != nil:
    body_600515 = body
  add(path_600514, "branchName", newJString(branchName))
  result = call_600513.call(path_600514, nil, nil, nil, body_600515)

var startDeployment* = Call_StartDeployment_600499(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_600500, base: "/", url: url_StartDeployment_600501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_600516 = ref object of OpenApiRestCall_599368
proc url_StopJob_600518(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopJob_600517(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_600519 = path.getOrDefault("jobId")
  valid_600519 = validateParameter(valid_600519, JString, required = true,
                                 default = nil)
  if valid_600519 != nil:
    section.add "jobId", valid_600519
  var valid_600520 = path.getOrDefault("appId")
  valid_600520 = validateParameter(valid_600520, JString, required = true,
                                 default = nil)
  if valid_600520 != nil:
    section.add "appId", valid_600520
  var valid_600521 = path.getOrDefault("branchName")
  valid_600521 = validateParameter(valid_600521, JString, required = true,
                                 default = nil)
  if valid_600521 != nil:
    section.add "branchName", valid_600521
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
  var valid_600522 = header.getOrDefault("X-Amz-Date")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Date", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Security-Token")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Security-Token", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Content-Sha256", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Algorithm")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Algorithm", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Signature")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Signature", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-SignedHeaders", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Credential")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Credential", valid_600528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600529: Call_StopJob_600516; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_600529.validator(path, query, header, formData, body)
  let scheme = call_600529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600529.url(scheme.get, call_600529.host, call_600529.base,
                         call_600529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600529, url, valid)

proc call*(call_600530: Call_StopJob_600516; jobId: string; appId: string;
          branchName: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_600531 = newJObject()
  add(path_600531, "jobId", newJString(jobId))
  add(path_600531, "appId", newJString(appId))
  add(path_600531, "branchName", newJString(branchName))
  result = call_600530.call(path_600531, nil, nil, nil, nil)

var stopJob* = Call_StopJob_600516(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_600517, base: "/",
                                url: url_StopJob_600518,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600532 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600534(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600535 = path.getOrDefault("resourceArn")
  valid_600535 = validateParameter(valid_600535, JString, required = true,
                                 default = nil)
  if valid_600535 != nil:
    section.add "resourceArn", valid_600535
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600536 = query.getOrDefault("tagKeys")
  valid_600536 = validateParameter(valid_600536, JArray, required = true, default = nil)
  if valid_600536 != nil:
    section.add "tagKeys", valid_600536
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
  var valid_600537 = header.getOrDefault("X-Amz-Date")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Date", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Security-Token")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Security-Token", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Content-Sha256", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Algorithm")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Algorithm", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Signature")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Signature", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-SignedHeaders", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Credential")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Credential", valid_600543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600544: Call_UntagResource_600532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_600544.validator(path, query, header, formData, body)
  let scheme = call_600544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600544.url(scheme.get, call_600544.host, call_600544.base,
                         call_600544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600544, url, valid)

proc call*(call_600545: Call_UntagResource_600532; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  var path_600546 = newJObject()
  var query_600547 = newJObject()
  if tagKeys != nil:
    query_600547.add "tagKeys", tagKeys
  add(path_600546, "resourceArn", newJString(resourceArn))
  result = call_600545.call(path_600546, query_600547, nil, nil, nil)

var untagResource* = Call_UntagResource_600532(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_600533,
    base: "/", url: url_UntagResource_600534, schemes: {Scheme.Https, Scheme.Http})
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
