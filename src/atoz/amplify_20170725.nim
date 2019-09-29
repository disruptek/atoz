
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_594031 = ref object of OpenApiRestCall_593437
proc url_CreateApp_594033(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApp_594032(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594034 = header.getOrDefault("X-Amz-Date")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Date", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Security-Token")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Security-Token", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Content-Sha256", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Algorithm")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Algorithm", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Signature")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Signature", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-SignedHeaders", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Credential")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Credential", valid_594040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594042: Call_CreateApp_594031; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_594042.validator(path, query, header, formData, body)
  let scheme = call_594042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594042.url(scheme.get, call_594042.host, call_594042.base,
                         call_594042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594042, url, valid)

proc call*(call_594043: Call_CreateApp_594031; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_594044 = newJObject()
  if body != nil:
    body_594044 = body
  result = call_594043.call(nil, nil, nil, nil, body_594044)

var createApp* = Call_CreateApp_594031(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_594032,
                                    base: "/", url: url_CreateApp_594033,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_593774 = ref object of OpenApiRestCall_593437
proc url_ListApps_593776(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApps_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593888 = query.getOrDefault("maxResults")
  valid_593888 = validateParameter(valid_593888, JInt, required = false, default = nil)
  if valid_593888 != nil:
    section.add "maxResults", valid_593888
  var valid_593889 = query.getOrDefault("nextToken")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "nextToken", valid_593889
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
  var valid_593890 = header.getOrDefault("X-Amz-Date")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Date", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Security-Token")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Security-Token", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Content-Sha256", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Algorithm")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Algorithm", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Signature")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Signature", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-SignedHeaders", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Credential")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Credential", valid_593896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593919: Call_ListApps_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_593919.validator(path, query, header, formData, body)
  let scheme = call_593919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593919.url(scheme.get, call_593919.host, call_593919.base,
                         call_593919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593919, url, valid)

proc call*(call_593990: Call_ListApps_593774; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  var query_593991 = newJObject()
  add(query_593991, "maxResults", newJInt(maxResults))
  add(query_593991, "nextToken", newJString(nextToken))
  result = call_593990.call(nil, query_593991, nil, nil, nil)

var listApps* = Call_ListApps_593774(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_593775, base: "/",
                                  url: url_ListApps_593776,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_594076 = ref object of OpenApiRestCall_593437
proc url_CreateBranch_594078(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateBranch_594077(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594079 = path.getOrDefault("appId")
  valid_594079 = validateParameter(valid_594079, JString, required = true,
                                 default = nil)
  if valid_594079 != nil:
    section.add "appId", valid_594079
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
  var valid_594080 = header.getOrDefault("X-Amz-Date")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Date", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Security-Token")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Security-Token", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Content-Sha256", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Algorithm")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Algorithm", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Signature")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Signature", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-SignedHeaders", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Credential")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Credential", valid_594086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594088: Call_CreateBranch_594076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_594088.validator(path, query, header, formData, body)
  let scheme = call_594088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594088.url(scheme.get, call_594088.host, call_594088.base,
                         call_594088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594088, url, valid)

proc call*(call_594089: Call_CreateBranch_594076; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_594090 = newJObject()
  var body_594091 = newJObject()
  add(path_594090, "appId", newJString(appId))
  if body != nil:
    body_594091 = body
  result = call_594089.call(path_594090, nil, nil, nil, body_594091)

var createBranch* = Call_CreateBranch_594076(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_594077,
    base: "/", url: url_CreateBranch_594078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_594045 = ref object of OpenApiRestCall_593437
proc url_ListBranches_594047(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListBranches_594046(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594062 = path.getOrDefault("appId")
  valid_594062 = validateParameter(valid_594062, JString, required = true,
                                 default = nil)
  if valid_594062 != nil:
    section.add "appId", valid_594062
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  section = newJObject()
  var valid_594063 = query.getOrDefault("maxResults")
  valid_594063 = validateParameter(valid_594063, JInt, required = false, default = nil)
  if valid_594063 != nil:
    section.add "maxResults", valid_594063
  var valid_594064 = query.getOrDefault("nextToken")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "nextToken", valid_594064
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
  var valid_594065 = header.getOrDefault("X-Amz-Date")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Date", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Security-Token")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Security-Token", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Content-Sha256", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Algorithm")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Algorithm", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Signature")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Signature", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-SignedHeaders", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Credential")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Credential", valid_594071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594072: Call_ListBranches_594045; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_594072.validator(path, query, header, formData, body)
  let scheme = call_594072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594072.url(scheme.get, call_594072.host, call_594072.base,
                         call_594072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594072, url, valid)

proc call*(call_594073: Call_ListBranches_594045; appId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  var path_594074 = newJObject()
  var query_594075 = newJObject()
  add(path_594074, "appId", newJString(appId))
  add(query_594075, "maxResults", newJInt(maxResults))
  add(query_594075, "nextToken", newJString(nextToken))
  result = call_594073.call(path_594074, query_594075, nil, nil, nil)

var listBranches* = Call_ListBranches_594045(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_594046,
    base: "/", url: url_ListBranches_594047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_594092 = ref object of OpenApiRestCall_593437
proc url_CreateDeployment_594094(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateDeployment_594093(path: JsonNode; query: JsonNode;
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
  var valid_594095 = path.getOrDefault("appId")
  valid_594095 = validateParameter(valid_594095, JString, required = true,
                                 default = nil)
  if valid_594095 != nil:
    section.add "appId", valid_594095
  var valid_594096 = path.getOrDefault("branchName")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = nil)
  if valid_594096 != nil:
    section.add "branchName", valid_594096
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
  var valid_594097 = header.getOrDefault("X-Amz-Date")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Date", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Security-Token")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Security-Token", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Content-Sha256", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Algorithm")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Algorithm", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Signature")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Signature", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-SignedHeaders", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Credential")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Credential", valid_594103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594105: Call_CreateDeployment_594092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_594105.validator(path, query, header, formData, body)
  let scheme = call_594105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594105.url(scheme.get, call_594105.host, call_594105.base,
                         call_594105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594105, url, valid)

proc call*(call_594106: Call_CreateDeployment_594092; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_594107 = newJObject()
  var body_594108 = newJObject()
  add(path_594107, "appId", newJString(appId))
  if body != nil:
    body_594108 = body
  add(path_594107, "branchName", newJString(branchName))
  result = call_594106.call(path_594107, nil, nil, nil, body_594108)

var createDeployment* = Call_CreateDeployment_594092(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_594093, base: "/",
    url: url_CreateDeployment_594094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_594126 = ref object of OpenApiRestCall_593437
proc url_CreateDomainAssociation_594128(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateDomainAssociation_594127(path: JsonNode; query: JsonNode;
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
  var valid_594129 = path.getOrDefault("appId")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = nil)
  if valid_594129 != nil:
    section.add "appId", valid_594129
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
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Security-Token")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Security-Token", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Content-Sha256", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Signature")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Signature", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-SignedHeaders", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Credential")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Credential", valid_594136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_CreateDomainAssociation_594126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_CreateDomainAssociation_594126; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_594140 = newJObject()
  var body_594141 = newJObject()
  add(path_594140, "appId", newJString(appId))
  if body != nil:
    body_594141 = body
  result = call_594139.call(path_594140, nil, nil, nil, body_594141)

var createDomainAssociation* = Call_CreateDomainAssociation_594126(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_594127, base: "/",
    url: url_CreateDomainAssociation_594128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_594109 = ref object of OpenApiRestCall_593437
proc url_ListDomainAssociations_594111(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListDomainAssociations_594110(path: JsonNode; query: JsonNode;
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
  var valid_594112 = path.getOrDefault("appId")
  valid_594112 = validateParameter(valid_594112, JString, required = true,
                                 default = nil)
  if valid_594112 != nil:
    section.add "appId", valid_594112
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  section = newJObject()
  var valid_594113 = query.getOrDefault("maxResults")
  valid_594113 = validateParameter(valid_594113, JInt, required = false, default = nil)
  if valid_594113 != nil:
    section.add "maxResults", valid_594113
  var valid_594114 = query.getOrDefault("nextToken")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "nextToken", valid_594114
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
  var valid_594115 = header.getOrDefault("X-Amz-Date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Date", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Content-Sha256", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Algorithm")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Algorithm", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Signature")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Signature", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-SignedHeaders", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Credential")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Credential", valid_594121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594122: Call_ListDomainAssociations_594109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_594122.validator(path, query, header, formData, body)
  let scheme = call_594122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594122.url(scheme.get, call_594122.host, call_594122.base,
                         call_594122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594122, url, valid)

proc call*(call_594123: Call_ListDomainAssociations_594109; appId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  var path_594124 = newJObject()
  var query_594125 = newJObject()
  add(path_594124, "appId", newJString(appId))
  add(query_594125, "maxResults", newJInt(maxResults))
  add(query_594125, "nextToken", newJString(nextToken))
  result = call_594123.call(path_594124, query_594125, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_594109(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_594110, base: "/",
    url: url_ListDomainAssociations_594111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_594159 = ref object of OpenApiRestCall_593437
proc url_CreateWebhook_594161(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_CreateWebhook_594160(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594162 = path.getOrDefault("appId")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "appId", valid_594162
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
  var valid_594163 = header.getOrDefault("X-Amz-Date")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Date", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Security-Token")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Security-Token", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Content-Sha256", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Algorithm")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Algorithm", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Signature")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Signature", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-SignedHeaders", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Credential")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Credential", valid_594169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594171: Call_CreateWebhook_594159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_594171.validator(path, query, header, formData, body)
  let scheme = call_594171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594171.url(scheme.get, call_594171.host, call_594171.base,
                         call_594171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594171, url, valid)

proc call*(call_594172: Call_CreateWebhook_594159; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_594173 = newJObject()
  var body_594174 = newJObject()
  add(path_594173, "appId", newJString(appId))
  if body != nil:
    body_594174 = body
  result = call_594172.call(path_594173, nil, nil, nil, body_594174)

var createWebhook* = Call_CreateWebhook_594159(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_594160,
    base: "/", url: url_CreateWebhook_594161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_594142 = ref object of OpenApiRestCall_593437
proc url_ListWebhooks_594144(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListWebhooks_594143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594145 = path.getOrDefault("appId")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = nil)
  if valid_594145 != nil:
    section.add "appId", valid_594145
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  section = newJObject()
  var valid_594146 = query.getOrDefault("maxResults")
  valid_594146 = validateParameter(valid_594146, JInt, required = false, default = nil)
  if valid_594146 != nil:
    section.add "maxResults", valid_594146
  var valid_594147 = query.getOrDefault("nextToken")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "nextToken", valid_594147
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
  var valid_594148 = header.getOrDefault("X-Amz-Date")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Date", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Security-Token")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Security-Token", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Content-Sha256", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Algorithm")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Algorithm", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Signature")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Signature", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-SignedHeaders", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Credential")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Credential", valid_594154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594155: Call_ListWebhooks_594142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_594155.validator(path, query, header, formData, body)
  let scheme = call_594155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594155.url(scheme.get, call_594155.host, call_594155.base,
                         call_594155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594155, url, valid)

proc call*(call_594156: Call_ListWebhooks_594142; appId: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  var path_594157 = newJObject()
  var query_594158 = newJObject()
  add(path_594157, "appId", newJString(appId))
  add(query_594158, "maxResults", newJInt(maxResults))
  add(query_594158, "nextToken", newJString(nextToken))
  result = call_594156.call(path_594157, query_594158, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_594142(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_594143,
    base: "/", url: url_ListWebhooks_594144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_594189 = ref object of OpenApiRestCall_593437
proc url_UpdateApp_594191(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_UpdateApp_594190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594192 = path.getOrDefault("appId")
  valid_594192 = validateParameter(valid_594192, JString, required = true,
                                 default = nil)
  if valid_594192 != nil:
    section.add "appId", valid_594192
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
  var valid_594193 = header.getOrDefault("X-Amz-Date")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Date", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Security-Token")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Security-Token", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Content-Sha256", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Algorithm")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Algorithm", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Signature")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Signature", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-SignedHeaders", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Credential")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Credential", valid_594199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594201: Call_UpdateApp_594189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_594201.validator(path, query, header, formData, body)
  let scheme = call_594201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594201.url(scheme.get, call_594201.host, call_594201.base,
                         call_594201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594201, url, valid)

proc call*(call_594202: Call_UpdateApp_594189; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_594203 = newJObject()
  var body_594204 = newJObject()
  add(path_594203, "appId", newJString(appId))
  if body != nil:
    body_594204 = body
  result = call_594202.call(path_594203, nil, nil, nil, body_594204)

var updateApp* = Call_UpdateApp_594189(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_594190,
                                    base: "/", url: url_UpdateApp_594191,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_594175 = ref object of OpenApiRestCall_593437
proc url_GetApp_594177(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetApp_594176(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594178 = path.getOrDefault("appId")
  valid_594178 = validateParameter(valid_594178, JString, required = true,
                                 default = nil)
  if valid_594178 != nil:
    section.add "appId", valid_594178
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
  var valid_594179 = header.getOrDefault("X-Amz-Date")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Date", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Security-Token")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Security-Token", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Algorithm")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Algorithm", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Signature")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Signature", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-SignedHeaders", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Credential")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Credential", valid_594185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594186: Call_GetApp_594175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_594186.validator(path, query, header, formData, body)
  let scheme = call_594186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594186.url(scheme.get, call_594186.host, call_594186.base,
                         call_594186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594186, url, valid)

proc call*(call_594187: Call_GetApp_594175; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_594188 = newJObject()
  add(path_594188, "appId", newJString(appId))
  result = call_594187.call(path_594188, nil, nil, nil, nil)

var getApp* = Call_GetApp_594175(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_594176,
                              base: "/", url: url_GetApp_594177,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_594205 = ref object of OpenApiRestCall_593437
proc url_DeleteApp_594207(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_DeleteApp_594206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594208 = path.getOrDefault("appId")
  valid_594208 = validateParameter(valid_594208, JString, required = true,
                                 default = nil)
  if valid_594208 != nil:
    section.add "appId", valid_594208
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
  var valid_594209 = header.getOrDefault("X-Amz-Date")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Date", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Security-Token")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Security-Token", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Algorithm")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Algorithm", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Signature")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Signature", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-SignedHeaders", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Credential")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Credential", valid_594215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594216: Call_DeleteApp_594205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_594216.validator(path, query, header, formData, body)
  let scheme = call_594216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594216.url(scheme.get, call_594216.host, call_594216.base,
                         call_594216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594216, url, valid)

proc call*(call_594217: Call_DeleteApp_594205; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_594218 = newJObject()
  add(path_594218, "appId", newJString(appId))
  result = call_594217.call(path_594218, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_594205(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_594206,
                                    base: "/", url: url_DeleteApp_594207,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_594234 = ref object of OpenApiRestCall_593437
proc url_UpdateBranch_594236(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateBranch_594235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594237 = path.getOrDefault("appId")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = nil)
  if valid_594237 != nil:
    section.add "appId", valid_594237
  var valid_594238 = path.getOrDefault("branchName")
  valid_594238 = validateParameter(valid_594238, JString, required = true,
                                 default = nil)
  if valid_594238 != nil:
    section.add "branchName", valid_594238
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
  var valid_594239 = header.getOrDefault("X-Amz-Date")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Date", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Security-Token")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Security-Token", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Content-Sha256", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Algorithm")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Algorithm", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Signature")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Signature", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-SignedHeaders", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Credential")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Credential", valid_594245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594247: Call_UpdateBranch_594234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_594247.validator(path, query, header, formData, body)
  let scheme = call_594247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594247.url(scheme.get, call_594247.host, call_594247.base,
                         call_594247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594247, url, valid)

proc call*(call_594248: Call_UpdateBranch_594234; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_594249 = newJObject()
  var body_594250 = newJObject()
  add(path_594249, "appId", newJString(appId))
  if body != nil:
    body_594250 = body
  add(path_594249, "branchName", newJString(branchName))
  result = call_594248.call(path_594249, nil, nil, nil, body_594250)

var updateBranch* = Call_UpdateBranch_594234(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_594235, base: "/", url: url_UpdateBranch_594236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_594219 = ref object of OpenApiRestCall_593437
proc url_GetBranch_594221(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetBranch_594220(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594222 = path.getOrDefault("appId")
  valid_594222 = validateParameter(valid_594222, JString, required = true,
                                 default = nil)
  if valid_594222 != nil:
    section.add "appId", valid_594222
  var valid_594223 = path.getOrDefault("branchName")
  valid_594223 = validateParameter(valid_594223, JString, required = true,
                                 default = nil)
  if valid_594223 != nil:
    section.add "branchName", valid_594223
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
  var valid_594224 = header.getOrDefault("X-Amz-Date")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Date", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Security-Token")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Security-Token", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Content-Sha256", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Algorithm")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Algorithm", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Signature")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Signature", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-SignedHeaders", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Credential")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Credential", valid_594230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594231: Call_GetBranch_594219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_594231.validator(path, query, header, formData, body)
  let scheme = call_594231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594231.url(scheme.get, call_594231.host, call_594231.base,
                         call_594231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594231, url, valid)

proc call*(call_594232: Call_GetBranch_594219; appId: string; branchName: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_594233 = newJObject()
  add(path_594233, "appId", newJString(appId))
  add(path_594233, "branchName", newJString(branchName))
  result = call_594232.call(path_594233, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_594219(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_594220,
                                    base: "/", url: url_GetBranch_594221,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_594251 = ref object of OpenApiRestCall_593437
proc url_DeleteBranch_594253(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteBranch_594252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594254 = path.getOrDefault("appId")
  valid_594254 = validateParameter(valid_594254, JString, required = true,
                                 default = nil)
  if valid_594254 != nil:
    section.add "appId", valid_594254
  var valid_594255 = path.getOrDefault("branchName")
  valid_594255 = validateParameter(valid_594255, JString, required = true,
                                 default = nil)
  if valid_594255 != nil:
    section.add "branchName", valid_594255
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
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Content-Sha256", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Algorithm")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Algorithm", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Signature")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Signature", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-SignedHeaders", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Credential")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Credential", valid_594262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_DeleteBranch_594251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_DeleteBranch_594251; appId: string; branchName: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  var path_594265 = newJObject()
  add(path_594265, "appId", newJString(appId))
  add(path_594265, "branchName", newJString(branchName))
  result = call_594264.call(path_594265, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_594251(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_594252, base: "/", url: url_DeleteBranch_594253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_594281 = ref object of OpenApiRestCall_593437
proc url_UpdateDomainAssociation_594283(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateDomainAssociation_594282(path: JsonNode; query: JsonNode;
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
  var valid_594284 = path.getOrDefault("appId")
  valid_594284 = validateParameter(valid_594284, JString, required = true,
                                 default = nil)
  if valid_594284 != nil:
    section.add "appId", valid_594284
  var valid_594285 = path.getOrDefault("domainName")
  valid_594285 = validateParameter(valid_594285, JString, required = true,
                                 default = nil)
  if valid_594285 != nil:
    section.add "domainName", valid_594285
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
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Content-Sha256", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Algorithm")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Algorithm", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Signature")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Signature", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-SignedHeaders", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Credential")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Credential", valid_594292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594294: Call_UpdateDomainAssociation_594281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_594294.validator(path, query, header, formData, body)
  let scheme = call_594294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594294.url(scheme.get, call_594294.host, call_594294.base,
                         call_594294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594294, url, valid)

proc call*(call_594295: Call_UpdateDomainAssociation_594281; appId: string;
          domainName: string; body: JsonNode): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  ##   body: JObject (required)
  var path_594296 = newJObject()
  var body_594297 = newJObject()
  add(path_594296, "appId", newJString(appId))
  add(path_594296, "domainName", newJString(domainName))
  if body != nil:
    body_594297 = body
  result = call_594295.call(path_594296, nil, nil, nil, body_594297)

var updateDomainAssociation* = Call_UpdateDomainAssociation_594281(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_594282, base: "/",
    url: url_UpdateDomainAssociation_594283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_594266 = ref object of OpenApiRestCall_593437
proc url_GetDomainAssociation_594268(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetDomainAssociation_594267(path: JsonNode; query: JsonNode;
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
  var valid_594269 = path.getOrDefault("appId")
  valid_594269 = validateParameter(valid_594269, JString, required = true,
                                 default = nil)
  if valid_594269 != nil:
    section.add "appId", valid_594269
  var valid_594270 = path.getOrDefault("domainName")
  valid_594270 = validateParameter(valid_594270, JString, required = true,
                                 default = nil)
  if valid_594270 != nil:
    section.add "domainName", valid_594270
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
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Content-Sha256", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Algorithm")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Algorithm", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Signature")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Signature", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-SignedHeaders", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Credential")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Credential", valid_594277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594278: Call_GetDomainAssociation_594266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_594278.validator(path, query, header, formData, body)
  let scheme = call_594278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594278.url(scheme.get, call_594278.host, call_594278.base,
                         call_594278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594278, url, valid)

proc call*(call_594279: Call_GetDomainAssociation_594266; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_594280 = newJObject()
  add(path_594280, "appId", newJString(appId))
  add(path_594280, "domainName", newJString(domainName))
  result = call_594279.call(path_594280, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_594266(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_594267, base: "/",
    url: url_GetDomainAssociation_594268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_594298 = ref object of OpenApiRestCall_593437
proc url_DeleteDomainAssociation_594300(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteDomainAssociation_594299(path: JsonNode; query: JsonNode;
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
  var valid_594301 = path.getOrDefault("appId")
  valid_594301 = validateParameter(valid_594301, JString, required = true,
                                 default = nil)
  if valid_594301 != nil:
    section.add "appId", valid_594301
  var valid_594302 = path.getOrDefault("domainName")
  valid_594302 = validateParameter(valid_594302, JString, required = true,
                                 default = nil)
  if valid_594302 != nil:
    section.add "domainName", valid_594302
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
  var valid_594303 = header.getOrDefault("X-Amz-Date")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Date", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Security-Token")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Security-Token", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Content-Sha256", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Signature")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Signature", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-SignedHeaders", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Credential")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Credential", valid_594309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_DeleteDomainAssociation_594298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_DeleteDomainAssociation_594298; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_594312 = newJObject()
  add(path_594312, "appId", newJString(appId))
  add(path_594312, "domainName", newJString(domainName))
  result = call_594311.call(path_594312, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_594298(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_594299, base: "/",
    url: url_DeleteDomainAssociation_594300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_594313 = ref object of OpenApiRestCall_593437
proc url_GetJob_594315(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetJob_594314(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594316 = path.getOrDefault("jobId")
  valid_594316 = validateParameter(valid_594316, JString, required = true,
                                 default = nil)
  if valid_594316 != nil:
    section.add "jobId", valid_594316
  var valid_594317 = path.getOrDefault("appId")
  valid_594317 = validateParameter(valid_594317, JString, required = true,
                                 default = nil)
  if valid_594317 != nil:
    section.add "appId", valid_594317
  var valid_594318 = path.getOrDefault("branchName")
  valid_594318 = validateParameter(valid_594318, JString, required = true,
                                 default = nil)
  if valid_594318 != nil:
    section.add "branchName", valid_594318
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
  var valid_594319 = header.getOrDefault("X-Amz-Date")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Date", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Security-Token")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Security-Token", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Content-Sha256", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Algorithm")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Algorithm", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Signature")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Signature", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-SignedHeaders", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Credential")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Credential", valid_594325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594326: Call_GetJob_594313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_594326.validator(path, query, header, formData, body)
  let scheme = call_594326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594326.url(scheme.get, call_594326.host, call_594326.base,
                         call_594326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594326, url, valid)

proc call*(call_594327: Call_GetJob_594313; jobId: string; appId: string;
          branchName: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_594328 = newJObject()
  add(path_594328, "jobId", newJString(jobId))
  add(path_594328, "appId", newJString(appId))
  add(path_594328, "branchName", newJString(branchName))
  result = call_594327.call(path_594328, nil, nil, nil, nil)

var getJob* = Call_GetJob_594313(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_594314, base: "/",
                              url: url_GetJob_594315,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_594329 = ref object of OpenApiRestCall_593437
proc url_DeleteJob_594331(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_DeleteJob_594330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594332 = path.getOrDefault("jobId")
  valid_594332 = validateParameter(valid_594332, JString, required = true,
                                 default = nil)
  if valid_594332 != nil:
    section.add "jobId", valid_594332
  var valid_594333 = path.getOrDefault("appId")
  valid_594333 = validateParameter(valid_594333, JString, required = true,
                                 default = nil)
  if valid_594333 != nil:
    section.add "appId", valid_594333
  var valid_594334 = path.getOrDefault("branchName")
  valid_594334 = validateParameter(valid_594334, JString, required = true,
                                 default = nil)
  if valid_594334 != nil:
    section.add "branchName", valid_594334
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
  var valid_594335 = header.getOrDefault("X-Amz-Date")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Date", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Security-Token")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Security-Token", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Content-Sha256", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Algorithm")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Algorithm", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Signature")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Signature", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-SignedHeaders", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Credential")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Credential", valid_594341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594342: Call_DeleteJob_594329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_594342.validator(path, query, header, formData, body)
  let scheme = call_594342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594342.url(scheme.get, call_594342.host, call_594342.base,
                         call_594342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594342, url, valid)

proc call*(call_594343: Call_DeleteJob_594329; jobId: string; appId: string;
          branchName: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_594344 = newJObject()
  add(path_594344, "jobId", newJString(jobId))
  add(path_594344, "appId", newJString(appId))
  add(path_594344, "branchName", newJString(branchName))
  result = call_594343.call(path_594344, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_594329(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_594330,
                                    base: "/", url: url_DeleteJob_594331,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_594359 = ref object of OpenApiRestCall_593437
proc url_UpdateWebhook_594361(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateWebhook_594360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594362 = path.getOrDefault("webhookId")
  valid_594362 = validateParameter(valid_594362, JString, required = true,
                                 default = nil)
  if valid_594362 != nil:
    section.add "webhookId", valid_594362
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
  var valid_594363 = header.getOrDefault("X-Amz-Date")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Date", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Security-Token")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Security-Token", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Content-Sha256", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Algorithm")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Algorithm", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Signature")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Signature", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-SignedHeaders", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Credential")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Credential", valid_594369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594371: Call_UpdateWebhook_594359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_594371.validator(path, query, header, formData, body)
  let scheme = call_594371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594371.url(scheme.get, call_594371.host, call_594371.base,
                         call_594371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594371, url, valid)

proc call*(call_594372: Call_UpdateWebhook_594359; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_594373 = newJObject()
  var body_594374 = newJObject()
  add(path_594373, "webhookId", newJString(webhookId))
  if body != nil:
    body_594374 = body
  result = call_594372.call(path_594373, nil, nil, nil, body_594374)

var updateWebhook* = Call_UpdateWebhook_594359(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_594360,
    base: "/", url: url_UpdateWebhook_594361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_594345 = ref object of OpenApiRestCall_593437
proc url_GetWebhook_594347(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetWebhook_594346(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594348 = path.getOrDefault("webhookId")
  valid_594348 = validateParameter(valid_594348, JString, required = true,
                                 default = nil)
  if valid_594348 != nil:
    section.add "webhookId", valid_594348
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
  var valid_594349 = header.getOrDefault("X-Amz-Date")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Date", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Security-Token")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Security-Token", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Content-Sha256", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-Algorithm")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Algorithm", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Signature")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Signature", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-SignedHeaders", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Credential")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Credential", valid_594355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594356: Call_GetWebhook_594345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_594356.validator(path, query, header, formData, body)
  let scheme = call_594356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594356.url(scheme.get, call_594356.host, call_594356.base,
                         call_594356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594356, url, valid)

proc call*(call_594357: Call_GetWebhook_594345; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_594358 = newJObject()
  add(path_594358, "webhookId", newJString(webhookId))
  result = call_594357.call(path_594358, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_594345(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_594346,
                                      base: "/", url: url_GetWebhook_594347,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_594375 = ref object of OpenApiRestCall_593437
proc url_DeleteWebhook_594377(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteWebhook_594376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594378 = path.getOrDefault("webhookId")
  valid_594378 = validateParameter(valid_594378, JString, required = true,
                                 default = nil)
  if valid_594378 != nil:
    section.add "webhookId", valid_594378
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
  var valid_594379 = header.getOrDefault("X-Amz-Date")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Date", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Security-Token")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Security-Token", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Content-Sha256", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Algorithm")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Algorithm", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Signature")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Signature", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-SignedHeaders", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Credential")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Credential", valid_594385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594386: Call_DeleteWebhook_594375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_594386.validator(path, query, header, formData, body)
  let scheme = call_594386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594386.url(scheme.get, call_594386.host, call_594386.base,
                         call_594386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594386, url, valid)

proc call*(call_594387: Call_DeleteWebhook_594375; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_594388 = newJObject()
  add(path_594388, "webhookId", newJString(webhookId))
  result = call_594387.call(path_594388, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_594375(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_594376,
    base: "/", url: url_DeleteWebhook_594377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_594389 = ref object of OpenApiRestCall_593437
proc url_GenerateAccessLogs_594391(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GenerateAccessLogs_594390(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. Optionally, deliver the logs to a given S3 bucket. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_594392 = path.getOrDefault("appId")
  valid_594392 = validateParameter(valid_594392, JString, required = true,
                                 default = nil)
  if valid_594392 != nil:
    section.add "appId", valid_594392
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
  var valid_594393 = header.getOrDefault("X-Amz-Date")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Date", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Security-Token")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Security-Token", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Content-Sha256", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Algorithm")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Algorithm", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Signature")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Signature", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-SignedHeaders", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Credential")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Credential", valid_594399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594401: Call_GenerateAccessLogs_594389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. Optionally, deliver the logs to a given S3 bucket. 
  ## 
  let valid = call_594401.validator(path, query, header, formData, body)
  let scheme = call_594401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594401.url(scheme.get, call_594401.host, call_594401.base,
                         call_594401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594401, url, valid)

proc call*(call_594402: Call_GenerateAccessLogs_594389; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. Optionally, deliver the logs to a given S3 bucket. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_594403 = newJObject()
  var body_594404 = newJObject()
  add(path_594403, "appId", newJString(appId))
  if body != nil:
    body_594404 = body
  result = call_594402.call(path_594403, nil, nil, nil, body_594404)

var generateAccessLogs* = Call_GenerateAccessLogs_594389(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_594390, base: "/",
    url: url_GenerateAccessLogs_594391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_594405 = ref object of OpenApiRestCall_593437
proc url_GetArtifactUrl_594407(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetArtifactUrl_594406(path: JsonNode; query: JsonNode;
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
  var valid_594408 = path.getOrDefault("artifactId")
  valid_594408 = validateParameter(valid_594408, JString, required = true,
                                 default = nil)
  if valid_594408 != nil:
    section.add "artifactId", valid_594408
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
  var valid_594409 = header.getOrDefault("X-Amz-Date")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Date", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Security-Token")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Security-Token", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Content-Sha256", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Algorithm")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Algorithm", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Signature")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Signature", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-SignedHeaders", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Credential")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Credential", valid_594415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594416: Call_GetArtifactUrl_594405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_594416.validator(path, query, header, formData, body)
  let scheme = call_594416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594416.url(scheme.get, call_594416.host, call_594416.base,
                         call_594416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594416, url, valid)

proc call*(call_594417: Call_GetArtifactUrl_594405; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_594418 = newJObject()
  add(path_594418, "artifactId", newJString(artifactId))
  result = call_594417.call(path_594418, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_594405(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_594406,
    base: "/", url: url_GetArtifactUrl_594407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_594419 = ref object of OpenApiRestCall_593437
proc url_ListArtifacts_594421(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListArtifacts_594420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594422 = path.getOrDefault("jobId")
  valid_594422 = validateParameter(valid_594422, JString, required = true,
                                 default = nil)
  if valid_594422 != nil:
    section.add "jobId", valid_594422
  var valid_594423 = path.getOrDefault("appId")
  valid_594423 = validateParameter(valid_594423, JString, required = true,
                                 default = nil)
  if valid_594423 != nil:
    section.add "appId", valid_594423
  var valid_594424 = path.getOrDefault("branchName")
  valid_594424 = validateParameter(valid_594424, JString, required = true,
                                 default = nil)
  if valid_594424 != nil:
    section.add "branchName", valid_594424
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  section = newJObject()
  var valid_594425 = query.getOrDefault("maxResults")
  valid_594425 = validateParameter(valid_594425, JInt, required = false, default = nil)
  if valid_594425 != nil:
    section.add "maxResults", valid_594425
  var valid_594426 = query.getOrDefault("nextToken")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "nextToken", valid_594426
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
  var valid_594427 = header.getOrDefault("X-Amz-Date")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Date", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Security-Token")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Security-Token", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Content-Sha256", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Algorithm")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Algorithm", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Signature")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Signature", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-SignedHeaders", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-Credential")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-Credential", valid_594433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594435: Call_ListArtifacts_594419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_594435.validator(path, query, header, formData, body)
  let scheme = call_594435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594435.url(scheme.get, call_594435.host, call_594435.base,
                         call_594435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594435, url, valid)

proc call*(call_594436: Call_ListArtifacts_594419; jobId: string; appId: string;
          body: JsonNode; branchName: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
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
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for a branch, part of an Amplify App. 
  var path_594437 = newJObject()
  var query_594438 = newJObject()
  var body_594439 = newJObject()
  add(path_594437, "jobId", newJString(jobId))
  add(path_594437, "appId", newJString(appId))
  add(query_594438, "maxResults", newJInt(maxResults))
  add(query_594438, "nextToken", newJString(nextToken))
  if body != nil:
    body_594439 = body
  add(path_594437, "branchName", newJString(branchName))
  result = call_594436.call(path_594437, query_594438, nil, nil, body_594439)

var listArtifacts* = Call_ListArtifacts_594419(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_594420, base: "/", url: url_ListArtifacts_594421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_594458 = ref object of OpenApiRestCall_593437
proc url_StartJob_594460(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_StartJob_594459(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594461 = path.getOrDefault("appId")
  valid_594461 = validateParameter(valid_594461, JString, required = true,
                                 default = nil)
  if valid_594461 != nil:
    section.add "appId", valid_594461
  var valid_594462 = path.getOrDefault("branchName")
  valid_594462 = validateParameter(valid_594462, JString, required = true,
                                 default = nil)
  if valid_594462 != nil:
    section.add "branchName", valid_594462
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
  var valid_594463 = header.getOrDefault("X-Amz-Date")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Date", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Security-Token")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Security-Token", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Content-Sha256", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Algorithm")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Algorithm", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Signature")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Signature", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-SignedHeaders", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Credential")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Credential", valid_594469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594471: Call_StartJob_594458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_594471.validator(path, query, header, formData, body)
  let scheme = call_594471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594471.url(scheme.get, call_594471.host, call_594471.base,
                         call_594471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594471, url, valid)

proc call*(call_594472: Call_StartJob_594458; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_594473 = newJObject()
  var body_594474 = newJObject()
  add(path_594473, "appId", newJString(appId))
  if body != nil:
    body_594474 = body
  add(path_594473, "branchName", newJString(branchName))
  result = call_594472.call(path_594473, nil, nil, nil, body_594474)

var startJob* = Call_StartJob_594458(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_594459, base: "/",
                                  url: url_StartJob_594460,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_594440 = ref object of OpenApiRestCall_593437
proc url_ListJobs_594442(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_ListJobs_594441(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594443 = path.getOrDefault("appId")
  valid_594443 = validateParameter(valid_594443, JString, required = true,
                                 default = nil)
  if valid_594443 != nil:
    section.add "appId", valid_594443
  var valid_594444 = path.getOrDefault("branchName")
  valid_594444 = validateParameter(valid_594444, JString, required = true,
                                 default = nil)
  if valid_594444 != nil:
    section.add "branchName", valid_594444
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  section = newJObject()
  var valid_594445 = query.getOrDefault("maxResults")
  valid_594445 = validateParameter(valid_594445, JInt, required = false, default = nil)
  if valid_594445 != nil:
    section.add "maxResults", valid_594445
  var valid_594446 = query.getOrDefault("nextToken")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "nextToken", valid_594446
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
  var valid_594447 = header.getOrDefault("X-Amz-Date")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Date", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Security-Token")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Security-Token", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Content-Sha256", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-Algorithm")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Algorithm", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Signature")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Signature", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-SignedHeaders", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Credential")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Credential", valid_594453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594454: Call_ListJobs_594440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_594454.validator(path, query, header, formData, body)
  let scheme = call_594454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594454.url(scheme.get, call_594454.host, call_594454.base,
                         call_594454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594454, url, valid)

proc call*(call_594455: Call_ListJobs_594440; appId: string; branchName: string;
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
  var path_594456 = newJObject()
  var query_594457 = newJObject()
  add(path_594456, "appId", newJString(appId))
  add(query_594457, "maxResults", newJInt(maxResults))
  add(query_594457, "nextToken", newJString(nextToken))
  add(path_594456, "branchName", newJString(branchName))
  result = call_594455.call(path_594456, query_594457, nil, nil, nil)

var listJobs* = Call_ListJobs_594440(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_594441, base: "/",
                                  url: url_ListJobs_594442,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594489 = ref object of OpenApiRestCall_593437
proc url_TagResource_594491(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_594490(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594492 = path.getOrDefault("resourceArn")
  valid_594492 = validateParameter(valid_594492, JString, required = true,
                                 default = nil)
  if valid_594492 != nil:
    section.add "resourceArn", valid_594492
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
  var valid_594493 = header.getOrDefault("X-Amz-Date")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Date", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Security-Token")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Security-Token", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Content-Sha256", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-Algorithm")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Algorithm", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Signature")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Signature", valid_594497
  var valid_594498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-SignedHeaders", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Credential")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Credential", valid_594499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594501: Call_TagResource_594489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_594501.validator(path, query, header, formData, body)
  let scheme = call_594501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594501.url(scheme.get, call_594501.host, call_594501.base,
                         call_594501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594501, url, valid)

proc call*(call_594502: Call_TagResource_594489; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  var path_594503 = newJObject()
  var body_594504 = newJObject()
  if body != nil:
    body_594504 = body
  add(path_594503, "resourceArn", newJString(resourceArn))
  result = call_594502.call(path_594503, nil, nil, nil, body_594504)

var tagResource* = Call_TagResource_594489(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594490,
                                        base: "/", url: url_TagResource_594491,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594475 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594477(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_594476(path: JsonNode; query: JsonNode;
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
  var valid_594478 = path.getOrDefault("resourceArn")
  valid_594478 = validateParameter(valid_594478, JString, required = true,
                                 default = nil)
  if valid_594478 != nil:
    section.add "resourceArn", valid_594478
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
  var valid_594479 = header.getOrDefault("X-Amz-Date")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Date", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Security-Token")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Security-Token", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Content-Sha256", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Algorithm")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Algorithm", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-Signature")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Signature", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-SignedHeaders", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Credential")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Credential", valid_594485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594486: Call_ListTagsForResource_594475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_594486.validator(path, query, header, formData, body)
  let scheme = call_594486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594486.url(scheme.get, call_594486.host, call_594486.base,
                         call_594486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594486, url, valid)

proc call*(call_594487: Call_ListTagsForResource_594475; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_594488 = newJObject()
  add(path_594488, "resourceArn", newJString(resourceArn))
  result = call_594487.call(path_594488, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594475(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594476, base: "/",
    url: url_ListTagsForResource_594477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_594505 = ref object of OpenApiRestCall_593437
proc url_StartDeployment_594507(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_StartDeployment_594506(path: JsonNode; query: JsonNode;
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
  var valid_594508 = path.getOrDefault("appId")
  valid_594508 = validateParameter(valid_594508, JString, required = true,
                                 default = nil)
  if valid_594508 != nil:
    section.add "appId", valid_594508
  var valid_594509 = path.getOrDefault("branchName")
  valid_594509 = validateParameter(valid_594509, JString, required = true,
                                 default = nil)
  if valid_594509 != nil:
    section.add "branchName", valid_594509
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
  var valid_594510 = header.getOrDefault("X-Amz-Date")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Date", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Security-Token")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Security-Token", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Content-Sha256", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-Algorithm")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-Algorithm", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Signature")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Signature", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-SignedHeaders", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Credential")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Credential", valid_594516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594518: Call_StartDeployment_594505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_594518.validator(path, query, header, formData, body)
  let scheme = call_594518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594518.url(scheme.get, call_594518.host, call_594518.base,
                         call_594518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594518, url, valid)

proc call*(call_594519: Call_StartDeployment_594505; appId: string; body: JsonNode;
          branchName: string): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_594520 = newJObject()
  var body_594521 = newJObject()
  add(path_594520, "appId", newJString(appId))
  if body != nil:
    body_594521 = body
  add(path_594520, "branchName", newJString(branchName))
  result = call_594519.call(path_594520, nil, nil, nil, body_594521)

var startDeployment* = Call_StartDeployment_594505(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_594506, base: "/", url: url_StartDeployment_594507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_594522 = ref object of OpenApiRestCall_593437
proc url_StopJob_594524(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_StopJob_594523(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594525 = path.getOrDefault("jobId")
  valid_594525 = validateParameter(valid_594525, JString, required = true,
                                 default = nil)
  if valid_594525 != nil:
    section.add "jobId", valid_594525
  var valid_594526 = path.getOrDefault("appId")
  valid_594526 = validateParameter(valid_594526, JString, required = true,
                                 default = nil)
  if valid_594526 != nil:
    section.add "appId", valid_594526
  var valid_594527 = path.getOrDefault("branchName")
  valid_594527 = validateParameter(valid_594527, JString, required = true,
                                 default = nil)
  if valid_594527 != nil:
    section.add "branchName", valid_594527
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
  var valid_594528 = header.getOrDefault("X-Amz-Date")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-Date", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Security-Token")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Security-Token", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Content-Sha256", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Algorithm")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Algorithm", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-Signature")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Signature", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-SignedHeaders", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Credential")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Credential", valid_594534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594535: Call_StopJob_594522; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_594535.validator(path, query, header, formData, body)
  let scheme = call_594535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594535.url(scheme.get, call_594535.host, call_594535.base,
                         call_594535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594535, url, valid)

proc call*(call_594536: Call_StopJob_594522; jobId: string; appId: string;
          branchName: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  var path_594537 = newJObject()
  add(path_594537, "jobId", newJString(jobId))
  add(path_594537, "appId", newJString(appId))
  add(path_594537, "branchName", newJString(branchName))
  result = call_594536.call(path_594537, nil, nil, nil, nil)

var stopJob* = Call_StopJob_594522(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_594523, base: "/",
                                url: url_StopJob_594524,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594538 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594540(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_594539(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594541 = path.getOrDefault("resourceArn")
  valid_594541 = validateParameter(valid_594541, JString, required = true,
                                 default = nil)
  if valid_594541 != nil:
    section.add "resourceArn", valid_594541
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594542 = query.getOrDefault("tagKeys")
  valid_594542 = validateParameter(valid_594542, JArray, required = true, default = nil)
  if valid_594542 != nil:
    section.add "tagKeys", valid_594542
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
  var valid_594543 = header.getOrDefault("X-Amz-Date")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-Date", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Security-Token")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Security-Token", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Content-Sha256", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Algorithm")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Algorithm", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-Signature")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-Signature", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-SignedHeaders", valid_594548
  var valid_594549 = header.getOrDefault("X-Amz-Credential")
  valid_594549 = validateParameter(valid_594549, JString, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "X-Amz-Credential", valid_594549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594550: Call_UntagResource_594538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_594550.validator(path, query, header, formData, body)
  let scheme = call_594550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594550.url(scheme.get, call_594550.host, call_594550.base,
                         call_594550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594550, url, valid)

proc call*(call_594551: Call_UntagResource_594538; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  var path_594552 = newJObject()
  var query_594553 = newJObject()
  if tagKeys != nil:
    query_594553.add "tagKeys", tagKeys
  add(path_594552, "resourceArn", newJString(resourceArn))
  result = call_594551.call(path_594552, query_594553, nil, nil, nil)

var untagResource* = Call_UntagResource_594538(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594539,
    base: "/", url: url_UntagResource_594540, schemes: {Scheme.Https, Scheme.Http})
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
